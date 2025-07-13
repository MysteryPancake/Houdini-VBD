#bind parm gravity fpreal3 val={0, -9.80665, 0}
#bind parm initialization int val=0

#bind point &P fpreal3
#bind point &v fpreal3
#bind point &inertia fpreal3
#bind point &pprevious fpreal3
#bind point &omega fpreal val=1
#bind point vprevious fpreal3
#bind point mass fpreal val=1

@KERNEL
{
    if (@mass <= 0) return; // Skip pinned points
    
    @pprevious.set(@P);
    
    // First order integration, same as Vellum
    fpreal3 inertia = @P + @v * @TimeInc;
    @inertia.set(inertia + @gravity * @TimeInc * @TimeInc);
    
    switch (@initialization)
    {
        case 0: // Previous position
        {
            break;
        }
        case 1: // Inertia
        {
            @P.set(inertia);
            break;
        }
        case 2: // Inertia and acceleration
        default:
        {
            @P.set(inertia + @gravity * @TimeInc * @TimeInc);
            break;
        }
        case 3: // Adaptive warmstart
        {
            fpreal3 accel = (@v - @vprevious) / @TimeInc;
            fpreal gravNorm = length(@gravity);
            fpreal accelWeight = clamp(dot(accel, @gravity / gravNorm) / gravNorm, 0.0f, 1.0f);
            @P.set(inertia + @gravity * accelWeight * @TimeInc * @TimeInc);
            break;
        }
    }
    
    // Used only when accelerated convergence is enabled
    @omega.set(1);
}