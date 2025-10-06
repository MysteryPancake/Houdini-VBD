#include <quaternion.h>

kernel void updateVelocity( 
    fpreal timeinc,
    int _bound_v_length,
    global fpreal * restrict _bound_v,
    int _bound_vprevious_length,
    global fpreal * restrict _bound_vprevious,
    int _bound_P_length,
    global fpreal * restrict _bound_P,
    int _bound_pprevious_length,
    global fpreal * restrict _bound_pprevious,
    int _bound_mass_length,
    global fpreal * restrict _bound_mass,
    int _bound_stopped_length,
    global int * restrict _bound_stopped,
    int _bound_wprevious_length,
    global fpreal * restrict _bound_wprevious,
    int _bound_w_length,
    global fpreal * restrict _bound_w,
    int _bound_orient_length,
    global fpreal * restrict _bound_orient,
    int _bound_orientprevious_length,
    global fpreal * restrict _bound_orientprevious
)
{
    int idx = get_global_id(0);
    if (idx >= _bound_v_length) return;

    const fpreal mass = _bound_mass[idx];
    const int stopped = _bound_stopped[idx];
    if (mass <= 0.0f || stopped) return; // Skip pinned points
    
    // Vellum sets @vprevious at the start of each substep, but VBD sets it here
    // This is not a typo, it's used for an acceleration estimate during adaptive warmstarting
    const fpreal3 v = vload3(idx, _bound_v);
    vstore3(v, idx, _bound_vprevious);
    
    // The same probably applies to rotation too (added by AVBD)
    const fpreal3 w = vload3(idx, _bound_w);
    vstore3(w, idx, _bound_wprevious);
    
    // First order velocity, same as Vellum
    const fpreal3 P = vload3(idx, _bound_P);
    const fpreal3 pprevious = vload3(idx, _bound_pprevious);
    vstore3((P - pprevious) / timeinc, idx, _bound_v);
    
    // First order angular from AVBD (Eq. 7)
    // https://graphics.cs.utah.edu/research/projects/avbd/Augmented_VBD-SIGGRAPH25_RTL.pdf
    const quat orient = vload4(idx, _bound_orient);
    const quat orientprevious = vload4(idx, _bound_orientprevious);
    
    // This assumes orientprevious is normalized
    const quat orientdiff = qmultiply(orient, qconjugate(orientprevious));
    vstore3((2.0f * orientdiff.xyz) / timeinc, idx, _bound_w);
}