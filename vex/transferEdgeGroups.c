int broken[] = expandedgegroup(1, "broken");
for (int i = 0; i < len(broken); i += 2) {
    int pt0 = point(1, "coloredidx", broken[i]);
    int pt1 = point(1, "coloredidx", broken[i+1]);
    if (pt0 < 0 || pt1 < 0) continue;
    setedgegroup(0, "broken", pt0, pt1, 1);
}