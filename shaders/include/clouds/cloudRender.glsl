#ifndef INCLUDE_CLOUD_RENDER
#define INCLUDE_CLOUD_RENDER

/* Port dari The Rev: shaders/lib/atmosphere/clouds/Render.glsl (Apache License 2.0)
   Refs: Schneider 2015-2023, Hillaire 2016, Högfeldt 2016, Bauer 2019, Wrenninge et al. 2013 */

#include "/include/clouds/cloudUtil.glsl"
#include "/include/clouds/cloudShape.glsl"
#include "/include/clouds/cloudPhaseLut.glsl"
#include "/include/clouds/cloudProximaLow.glsl"

float CloudVolumeOpticalDepth(vec3 rayPos, vec3 rayDir, float noise) {
	const uint steps = uint(CLOUD_LOW_SUNLIGHT_SAMPLES);
	const float rSteps = 1.0 / float(steps);
	float rayLength = cloudLayer0.thickness / max(rayDir.y, 0.5) * REV_LOW_LIGHT_DISTANCE;

	float stepLength = rayLength * rSteps * rSteps;
	vec3 rayStep = rayDir * stepLength;

	float threshold = -log(0.005) / (cloudLayer0.coeff.extinction * stepLength);

	float sumDensity = 0.0;
	for (uint i = 0u; i < steps && sumDensity < threshold; ++i) {
		float fi = float(i);
		vec3 samplePos = rayPos + rayStep * sqr(fi + noise);

		float heightFraction = length(samplePos) * rcp(cloudLayer0.thickness) - cloudLayer0.minHeight / cloudLayer0.thickness;

		float temp;
		uint sampleMode = i < uint(REV_LOW_SUNLIGHT_DETAIL_SAMPLES) ? cloudDensityModeDetail : cloudDensityModeBase;
		float density = CloudVolumeDensity(samplePos, heightFraction, temp, sampleMode);
		sumDensity += density * (fi + 0.5);
	}

	return cloudLayer0.coeff.extinction * 2.0 * stepLength * sumDensity;
}

vec2 CloudMultiScatteringApproxHaringPro(float sunlightOD, float phase, float sigmaT, float omega, float msVolume, vec3 lightDir) {
	// https://zhuanlan.zhihu.com/p/457997155
	float fms = omega * oms(exp2(-256.0 * sigmaT));

	float scatteringSun = phase + uniformPhase * fms / (1.0 - fms);
	scatteringSun *= exp(-sunlightOD);
	scatteringSun += msVolume / (1.0 + sunlightOD * 0.5);

	float skylightOD = sunlightOD * max(lightDir.y, 0.1);
	float scatteringSky = 1.0 / (1.0 + skylightOD);

	return vec2(scatteringSun, scatteringSky);
}

vec3 RenderCloudHigh(vec3 rayPos, vec3 lightDir, float noise, float LdotV) {
	float density = CloudHighDensity(rayPos.xz);
	if (density > EPS) {
		float sigmaT = density * cloudLayer2.coeff.extinction;
		float transmittance = exp2(-rLOG2 * sigmaT * cloudLayer2.thickness);

		const uint steps = uint(REV_HI_SUNLIGHT_SAMPLES);
		const float rSteps = 1.0 / float(steps);
		float rayLength = cloudLayer2.thickness / max(lightDir.y, 0.5);
		float stepLength = rayLength * rSteps * rSteps;

		vec2 rayStep = lightDir.xz * stepLength;

		float sumDensity = 0.0;
		for (uint i = 0u; i < steps; ++i) {
			float fi = float(i);
			vec2 samplePos = rayPos.xz + rayStep * sqr(fi + noise);
			float d = CloudHighDensity(samplePos);
			sumDensity += d * (fi + 0.5);
		}

		float opticalDepthSun = cloudLayer2.coeff.extinction * 2.0 * stepLength * sumDensity;

		float phase = SampleCloudPhaseLutScalar(LdotV, CLOUD_PHASE_CI);
		vec2 scattering = CloudMultiScatteringApproxHaringPro(opticalDepthSun, phase, sigmaT, cloudLayer2.coeff.albedo, density + 0.25, lightDir);

		scattering *= oms(transmittance) * cloudLayer2.coeff.albedo;
		return vec3(scattering, transmittance);
	}

	return vec3(0.0, 0.0, 1.0);
}

// skyRadiance & skyUpIlluminance dalam satuan ZEPT (tanpa EXPONENT_BIAS)
CloudRenderResult RenderClouds(vec3 rayDir, vec2 noise, vec3 skyRadiance, vec3 skyUpIlluminance) {
	CloudRenderResult result = CloudRenderResult(vec3(0.0), 1.0, 1e6);

	vec2 scatteringBase = vec2(0.0);

	float moonlightFactor = smoothstep(-0.03, -0.05, sunDir.y);
	vec3 lightDir = normalize(sunDir * oms(2.0 * moonlightFactor));

	float LdotV = dot(lightDir, rayDir);

	float r = atmosphereViewHeight;
	float mu = rayDir.y;

	float phase = SampleCloudPhaseLutScalar(LdotV, CLOUD_PHASE_CU);

	bool planetIntersection = RayIntersectPlanetGround(r, mu);

	// Low-level clouds
	#if defined CLOUD_CU && defined PROXIMA_LOW_CLOUDS
		RenderProximaLowClouds(rayDir, noise, scatteringBase, result);
	#elif defined CLOUD_CU
		if (!((planetIntersection && r < cloudLayer0.minHeight) || (mu > 0.0 && r > cloudLayer0.maxHeight))) {
			vec2 intersection = RaySphericalShellIntersection(r, mu, cloudLayer0.minHeight, cloudLayer0.maxHeight);

			if (intersection.y > 0.0) {
				const float maxRaymarchingDist = REV_LOW_MAX_DISTANCE * 1000.0;
				float tMax = clamp(intersection.y - intersection.x, 0.0, maxRaymarchingDist);

				float stepCount = floor(mix(
					float(CLOUD_LOW_SAMPLES_MIN),
					float(CLOUD_LOW_SAMPLES_MAX),
					saturate(tMax * rcp(maxRaymarchingDist))
				));
				float invStepCount = rcp(stepCount);
				float stepLength = tMax * invStepCount;

				vec3 startPos = atmosphereViewPos + rayDir * intersection.x;

				float sumDist = 0.0;

				vec2 stepScattering = vec2(0.0);
				float transmittance = 1.0;
				#ifdef CLOUD_EMPTY_SPACE_SKIP
					bool fineSampling = true;
					uint emptySampleCount = 0u;
					const uint emptySampleLimit = uint(REV_LOW_EMPTY_SAMPLE_LIMIT);
					const float maxCoarseSpan = cloudLayer0.thickness * 0.125;
					bool allowCoarseStride = stepLength <= maxCoarseSpan;
				#endif

				for (int i = 0; i < int(stepCount); ++i) {
					float t = (float(i) + noise.x) * stepLength;
					vec3 rayPos = startPos + rayDir * t;

					float heightFraction = length(rayPos) * rcp(cloudLayer0.thickness) - cloudLayer0.minHeight / cloudLayer0.thickness;

					#ifdef CLOUD_EMPTY_SPACE_SKIP
					if (!fineSampling) {
						float dimensionalProfile;
						CloudVolumeDensity(rayPos, heightFraction, dimensionalProfile, cloudDensityModeCoarse);
						if (dimensionalProfile < cloudProfileEpsilon) {
							if (allowCoarseStride) i++;
							continue;
						}
						fineSampling = true;
						emptySampleCount = 0u;
						i = max(i - 2, -1);
						continue;
					}
					#endif

					float dimensionalProfile;
					float stepDensity = CloudVolumeDensity(rayPos, heightFraction, dimensionalProfile, cloudDensityModeDetail);

					#ifdef CLOUD_EMPTY_SPACE_SKIP
					if (stepDensity < cloudDensityEpsilon) {
						if (++emptySampleCount >= emptySampleLimit) {
							fineSampling = false;
							emptySampleCount = 0u;
						}
						continue;
					}
					emptySampleCount = 0u;
					#endif

					if (stepDensity >= cloudDensityEpsilon) {
						float sigmaT = stepDensity * cloudLayer0.coeff.extinction;

						float opticalDepthSun = CloudVolumeOpticalDepth(rayPos, lightDir, noise.y) * REV_LOW_SHADOW_DARKNESS;

						float msVolume = linearstep(0.25, 1.0, dimensionalProfile);
						msVolume *= linearstep(0.0, 0.4, heightFraction);
						msVolume *= REV_LOW_MS_ENERGY;
						vec2 scattering = CloudMultiScatteringApproxHaringPro(opticalDepthSun, phase, sigmaT, cloudLayer0.coeff.albedo, msVolume, lightDir);

						scattering.y = pow(max(scattering.y, 0.0), REV_LOW_SKY_OCCLUSION);

						#ifdef REV_LOW_POWDER
							float powder = oms(exp2(-rLOG2 * 2.0 * sigmaT * REV_LOW_POWDER_DEPTH));
							powder = mix(powder, 1.0, saturate(LdotV * 0.5 + 0.5));
							scattering.x *= mix(1.0, powder, REV_LOW_POWDER_STRENGTH);
						#endif

						float groundT = rcp(1.0 + sigmaT * heightFraction * cloudLayer0.thickness);
						scattering += groundT * uniformPhase * lightDir.y * REV_LOW_GROUND_MULT;

						float stepTransmittance = exp2(-rLOG2 * sigmaT * stepLength);

						float stepIntegral = transmittance * oms(stepTransmittance);
						stepScattering += scattering * stepIntegral;
						transmittance *= stepTransmittance;

						sumDist += (t + intersection.x) * stepIntegral;

						if (transmittance < REV_LOW_MIN_TRANSMITTANCE) {
							transmittance = 0.0;
							break;
						}
					}
				}

				if (lessThanFLT1(transmittance)) {
					scatteringBase = stepScattering * cloudLayer0.coeff.albedo * vec2(REV_LOW_SUN_MULT, REV_LOW_SKY_MULT);
					scatteringBase.x *= oms(wetness * REV_LOW_RAIN_DARKEN);
					result.transmittance = transmittance;
					result.frontDepth = sumDist / oms(transmittance);
				}
			}
		}
	#endif

	// Mid-level clouds: TODO di The Rev

	// High-level clouds
	#if defined CLOUD_CC || defined CLOUD_CS || defined CLOUD_CI
		vec2 intersectionHi = RaySphereIntersection(r, mu, cloudLayer2.minHeight);

		if (intersectionHi.y > 0.0 && (!planetIntersection || r > cloudLayer2.minHeight)) {
			float rayLength = r > cloudLayer2.minHeight ? intersectionHi.x : intersectionHi.y;
			vec3 rayPos = rayDir * rayLength + atmosphereViewPos;

			vec3 cloudTemp = RenderCloudHigh(rayPos, lightDir, noise.y, LdotV);

			if (lessThanFLT1(cloudTemp.z)) {
				scatteringBase = mix(scatteringBase + cloudTemp.xy * result.transmittance, scatteringBase * cloudTemp.z + cloudTemp.xy, step(cloudLayer2.minHeight, r));
				result.transmittance *= cloudTemp.z;
				result.frontDepth = min(rayLength, result.frontDepth);
			}
		}
	#endif

	if (lessThanFLT1(result.transmittance)) {
		vec3 cloudPos = atmosphereViewPos + rayDir * result.frontDepth;

		// [ZEPT] matahari ZEPT = 1.0 (satuan langit evalScattering), bulan = slider
		vec3 sunIlluminance  = vec3(CLOUD_SUN_ILLUMINANCE) * CloudTransmittanceToLight(cloudPos, sunDir);
		vec3 moonIlluminance = cloudMoonColor * CLOUD_MOON_ILLUMINANCE * CloudTransmittanceToLight(cloudPos, moonDir);
		vec3 directIlluminance = sunIlluminance + moonIlluminance;

		result.scatteredLight  = scatteringBase.x * directIlluminance;
		result.scatteredLight += scatteringBase.y * skyUpIlluminance;

		result.scatteredLight += LightningContribution(cloudPos - atmosphereViewPos) * sqr(scatteringBase.y);

		// Aerial perspective
		vec3 aerialT = CloudAerialTransmittance(rayDir, result.frontDepth);
		result.scatteredLight = mix(skyRadiance * oms(result.transmittance), result.scatteredLight, aerialT);
	}

	return result;
}

#endif
