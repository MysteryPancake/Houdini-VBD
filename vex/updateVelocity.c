// VEX used for debugging the OpenCL version (ocl/updateVelocity.cl)
// Slow and outdated now (rewrite of TinyVBD), but easier to read

if (f@mass <= 0) return;

v@v = (v@P - v@pprevious) / f@TimeInc;

v@vprevious = v@v;
i@has_vprevious = 1;