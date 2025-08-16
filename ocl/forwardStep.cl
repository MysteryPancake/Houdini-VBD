#bind parm gravity fpreal3 val={0, -9.80665, 0}
#bind parm initialization int val=0

#bind point &P fpreal3
#bind point &v fpreal3
#bind point &inertia fpreal3
#bind point &pprevious fpreal3
#bind point vprevious fpreal3
#bind point mass fpreal val=1
#bind point stopped int val=0

@KERNEL
{
    if (@mass <= 0 || @stopped) return; // Skip pinned points
    
    @pprevious.set(@P);
    
#if use_gravity
    // Gravity gets added directly to the velocity
    // This is the same as adding it to the inertia as @gravity * @TimeInc * @TimeInc
    @v.set(@v + @gravity * @TimeInc);
#endif

    // First order integration, same as Vellum
    const fpreal3 inertia = @P + @v * @TimeInc;
    @inertia.set(inertia);
    
#if initialization == 0
    // Inertia
    @P.set(@P + @vprevious * @TimeInc);
#elif initialization == 1
    // Inertia and acceleration
    @P.set(inertia);
#elif initialization == 2
    // Adaptive
    if (@SimFrame <= 2)
    {
        // We don't have @vprevious, use inertia and acceleration
        @P.set(inertia);
    }
    else
    {
        const fpreal3 accel = (@v - @vprevious) / @TimeInc;
        const fpreal gravNorm = length(@gravity);
        const fpreal3 gravDir = @gravity / gravNorm;
        const fpreal accelWeight = clamp(dot(accel, gravDir) / gravNorm, 0.0f, 1.0f);
        @P.set(@P + @vprevious * @TimeInc + @gravity * accelWeight * @TimeInc * @TimeInc);
    }
#endif
}