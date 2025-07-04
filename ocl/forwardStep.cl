#bind parm gravity fpreal3 val={0, -9.81, 0}
#bind parm order int val=0
#bind parm initialization int val=0

#bind point &P fpreal3
#bind point &v fpreal3 val=0
#bind point &inertia fpreal3 val=0
#bind point &pprevious fpreal3
#bind point &plast fpreal3
#bind point &plastiter fpreal3
#bind point &omega fpreal val=1
#bind point &vprevious fpreal3 val=0
#bind point &vlast fpreal3 val=0
#bind point mass fpreal val=1

@KERNEL
{
    if (@mass <= 0) return; // Skip pinned points
    
    @plast.set(@pprevious);
    @pprevious.set(@P);
    
    @vlast.set(@vprevious);
    @vprevious.set(@v);
    
    @v.set(@v + @gravity * @TimeInc);
    
    fpreal3 accel;
    if (@order == 0) // First-order (from VBD)
    {
        @inertia.set(@P + @v * @TimeInc);
        accel = (@v - @vprevious) / @TimeInc;
    }
    else // Second-order (Vellum style)
    {
        fpreal3 v = (4 * @vprevious - @vlast + 2 * (@v - @vprevious)) / 3;
        @inertia.set((4 * @pprevious - @plast + 2 * @TimeInc * v) / 3);
        accel = ((2 * @v + (@v + @vlast)) - 4 * @vprevious) / (2 * @TimeInc);
    }

    switch (@initialization)
    {
        case 0: // Previous position
        {
            break;
        }
        case 1: // Inertia
        {
            @P.set(@inertia);
            break;
        }
        case 2: // Inertia and acceleration
        default:
        {
            @P.set(@inertia + accel * @TimeInc * @TimeInc);
            break;
        }
        case 3: // Adaptive, based on https://github.com/AnkaChan/TinyVBD/blob/main/main.cpp#L333
        {
            fpreal3 gravDir = normalize(@gravity);
            fpreal accelComponent = min(length(@gravity), dot(accel, gravDir));
            @P.set(@inertia + accelComponent * gravDir * @TimeInc * @TimeInc);
            break;
        }
    }
        
    @plastiter.set(@P);
    
    // Used only when accelerated convergence is enabled
    @omega.set(1);
}