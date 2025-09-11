kernel void forwardStep_vellum( 
    float timeinc,
    fpreal3 gravity,
    int _bound_P_length,
    global fpreal * restrict _bound_P,
    int _bound_v_length,
    global fpreal * restrict _bound_v,
    int _bound_pprevious_length,
    global fpreal * restrict _bound_pprevious,
#ifdef HAS_plast
    int _bound_plast_length,
    global fpreal * restrict _bound_plast,
#endif
    int _bound_vprevious_length,
    global fpreal * restrict _bound_vprevious,
#ifdef HAS_vlast
    int _bound_vlast_length,
    global fpreal * restrict _bound_vlast,
#endif
    int _bound_inertia_length,
    global fpreal * restrict _bound_inertia,
    int _bound_mass_length,
    global fpreal * restrict _bound_mass,
    int _bound_stopped_length,
    global int * restrict _bound_stopped)
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

#if defined(HAS_plast) && defined(HAS_vlast)
    // Second order integration
    const fpreal3 pprevious = vload3(idx, _bound_pprevious);
    const fpreal3 plast = vload3(idx, _bound_plast);
    const fpreal3 vprevious = vload3(idx, _bound_vprevious);
    const fpreal3 vlast = vload3(idx, _bound_vlast);
    v = (4.0f * vprevious - vlast + 2.0f * (v - vprevious)) / 3.0f;
    const fpreal3 inertia = (4.0f * pprevious - plast + 2.0f * timeinc * v) / 3.0f;
#else
    // First order integration
    const fpreal3 P = vload3(idx, _bound_P);
    const fpreal3 inertia = P + v * timeinc;
#endif
    
    vstore3(inertia, idx, _bound_inertia);
    vstore3(inertia, idx, _bound_P);
}