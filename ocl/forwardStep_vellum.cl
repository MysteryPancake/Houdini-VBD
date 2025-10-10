#include <quaternion.h>

kernel void forwardStep_vellum(
    float timeinc,
    fpreal3 gravity,
    int _bound_P_length,
    global fpreal * restrict _bound_P,
    int _bound_orient_length,
    global fpreal * restrict _bound_orient,
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
#ifdef HAS_stopped
    int _bound_stopped_length,
    global int * restrict _bound_stopped,
#endif
#ifdef HAS_orientlast
    int _bound_orientlast_length,
    global fpreal * restrict _bound_orientlast,
#endif
#ifdef HAS_wlast
    int _bound_wlast_length,
    global fpreal * restrict _bound_wlast,
#endif
    int _bound_w_length,
    global fpreal * restrict _bound_w,
    int _bound_orientprevious_length,
    global fpreal * restrict _bound_orientprevious,
    int _bound_wprevious_length,
    global fpreal * restrict _bound_wprevious)
{
    int idx = get_global_id(0);
    if (idx >= _bound_P_length) return;

    const fpreal mass = _bound_mass[idx];
    if (mass <= 0.0f) return; // Skip pinned points

#ifdef HAS_stopped
    // @stopped = 1 pins position
    const int stopped = _bound_stopped[idx];
    if (!(stopped & 1))
    {
#endif

    // Gravity gets added directly to the velocity
    // This is the same as adding it to the inertia as @gravity * @TimeInc * @TimeInc
    fpreal3 v = vload3(idx, _bound_v);
    v += gravity * timeinc;
    vstore3(v, idx, _bound_v);
        
#if defined(HAS_plast) && defined(HAS_vlast)
    // Second order integration (BDF2)
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

#ifdef HAS_stopped
    }
    // @stopped = 2 pins rotation
    if (stopped & 2) return;
#endif

    // Angular integration
    quat orient = vload4(idx, _bound_orient);
    fpreal3 w = vload3(idx, _bound_w);
    
#if defined(HAS_orientlast) && defined(HAS_wlast)
    // Second order integration (BDF2)
    // This isn't actually valid for quaternions, causes some weird results
    const quat orientprevious = vload4(idx, _bound_orientprevious);
    const quat orientlast = vload4(idx, _bound_orientlast);
    const fpreal3 wprevious = vload3(idx, _bound_wprevious);
    const fpreal3 wlast = vload3(idx, _bound_wlast);
    
    w = (4.0f * wprevious - wlast + 2.0f * (w - wprevious)) / 3.0f;
    // Vellum has a mistake below where the last component is 1 instead of 0
    const quat dqdt = 0.5f * qmultiply((quat)(w, 0.0f), orient);
    orient = (4.0f * orientprevious - orientlast + 2.0f * timeinc * dqdt) / 3.0f;
#else
    // First order integration
    orient += timeinc * 0.5f * qmultiply((quat)(w, 0.0f), orient);
#endif

    vstore4(normalize(orient), idx, _bound_orient);
}