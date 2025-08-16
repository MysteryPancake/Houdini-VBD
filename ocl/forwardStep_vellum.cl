#bind parm gravity fpreal3 val={0, -9.81, 0}

#bind point &P fpreal3
#bind point &v fpreal3
#bind point &pprevious fpreal3
#bind point &?plast fpreal3
#bind point &vprevious fpreal3
#bind point &?vlast fpreal3
#bind point &inertia fpreal3
#bind point mass fpreal val=1
#bind point stopped int val=0

@KERNEL
{
    if (@mass <= 0 || @stopped) return; // Skip pinned points
    
#ifdef HAS_plast
    @plast.set(@pprevious);
#endif
    // Vellum sets @vprevious here rather than in updateVelocity()
    @pprevious.set(@P);

#ifdef HAS_vlast
    @vlast.set(@vprevious);
#endif
    @vprevious.set(@v);
    
#if use_gravity
    // Gravity gets added directly to the velocity
    // This is the same as adding it to the inertia as @gravity * @TimeInc * @TimeInc
    @v.set(@v + @gravity * @TimeInc);
#endif

#if defined(HAS_plast) && defined(HAS_vlast)
    // Second order integration
    const fpreal3 v = (4 * @vprevious - @vlast + 2 * (@v - @vprevious)) / 3;
    @inertia.set((4 * @pprevious - @plast + 2 * @TimeInc * v) / 3);
#else
    // First order integration
    @inertia.set(@P + @v * @TimeInc);
#endif
    
    @P.set(@inertia);
}