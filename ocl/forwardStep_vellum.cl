#bind parm gravity fpreal3 val={0, -9.81, 0}
#bind parm order int

#bind point &P fpreal3
#bind point &v fpreal3
#bind point &pprevious fpreal3
#bind point &plast fpreal3
#bind point &vprevious fpreal3
#bind point &vlast fpreal3
#bind point &inertia fpreal3
#bind point mass fpreal val=1
#bind point &omega fpreal val=1

@KERNEL
{
    if (@mass <= 0) return; // Skip pinned points
    
    // Vellum sets @vprevious here rather than in updateVelocity()
    @plast.set(@pprevious);
    @pprevious.set(@P);
    
    @vlast.set(@vprevious);
    @vprevious.set(@v);
    
    @v.set(@v + @gravity * @TimeInc);
    
    if (@order == 0) // First order integration
    {
        @inertia.set(@P + @v * @TimeInc);
    }
    else // Second order integration
    {
        fpreal3 v = (4 * @vprevious - @vlast + 2 * (@v - @vprevious)) / 3;
        @inertia.set((4 * @pprevious - @plast + 2 * @TimeInc * v) / 3);
    }
    
    @P.set(@inertia);
    
    // Used only when accelerated convergence is enabled
    @omega.set(1);
}