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
    global int * restrict _bound_stopped
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
    
    // First order velocity, same as Vellum
    const fpreal3 P = vload3(idx, _bound_P);
    const fpreal3 pprevious = vload3(idx, _bound_pprevious);
    vstore3((P - pprevious) / timeinc, idx, _bound_v);
}