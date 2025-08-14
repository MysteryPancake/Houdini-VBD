#define AVBD_SPRING -1715226869

#bind parm alpha fpreal
#bind parm gamma fpreal
#bind parm PENALTY_MIN fpreal
#bind parm PENALTY_MAX fpreal

#bind prim &lambda fpreal geo=ConstraintGeometry
#bind prim &penalty fpreal geo=ConstraintGeometry
#bind prim stiffness fpreal geo=ConstraintGeometry
#bind prim type_hash int geo=ConstraintGeometry

// Dual update from AVBD
// From https://github.com/savant117/avbd-demo2d/blob/main/source/solver.cpp#L105
@KERNEL
{
    // Skip non AVBD constraints
    if (@type_hash != AVBD_SPRING) return;
    
    // Warmstart the dual variables and penalty parameters (Eq. 19)
    // Penalty is safely clamped to a minimum and maximum value
    @lambda.set(@lambda * @alpha * @gamma);
    
    // If it's not a hard constraint, we don't let the penalty exceed the material stiffness
    const fpreal penalty = clamp(@penalty * @gamma, @PENALTY_MIN, @PENALTY_MAX);
    @penalty.set(min(penalty, @stiffness));
}