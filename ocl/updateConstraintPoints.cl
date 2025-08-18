#bind point P fpreal3
#bind point coloredidx int geo=ConstraintGeometry
#bind point &Pcom fpreal3 name=P geo=ConstraintGeometry

@KERNEL
{
    // Skip non-matching points
    if (@coloredidx < 0) return;

    @Pcon.set(@P.getAt(@coloredidx));
}