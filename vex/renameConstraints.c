if (find({"distance", "bend", "bendtwist", "stitch", "branchstitch", "stretchshear"}, s@type) >= 0) {
    s@type = "vbd_massspring";
} else if (startswith(s@type, "tet")) {
    s@type = "vbd_neohookean";
    // Vellum doesn't have bend attributes for tetrahedrons, reuse the stretch attributes
    setprimattrib(0, "bendstiffness", i@primnum, f@stiffness);
    setprimattrib(0, "benddampingratio", i@primnum, f@dampingratio);
} else if (s@type == "shapematch") {
    // Use infinitely stiff AVBD springs for now
    s@type = "avbd_spring";
    f@stiffness = 1e50; // Rounds to infinity
}