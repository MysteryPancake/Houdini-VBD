// For accelerated convergence, tends to explode so it's disabled by default
kernel void resetOmega( 
    int omega_length,
    global fpreal * restrict omega)
{
    const int idx = get_global_id(0);
    if (idx >= omega_length) return;
    omega[idx] = 1.0f;
}