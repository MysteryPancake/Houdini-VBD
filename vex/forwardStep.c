// VEX used for debugging the OpenCL version (ocl/forwardStep.cl)
// Slow and outdated now (rewrite of TinyVBD), but easier to read

if (f@mass <= 0) return; // Skip pinned points

vector gravity = chv("gravity");

v@pprevious = v@P;

// First order integration, same as Vellum
v@inertia = v@P + v@v * f@TimeInc + gravity * f@TimeInc * f@TimeInc;

// Adaptive warmstart
vector accel = (v@v - v@vprevious) / f@TimeInc;
float gravNorm = length(v@gravity);
float accelWeight = clamp(dot(v@accel, v@gravity / gravNorm) / gravNorm, 0, 1);
v@P = v@inertia + accelWeight * v@gravity * f@TimeInc * f@TimeInc;

// Used for accelerated convergence
f@omega = 1;