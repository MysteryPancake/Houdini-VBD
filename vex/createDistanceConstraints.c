#include "pbd_constraints.h"

// To fix extra distance constraints being created incorrectly
void createDistanceConstraintFixed(const int geo; const int ptnum; const string edgegrp; const int outgeo; const string outgrp) {
    int nbrs[] = neighbours(geo, ptnum);
    foreach(int n; nbrs) {
        if (n <= ptnum || !inedgegroup(geo, edgegrp, ptnum, n)) continue;
        int prim = addprim(outgeo, "polyline", ptnum, n);
        setprimgroup(outgeo, outgrp, prim, 1);
        setprimattrib(outgeo, "restlength", prim, computeDistanceRestLength(geo, ptnum, n));
    }
}

if (nedgesgroup(1, "__constraintsrcorig") > 0) {
    // Correct behaviour for prim and edge groups
    createDistanceConstraintFixed(1, @ptnum, "__constraintsrcorig", geoself(), "__stretchconstraints");
} else {
    createDistanceConstraint(1, @ptnum, "__constraintsrc", geoself(), "__stretchconstraints");
}