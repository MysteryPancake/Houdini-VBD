# Houdini Vertex Block Descent

WIP of Vertex Block Descent in Houdini. I made an OpenCL version for performance, and a VEX version for debugging.

Currently it includes everything in [TinyVBD](https://github.com/AnkaChan/TinyVBD), which isn't much.

I'll work on this when I have time, but feel free to [contribute](https://github.com/MysteryPancake/Houdini-VBD/pulls) to speed up progress!

## Todo
- [x] Steal from [TinyVBD](https://github.com/AnkaChan/TinyVBD)
  - [x] [Simple mass-spring energy definition](https://github.com/AnkaChan/TinyVBD/blob/main/main.cpp#L381)
  - [x] [Accelerated convergence method](https://graphics.cs.utah.edu/research/projects/vbd/vbd-siggraph2024.pdf)
- [ ] Steal from [full VBD](https://github.com/AnkaChan/Gaia)
  - [ ] [Neo-Hookean energy definition](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_NeoHookean.cpp), likely more stable
  - [ ] Self collisions
  - [ ] External collisions
- [ ] Steal from [AVBD](https://graphics.cs.utah.edu/research/projects/avbd/)
  - [ ] [LDLT decomposition](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf) to improve stability
  - [ ] [Hard constraints](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf)
  - [ ] All other improvements

## What's VBD?

Vertex Block Descent is pretty similar to Vellum. It's basically Vellum 2.

Vellum uses a technique called XPBD (Extended Position Based Dynamics). Here's a few differences:

|  | VBD | Vellum (XPBD) | Advantage | Disadvantage |
| --- | --- | --- | --- | --- |
| **Runs over** | Points | Prims (each constraint) | Fewer colors/workgroups, faster for parallel processing | Takes longer to propagate for stiff objects, since it updates 1 point per iteration instead of 2 (one on each side of the constraint) |
| **Constraints** | Energy based (eg mass-spring energy or Neo-Hookean energy) | XPBD based (eg distance constraints) | Better for larger mass ratios | Randomly explodes due to hessian matrix inversion |
| **Iterations** | Gauss-Seidel | Gauss-Seidel (for constraint iterations) and Jacobi (for smoothing iterations) | Reaches a global solution faster | Might be less stable |

## Why does it explode randomly?
This is a problem with VBD in general.

The core idea of VBD is updating the position based on a force vector and a hessian matrix:
```c
v@P += force * invert(hessian); // force and hessian depend on the energy definition, eg mass-spring or Neo-Hookean
```

`invert(hessian)` is very unstable, so everyone tries to bandaid it in various ways. The VBD paper uses the determinant of the matrix:

```c
if (abs(determinant(hessian)) > 1e-7) {
  v@P += force * invert(hessian);
}
```

This helps, but it explodes when the values gets too large as well.

[AVBD](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf) uses an approximation to make the hessian symmetric positive definite (SPD) to allow LDLT decomposition instead.

It also explodes because [TinyVBD](https://github.com/AnkaChan/TinyVBD) implements [mass-spring energy](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_MassSpring.cpp) instead of [Neo-Hookean](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_NeoHookean.cpp) energy. They [removed mass-spring energy](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_MassSpring.cpp) from full VBD, likely for this reason.

## AVBD Q&A

There's a new paper called [Augmented Vertex Block Descent (AVBD)](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf). It adds many improvements to VBD.

I asked the authors about a few differences. They responded with lots of useful information. Thanks guys!

### Missing accelerated convergence in AVBD

Hi Chris, In the original VBD paper and in TinyVBD, they used an acceleration method to improve convergence (Section 3.8). I noticed in AVBD there's no mention of this method. Was it causing too much instability? Thanks!

> Hi,
> Yeah we ended up not using the acceleration from VBD as it was in general kind of unstable and difficult to tune, even with the original VBD method. It would be interesting to explore other acceleration methods as future work though.
> -Chris

### Energy definition used for AVBD

Hi Chris, I was wondering what type energy you used for constraints? There were multiple used in the VBD paper, including mass spring, StVK, and Neo-Hookean. It looks like you used mass spring energy. Is this correct, or did you use Neo-Hookean? Thanks!

> Hello,
> So you are correct, in our demos we only used a simple spring energy for the deformable examples, as we weren't focused on rehashing what the original VBD paper showed. However, in AVBD, you can use any energy that works in VBD, such as the ones you mentioned. This is because AVBD is purely an extension of VBD. The only thing to keep in mind with those more complex energy types, is that you need to be careful about how you solve each block since their hessians can be indefinite. In general, you can follow the same pattern that AVBD uses for constraint energies. That is, decompose the hessian into an SPD part and a non-SPD part, then use the diagonal lumped approximation proposed in the paper for the non-SPD part.
> Hope that helps!
> -Chris
