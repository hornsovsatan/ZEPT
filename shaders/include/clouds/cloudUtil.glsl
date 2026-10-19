#ifndef INCLUDE_CLOUD_UTIL
#define INCLUDE_CLOUD_UTIL

/*
    Jembatan kode awan The Rev (lib/) -> ZEPT (include/).
    Disalin dari The Rev: lib/utility/Math.glsl, lib/utility/Phase.glsl,
    lib/atmosphere/Common.glsl (Revelation Shaders, HaringPro, Apache License 2.0).
    Konstanta & fungsi kecil dibuat macro agar tidak bentrok dengan nama di ZEPT.
*/

//======// Opsi khusus ZEPT //====================================================================//

#define CLOUD_VIEWER_ALTITUDE 256.0   // [64.0 128.0 256.0 384.0 512.0 1024.0]
#define CLOUD_SUN_ILLUMINANCE 1.0     // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 3.0 4.0]
#define CLOUD_MOON_ILLUMINANCE 0.002  // [0.0 0.0005 0.001 0.002 0.004 0.008 0.016 0.032]
#define CLOUD_SKY_ILLUMINANCE 1.0     // [0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0]

//======// Uniform & tekstur //===================================================================//

uniform float wetness;
uniform float worldTimeCounter;
uniform vec4  lightningBoltPosition;

uniform sampler3D baseNoiseTex;
uniform sampler3D curlNoise3D;
uniform sampler2D cloudMapLo;
uniform sampler2D cloudMapHi;
uniform sampler2D verticalLut;
uniform sampler2D curlNoise2D;
uniform sampler2D cirroLutTex;
uniform sampler2D cloudPhaseLut;
uniform sampler2D cloudNoise2D; // pengganti noisetex 2D The Rev (Noise2D.png)

//======// Math.glsl (The Rev) //=================================================================//

#ifndef rPI
    #define rPI 0.31830988618
#endif
#ifndef rLOG2
    #define rLOG2 1.44269504089
#endif
#ifndef goldenAngle
    #define goldenAngle 2.39996322973
#endif
#ifndef EPS
    #define EPS 0.000001
#endif
#ifndef oms
    #define oms(x) (1.0 - (x))
#endif
#ifndef satSnorm
    #define satSnorm(x) clamp(x, -1.0, 1.0)
#endif
#ifndef cube
    #define cube(x) ((x) * (x) * (x))
#endif
#ifndef sdot
    #define sdot(x) dot(x, x)
#endif
#ifndef linearstep
    #define linearstep(a, b, x) saturate(((x) - (a)) / ((b) - (a)))
#endif
#ifndef approxSqrt
    #define approxSqrt(x) uintBitsToFloat((floatBitsToUint(x) >> 1) + 0x1FC00000u)
#endif
#ifndef lessThanFLT1
    #define lessThanFLT1(x) (floatBitsToUint(x) < 0x3F800000u)
#endif
// [Schneider, 2015] (clouds/Common.glsl The Rev)
#ifndef remap
    #define remap(value, oMin, oMax, nMin, nMax) ((nMin) + saturate(((value) - (oMin)) / ((oMax) - (oMin))) * ((nMax) - (nMin)))
#endif

//======// Phase.glsl (The Rev) //================================================================//

#ifndef uniformPhase
    #define uniformPhase (0.25 * rPI)
#endif

float HenyeyGreensteinPhase(float cosTheta, float g) {
	float gg = g * g;
	float t = inversesqrt(1.0 + gg - 2.0 * g * cosTheta);
	return uniformPhase * oms(gg) * cube(t);
}

float CornetteShanksPhase(float cosTheta, float g) {
	float gg = g * g;
	float t = inversesqrt(1.0 + gg - 2.0 * g * cosTheta);
	float p1 = oms(gg) * cube(t);
	float p2 = (1.0 + cosTheta * cosTheta) * (1.5 / (2.0 + gg));
	return uniformPhase * p1 * p2;
}

float DrainePhase(float cosTheta, float g, float a) {
	float gg = g * g;
	float t = inversesqrt(1.0 + gg - 2.0 * g * cosTheta);
	float p1 = oms(gg) * cube(t);
	float p2 = (1.0 + a * cosTheta * cosTheta) / (1.0 + a * (1.0 + 2.0 * gg) * rcp(3.0));
	return uniformPhase * p1 * p2;
}

float HgDrainePhase(float cosTheta, float d) {
	float gHG, gD, a, wD;
	if (d <= 0.1) {
		gHG = 13.8 * d * d;
		gD 	= 1.1456 * d * sin(9.29044 * d);
		a 	= 250.0;
		wD 	= 0.252977 - 312.983 * pow(d, 4.3);
	} else if (d < 1.5) {
		float ld = log(d);
		gHG = 0.862 - 0.143 * ld * ld;
		gD 	= 0.379685 * cos(1.19692 * cos((ld - 0.238604) * (ld + 1.00667) / (0.507522 - 0.15677 * ld)) + 1.37932 * ld + 0.0625835) + 0.344213;
		a 	= 250.0;
		wD 	= 0.146209 * cos(3.38707 * ld + 2.11193) + 0.316072 + 0.0778917 * ld;
	} else if (d < 5.0) {
		float ld = log(d);
		gHG = 0.0604931 * log(ld) + 0.940256;
		gD 	= 0.500411 - 0.081287 / (-2.0 * ld + tan(ld) + 1.27551);
		a 	= 7.30354 * ld + 6.31675;
		wD 	= 0.026914 * (ld - cos(5.68947 * (log(ld) - 0.0292149))) + 0.376475;
	} else {
		gHG = exp(-0.0990567 / (d - 1.67154));
		gD 	= exp(-2.20679 / (d + 3.91029) - 0.428934);
		a 	= exp(3.62489 - 8.29288 / (d + 5.52825));
		wD 	= exp(-0.599085 / (d - 0.641583) - 0.665888);
	}
	return mix(HenyeyGreensteinPhase(cosTheta, gHG), DrainePhase(cosTheta, gD, a), wD);
}

//======// atmosphere/Common.glsl (The Rev) //====================================================//

// Posisi pengamat untuk geometri awan (sama seperti The Rev: planetRadius + VIEWER_BASE_ALTITUDE + eyeAltitude)
#define atmosphereViewHeight (planetRadius + CLOUD_VIEWER_ALTITUDE + eyeAltitude)
#define atmosphereViewPos    vec3(0.0, atmosphereViewHeight, 0.0)

vec2 UnitToSubUv(vec2 uv, vec2 res) {
	return uv * (1.0 - 1.0 / res) + 0.5 / res;
}

vec2 RaySphereIntersection(float r, float mu, float rad) {
	float delta = sqr(r) * fma(mu, mu, -1.0) + sqr(rad);
	if (delta >= 0.0) {
		delta *= inversesqrt(delta);
		return vec2(-delta, delta) - r * mu;
	} else {
		return vec2(-1.0);
	}
}

vec2 RaySphericalShellIntersection(float r, float mu, float bottomRad, float topRad) {
	vec2 bottomIntersection = RaySphereIntersection(r, mu, bottomRad);
	vec2 topIntersection = RaySphereIntersection(r, mu, topRad);

	if (topIntersection.y >= 0.0) {
		vec2 intersection;
		if (bottomIntersection.y < 0.0) {
			intersection.x = max0(topIntersection.x);
			intersection.y = topIntersection.y;
		} else if (bottomIntersection.x < 0.0) {
			intersection.x = bottomIntersection.y;
			intersection.y = topIntersection.y;
		} else {
			intersection.x = max0(topIntersection.x);
			intersection.y = bottomIntersection.x;
		}
		return intersection;
	} else {
		return vec2(-1.0);
	}
}

bool RayIntersectPlanetGround(float r, float mu) {
	return mu < 0.0 && r * r * fma(mu, mu, -1.0) + planetRadius * planetRadius >= 0.0;
}

//======// Jembatan ke atmosfer ZEPT //===========================================================//

const vec3 cloudMoonColor = vec3(0.75, 0.95, 1.0); // moonAlbedo The Rev

// Ruang awan -> ruang atmosfer ZEPT (ZEPT memakai ALTITUDE_BIAS)
vec3 CloudToZeptPos(vec3 p) {
	return p + vec3(0.0, ALTITUDE_BIAS - CLOUD_VIEWER_ALTITUDE, 0.0);
}

// Pengganti AtmosphereTransmittanceToSun (The Rev) -> lightTransmittance (ZEPT)
vec3 CloudTransmittanceToLight(vec3 cloudPos, vec3 lightDir) {
	return lightTransmittance(CloudToZeptPos(cloudPos), lightDir);
}

// Pengganti AtmosphereTransmittanceToPoint (rumus yang sama: T(kamera)/T(titik))
vec3 CloudAerialTransmittance(vec3 rayDir, float d) {
	if (rayDir.y < 0.0) return vec3(1.0);
	vec3 camPos = vec3(0.0, planetRadius + eyeAltitude + ALTITUDE_BIAS, 0.0);
	vec3 tCam   = lightTransmittance(camPos, rayDir);
	vec3 tPoint = lightTransmittance(camPos + rayDir * d, rayDir);
	return saturate(tCam / max(tPoint, vec3(1e-6)));
}

// Petir (The Rev), diskalakan 1/126 karena matahari The Rev = 126, matahari ZEPT = 1
vec3 LightningContribution(vec3 pos) {
	if (lightningBoltPosition.w < 0.5) return vec3(0.0);
	float distSq = sdot(lightningBoltPosition.xyz - pos);
	return vec3(0.32, 0.3, 1.0) * 5e4 / (1.0 + distSq) * (1.0 / 126.0);
}

#endif
