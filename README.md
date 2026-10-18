> [!WARNING]
> Disclaimer: This shaderpack is an early work-in-progress so 
> bugs, missing features and performance issues are to be expected.

## Features

* Accurate ray-geometry intersection
* Path traced diffuse, reflections and sun shadows
* Temporal anti-aliasing and upsampling
* Normal & specular mapping support
* Physically based sky rendering
    * Hillaire multi-scattering approximation
* Sparse irradiance cache for diffuse multi-bounce approximation
* Reflection motion vector calculation (no TAA ghosting on reflections)
* Spatiotemporal denoising
* Camera effects: motion blur & depth of field
* Post-processing: auto exposure & chromatic aberration

## Compatibility / Mod Support

* GPUs: NVIDIA, AMD
* Minecraft - version 1.21 and above
* Iris - version 1.8.0 and above
* Optifine - not supported
* Distant Horizons/Voxy - not supported (planned)
* OrthoCamera - supported but still broken in a few cases
* macOS - not supported

## Performance Tips

* Sample count: This directly affects the quality of the lighting. Higher sample counts show less noise and more detailed lighting/reflections at the cost of performance. Keep this at 1 for the best performance.
* Diffuse Lighting > Denoising Passes: The amount of passes used for diffuse lighting denoising. Even though not as high as sample count, this has a performance impact too. You can still get decent lighting with just 6 passes most of the time, but a pass count of 8 is recommended for the best lighting. You can set this to 0 if you're fine with the noise.
* If you are in a completely closed room with no outdoor light entering it, set Shadow Samples to 0. This will disable sunlight.
* Irradiance Cache > Update Interval: The maximum amount of frames that are allowed to pass between updates of the same part of the irradiance cache. Lower values cost more performance, but result in more responsive lighting and less noise in reflections.

## TODO / Known Issues

* ~~TAAU looks *very* bad currently. I don't recommend using it unless you really need FPS.~~
* ~~Currently, you need a labPBR resource pack enabled for this shaderpack to function properly.~~
* Rain particles are not rendered.
* Reflections (especially mirror-like ones) show a lot of noise and flickering. Lowering Irradiance Cache -> Update Interval and increasing reflection samples in path tracing settings can improve it.
* The shaderpack takes very long to load on first use, but it should be faster on subsequent loads.
* Normal maps don't show up in reflections.
* Breaking blocks in caves shows light leaking for a split second. This is unavoidable now.
* In some cases, parts of the terrain will fail to voxelize. Increasing Triangle and Voxel Array Size usually fixes it.
* ~~TAA produces a lot of ghosting on smooth reflections in movement. It might be possible to improve on this by using a reflection virtual depth buffer for TAA reprojection.~~
