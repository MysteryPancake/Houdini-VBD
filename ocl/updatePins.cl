#bind point &P fpreal3
#bind point gluetoanimation int
#bind point coloredidx int
#bind point animP name=P geo=Animated fpreal3

@KERNEL
{
    if (@gluetoanimation)
    {
        // Graph Color sorts the points, so the order of the animated points mismatches
        // @coloredidx stores the index before sorting, use it to map back to the correct point
        @P.set(@animP.getAt(@coloredidx));
        return;
    }
}