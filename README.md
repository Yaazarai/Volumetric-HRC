Constant-Time per-pixel volumetrics using ray-extensions via [Holographic Radiance Cascades](https://arxiv.org/abs/2505.02041). This implementation is the closest good-faith reproduction of the paper that I can manage with minor modifications to make setup easier and to reduce overall aliasing.

Implementation provided in GameMaker and shoudl run with the free-version. Scenes are rendered volumetrically using two physical material properties: emissivity and absorption. Emissivity controls light emitted from each pixel and absorption controls how much light is absorbed by each pixel--note that emissive objects must be drawn TWICE, once as emissive and a secodn time with an absorption property. An example scene (see below) provided for reference on how to setup scenes. Note that object depth or render-order of objects to the scene will determine how occlusion works, render objects far -> near (assuming the far plane away from the camera is the floor and near-plane is the screen). Utilizing absorption and depth-order properly will lend a sense of dimensionality to your final scene.

<img width="2048" height="2048" alt="HRC2k" src="https://github.com/user-attachments/assets/d9288305-5cc2-4de6-beee-6d863a3d65a8" />
<p align="center">Simple 2048 x 2048 volumetric scene rendered on an RTX 3080.</p>

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

The largest deviation from the paper in terms of final result is going to be when I start my ray-extensions. The paper mentions to start extensions at cascade3. This however with my implementation provided a lot of aliasing and instability in moving light sources. This could be due to my insufferable need to not implement [DDA properly](https://aaaa.sh/creatures/dda-algorithm-interactive/) and instead opting for a [simpler variant of DDA](https://benedikt-bitterli.me/tantalum/) which does not handle edges and runs in constant-time. EIther way neither of these line algorithms are required when extending rays from cascade0. See below for a comparison, firt video extending from c0, second video extending from c3 using the simple DDA model.

The stability is basically perfect as far as discrete ray-tracing models go, with not even Vanilla RC able to match.

https://github.com/user-attachments/assets/8e474182-fca4-46f0-b83b-7b75a22b1d94

https://github.com/user-attachments/assets/62730957-4870-4e41-8107-40b75a5bc0b6

Vanill RC + Bilinear-Fix for reference with a 1px light on as 512x512 scene with 4x the ray-density (200ms). The results are not even comparable.

<img width="1016" height="1024" alt="image" src="https://github.com/user-attachments/assets/75b6ce05-5f7c-4cab-8767-353c44d55125" />

