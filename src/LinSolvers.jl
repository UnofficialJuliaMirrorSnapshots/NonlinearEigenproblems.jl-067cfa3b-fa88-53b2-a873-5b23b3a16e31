module LinSolvers
    using ..NEPCore
    using LinearAlgebra
    using SparseArrays
    using SuiteSparse
    using IterativeSolvers
    using LinearMaps
    using Arpack

    # Linear system of equation solvers
    export LinSolver
    export DefaultLinSolver
    export BackslashLinSolver
    export GMRESLinSolver
    export lin_solve

    export default_linsolvercreator
    export backslash_linsolvercreator
    export gmres_linsolvercreator

    # Eigenvalue solvers
    export EigSolver
    export DefaultEigSolver
    export NativeEigSolver
    export NativeEigSSolver
    export eig_solve

    import Base.eltype
    export eltype
    import Base.size
    export size
    import Base.*
    export *

##############################################################################
"""
    abstract type LinSolver

Structs inheriting from this type are able to solve linear systems associated with
a NEP, for a specific `λ`-value. The most common are direct solvers such as
[`DefaultLinSolver`](@ref), [`BackslashLinSolver`](@ref) and iterative solvers
such as [`GMRESLinSolver`](@ref).

The LinSolver objects are usually created by the NEP-algorithms through
creator functions, which are passed as parameters.

# Example

The most common usecase is that you want to pass a `linsolvercreator`-function
as a parameter to the NEP-algorithm.
This example shows how you can use solvers based on backslash or `factorize()`.
In the example, `BackslashLinSolver` does not exploit that the system matrix
remains the same throughout the algorithm and is therefore slower.
```julia-repl
julia> nep=nep_gallery("qdep0");
julia> using BenchmarkTools
julia> v0=ones(size(nep,1));
julia> @btime λ,v=quasinewton(nep,λ=-1,v=v0, linsolvercreator=default_linsolvercreator);
  199.540 ms (4929 allocations: 59.83 MiB)
julia> @btime λ,v=quasinewton(nep,λ=-1,v=v0, linsolvercreator=backslash_linsolvercreator);
  1.632 s (6137 allocations: 702.85 MiB)
```

# Example

The `LinSolver`s are constructed for extendability. This example creates our
own `LinSolver` which uses an explicit formula for the inverse
if the NEP has dimension 2x2.

Create the types and a creator.
```julia
julia> using LinearAlgebra
julia> struct MyLinSolver <: LinSolver
   M::Matrix{ComplexF64}
end
julia> function my_linsolvercreator(nep,λ)
   M=compute_Mder(nep,λ);
   return MyLinSolver(M);
end
```
Explicit import `lin_solve` to show how to solve a linear system.
```julia-repl
julia> import NonlinearEigenproblems.LinSolvers.lin_solve;
julia> function lin_solve(solver::MyLinSolver,b::AbstractVecOrMat;tol=0)
   M=solver.M;
   invM=(1/(det(M)))*[M[2,2] -M[1,2];-M[2,1] M[1,1]]
   return invM*b
end
julia> nep=SPMF_NEP([[1.0 3.0; 4.0 5.0], [2.0 1.0; -1 2.0]], [S->S^2,S->exp(S)])
julia> λ,v=quasinewton(nep,λ=-1,v=[1;1],linsolvercreator=my_linsolvercreator);
```

See also: [`lin_solve`](@ref),
[`DefaultLinSolver`](@ref), [`default_linsolvercreator`](@ref),
[`BackslashLinSolver`](@ref), [`backslash_linsolvercreator`](@ref),
[`GMRESLinSolver`](@ref), [`gmres_linsolvercreator`](@ref)

"""
    abstract type LinSolver end

##############################################################################
"""
    struct DefaultLinSolver <: LinSolver

This represents the linear solver associated with julia `factorize()`.
See [`LinSolver`](@ref) and [`default_linsolvercreator`](@ref) for examples.
"""
    struct DefaultLinSolver{T} <: LinSolver
        Afact::T
        umfpack_refinements::Int
    end

    function DefaultLinSolver(nep::NEP, λ, umfpack_refinements)
        A=compute_Mder(nep,λ)
        if isposdef(A)
            Afact=factorize(A)
        else
            Afact=lu(A)
        end
        Afact=lu(A)
        return DefaultLinSolver(Afact, umfpack_refinements)
    end

"""
    lin_solve(solver::LinSolver, b::AbstractVecOrMat; tol=0)

This function solves the linear system represented in `solver::LinSolver` with a
right-hand side `b`. The `tol` kwarg is controlling how accurate the linear
system needs to be solved. A NEP-algorithm will call this solver every
time a linear system associated with `M(λ)` needs to be solved.

This function must be overloaded if a user wants to define their own
way of solving linear systems. See [`LinSolver`](@ref) for examples.
"""
    function lin_solve(solver::DefaultLinSolver, x::Array; tol = 0)
        with_umfpack_refinements(solver.umfpack_refinements) do
            solver.Afact \ x
        end
    end

    function with_umfpack_refinements(f::Function, refinements)
        current_refinements = SuiteSparse.UMFPACK.umf_ctrl[8]
        try
            SuiteSparse.UMFPACK.umf_ctrl[8] = refinements
            f()
        finally
            SuiteSparse.UMFPACK.umf_ctrl[8] = current_refinements
        end
    end

"""
    default_linsolvercreator(nep::NEP, λ; umfpack_refinements = 2)

Create a linear solver of type `DefaultLinSolver` for the NEP evaluated in point `λ`.
For sparse matrices (the underlying solver is usually UMFPACK) the maximum number
of iterative refinements can be changed to trade accuracy for performance
with the parameter `umfpack_refinements`. UMFPACK defaults to a
maximum of 2 iterative refinements.

For examples see [`LinSolver`](@ref).

See also: [`DefaultLinSolver`](@ref).
"""
    function default_linsolvercreator(nep::NEP, λ; umfpack_refinements = 2)
        return DefaultLinSolver(nep, λ, umfpack_refinements)
    end


"""
    struct BackslashLinSolver <: LinSolver

This represents a linear solver corresponding to the backslash operator (no pre-factorization).

See also: [`LinSolver`](@ref) and [`backslash_linsolvercreator`](@ref)
"""
    struct BackslashLinSolver{T_mat} <: LinSolver
        A::T_mat
    end
#    BackslashLinSolver(A::AbstractMatrix{T_num}) where T_num = new(A)

    function BackslashLinSolver(nep::NEP,λ)
        A=compute_Mder(nep,λ)
        return BackslashLinSolver{typeof(A)}(A)
    end

    function lin_solve(solver::BackslashLinSolver{T_mat}, x::Array; tol=0) where T_mat
        return solver.A\x
    end

"""
    backslash_linsolvercreator(nep::NEP, λ)

Create a linear solver of type `BackslashLinSolver` evaluated in `λ`.

See also: [`LinSolver`](@ref), [`BackslashLinSolver`](@ref)
"""
    function backslash_linsolvercreator(nep::NEP, λ)
        return BackslashLinSolver(nep, λ)
    end


##############################################################################
"""
    struct GMRESLinSolver <: LinSolver

This represents a solver done with the julia GMRES implementation.

See also: [`LinSolver`](@ref), [`gmres_linsolvercreator`](@ref)
"""
    struct GMRESLinSolver{T_num<:Number, T_kwargs} <: LinSolver
        A::LinearMap{T_num}
        kwargs::T_kwargs

        function GMRESLinSolver{T_num}(nep, λ::T_num, kwargs::T_kwargs) where {T_num<:Number, T_kwargs}
            f = v -> compute_Mlincomb(nep,λ,v)
            A = LinearMap{T_num}(f, size(nep,1), ismutating=false)
            new{T_num, T_kwargs}(A, kwargs)
        end

    end


    function lin_solve(solver::GMRESLinSolver{T_num,T_kwargs}, b::Vector{T_num}; tol=eps(real(T_num))) where {T_num,T_kwargs}
        v = zero(x)
        gmres!(v, solver.A, x; tol=tol, solver.kwargs...)
        return v
    end


"""
    gmres_linsolvercreator(nep::NEP, λ, kwargs=())

Create a linear solver of type `GMRESLinSolver`. The `kwargs` are
passed as parameter to Julia-built-in-GMRES.

See also: [`LinSolver`](@ref), [`GMRESLinSolver`](@ref)

"""
    function gmres_linsolvercreator(nep::NEP, λ, kwargs=())
        return GMRESLinSolver{typeof(λ)}(nep, λ, kwargs)
    end



##############################################################################
"""
    abstract type EigSolver

Structs inheriting from this type are able to solve linear eigenvalue problems
arising in certain methods, such as, e.g., `mslp`, `sgiter`,
and `polyeig`.

The `EigSolver` objects are passed as types to the NEP-algorithms,
which uses it to dispatch the correct version of the function [`eig_solve`](@ref).

# Example

The most common usecase is that you do not want to specify anything in particular, since
the [`DefaultEigSolver`](@ref) will use a dense or a sparse method depending on you problem.
However, this example shows how you can force `mslp` to use the sparse solver.
```julia-repl
julia> nep=nep_gallery("qdep0");
julia> λ,v = mslp(nep, eigsolvertype=NativeEigSSolver);
julia> norm(compute_Mlincomb(nep,λ,v))
1.0324139764567768e-15
```

# Example

The `EigSolver`s are constructed for extendability. As an illustartion this example
creates a naive `EigSolver` which casts the problem to a standard linear eigenproblem
and calls the built-in function to solve it.

Create the types and a creator.
```julia-repl
julia> struct MyEigSolver <: EigSolver
   A
   E
   function MyEigSolver(A,E)
      return new(A,E)
   end
end

julia> import NonlinearEigenproblems.LinSolvers.eig_solve;
julia> function eig_solve(solver::MyEigSolver;nev = 1, target = 0)
   M = solver.E \\ solver.A
   eig = eigen(M)
   i = argmin(abs.(eig.values))
   return eig.values[i], eig.vectors[:,i]
end
julia> nep=nep_gallery("dep0", 50);
julia> λ,v = mslp(nep, eigsolvertype=MyEigSolver, tol=1e-5);
julia> norm(compute_Mlincomb(nep,λ,v))
3.0777795031319117e-10
```

See also: [`eig_solve`](@ref),
[`DefaultEigSolver`](@ref), [`NativeEigSolver`](@ref),
[`NativeEigSSolver`](@ref), [`eig_solve`](@ref)

"""
    abstract type EigSolver end


##############################################################################
"""
    struct NativeEigSolver <: EigSolver

A linear eigenvalueproblem solver that calls Julia's in-built eigen()

Constructed as `NativeEigSolver(A, [B,])`, and solves the problem
```math
Ax = λBx
```
The paramter `B` is optional an default is indentity, for which a standard linear
eigenproblem is solved.

See also: [`EigSolver`](@ref) and [`eig_solve`](@ref)
"""
    struct NativeEigSolver{T_A,T_B} <: EigSolver
        A::T_A
        B::T_B

        function NativeEigSolver(A)
            return new{typeof(A),Missing}(A,missing)
        end
        function NativeEigSolver(A,B)
            return new{typeof(A),typeof(B)}(A,B)
        end
    end



    function eig_solve(solver::NativeEigSolver; nev = 1, target = 0)
        D,V = inner_eig_solve(solver)

        #Sort the eigenvalues wrt distance from target, and permute
        I = sortperm(abs.(target*ones(size(D,1))-D));
        D = D[I];V = V[:,I];
        return D[1:nev],V[:,1:nev];
    end

    function inner_eig_solve(solver::NativeEigSolver{T_A,T_B}) where {T_A, T_B}
        D,V = eigen(solver.A,solver.B)
    end
    function inner_eig_solve(solver::NativeEigSolver{T_A,T_B}) where {T_A, T_B<:Missing}
        D,V = eigen(solver.A)
    end

"""
    struct NativeEigSSolver <: EigSolver

A linear eigenvalueproblem solver for large and sparse problems that calls
Julia's in-built eigs()

Constructed as `NativeEigSSolver(A, [B,])`, and solves the problem
```math
Ax = λBx
```
The paramter `B` is optional an default is indentity, for which a standard linear
eigenproblem is solved.

See also: [`EigSolver`](@ref) and [`eig_solve`](@ref)
"""
    struct NativeEigSSolver{T_A,T_B} <: EigSolver
        A::T_A
        B::T_B

        function NativeEigSSolver(A)
            return new{typeof(A),Missing}(A,missing)
        end
        function NativeEigSSolver(A,B)
            return new{typeof(A),typeof(B)}(A,B)
        end

    end


    function eig_solve(solver::NativeEigSSolver; nev=6, target=0)
        D,V = inner_eigs_solve(solver, nev, target)
        return D,V
    end

    function inner_eigs_solve(solver::NativeEigSSolver{T_A,T_B}, nev, target) where {T_A, T_B}
        # Julia's eigs(A,B) is currently broken for
        # indefinite B
        # https://github.com/JuliaLang/julia/issues/24668
        # This is what we want to do:
        # D,V = eigs(solver.A,solver.B;nev=nev,sigma=target)
        # We do a work-around by computing
        # largest eigenvalue of (target B -A)\B
        C=target*solver.B-solver.A;
        Cfact=factorize(C);
        Atransformed=LinearMap{eltype(Cfact)}(x->Cfact\(solver.B*x),
                               size(solver.A,1),size(solver.A,1));
        D0,V = eigs(Atransformed; nev=nev, which=:LM)
        # And reverse transformation
        D = target .- inv.(D0) # Reverse transformation
        return D,V
    end
    function inner_eigs_solve(solver::NativeEigSSolver{T_A,T_B}, nev, target) where {T_A, T_B<:Missing}
        D,V = eigs(solver.A; nev=nev, sigma=target)
    end




"""
    struct DefaultEigSolver <: EigSolver

A linear eigenvalueproblem solver that calls checks for sparsity and accordingly
assigns an appropriate solver.

See also: [`EigSolver`](@ref), [`eig_solve`](@ref), [`NativeEigSolver`](@ref), [`NativeEigSSolver`](@ref)
"""
    struct DefaultEigSolver{T_sub} <: EigSolver
        subsolver::T_sub

        function DefaultEigSolver(A,B)
            local subsolver
            if(issparse(A))
                subsolver = NativeEigSSolver(A,B)
            else
                subsolver = NativeEigSolver(A,B)
            end
            return new{typeof(subsolver)}(subsolver)
        end
        function DefaultEigSolver(A)
            local subsolver
            if(issparse(A))
                subsolver = NativeEigSSolver(A)
            else
                subsolver = NativeEigSolver(A)
            end
            return new{typeof(subsolver)}(subsolver)
        end
    end


"""
    eig_solve(solver::EigSolver; [nev,] [target,])

This function solves the linear eigenvalue problem represented in `solver::EigSolver`.
The `nev` kwarg is controlling the number of eigenvalues aimed for, and `target`
specifies around which point the eigenvalues are computed. The former has a defalut value
equalt to the seize of the problem, and the latter has a defalut value 0.

Return values are of the form (Vector, Matrix) where the former contains the eigenvalues
and the latter the eigenvectors.

This function must be overloaded if a user wants to define their own
way of solving linear eigenvalue problems. See [`EigSolver`](@ref) for examples.
"""
    function eig_solve(solver::DefaultEigSolver;nev=size(solver.subsolver.A,1),target=0)
        return eig_solve(solver.subsolver,nev=nev,target=target)
    end

end
