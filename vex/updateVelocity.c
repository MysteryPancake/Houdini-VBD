// VEX used for debugging the OpenCL version (ocl/updateVelocity.cl)
// Slow and outdated now (rewrite of TinyVBD), but easier to read

if (f@mass <= 0) return; // Skip pinned points

// Vellum sets @vprevious at the start of each substep, but VBD sets it here
// This is not a typo, it's used for an acceleration estimate during adaptive warmstarting
v@vprevious = v@v;
i@has_vprevious = 1;

// First order velocity, same as Vellum
v@v = (v@P - v@pprevious) / f@TimeInc;