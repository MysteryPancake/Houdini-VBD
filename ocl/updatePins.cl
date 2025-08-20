#bind point &P fpreal3
#bind point gluetoanimation int
#bind point id int
#bind point animP name=P geo=Animated fpreal3

@KERNEL
{
    if (!@gluetoanimation) return;

    // Graph Color sorts the points, so the order of the animated points mismatches
    // @id stores the index before sorting, use it to map back to the correct point
    // This must be done after graph coloring since @id relies on it
    @P.set(@animP.getAt(@id));
}