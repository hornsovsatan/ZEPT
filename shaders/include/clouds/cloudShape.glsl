#ifndef INCLUDE_CLOUD_SHAPE
#define INCLUDE_CLOUD_SHAPE

/* Port dari The Rev: shaders/lib/atmosphere/clouds/Shape.glsl (Apache License 2.0) */

#include "/include/clouds/cloudCommon.glsl"
#ifdef REV_CU_DETAIL_NOISE
	uniform sampler3D revDetailNoiseTex;
#endif

// [Schneider, 2023]
float ValueErosion(float value, float oldMin) {
	return saturate((value - oldMin) / (1.0 - oldMin));
}

float CloudHighDensity(vec2 rayPos) {
	const vec2 windVelocity = vec2(cos(cloudLayer2.windAngle), sin(cloudLayer2.windAngle)) * cloudLayer2.windSpeed;
	vec2 windOffset = windVelocity * worldTimeCounter;

	const mat2 goldenRotate = mat2(cos(goldenAngle), -sin(goldenAngle), sin(goldenAngle), cos(goldenAngle));

	rayPos -= windOffset;
	rayPos += cameraPosition.xz;

	vec4 cloudMap = texture(cloudMapHi, rayPos * rcp(REV_HI_MAP_SCALE * 1e3));

	float localCoverage = cloudMap.w;
	if (localCoverage < cloudDensityEpsilon) return 0.0;

	float activeCoverage = 0.0;

	#ifdef CLOUD_CI
		float coverageCi = cube(saturate(cloudMap.x * (1.0 + CLOUD_CI_COVERAGE) - 0.5));
		activeCoverage = coverageCi;
	#endif

	#ifdef CLOUD_CS
		float coverageCs = cube(saturate(cloudMap.y * (1.0 + CLOUD_CS_COVERAGE) - 0.5));
		activeCoverage += coverageCs;
	#endif

	#ifdef CLOUD_CC
		float coverageCc = cube(saturate(cloudMap.z * (1.0 + CLOUD_CC_COVERAGE) - 0.5) * 2.0);
		activeCoverage += coverageCc;
	#endif

	if (activeCoverage < EPS) return 0.0;

	vec2 curlNoise = texture(curlNoise2D, rayPos * rcp(REV_HI_CURL_SCALE * 1e3)).xy;

	vec2 position = rayPos * 1e-3 - windOffset * 5e-4 + curlNoise * REV_HI_CURL_STRENGTH;
	position *= goldenRotate;

	vec2 lookupPos = position * 0.05 - localCoverage * 0.1;

	vec3 shapes = sqr(texture(cirroLutTex, lookupPos * 2.0).xyz);
	shapes = mix(shapes, texture(cirroLutTex, lookupPos).xyz, cloudMap.xyz);

	float density = 0.0;

	#ifdef CLOUD_CI
		density = shapes.x * coverageCi;
	#endif
	#ifdef CLOUD_CS
		density += shapes.y * coverageCs;
	#endif
	#ifdef CLOUD_CC
		density += shapes.z * coverageCc;
	#endif

	density *= sqr(localCoverage) * REV_HI_DENSITY;
	return saturate(density);
}

float GetVerticalProfile(float heightFraction, float cloudType) {
	return texture(verticalLut, vec2(cloudType, heightFraction)).x;
}

const float cloudProfileEpsilon = 0.05;

const uint cloudDensityModeCoarse = 0u;
const uint cloudDensityModeBase = 1u;
const uint cloudDensityModeDetail = 2u;

float CloudVolumeDensity(vec3 rayPos, float heightFraction, out float dimensionalProfile, uint sampleMode) {
	dimensionalProfile = 0.0;

	const vec3 windDir = vec3(cos(cloudLayer0.windAngle), REV_LOW_WIND_VERTICAL, sin(cloudLayer0.windAngle));
	const vec3 windVelocity = windDir * cloudLayer0.windSpeed;
	vec3 windOffset = windVelocity * worldTimeCounter;

	rayPos -= windOffset;
	rayPos.xz += cameraPosition.xz;

	vec2 cloudMap = texture(cloudMapLo, rayPos.xz * rcp(REV_CU_MAP_SCALE * 1e3)).xy;

	vec2 stepEdge = mix(vec2(0.7, 1.0) - CLOUD_CU_COVERAGE * 0.5, vec2(0.1, 0.3), sqr(wetness) * REV_CU_RAIN_COVERAGE);
	float coverage = linearstep(stepEdge.x, stepEdge.y, cloudMap.x);
	if (coverage < 0.1) return 0.0;

	// [ZEPT] noisetex The Rev (2D) -> cloudNoise2D
	float localCoverage = texture(cloudNoise2D, rayPos.xz * rcp(REV_CU_LOCAL_COVERAGE_SCALE * 1e3) + 0.75).z;
	coverage *= linearstep(stepEdge.x, stepEdge.y * 0.8, localCoverage);

	heightFraction = saturate(heightFraction / cloudMap.x);

	float gradient = GetVerticalProfile(heightFraction, cloudMap.y);
	dimensionalProfile = gradient * coverage;
	if (dimensionalProfile < cloudProfileEpsilon) return 0.0;

	#ifdef CLOUD_EMPTY_SPACE_SKIP
	if (sampleMode == cloudDensityModeCoarse) return dimensionalProfile;
	#endif

	vec3 noisePos = rayPos - windDir * heightFraction * cloudLayer0.thickness * REV_CU_NOISE_SKEW;
	noisePos.y += dot(noisePos.xz, vec2(0.2, 0.3));
	noisePos *= rcp(2e3) * REV_CU_BASE_NOISE_SCALE;

	if (sampleMode == cloudDensityModeDetail) {
		vec3 curlNoise = texture(curlNoise3D, noisePos * REV_CU_CURL_SCALE).xyz;
		noisePos += curlNoise * gradient * oms(coverage) * REV_CU_CURL_STRENGTH;
	}

	float baseNoise = texture(baseNoiseTex, noisePos).x;

	float erosion = oms(baseNoise * gradient) * REV_CU_EROSION;
	float cloudDensity = dimensionalProfile - erosion;
	if (cloudDensity < cloudDensityEpsilon) return 0.0;

	#ifdef REV_CU_DETAIL_NOISE
	if (sampleMode == cloudDensityModeDetail) {
		float detailNoise = texture(revDetailNoiseTex, noisePos * REV_CU_DETAIL_NOISE_SCALE).x;
		detailNoise = mix(detailNoise, oms(detailNoise), saturate(heightFraction * 4.0));
		cloudDensity -= detailNoise * oms(dimensionalProfile) * 0.2 * REV_CU_DETAIL_STRENGTH;
		if (cloudDensity < cloudDensityEpsilon) return 0.0;
	}
	#endif

	float heightFade = smoothstep(0.1, 0.5, heightFraction);

	cloudDensity *= mix(1.0, inversesqrt(cloudDensity), dimensionalProfile);
	return cloudDensity * mix(CLOUD_CU_DENSITY_B, CLOUD_CU_DENSITY_T, heightFade);
}

#endif
