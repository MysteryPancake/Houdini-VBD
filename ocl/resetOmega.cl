#bind point &omega fpreal val=1

// For accelerated convergence, tends to explode so it's disabled by default
@KERNEL
{
    @omega.set(1);
}