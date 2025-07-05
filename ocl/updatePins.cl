#bind point &P fpreal3
#bind point gluetoanimation int
#bind point coloredidx int
#bind point animP name=P geo=Animated fpreal3

@KERNEL
{
    if (@gluetoanimation)
    {
        @P.set(@animP.getAt(@coloredidx));
        return;
    }
}