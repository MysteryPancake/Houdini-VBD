# Houdini Vertex Block Descent

<img src="./images/demo.webp" height="300">

Very early WIP of Vertex Block Descent in Houdini. It runs natively without plugins, as god intended.

There's an OpenCL version for performance, and a VEX version for debugging. Both are included in the HIP files.

Currently it has everything from [TinyVBD](https://github.com/AnkaChan/TinyVBD) and some bits from [AVBD](https://graphics.cs.utah.edu/research/projects/avbd/).

| [Download the HIP file!](../../releases/latest) |
| --- |

## Todo
- [x] Steal from [TinyVBD](https://github.com/AnkaChan/TinyVBD)
  - [x] [Mass-spring/StVK energy definition](https://github.com/AnkaChan/TinyVBD/blob/main/main.cpp#L381)
  - [x] [Accelerated convergence method (section 3.8)](https://graphics.cs.utah.edu/research/projects/vbd/vbd-siggraph2024.pdf)
- [ ] Steal from [full VBD](https://github.com/AnkaChan/Gaia)
  - [ ] [Neo-hookean energy definition](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_NeoHookean.cpp), likely more stable
  - [ ] Damping
  - [ ] Self collisions
  - [ ] External collisions
  - [ ] Friction
- [ ] Steal from [AVBD](https://graphics.cs.utah.edu/research/projects/avbd/)
  - [x] [LDLT decomposition](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf) to improve stability
  - [ ] [Hard constraints](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf)
  - [ ] All other improvements
- [ ] Touch grass

## What's Vertex Block Descent?

VBD is very similar to Vellum. You might call it Vellum 2.

Vellum uses a technique called [XPBD (Extended Position-Based Dynamics)](https://matthias-research.github.io/pages/publications/XPBD.pdf). XPBD uses constraints to simulate soft body behaviour. Constraints are solved in parallel workgroups (colors) in OpenCL for better performance. Colors are groups of constraints that aren't directly connected.

Cloth is a good example of a soft body. It's bendy but stiff in terms of edge lengths. In XPBD this is simulated with distance constraints. Distance constraints try to preserve their rest length based on stiffness. When you stretch or squash a distance constraint, it pulls the points towards the middle until they reach their rest length again. Since shortening one constraint makes others longer and vice versa, it's an iterative process. It propagates over several iterations until everything converges to the target length.

<img src="./images/edging.png" width="700">

VBD constraints are similar, but they're defined in terms of energy instead. They also run over each point rather than each constraint, meaning less workgroups (colors) overall. The Graph Color node allows workgroups for points as well as prims, so it works both for VBD and XPBD.

Here's a quick comparison between VBD and XPBD:

|  | VBD | Vellum (XPBD) | Advantage | Disadvantage |
| --- | --- | --- | --- | --- |
| **Runs over** | <p align="center">Point colors<br><img src="./images/color_points.png"></p> | <p align="center">Colors per constraint<br><img src="./images/color_prims.png"></p> | Less colors/workgroups, better for parallel processing | Takes longer to converge for stiff objects, partly because it updates 1 point per iteration instead of 2 (one on each side of the constraint) |
| **Constraints** | Energy based (eg mass-spring energy or neo-hookean energy) | XPBD based (eg distance constraints) | Better for larger mass ratios | Randomly explodes due to hessian matrix inversion |
| **Iterations** | Gauss-Seidel | Gauss-Seidel (for constraint iterations) and Jacobi (for smoothing iterations) | Reaches a global solution faster | Might be less stable |

The most important part of VBD is the energy definition, but no one seems to agree on this.

I've seen many different energy definitions, including mass-spring (used by [TinyVBD](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_MassSpring.cpp) and [AVBD](https://github.com/savant117/avbd-demo2d/blob/main/source/spring.cpp#L40), but [removed from full VBD](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_MassSpring.cpp)) and neo-hookean (used by [full VBD](https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_NeoHookean.cpp)).

Neo-hookean energy was the most used in the paper, so I'm guessing it's the mist stable.

## How does Vertex Block Descent run?

Ignoring collisions, VBD is really just 3 steps. These steps are nearly identical to XPBD apart from the constraints.

### 1. Integrate the positions

Add the velocity to the position (same as XPBD). VBD has a few methods of doing this, but they all give similar results.

I included first and second-order Euler integration (Vellum style), with a flag to enable adaptive first-order integration as seen in VBD.

```c
// First-order Euler integration
v@pprevious = v@P;
v@v += gravity * f@TimeInc;
v@P += v@v * f@TimeInc;
```

| [OpenCL version](./ocl/forwardStep.cl) | [VEX version (outdated)](./vex/forwardStep.c) |
| --- | --- |

### 2. Apply the constraints

The core idea of VBD is updating the position based on a force vector and a hessian matrix.

If the influences are correct, moving the position should reduce the variational energy of the system.

> [!CAUTION]
> **This MUST be run in workgroups based on graph coloring!**
>
> If points move while their neighbours access them (like if running in sequential order), it breaks the assumption used by VBD:
> 
>  > We adjust each vertex separately, assuming the others remain fixed
> 
> This causes growing error each iteration, leading VBD to explode much more than usual.

```c
vector force = 0;
matrix3 hessian = 0;

// Add influences to the force and hessian variables
accumulateInertiaForceAndHessian(force, hessian); // Influences due to mass and inertia
accumulateMaterialForceAndHessian(force, hessian); // Influences due to constraints (eg mass-spring or neo-hookean)
accumulateDampingForceAndHessian(force, hessian); // Influences due to damping
accumlateBoundaryForceAndHessian(force, hessian); // Influences due to boundaries (eg floor planes)
accumlateCollisionForceAndHessian(force, hessian); // Influences due to collisions

v@P += force * invert(hessian); // Reduce the variational energy of the system
```

| [OpenCL version](./ocl/solveConstraintsVBD.cl) | [VEX version (outdated)](./vex/solveConstraintsVBD.c) |
| --- | --- |

### 3. Update the velocities

Update the velocities based on the change in position (same as XPBD). TinyVBD only included first-order velocities.

I included first and second-order Euler velocities (Vellum style).

```c
// First-order Euler velocities
v@v = (v@P - v@pprevious) / f@TimeInc;
```

| [OpenCL version](./ocl/updateVelocity.cl) | [VEX version (outdated)](./vex/updateVelocity.c) |
| --- | --- |

## Why does it explode randomly?

This solver used to explode every 5 seconds, but now it's much better. Explosions are a common issue with VBD.

VBD involves updating the position based on a force vector and a hessian matrix:

```c
v@P += force * invert(hessian); // force and hessian depend on the energy definition, eg mass-spring or neo-hookean
```

`invert(hessian)` is very unstable, so everyone tries to bandaid it in various ways. The [VBD paper](https://graphics.cs.utah.edu/research/projects/vbd/vbd-siggraph2024.pdf) uses the determinant of the matrix:

```c
if (abs(determinant(hessian)) > 1e-7) { // if |det(H𝑖)| > 𝜖 for some small threshold 𝜖
  v@P += force * invert(hessian);
}
```

This helps, but it also explodes when the values gets too large (for example with very stiff constraints).

The new [AVBD paper](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf) uses an approximation to make the hessian positive semi-definite. I found this massively improves the stability.

## AVBD Q&A

There's a new paper called [Augmented Vertex Block Descent (AVBD)](https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25.pdf). It adds many improvements to VBD.

I asked the authors about some differences I noticed. They responded with lots of useful information. Thanks guys!

### Missing accelerated convergence

Hi Chris, In the original VBD paper and in TinyVBD, they used an acceleration method to improve convergence (Section 3.8). I noticed in AVBD there's no mention of this method. Was it causing too much instability? Thanks!

> Hi,
> Yeah we ended up not using the acceleration from VBD as it was in general kind of unstable and difficult to tune, even with the original VBD method. It would be interesting to explore other acceleration methods as future work though.
> -Chris

> No, we haven't looked into acceleration for AVBD.
> -Cem

### Energy definition used

Hi Chris, I was wondering what type energy you used for constraints? There were multiple used in the VBD paper, including mass-spring and neo-hookean. It looks like you used mass-spring energy. Is this correct, or did you use neo-hookean? Thanks!

> Hello,
> So you are correct, in our demos we only used a simple spring energy for the deformable examples, as we weren't focused on rehashing what the original VBD paper showed. However, in AVBD, you can use any energy that works in VBD, such as the ones you mentioned. This is because AVBD is purely an extension of VBD. The only thing to keep in mind with those more complex energy types, is that you need to be careful about how you solve each block since their hessians can be indefinite. In general, you can follow the same pattern that AVBD uses for constraint energies. That is, decompose the hessian into an SPD part and a non-SPD part, then use the diagonal lumped approximation proposed in the paper for the non-SPD part.
> Hope that helps!
> -Chris

> No. The AVBD tests we have are for contacts and joints. VBD already covers soft bodies. AVBD makes no changes to that.
> -Cem
