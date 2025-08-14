#bind parm gravity fpreal3 val={0, -9.80665, 0}
#bind parm initialization int val=0

#bind point &P fpreal3
#bind point &v fpreal3
#bind point &inertia fpreal3
#bind point &pprevious fpreal3
#bind point &?omega fpreal val=1
#bind point vprevious fpreal3
#bind point mass fpreal val=1

@KERNEL
{
    if (@mass <= 0) return; // Skip pinned points
    
    @pprevious.set(@P);
    
    // First order integration, same as Vellum
    @v.set(@v + @gravity * @TimeInc);
    const fpreal3 inertia = @P + @v * @TimeInc;
    @inertia.set(inertia);
    
    switch (@initialization)
    {
        case 0: // Inertia
        {
            @P.set(@P + @vprevious * @TimeInc);
            break;
        }
        case 1: // Inertia and acceleration
        default:
        {
            @P.set(inertia);
            break;
        }
        case 2: // Adaptive warmstart, this has bizarre issues with gravity reduction depending on mass
        {
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
            break;
        }
    }

#ifdef HAS_omega
    // Used for accelerated convergence, tends to explode so it's disabled by default
    @omega.set(1);
#endif
}