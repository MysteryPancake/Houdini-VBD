#bind parm order int val=0

#bind point &v fpreal3 val=0
#bind point P fpreal3
#bind point pprevious fpreal3
#bind point plast fpreal3
#bind point mass fpreal val=1

@KERNEL
{
    if (@mass <= 0) return; // Skip pinned points
    
    if (@order == 0) // First order (from XPBD)
    {
        @v.set((@P - @pprevious) / @TimeInc);
    }
    else // Second order (Vellum style)
    {
        @v.set(((2 * @P + (@P + @plast)) - 4 * @pprevious) / (2 * @TimeInc));
    }
}