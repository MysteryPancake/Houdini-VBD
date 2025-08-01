// VEX used for debugging the OpenCL version (ocl/forwardStep.cl)
// Slow and outdated now (rewrite of TinyVBD), but easier to read

if (f@mass <= 0) return; // Skip pinned points

int adaptive = chi("initialization");
vector gravity = chv("gravity");

v@pprevious = v@P;

// First order integration, same as Vellum
v@inertia = v@P + v@v * f@TimeInc + gravity * f@TimeInc * f@TimeInc;

if (adaptive && i@has_vprevious) {
    // Adaptive warmstart, this has bizarre issues with gravity reduction depending on mass
    vector accel = (v@v - v@vprevious) / f@TimeInc;
    float gravNorm = length(gravity);
    float accelWeight = clamp(dot(accel, gravity / gravNorm) / gravNorm, 0, 1);
    v@P = v@inertia + gravity * accelWeight * f@TimeInc * f@TimeInc;
} else {
    // Inertia and acceleration, much more reliable
    v@P = v@inertia;
}

// Used for accelerated convergence
f@omega = 1;