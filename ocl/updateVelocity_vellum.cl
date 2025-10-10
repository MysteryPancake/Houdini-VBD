#include <quaternion.h>

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
#ifdef HAS_stopped
    int _bound_stopped_length,
    global int * restrict _bound_stopped,
#endif
    int _bound_w_length,
    global fpreal * restrict _bound_w,
    int _bound_orient_length,
    global fpreal * restrict _bound_orient,
#ifdef HAS_orientlast
    int _bound_orientlast_length,
    global fpreal * restrict _bound_orientlast,
#endif
    int _bound_orientprevious_length,
    global fpreal * restrict _bound_orientprevious)
{
    int idx = get_global_id(0);
    if (idx >= _bound_v_length) return;
    
    const fpreal mass = _bound_mass[idx];
    if (mass <= 0.0f) return; // Skip pinned points

#ifdef HAS_stopped
    // @stopped = 1 pins position
    const int stopped = _bound_stopped[idx];
    if (!(stopped & 1))
    {
#endif

    const fpreal3 P = vload3(idx, _bound_P);
    const fpreal3 pprevious = vload3(idx, _bound_pprevious);
    
#ifdef HAS_plast
    // Second order integration (BDF2)
    const fpreal3 plast = vload3(idx, _bound_plast);
    vstore3(((2.0f * P + (P + plast)) - 4.0f * pprevious) / (2.0f * timeinc), idx, _bound_v);
#else
    // First order integration
    vstore3((P - pprevious) / timeinc, idx, _bound_v);
#endif

#ifdef HAS_stopped
    }
    // @stopped = 2 pins rotation
    if (stopped & 2) return;
#endif

    quat orient = vload4(idx, _bound_orient);
    const quat orientprevious = vload4(idx, _bound_orientprevious);

#ifdef HAS_orientlast
    // Second order integration (BDF2)
    // This isn't actually valid for quaternions, causes some weird results
    const quat orientlast = vload4(idx, _bound_orientlast);
    orient = qmultiply(3.0f * orient - 4.0f * orientprevious + orientlast, qconjugate(orient));
    vstore3(orient.xyz / timeinc, idx, _bound_w);
#else
    // First order integration, assumes orientprevious is normalized
    orient = qmultiply(orient, qconjugate(orientprevious));
    vstore3((2.0f * orient.xyz) / timeinc, idx, _bound_w);
#endif
}