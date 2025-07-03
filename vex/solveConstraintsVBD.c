// VEX used for debugging the OpenCL version (ocl/solveConstraintsVBD.cl)
// Slow and outdated now (rewrite of TinyVBD), but easier to read

if (f@mass <= 0) return;

vector previterpos = v@P;

float dtSqrReciprocal = 1.0 / (f@TimeInc * f@TimeInc);

3@h = f@mass * dtSqrReciprocal * ident();
v@f = f@mass * (v@inertia - v@P) * dtSqrReciprocal;

int constraints[] = pointprims(1, i@ptnum);
foreach (int con; constraints) {
    int pts[] = primpoints(1, con);
    
    int v1 = pts[0];
    int v2 = pts[1];
    vector p1 = point(0, "P", v1);
    vector p2 = point(0, "P", v2);
    vector diff = p1 - p2;
    float l = length(diff);
    float l0 = prim(1, "restlength", con);
    
    // evaluate hessian
    float stiffness = prim(1, "stiffness", con);
    3@h += stiffness * (ident() - (l0 / l) * (ident() - outerproduct(diff, diff) / (l * l)));
    v@f += (stiffness * (l0 - l) / l) * diff * (v1 == i@ptnum ? 1 : -1);
}

// invert() can produce crazy results
if (abs(determinant(3@h)) > chf("min_energy")) {
    v@P += v@f * invert(3@h);
}

if (!chi("use_accelerator")) return;

float getAcceleratorOmega(int order; float pho; float prevOmega) {
    if (order == 1) {
        return 1.0;
    } else if (order == 2) {
        return 2.0 / (2.0 - (pho * pho));
    } else {
        return 4.0 / (4.0 - (pho * pho) * prevOmega);
    }
}

int iter = detail(-2, "iteration", 0);
f@omega = getAcceleratorOmega(iter + 1, chf("acceleration_rho"), f@omega);

// Apply accelerator, tends to be unstable so disabled by default
if (f@omega > 1.0) v@P = f@omega * (v@P - v@plast) + v@plast;

v@plast = previterpos;