#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"
#include "/include/brdf.glsl"
#include "/include/spaceConversion.glsl"

#if defined DIMENSION_OVERWORLD
    #define SCATTER_POINTS 16
    #include "/include/atmosphere.glsl"
    #include "/include/clouds/cloudRender.glsl"
#endif

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{   
    ivec2 texel = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex1, texel, 0).r;
    
    if (depth != 1.0) {
        color = texelFetch(colortex7, texel, 0);
    } else {
        color = texture(colortex11, internalTexelSize * gl_FragCoord.xy);
        vec3 skyOnly = color.rgb;
        color.rgb += EXPONENT_BIAS * pow(texelFetch(colortex10, texel, 0).rgb, vec3(2.2));

                #if defined DIMENSION_OVERWORLD && defined CLOUDS
            vec2 uv = internalTexelSize * gl_FragCoord.xy;
            vec3 rayDir = normalize(screenToPlayerPos(vec3(uv, 1.0)).xyz - screenToPlayerPos(vec3(uv, 0.0)).xyz);

            // Skylight dari zenith langit ZEPT (E = PI * L)
            vec3 zeptViewPos = vec3(0.0, planetRadius + eyeAltitude + ALTITUDE_BIAS, 0.0);
            vec3 skyUpIlluminance = PI * CLOUD_SKY_ILLUMINANCE * evalScattering(zeptViewPos, vec3(0.0, 1.0, 0.0), sunDir, 0.5);

            CloudRenderResult clouds = RenderClouds(rayDir, blueNoise(gl_FragCoord.xy).xy, skyOnly / EXPONENT_BIAS, skyUpIlluminance);

            // Awan menutupi langit + matahari/bulan
            color.rgb = color.rgb * clouds.transmittance + EXPONENT_BIAS * clouds.scatteredLight;
        #endif
    }
}
