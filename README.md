Constant and real-time per-pixel volumetrics using ray-extensions via [Holographic Radiance Cascades](https://arxiv.org/abs/2505.02041). This implementation is the closest good-faith reproduction of the paper that I can manage with minor modifications to make setup easier and to reduce overall aliasing.

https://github.com/user-attachments/assets/ff941093-3b06-4b8b-ab77-c965a6c42fa6
<p align="center">Simple 2048 x 2048 volumetric scene rendered on an RTX 3080 in 9ms.</p>

### How HRC Works
The premise of HRC is simple, cast rays in a 90-degree cone from every probe. The number of probes in the scene decreases along one-axis only (perpendicular to the frustum direction). This means we cast probes as planes evenly distributed throughout the scene and each successive cascade has 1/2x as many probes and 2x as many rays per probe. To be precise the exact number of rays-per-probe for each cascade is actually `pow2(N)+1`, where we cast one ray for every 2 pixels across the full width of the frustum of each cascade: `frustum_width = pow(2.0, cascade_index) * 2.0 + 1.0`. As the width of the frustum grows as the distance between planes in higher cascades increases.
<img width="1420" height="497" alt="image" src="https://github.com/user-attachments/assets/55ab1989-8649-45c2-8f56-9e8a2cbfbe33" />

Then we define a series of cones or angular spans between two rays which compute the total angular fluence each cone represents while merging across planes and down. The cones represent the total angular span across each frustum (90 degrees of radiance) and thus we must re-compute the output fluence in 4 separate directions. This is achieved by re-running the shader(s) 4 separate times by passing in the same scene rotated to each respective frustum direction. Finally average the contributions at each screen-space pixel from all 4 frustums. Each pixel must offset its radiance contribution outwards by 1-pixel for each frustum since frustums share a ray-direction at each edge.
<img width="1371" height="1364" alt="image" src="https://github.com/user-attachments/assets/8b5446f5-feae-4b1e-b2a8-5b8092fe5dac" />

### Tracing vs Ray Extensions
Raytracing provides measurably worse results and worse aliasing, but more flexibility in the implementation. The major benefit of ray extensions is that each ray takes at most `log2(N)` samples to compute each ray in constant-time + angular diffusion across the cascades to minimize aliasing.

To produce the rays themselves you can either ray-trace using DDA or line-algorithm of choice or you can use ray extensions. Ray extensions combine chained rays of cN-1 to formulate rays of cN. This is done by computing the upper/lower ray indexes of the nearest cN-1 ray-directions left/right of the current ray direction and extending those rays across two planes while flipping the ray indices to force the rays to converge.
<img width="1024" height="433" alt="image" src="https://github.com/user-attachments/assets/be2564fd-d5af-4d7b-bdb2-c61fd2aed7e0" />

### HRC Merging
The merging model is much different than Vanilla RC. The idea is that we want to produce one cone for each discrete angular span between the rays cast of each cascades. For example in the image above c0 has 2 rays with one angular span between them (one cone), c2 has 3 rays = 2 cones, c3 has 5 rays = 4 cones. We're producing `N` cones from `N+1` rays--this can be seen in the image below.

Producing the cones is as simple as looking up the left/right rays that bound the edge of the cone and merge each ray with 2 rays in cN+1 that start at their end-points.
<img width="1579" height="857" alt="image" src="https://github.com/user-attachments/assets/df4f3a1a-0a45-47a6-8177-745462dba826" />

Considering that we're casting "planes of probes," which produces discretely rectangular radiance, rays must also be weighted to produce the appropriate output fluence. Each cone of cN represents a fraction of the angular span of the full frustum and the left/right rays of the cone each represent 1/2 of that total angular span. So then to weight the rays we multiple each ray by 1/2 the cone's angular span BEFORE merging. This is done by multiplying each ray by 1/2 of `atan(right.y / right.x) - atan(left.y / left.x)`, where `atan()` here gives us the angle of each ray and we take the difference between the left/right rays as the angular span of the cone.
<img width="796" height="771" alt="image" src="https://github.com/user-attachments/assets/c0ba6478-3b7e-4b55-a122-e50a59bbfb57" />

We have two edge cases for merging: even & odd planes. Even plane's line up perfectly with cN+1 can merge with the nearest cN+1 plane.
<img width="874" height="356" alt="image" src="https://github.com/user-attachments/assets/9be45c5b-bb02-4e23-bc42-d5f478d7f3d1" />

However even planes cannot. To solve this we need to cast 2x length rays for even plans and merge twice. Once for the near plane and once again for the far plane. We then take the MERGED results of both planes and interpolate their fluence. Interpolating before merging will break volumetrics. This strategy interpolates the FLUENCE (radiance at a point) not the relative position between both planes. This means you must merge the near and far planes as separate points of fluence and then interpolate them afterwards for the correct result.
<img width="879" height="352" alt="image" src="https://github.com/user-attachments/assets/98050b82-2670-4ea0-9fa3-b8bfa1e62526" />

When all is said and done this merging strategy produces the output of the diagram below.
<img width="1244" height="1104" alt="image" src="https://github.com/user-attachments/assets/af832078-017c-4ad4-acc0-45643071c8cd" />

I actually managed to reproduce the diagram for a single frustum within HRC itself by raytracing to planes 16x as far away--which verified my results were accurate.
<img width="1015" height="1015" alt="image" src="https://github.com/user-attachments/assets/682453ac-4750-4bfe-8b30-f289cf66d7f4" />

### Rendering Scenes / Depth Order
Implementation provided in GameMaker and should run with the free-version. Scenes are rendered volumetrically using two physical material properties: emissivity and absorption. Emissivity controls light emitted from each pixel and absorption controls how much light is absorbed by each pixel--note that emissive objects must be drawn TWICE, once as emissive and a second time with an absorption property. An example scene (see below) provided for reference on how to setup scenes. Note that object depth or render-order of objects to the scene will determine how occlusion works, render objects far -> near (assuming the far plane away from the camera is the floor and near-plane is the screen). Utilizing absorption and depth-order properly will lend a sense of dimensionality to your final scene.

### Performance Results (RTX 3080)
* 256 x 256 ~ 1ms.
* 512 x 512 ~ 1-2ms.
* 1024 x 1024 ~ 5-6ms.
* 2048 x 2048 ~ 9-11ms.
* 4096 x 4096 ~ 35-45ms.
* 8,192 x 8,192 ~ 2,000ms / Crash (memory bound).

### Improving Performance
While the current implementation is fast--especially considering its running per-pixel volumetrics--there is still room for improvement. The shaders can be modified to cast only 1/2x as many probes along each plane, then allow rays to interpolate between those probes when extending/merging. This will provide slight aliasing, but double performance where needed.

This has not been implemented--I've been working on this for too damn long.

### Aliasing Fix / Spatial Stability

The largest deviation from the paper in terms of final result is going to be when I start my ray-extensions. The paper mentions to start extensions at cascade3. This however with my implementation provided a lot of aliasing and instability in moving light sources. This could be due to my insufferable need to not implement [DDA properly](https://aaaa.sh/creatures/dda-algorithm-interactive/) and instead opting for a [simpler variant of DDA](https://benedikt-bitterli.me/tantalum/) which does not handle edges and runs in constant-time. EIther way neither of these line algorithms are required when extending rays from cascade0. See below for a comparison, first video extending from c0, second video extending from c3 using the simple DDA model.

The primary reason for this stability improvement is that increase in angular diffusion by extending from c0 rather than c3. Ray-extensions combine rays in lower-level cascades to build rays in higher cascades, this means that the angular distribution of samples is diffused along the ray-directions. More diffusion = better stability.

The stability is basically perfect as far as discrete ray-tracing models go, with not even Vanilla RC able to match.

https://github.com/user-attachments/assets/8e474182-fca4-46f0-b83b-7b75a22b1d94

https://github.com/user-attachments/assets/62730957-4870-4e41-8107-40b75a5bc0b6

Vanilla RC + Bilinear-Fix for reference with a 1px light on as 512x512 scene with 4x the ray-density (200ms). The results are not even comparable.

<img width="1016" height="1024" alt="image" src="https://github.com/user-attachments/assets/75b6ce05-5f7c-4cab-8767-353c44d55125" />

