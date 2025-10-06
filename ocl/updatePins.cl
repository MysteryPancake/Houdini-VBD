kernel void updatePins( 
    int _bound_P_length,
    global fpreal * restrict _bound_P,
#ifdef HAS_gluetoanimation
    int _bound_gluetoanimation_length,
    global int * restrict _bound_gluetoanimation,
#endif
#ifdef HAS_pintoanimation
    int _bound_pintoanimation_length,
    global int * restrict _bound_pintoanimation,
#endif
    int _bound_id_length,
    global int * restrict _bound_id,
    int _bound_animP_length,
    global fpreal * restrict _bound_animP)
{
    const int idx = get_global_id(0);
    if (idx >= _bound_P_length) return;

    // For now @gluetoanimation and @pintoanimation do the same thing
    int stuck = 0;
#ifdef HAS_gluetoanimation
    stuck |= _bound_gluetoanimation[idx];
#endif
#ifdef HAS_pintoanimation
    stuck |= _bound_pintoanimation[idx];
#endif
    if (!stuck) return;

    // Graph Color sorts the points, so the order of the animated points mismatches
    // @id stores the index before sorting, use it to map back to the correct point
    // This must be done after graph coloring since @id relies on it
    const int id = _bound_id[idx];
    if (id >= _bound_P_length) return;

    // TODO: Interpolate animated position like Otis does
    const fpreal3 animP = vload3(id, _bound_animP);
    vstore3(animP, idx, _bound_P);
}