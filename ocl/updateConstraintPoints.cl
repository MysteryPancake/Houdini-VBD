kernel void updateConstraintPoints(
    int _bound_Pcon_length,
    global fpreal * restrict _bound_Pcon,
    int _bound_coloredidx_length,
    global int * restrict _bound_coloredidx,
    int _bound_P_length,
    global fpreal * restrict _bound_P)
{
    const int idx = get_global_id(0);
    if (idx >= _bound_Pcon_length) return;

    // Skip non-matching points
    const int coloredidx = _bound_coloredidx[idx];
    if (coloredidx < 0 || coloredidx >= _bound_Pcon_length) return;

    const fpreal3 P = vload3(coloredidx, _bound_P);
    vstore3(P, coloredidx, _bound_Pcon);
}