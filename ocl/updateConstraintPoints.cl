#bind point P fpreal3
#bind point &conP name=P geo=ConstraintGeometry fpreal3

@KERNEL
{
    @conP.set(@P);
}