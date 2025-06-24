# Houdini Vertex Block Descent (VBD Solver)

Early rewrite of Vertex Block Descent for Houdini. I made an OpenCL version for decent performance, and a VEX version for debugging.

Currently it includes everything in [TinyVBD](https://github.com/AnkaChan/TinyVBD), which isn't much.

Currently it's pretty unstable. This is a problem with VBD overall, but also because TinyVBD uses mass-spring energy instead of Neo-Hookean energy.

They removed mass spring energy from the main codebase, probably for this reason.

## What's VBD?

Vertex Block Descent is pretty similar to Vellum. Vellum uses a technique called XPBD (Extended Position Based Dynamics).

Cloth is connected by a bunch of edges. In XPBD, these edges act as distance constraints. Distance constraints try to keep their length the same, so if the cloth gets stretched it tries to return back to its original length.

XPBD

## Todo
- [x] Basic mass spring energy, unstable (TinyVDB)
- [x] Accelerated convergence method (VDB paper, section 3.8)
- [ ] LDLT Decomposition (AVBD paper)
- [ ] Neo-Hookean energy, more stable (GAIA)
- [ ] Collisions
- [ ] Improvements from AVBD paper
