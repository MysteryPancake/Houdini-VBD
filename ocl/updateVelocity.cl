#bind point &v fpreal3 val=0
#bind point &vprevious fpreal3 val=0
#bind point P fpreal3
#bind point pprevious fpreal3
#bind point mass fpreal val=1

@KERNEL
{
    if (@mass <= 0) return; // Skip pinned points
    
    // Vellum sets @vprevious at the start of each substep, but VBD sets it here
    // This is not a typo, it's used for an acceleration estimate during adaptive warmstarting
    @vprevious.set(@v);
    
    // First order velocity, same as Vellum
    @v.set((@P - @pprevious) / @TimeInc);
}