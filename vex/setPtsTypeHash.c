#include <pbd_constraints.h>

i[]@pts = primpoints(0, i@primnum);

// Map to correct @coloredidx on Geometry
for (int i = 0; i < len(i[]@pts); ++i) {
    int id = point(0, "id", i[]@pts[i]);
    if (id < 0) id = i[]@pts[i];
    int match = idtopoint(1, id);
    // Don't use prims with missing children
    if (match < 0) {
        i[]@pts = {};
        return;
    }
    i[]@pts[i] = match;
}

i@type_hash = constraintHash(s@type);