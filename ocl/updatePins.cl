kernel void updatePins( 
    int _bound_P_length,
    global fpreal * restrict _bound_P,
    int _bound_gluetoanimation_length,
    global int * restrict _bound_gluetoanimation,
    int _bound_id_length,
    global int * restrict _bound_id,
    int _bound_animP_length,
    global fpreal * restrict _bound_animP)
{
    const int idx = get_global_id(0);
    if (idx >= _bound_P_length) return;

    const int glue = _bound_gluetoanimation[idx];
    if (!glue) return;

    // Graph Color sorts the points, so the order of the animated points mismatches
    // @id stores the index before sorting, use it to map back to the correct point
    // This must be done after graph coloring since @id relies on it
    const int id = _bound_id[idx];
    if (id >= _bound_P_length) return;

    const fpreal3 animP = vload3(id, _bound_animP);
    vstore3(animP, idx, _bound_P);
}