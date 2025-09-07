// The new Otis solver in Houdini 21 also uses VBD
// It includes some new hessian approximations I want to try out
i@has_otis = __vex_major >= 21;