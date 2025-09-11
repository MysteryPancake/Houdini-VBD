kernel void updateVelocity_vellum( 
    fpreal timeinc,
    int _bound_v_length,
    global fpreal * restrict _bound_v,
    int _bound_P_length,
    global fpreal * restrict _bound_P,
    int _bound_pprevious_length,
    global fpreal * restrict _bound_pprevious,
#ifdef HAS_plast
    int _bound_plast_length,
    global fpreal * restrict _bound_plast,
#endif
    int _bound_mass_length,
    global fpreal * restrict _bound_mass,
    int _bound_stopped_length,
    global int * restrict _bound_stopped)
{
    int idx = get_global_id(0);
    if (idx >= _bound_v_length) return;
    
    const fpreal mass = _bound_mass[idx];
    const int stopped = _bound_stopped[idx];
    if (mass <= 0.0f || stopped) return; // Skip pinned points

    const fpreal3 P = vload3(idx, _bound_P);
    const fpreal3 pprevious = vload3(idx, _bound_pprevious);
    
#ifdef HAS_plast
    // Second order integration
    const fpreal3 plast = vload3(idx, _bound_plast);
    vstore3(((2.0f * P + (P + plast)) - 4.0f * pprevious) / (2.0f * timeinc), idx, _bound_v);
#else
    // First order integration
    vstore3((P - pprevious) / timeinc, idx, _bound_v);
#endif
}