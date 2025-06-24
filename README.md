# Houdini Vertex Block Descent

Early rewrite of Vertex Block Descent for Houdini. I made an OpenCL version for good performance, and a VEX version for debugging. Currently it includes everything in [TinyVBD](https://github.com/AnkaChan/TinyVBD), which isn't much.

Currently it's pretty unstable. This is a problem with VBD in general, but also because TinyVBD implements [mass-spring energy](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_MassSpring.cpp) instead of [Neo-Hookean](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_NeoHookean.cpp) energy. They removed mass-spring energy from [the main codebase](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_MassSpring.cpp), probably for this reason.

I'll work on this when I have time, but feel free to contribute if you want!

## What's VBD?

Vertex Block Descent is pretty similar to Vellum. Vellum uses a technique called XPBD (Extended Position Based Dynamics).

Here's a few differences between them:

|  | VBD | Vellum (XPBD) | Advantage | Disadvantage |
| --- | --- | --- | --- | --- |
| **Runs over** | Points | Prims (each constraint) | Fewer colors/workgroups, faster for parallel processing | Takes longer to propagate for stiff objects, since it updates 1 point per iteration instead of 2 (one on each side of the constraint) |
| **Constraints** | Energy based (eg mass-spring energy or Neo-Hookean energy) | XPBD based (eg distance constraints) | Better for larger mass ratios | Randomly explodes due to matrix inversion |
| **Collisions** | Require hard constraints | Require any type of constraints |

## Todo
- [x] Mss spring energy ([based on TinyVDB](https://github.com/AnkaChan/TinyVBD))
- [x] Accelerated convergence method ([based on VDB paper, section 3.8](https://graphics.cs.utah.edu/research/projects/vbd/vbd-siggraph2024.pdf))
- [ ] LDLT decomposition to improve stability ([based on AVBD paper](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf))
- [ ] Neo-Hookean energy, probably more stable ([based on GAIA](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_NeoHookean.cpp))
- [ ] Collision handling (based either on Vellum or VBD)
- [ ] [Hard constraints from AVBD paper](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf)
