#ifndef INCLUDE_CLOUD_COMMON
#define INCLUDE_CLOUD_COMMON

/* Port dari The Rev: shaders/lib/atmosphere/clouds/Common.glsl (Apache License 2.0)
   Refs: Schneider 2015-2023 (Nubis), Hillaire 2016, Högfeldt 2016, Bauer 2019, Wrenninge et al. 2013 */

#define CLOUDS

/* Low-level clouds */
	#define CLOUD_CU_MODE 				2       // [0 1 2] 0: Off, 1: Revelation, 2: Proxima

	#if CLOUD_CU_MODE > 0
		#define CLOUD_CU 1
	#endif

	#if CLOUD_CU_MODE == 2
		#define PROXIMA_LOW_CLOUDS 1
	#endif

	#define CLOUD_LOW_SAMPLES_MIN 		20      // [4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 36 40 44 48 50 52 56 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300 310 320 330 340 350 360 370 380 390 400 410 420 430 440 450 460 470 480 490 500]
	#define CLOUD_LOW_SAMPLES_MAX 		40      // [4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 36 40 44 48 50 52 56 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300 310 320 330 340 350 360 370 380 390 400 410 420 430 440 450 460 470 480 490 500]
	#define CLOUD_EMPTY_SPACE_SKIP

	#define CLOUD_LOW_SUNLIGHT_SAMPLES 	6       // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50]
	#define CLOUD_LOW_WIND_SPEED 		10.0    // [5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0 95.0 100.0 105.0 110.0 115.0 120.0 125.0 130.0 135.0 140.0 145.0 150.0 155.0 160.0 165.0 170.0 175.0 180.0 185.0 190.0 195.0 200.0]
	#define CLOUD_LOW_WIND_ANGLE        20.0    // [0.0 10.0 20.0 30.0 40.0 50.0 60.0 70.0 80.0 90.0 100.0 110.0 120.0 130.0 140.0 150.0 160.0 170.0 180.0 190.0 200.0 210.0 220.0 230.0 240.0 250.0 260.0 270.0 280.0 290.0 300.0 310.0 320.0 330.0 340.0 350.0]

	#define CLOUD_CU_ALTITUDE 		   	1500.0  // [400.0 500.0 600.0 700.0 800.0 900.0 1000.0 1100.0 1200.0 1300.0 1400.0 1500.0 1600.0 1700.0 1800.0 1900.0 2000.0 2500.0 3000.0 3500.0 4000.0 4500.0 5000.0 5500.0 6000.0 6500.0 7000.0 7500.0 8000.0 8500.0 9000.0 9500.0 10000.0]
	#define CLOUD_CU_THICKNESS 		    2000.0  // [500.0 600.0 700.0 800.0 900.0 1000.0 1100.0 1200.0 1300.0 1400.0 1450.0 1500.0 1550.0 1600.0 1650.0 1700.0 1750.0 1800.0 1850.0 1900.0 1950.0 2000.0 2050.0 2100.0 2150.0 2200.0 2250.0 2300.0 2350.0 2400.0 2450.0 2500.0 2550.0 2600.0 2650.0 2700.0 2750.0 2800.0 2850.0 2900.0 2950.0 3000.0 3500.0 4000.0 4500.0 5000.0 5500.0 6000.0 6500.0 7000.0 7500.0 8000.0 8500.0 9000.0 9500.0 10000.0]
	#define CLOUD_CU_COVERAGE           0.5     // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
	#define CLOUD_CU_DENSITY_B          0.1     // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
	#define CLOUD_CU_DENSITY_T          1.0     // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0 3.5 4.0 4.5 5.0]

	/* Revelation cumulus (CLOUD_CU_MODE == 1) */
	#define REV_LOW_SUNLIGHT_DETAIL_SAMPLES 3       // [0 1 2 3 4 5 6 8 10 12 16 20 24 32 50]
	#define REV_LOW_LIGHT_DISTANCE          1.0     // [0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0 4.0]
	#define REV_LOW_MAX_DISTANCE            50.0    // [20.0 30.0 40.0 50.0 60.0 75.0 100.0 125.0 150.0 200.0]
	#define REV_LOW_MIN_TRANSMITTANCE       0.01    // [0.0001 0.0005 0.001 0.002 0.005 0.01 0.02 0.05]
	#define REV_LOW_EMPTY_SAMPLE_LIMIT      4       // [1 2 3 4 6 8 12 16]

	#define REV_CU_MAP_SCALE                64.0    // [16.0 24.0 32.0 48.0 64.0 80.0 96.0 128.0 160.0 192.0 256.0]
	#define REV_CU_LOCAL_COVERAGE_SCALE     512.0   // [64.0 128.0 256.0 384.0 512.0 768.0 1024.0]
	#define REV_CU_RAIN_COVERAGE            1.0     // [0.0 0.25 0.5 0.75 1.0]
	#define REV_CU_BASE_NOISE_SCALE         1.0     // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0 4.0]
	#define REV_CU_EROSION                  0.75    // [0.3 0.4 0.5 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
	#define REV_CU_NOISE_SKEW               0.3     // [0.0 0.1 0.2 0.3 0.4 0.5 0.75 1.0]
	#define REV_CU_CURL_SCALE               2.0     // [0.5 1.0 1.5 2.0 3.0 4.0 6.0 8.0]
	#define REV_CU_CURL_STRENGTH            0.3     // [0.0 0.1 0.2 0.3 0.4 0.5 0.75 1.0]
	//#define REV_CU_DETAIL_NOISE
	#define REV_CU_DETAIL_NOISE_SCALE       8.0     // [2.0 4.0 6.0 8.0 10.0 12.0 16.0 24.0 32.0]
	#define REV_CU_DETAIL_STRENGTH          1.0     // [0.25 0.5 0.75 1.0 1.25 1.5 2.0]

	#define REV_LOW_EXTINCTION              0.06    // [0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.1 0.12 0.15 0.2]
	#define REV_LOW_ALBEDO                  0.999   // [0.9 0.92 0.94 0.95 0.96 0.97 0.98 0.99 0.995 0.999]
	#define REV_LOW_SHADOW_DARKNESS         1.0     // [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.5 3.0 4.0 5.0 6.0 8.0]
	#define REV_LOW_MS_ENERGY               1.0     // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
	#define REV_LOW_SKY_OCCLUSION           1.0     // [0.5 0.75 1.0 1.5 2.0 2.5 3.0 4.0 6.0 8.0]
	#define REV_LOW_GROUND_MULT             1.0     // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]
	//#define REV_LOW_POWDER
	#define REV_LOW_POWDER_STRENGTH         0.5     // [0.1 0.25 0.5 0.75 1.0]
	#define REV_LOW_POWDER_DEPTH            100.0   // [25.0 50.0 100.0 200.0 400.0]
	#define REV_LOW_SUN_MULT                1.0     // [0.5 0.75 1.0 1.25 1.5 2.0]
	#define REV_LOW_SKY_MULT                1.0     // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
	#define REV_LOW_RAIN_DARKEN             0.0     // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.75]
	#define REV_LOW_WIND_VERTICAL           0.5     // [0.0 0.25 0.5 0.75 1.0]

/* Mid-level clouds (belum diimplementasi di The Rev) */
	#define CLOUD_MID_ALTITUDE 			4000.0
	#define CLOUD_MID_THICKNESS 		2000.0
	#define CLOUD_MID_WIND_SPEED 		20.0
	#define CLOUD_MID_WIND_ANGLE        40.0

/* High-level clouds */
	#define CLOUD_HIGH_ALTITUDE 		8000.0  // [500.0 600.0 700.0 800.0 900.0 1000.0 1100.0 1200.0 1300.0 1400.0 1500.0 1600.0 1700.0 1800.0 1900.0 2000.0 2500.0 3000.0 3500.0 4000.0 4500.0 5000.0 5500.0 6000.0 6500.0 7000.0 7500.0 8000.0 8500.0 9000.0 9500.0 10000.0 10500.0 11000.0 11500.0 12000.0]
	#define CLOUD_HIGH_THICKNESS 		1000.0  // [500.0 600.0 700.0 800.0 900.0 1000.0 1100.0 1200.0 1300.0 1400.0 1500.0 1600.0 1700.0 1800.0 1900.0 2000.0 2500.0 3000.0 3500.0 4000.0 4500.0 5000.0]
	#define CLOUD_HIGH_WIND_SPEED 		30.0    // [5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0 95.0 100.0 110.0 120.0 130.0 140.0 150.0 160.0 170.0 180.0 190.0 200.0]
	#define CLOUD_HIGH_WIND_ANGLE       70.0    // [0.0 10.0 20.0 30.0 40.0 50.0 60.0 70.0 80.0 90.0 100.0 110.0 120.0 130.0 140.0 150.0 160.0 170.0 180.0 190.0 200.0 210.0 220.0 230.0 240.0 250.0 260.0 270.0 280.0 290.0 300.0 310.0 320.0 330.0 340.0 350.0]

	#define REV_HI_SUNLIGHT_SAMPLES         3       // [1 2 3 4 5 6 8 10 12 16]
	#define REV_HI_DENSITY                  8.0     // [2.0 4.0 6.0 8.0 10.0 12.0 16.0]
	#define REV_HI_EXTINCTION               0.02    // [0.005 0.01 0.015 0.02 0.03 0.04 0.05]
	#define REV_HI_ALBEDO                   0.99    // [0.9 0.95 0.97 0.98 0.99 0.995]
	#define REV_HI_MAP_SCALE                786.0   // [256.0 384.0 512.0 640.0 786.0 1024.0 1536.0]
	#define REV_HI_CURL_SCALE               24.0    // [8.0 12.0 16.0 24.0 32.0 48.0]
	#define REV_HI_CURL_STRENGTH            1.0     // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]

	#define CLOUD_CI
	#define CLOUD_CI_COVERAGE           0.5     // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
	#define CLOUD_CS
	#define CLOUD_CS_COVERAGE           0.5     // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
	#define CLOUD_CC
	#define CLOUD_CC_COVERAGE           0.5     // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

//================================================================================================//

const uint  cloudMsCount 			= 4;

const float cloudMsFalloffA 	    = 0.5;
const float cloudMsFalloffB 	    = 0.5;
const float cloudMsFalloffC 	    = 0.5;

const float cloudForwardG           = 0.65;
const float cloudBackwardG          = -0.3;
const float cloudLobeMixer          = 0.25;
const float cloudSilverG 		    = 0.95;
const float cloudSilverI 	        = 0.20;

const float cloudDensityEpsilon     = 0.001;
const float cloudMinTransmittance   = 0.01;

struct CloudMediumCoeff {
	float extinction;
	float scattering;
	float albedo;
};

struct CloudLayerParams {
	float minHeight;
	float maxHeight;
	float thickness;
	float windSpeed;
	float windAngle;
	CloudMediumCoeff coeff;
};

const CloudLayerParams cloudLayer0 = {
	planetRadius + CLOUD_CU_ALTITUDE,
	planetRadius + CLOUD_CU_ALTITUDE + CLOUD_CU_THICKNESS,
	CLOUD_CU_THICKNESS,
	CLOUD_LOW_WIND_SPEED,
	radians(CLOUD_LOW_WIND_ANGLE),
	CloudMediumCoeff(REV_LOW_EXTINCTION, REV_LOW_EXTINCTION * REV_LOW_ALBEDO, REV_LOW_ALBEDO)
};

const CloudLayerParams cloudLayer1 = {
	planetRadius + CLOUD_MID_ALTITUDE,
	planetRadius + CLOUD_MID_ALTITUDE + CLOUD_MID_THICKNESS,
	CLOUD_MID_THICKNESS,
	CLOUD_MID_WIND_SPEED,
	radians(CLOUD_MID_WIND_ANGLE),
	CloudMediumCoeff(0.04, 0.04 * 0.995, 0.995)
};

const CloudLayerParams cloudLayer2 = {
	planetRadius + CLOUD_HIGH_ALTITUDE,
	planetRadius + CLOUD_HIGH_ALTITUDE + CLOUD_HIGH_THICKNESS,
	CLOUD_HIGH_THICKNESS,
	CLOUD_HIGH_WIND_SPEED,
	radians(CLOUD_HIGH_WIND_ANGLE),
	CloudMediumCoeff(REV_HI_EXTINCTION, REV_HI_EXTINCTION * REV_HI_ALBEDO, REV_HI_ALBEDO)
};

struct CloudRenderResult {
	vec3 scatteredLight;
	float transmittance;
	float frontDepth;
};

#endif
