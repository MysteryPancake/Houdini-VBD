// VEX used for debugging the OpenCL version (ocl/forwardStep.cl)
// Slow and outdated now (rewrite of TinyVBD), but easier to read

if (f@mass <= 0) return;

vector gravity = chv("gravity");
float gravNorm = chf("gravity_norm");

v@v += gravity * f@TimeInc;
v@inertia = v@P + v@v * f@TimeInc;
v@pprevious = v@P;

if (i@has_vprevious) {
    v@accel = (v@v - v@vprevious) / f@TimeInc;
    i@has_accel = 1;
}

if (i@has_accel) {
    vector gravDir = normalize(gravity);
    float accelComponent = min(gravNorm, dot(v@accel, gravDir));
    if (accelComponent < 1e-5) accelComponent = 0;
    v@P += v@vprevious * f@TimeInc + accelComponent * gravDir * f@TimeInc * f@TimeInc;
} else {
    v@P = v@inertia;
}

f@omega = 1.0;