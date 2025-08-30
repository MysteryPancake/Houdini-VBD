// From Vellum, if geometry was added or removed we need to recolor
#include "pbd_constraints.h"

// Compare the current constraint topology to the topolgy when we last colored
int curtopo[] = detail(0, "coloredtopology");
int newtopo[] = calcConstraintTopology(0, 1);

// Need to graph-color if the constraint topology has changed (or if we've never colored in the first place)
if (!hasdetailattrib(0, "sizes_vbd") ||
    !hasdetailattrib(0, "offsets_vbd") ||
    !compareIntArrays(curtopo, newtopo)) {
   adddetailattrib(geoself(), "needscoloring", 1);
}