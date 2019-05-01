# NEP-PACK

[![Build Status](https://img.shields.io/travis/nep-pack/NonlinearEigenproblems.jl.svg)](https://travis-ci.org/nep-pack/NonlinearEigenproblems.jl)
[![codecov](https://img.shields.io/codecov/c/github/nep-pack/NonlinearEigenproblems.jl.svg?label=codecov)](https://codecov.io/gh/nep-pack/NonlinearEigenproblems.jl)

A nonlinear eigenvalue problem is the problem to determine a scalar *λ* and a vector *v* such that
*<p align="center">M(λ)v=0</p>*
where *M* is an *nxn*-matrix depending on a parameter. This package aims to provide state-of-the-art algorithms to solve this problem, as well as a framework to formulate applications and easy access to benchmark problems. This currently includes (but is not restricted to) Newton-type methods, Subspace methods, Krylov methods, contour integral methods, block methods, companion matrix approaches. Problem transformation techniques such as scaling, shifting, deflating are also natively supported by the package.  


# How to use it?

On Julia 1.X and Julia 0.7, install it as a registered package by typing `] add ...` at the REPL-prompt:
```
julia> ]
(v1.0) pkg> add NonlinearEigenproblems
```

After that, check out "Getting started" in

<p align="center"><a href="https://nep-pack.github.io/NonlinearEigenproblems.jl">NEP-PACK online user's guide</a></p>

or read the preprint: https://arxiv.org/abs/1811.09592

## GIT Version

If you want the cutting edge development version and not the latest release, install it with the URL:
```
julia> ]
(v1.0) pkg> add git://github.com/nep-pack/NonlinearEigenproblems.jl.git
```
## NEP solvers

These solvers are currently available (see https://nep-pack.github.io/NonlinearEigenproblems.jl/methods/):

* Newton & Rayleigh type:
    * Classical Newton-Raphson
    * Augmented Newton
    * Residual inverse iteration
    * Quasi-Newton
    * Block Newton
    * Rayleigh functional iteration (RFI a, b)
    * Newton-QR
    * Implicit determinant method
    * Broyden's method 
* Arnoldi/Krylov type
    * NLEIGS
    * Infinite Arnoldi method (IAR, TIAR, Infinite bi-Lanczos, Infinite Lanczos)
* Projection methods
    * Jacobi-Davidson (two versions)
    * Nonlinear Arnoldi method
* Contour integral 
    * Beyn's contour integral method
    * Higher momement contour integral method (a.k.a the Asakura&Sakurai method)
* Deflation
    * Effenberger style deflation
    

# Development

The main work of NEP-PACK has been done in a closed repository at KTH, but as of May 2018 the development is carried out in a public github repo.

Core developers (alphabetical): Max Bennedich, Elias Jarlebring (www.math.kth.se/~eliasj), Giampaolo Mele (www.math.kth.se/~gmele), Emil Ringh (www.math.kth.se/~eringh), Parikshit Upadhyaya (https://www.kth.se/profile/pup/). Thanks to A Koskela for involvement in initial version of the software.

# How to cite

If you find this software useful please cite

```bibtex
@Misc{,
  author = 	 {E. Jarlebring and M. Bennedich and G. Mele and E. Ringh and P. Upadhyaya},
  title = 	 {{NEP-PACK}: A {Julia} package for nonlinear eigenproblems},
  year = 	 {2018},
  note = 	 {https://github.com/nep-pack},
  eprint = {arXiv:1811.09592},
}
```
If you use a specific method, please also give credit to the algorithm researcher.
Reference to a corresponding algorithm paper can be found by in, e.g., by writing `?resinv`.

Some links below are developer info on KTH. We will migrate them soon:


* NEP-page style "guide": https://github.com/nep-pack/NonlinearEigenproblems.jl/wiki/Style-guidelines-and-notes

* GIT-workflow: https://github.com/nep-pack/NonlinearEigenproblems.jl/wiki/Git-workflow

* GIT-usage @ KTH: https://gitr.sys.kth.se/nep-pack/nep-pack-alpha/wiki

* NEP-methods @ KTH: https://gitr.sys.kth.se/nep-pack/nep-pack-alpha/wiki/NEP-methods

* NEP-applications @ KTH: https://gitr.sys.kth.se/nep-pack/nep-pack-alpha/wiki/Applications
