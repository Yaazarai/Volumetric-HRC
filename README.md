Constant-Time per-pixel volumetrics using ray-extensions via [Holographic Radiance Cascades](https://arxiv.org/abs/2505.02041).

This implementation is the closest good-faith reproduction of the paper that I can manage with minor modifications to make setup easier and to reduce overall aliasing.

<img width="2048" height="2048" alt="HRC2k" src="https://github.com/user-attachments/assets/d9288305-5cc2-4de6-beee-6d863a3d65a8" />
<p align="center">Simple 2048 x 2048 volumetric scene rendered on an RTX 3080.</p>

The largest deviation from the paper in terms of final result is going to be when I start my ray-extensions. The paper mentions to start extensions at cascade3. This however with my implementation provided a lot of aliasing and instability in moving light sources. This could be due to my insufferable need to not implement [DDA properly](https://aaaa.sh/creatures/dda-algorithm-interactive/) and instead opting for a [simpler variant of DDA](https://benedikt-bitterli.me/tantalum/) which does not handle edges and runs in constant-time. EIther way neither of these line algorithms are required when extending rays from cascade0. See below for a comparison, firt video extending from c0, second video extending from c3 using the simple DDA model.

https://github.com/user-attachments/assets/8e474182-fca4-46f0-b83b-7b75a22b1d94

https://github.com/user-attachments/assets/62730957-4870-4e41-8107-40b75a5bc0b6


#### Improving Performance
While the current implementation is fast, especially for per-pixel volumetrics, there is stil lroom for improvement. The shaders can be modified to cast only 1/2x as many probes along each plane, then allow rays to interpolate between those probes when extending/merging. This will provide slight aliasing, but double performance where needed. This has not been implemented.
