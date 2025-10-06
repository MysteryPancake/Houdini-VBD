#include <quaternion.h>

kernel void forwardStep(
    fpreal timeinc,
    int simframe,
    fpreal3 gravity,
    int _bound_initialization,
    int _bound_P_length,
    global fpreal * restrict _bound_P,
    int _bound_v_length,
    global fpreal * restrict _bound_v,
    int _bound_inertia_length,
    global fpreal * restrict _bound_inertia,
    int _bound_pprevious_length,
    global fpreal * restrict _bound_pprevious,
    int _bound_vprevious_length,
    global fpreal * restrict _bound_vprevious,
    int _bound_mass_length,
    global fpreal * restrict _bound_mass,
    int _bound_stopped_length,
    global int * restrict _bound_stopped,
    int _bound_orient_length,
    global fpreal * restrict _bound_orient,
    int _bound_w_length,
    global fpreal * restrict _bound_w)
{
    int idx = get_global_id(0);
    if (idx >= _bound_P_length) return;

    const fpreal mass = _bound_mass[idx];
    const int stopped = _bound_stopped[idx];
    if (mass <= 0.0f || stopped) return; // Skip pinned points
    
    // Gravity gets added directly to the velocity
    // This is the same as adding it to the inertia as @gravity * @TimeInc * @TimeInc
    fpreal3 v = vload3(idx, _bound_v);
    v += gravity * timeinc;
    vstore3(v, idx, _bound_v);

    // First order integration, same as Vellum
    const fpreal3 P = vload3(idx, _bound_P);
    const fpreal3 inertia = P + v * timeinc;
    vstore3(inertia, idx, _bound_inertia);
    
#if initialization == 0
    // Inertia
    const fpreal3 vprevious = vload3(idx, _bound_vprevious);
    vstore3(P + vprevious * timeinc, idx, _bound_P);
#elif initialization == 1
    // Inertia and acceleration
    vstore3(inertia, idx, _bound_P);
#elif initialization == 2
    // Adaptive
    if (simframe <= 2.0f)
    {
        // We don't have @vprevious, use inertia and acceleration
        vstore3(inertia, idx, _bound_P);
    }
    else
    {
        const fpreal3 vprevious = vload3(idx, _bound_vprevious);
        const fpreal3 accel = (v - vprevious) / timeinc;
        const fpreal gravNorm = length(gravity);
        const fpreal3 gravDir = gravity / gravNorm;
        const fpreal accelWeight = clamp(dot(accel, gravDir) / gravNorm, 0.0f, 1.0f);
        vstore3(P + vprevious * timeinc + gravity * accelWeight * timeinc * timeinc, idx, _bound_P);
    }
#endif

    // First order angular integration from AVBD (Eq. 9)
    // https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25_RTL.pdf
    quat orient = vload4(idx, _bound_orient);
    const fpreal3 w = vload3(idx, _bound_w);
    orient += timeinc * 0.5f * qmultiply((quat)(w, 0.0f), orient);
    vstore4(normalize(orient), idx, _bound_orient);
}