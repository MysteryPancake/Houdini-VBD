#include <matrix.h>

//#define USE_AVBD_SOLVE

// Slightly faster but memory unsafe
#define entriesAt(_arr_, _idx_) (_arr_##_index[_idx_+1] - _arr_##_index[_idx_])
#define compAt(_arr_, _idx_, _compidx_) _arr_[_arr_##_index[_idx_] + _compidx_]
//#define entriesAt(_arr_, _idx_) ((_idx_ >= 0 && _idx_ < _arr_##_length) ? (_arr_##_index[_idx_+1] - _arr_##_index[_idx_]) : 0)
//#define compAt(_arr_, _idx_, _compidx_) ((_idx_ >= 0 && _idx_ < _arr_##_length && _compidx_ >= 0 && _compidx_ < entriesAt(_arr_, _idx_)) ? _arr_[_arr_##_index[_idx_] + _compidx_] : 0)

#ifdef USE_AVBD_SOLVE
// f * invert(h) using LDLT decomposition, less stable in my tests
// From https://github.com/savant117/avbd-demo2d/blob/main/source/maths.h#L323
static inline fpreal3 solve(
    const fpreal3 force,
    const mat3 hessian)
{
    // Compute LDL^T decomposition
    fpreal D1 = hessian[0][0];
    fpreal L21 = hessian[1][0] / hessian[0][0];
    fpreal L31 = hessian[2][0] / hessian[0][0];
    fpreal D2 = hessian[1][1] - L21 * L21 * D1;
    fpreal L32 = (hessian[2][1] - L21 * L31 * D1) / D2;
    fpreal D3 = hessian[2][2] - (L31 * L31 * D1 + L32 * L32 * D2);

    // Forward substitution: Solve Ly = f
    fpreal y1 = force.x;
    fpreal y2 = force.y - L21 * y1;
    fpreal y3 = force.z - L31 * y1 - L32 * y2;

    // Diagonal solve: Solve Dz = y
    fpreal z1 = y1 / D1;
    fpreal z2 = y2 / D2;
    fpreal z3 = y3 / D3;

    // Backward substitution: Solve L^T x = z
    fpreal3 x;
    x[2] = z3;
    x[1] = z2 - L32 * x[2];
    x[0] = z1 - L21 * x[1] - L31 * x[2];

    return x;
}
#else
// out = f * invert(h) with a check similar to abs(det(h)) > epsilon
// From https://github.com/AnkaChan/CuMatrix/blob/main/CuMatrix/MatrixOps/CuMatrix.h#L235
static inline int solve(
    const fpreal3 force,
    const mat3 hessian,
    fpreal3 *out,
    const fpreal epsilon)
{
    const fpreal s0 = hessian[0].s0; const fpreal s3 = hessian[1].s0; const fpreal s6 = hessian[2].s0;
    const fpreal s1 = hessian[0].s1; const fpreal s4 = hessian[1].s1; const fpreal s7 = hessian[2].s1;
    const fpreal s2 = hessian[0].s2; const fpreal s5 = hessian[1].s2; const fpreal s8 = hessian[2].s2;
    
    const fpreal i0 = s8 * s4 - s5 * s7;
    const fpreal i1 = -(s8 * s3 - s5 * s6);
    const fpreal i2 = s7 * s3 - s4 * s6;
    
    const fpreal det = s0 * i0 + s1 * i1 + s2 * i2;
    
    if (fabs(det) < epsilon * (fabs(s0 * i0) + fabs(s1 * i1) + fabs(s2 * i2)))
    {
        (*out) = force;
        return 0;
    }
    
    (*out).x = (i0 * force.x + i1 * force.y + i2 * force.z) / det;
    (*out).y = (-(s8 * s1 - s2 * s7) * force.x +  (s8 * s0 - s2 * s6) * force.y + -(s7 * s0 - s1 * s6) * force.z) / det;
    (*out).z = ( (s5 * s1 - s2 * s4) * force.x + -(s5 * s0 - s2 * s3) * force.y +  (s4 * s0 - s1 * s3) * force.z) / det;
    return 1;
}
#endif

// Used for accelerated convergence, tends to explode. Probably will remove later
// From https://github.com/AnkaChan/TinyVBD/blob/main/main.cpp#L193
static inline fpreal getAcceleratorOmega(
    const int order,
    const fpreal pho,
    const fpreal prevOmega)
{
    switch (order)
    {
        case 1:
            return 1.0;
        case 2:
            return 2.0 / (2.0 - (pho * pho));
        default:
            return 4.0 / (4.0 - (pho * pho) * prevOmega);
    }
}

// Include influence from inertia
// From https://github.com/AnkaChan/Gaia/blob/main/Simulator/Modules/VBD/VBD_BaseMaterial.h#L359
static inline void accumulateInertiaForceAndHessian(
    fpreal3 *force,
    mat3 hessian,
    const fpreal mass,
    const fpreal3 P,
    const fpreal3 inertia,
    const fpreal dtSqrReciprocal)
{
    (*force) += mass * (inertia - P) * dtSqrReciprocal;
    fpreal md = mass * dtSqrReciprocal;
    hessian[0] += (fpreal3)(md, 0.0f, 0.0f);
    hessian[1] += (fpreal3)(0.0f, md, 0.0f);
    hessian[2] += (fpreal3)(0.0f, 0.0f, md);
}

// Include influence from spring constraints, for mass-spring energy
static inline void accumulateMaterialForceAndHessian_MassSpring(
    fpreal3 *force,
    mat3 hessian,
    const int idx,
    global int *_bound_pointprims,
    global int *_bound_pointprims_index,
    global int *_bound_primpoints,
    global int *_bound_primpoints_index,
    global fpreal *_bound_P,
    global fpreal* _bound_stiffness,
    global fpreal *_bound_restlength)
{
    int len = entriesAt(_bound_pointprims, idx);
    // For each edge connected to the current point
    for (int con = 0; con < len; ++con)
    {
        // Get the constraint associated with this edge
        int prim = compAt(_bound_pointprims, idx, con);
        
        // Get the edge's first 2 points, assuming one point is us and the other isn't
        int pt0 = compAt(_bound_primpoints, prim, 0);
        int pt1 = compAt(_bound_primpoints, prim, 1);
        fpreal3 p0 = vload3(pt0, _bound_P);
        fpreal3 p1 = vload3(pt1, _bound_P);
        
        /// Evaluate the hessian for the mass-spring energy definition
        // From https://github.com/AnkaChan/TinyVBD/blob/main/main.cpp#L381
        fpreal3 diff = p0 - p1;
        fpreal l = length(diff);
        fpreal l0 = _bound_restlength[prim];
        fpreal stiffness = _bound_stiffness[prim];
        fpreal lengthScale = l0 / l;
        fpreal l2 = l * l;
        hessian[0] += stiffness * ((fpreal3)(1.0f, 0.0f, 0.0f) - lengthScale * ((fpreal3)(1.0f, 0.0f, 0.0f) - (diff * diff.x) / l2));
        hessian[1] += stiffness * ((fpreal3)(0.0f, 1.0f, 0.0f) - lengthScale * ((fpreal3)(0.0f, 1.0f, 0.0f) - (diff * diff.y) / l2));
        hessian[2] += stiffness * ((fpreal3)(0.0f, 0.0f, 1.0f) - lengthScale * ((fpreal3)(0.0f, 0.0f, 1.0f) - (diff * diff.z) / l2));
        
        // Force for the mass-spring energy definition
        (*force) += (stiffness * (l0 - l) / l) * diff * (pt0 == idx ? 1 : -1);
    }
}

// I stole the workgroup span code from Vellum (pbd_constraints.cl)
// It ensures stuff runs properly regardless how the workgroups are split
// Check the "Use Single Workgroup" setting in the Options tab to see what it does
kernel void solveConstraintsVBD(
#ifdef SINGLE_WORKGROUP
#ifdef SINGLE_WORKGROUP_SPANS
    int startcolor,
#endif
    int ncolors,
    global const int *color_offsets,
    global const int *color_lengths,
#else
    int color_offset,
    int color_length,
#endif
    fpreal timeinc,
    int _bound_P_length,
    global fpreal * restrict _bound_P,
    int _bound_inertia_length,
    global fpreal * restrict _bound_inertia,
    int _bound_mass_length,
    global fpreal * restrict _bound_mass,
    int _bound_pointprims_length,
    global int * restrict _bound_pointprims_index,
    global int * restrict _bound_pointprims,
    int _bound_restlength_length,
    global fpreal * restrict _bound_restlength,
    int _bound_stiffness_length,
    global fpreal * restrict _bound_stiffness,
    int _bound_primpoints_length,
    global int * restrict _bound_primpoints_index,
    global int * restrict _bound_primpoints,
    int _bound_omega_length,
    global fpreal * restrict _bound_omega,
    fpreal accel_rho,
    int iteration,
    int use_accel,
    int _bound_plastiter_length,
    global fpreal * restrict _bound_plastiter,
    fpreal epsilon
)
{
#ifdef SINGLE_WORKGROUP
#define SKIPWORKITEM continue
#ifdef SINGLE_WORKGROUP_SPANS
   for (int i = startcolor; i < startcolor + ncolors; ++i)
   {
#else
   for (int i = 0; i < ncolors; ++i)
   {
#endif
        int color_length = color_lengths[i];
        int color_offset = color_offsets[i];
        if (i > 0) barrier(CLK_GLOBAL_MEM_FENCE);
#ifdef SINGLE_WORKGROUP_ALWAYS
    color_offset -= get_global_size(0);
    color_length += get_global_size(0);
    while (1)
    {
        color_offset += get_global_size(0);
        color_length -= get_global_size(0);
        if (color_length <= 0) break;
#endif
#else
#define SKIPWORKITEM return
    {
#endif
    int idx = get_global_id(0);
    if (idx >= color_length) SKIPWORKITEM;
    idx += color_offset;
    
    fpreal mass = _bound_mass[idx];
    if (mass <= 0.0f) SKIPWORKITEM; // Skip pinned points
    
    fpreal3 P = vload3(idx, _bound_P);
    fpreal3 P_before_solve = P;
    fpreal3 inertia = vload3(idx, _bound_inertia);
    fpreal dtSqrReciprocal = 1.0f / (timeinc * timeinc);
    
    fpreal3 force = (fpreal3)(0.0f);
    mat3 hessian;
    mat3zero(hessian);
    
    // Include influence from inertia
    accumulateInertiaForceAndHessian(&force, hessian, mass, P, inertia, dtSqrReciprocal);
    
    // Include influence from spring constraints, for mass-spring energy
    accumulateMaterialForceAndHessian_MassSpring(&force, hessian, idx,
        _bound_pointprims, _bound_pointprims_index, _bound_primpoints, _bound_primpoints_index,
        _bound_P, _bound_stiffness, _bound_restlength);
    
    // The core of VBD is P += force * invert(hessian)
    // Sadly invert(hessian) is mega unstable, so we bandaid it below
    #ifdef USE_AVBD_SOLVE
        P += solve(force, hessian);
        vstore3(P, idx, _bound_P);
    #else
        if (dot(force, force) > (epsilon * epsilon))
        {
            fpreal3 descentDirection;
            int success = solve(force, hessian, &descentDirection, epsilon);
            if (success)
            {
                P += descentDirection;
                vstore3(P, idx, _bound_P);
            }
        }
    #endif
    
    // Accelerated convergence tends to explode, so it's disabled by default
    if (use_accel) 
    {
        fpreal omega = getAcceleratorOmega(iteration + 1, accel_rho, _bound_omega[idx]);
        _bound_omega[idx] = omega;

        fpreal3 plast = vload3(idx, _bound_plastiter);
        P = plast + (P - plast) * omega;
        vstore3(P, idx, _bound_P);

        vstore3(P_before_solve, idx, _bound_plastiter);
    }
#ifdef SINGLE_WORKGROUP
#ifdef SINGLE_WORKGROUP_ALWAYS
    }
#endif
#endif
    }
}