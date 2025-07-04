#bind point &v fpreal3 val=0
#bind point &vprevious fpreal3 val=0
#bind point P fpreal3
#bind point pprevious fpreal3
#bind point mass fpreal val=1

@KERNEL
{
    if (@mass <= 0) return; // Skip pinned points
    
    @vprevious.set(@v);
    
    @v.set((@P - @pprevious) / @TimeInc);
}