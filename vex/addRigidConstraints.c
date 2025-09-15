int rigids[] = expandpointgroup(1, "__constraintsrc");

foreach (int rigid; rigids) {
    vector pos = point(1, "P", rigid);
    int idx = point(1, "__idxorig", rigid);
    string name = point(1, "name", rigid);
    
    int rigid_pt = -1;
    if (idx < 0) {
        // Rigids which were newly packed
        rigid_pt = addpoint(0, pos);
        setpointattrib(0, "__idxorig", rigid_pt, idx);
    } else {
        // Rigids which were already packed
        rigid_pt = findattribval(0, "point", "__idxorig", idx);
    }
    
    if (chi("keep_connections")) {
        int connections[] = point(1, "__connections", rigid);
        foreach (int pt; connections) {
            int match = findattribval(0, "point", "__idxorig", pt);
            if (match < 0 || match == rigid_pt) continue;
            setpointattrib(0, "name", match, name);
        }
    }
    
    setpointgroup(0, "__constraintsrc", rigid_pt, 1);
    setpointattrib(0, "name", rigid_pt, name);
}