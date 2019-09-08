push!(LOAD_PATH, string(@__DIR__, "/.."))
using Documenter;
using NonlinearEigenproblems

makedocs(
    clean = true,
    doctest = false,
    sitename = "NEP-PACK",
    pages = Any[
        "Introduction" => "index.md",
        "Manual" => [
        "methods.md",
            "types.md",
        "compute_functions.md",
        "linsolvers.md",
        "innersolvers.md",
        "errmeasure.md",
        "logger.md",
        "transformations.md",
        "deflation.md",
            "gallery.md"],
        "Tutorials" => [
        "Tutorial 1 (ABC)" => "movebc_tutorial.md",
        "Tutorial 2 (Contour)" => "tutorial_contour.md",
        "Tutorial 3 (BEM)" => "bemtutorial.md",
        "Tutorial 4 (Deflation)" => "deflate_tutorial.md",
        "Tutorial 5 (Python)" => "tutorial_call_python.md",
        "Tutorial 6 (MATLAB)" => "tutorial_matlab1.md",
        "Tutorial 7 (FORTRAN)" => "tutorial_fortran1.md",
        "Tutorial 8 (gmsh + nanophotonics)" => "tutorial_nano1.md",
        "Tutorial 9 (New solver)" => "tutorial_newmethod.md",
        "Tutorial 10 (Linear solvers)" => "tutorial_linsolve.md",
            "Tutorial 11 (Orr--Somerfeld)" => "hydrotutorial.md"
            ]
    ]
)


#deploydocs(
#    repo = "github.com/nep-pack/NonlinearEigenproblems.jl.git",
#    target = "build",
#)
