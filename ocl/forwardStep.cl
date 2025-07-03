#bind parm gravity fpreal3 val={0, -9.81, 0}
#bind parm order int val=0

#bind point &P fpreal3
#bind point &v fpreal3 val=0
#bind point &accel fpreal3 val=0
#bind point &inertia fpreal3 val=0
#bind point &pprevious fpreal3
#bind point &plast fpreal3
#bind point &plastiter fpreal3
#bind point &omega fpreal val=1

#bind point vprevious fpreal3 val=0
#bind point vlast fpreal3 val=0
#bind point mass fpreal val=1

#define USE_INERTIA

@KERNEL
{
    if (@mass <= 0.0) return; // Skip pinned points
    
    @plast.set(@pprevious);
    @pprevious.set(@P);
    
    @v.set(@v + @gravity * @TimeInc);
    
    if (@order == 0) // First-order (from VBD)
    {
        @inertia.set(@P + @v * @TimeInc);
    }
    else // Second-order (from Vellum)
    {
        fpreal3 v = (4 * @vprevious - @vlast + 2 * (@v - @vprevious)) / 3;
        @inertia.set((4 * @pprevious - @plast + 2 * @TimeInc * v) / 3);
    }
    
    @accel.set((@v - @vprevious) / @TimeInc);

    #ifdef USE_INERTIA
        // Should give better results for 2nd order integration
        @P.set(@inertia);
    #else
        // From https://github.com/AnkaChan/TinyVBD/blob/main/main.cpp#L333
        fpreal3 gravDir = normalize(@gravity);
        fpreal accelComponent = min(length(@gravity) + 1, dot(@accel, gravDir));
        if (accelComponent < 1e-5) accelComponent = 0.0;
        @P.set(@P + @vprevious * @TimeInc + accelComponent * gravDir * @TimeInc * @TimeInc);
    #endif
        
    @plastiter.set(@P);
    
    // Used only when accelerated convergence is enabled
    @omega.set(1);
}