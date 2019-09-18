###########################################################
# Polynomial eigenvalue problem - PEP
#

"""
    struct PEP <: AbstractSPMF
    function PEP(AA::Vector{AbstractMatrix})

The type `PEP` defines a polynomial eigenvalue
 problem via its monomial coefficients.
A polynomial eigenvalue problem (PEP) is defined by the sum the
```math
Σ_i A_i λ^i,
```
where ``i = 0,1,2,``, and  all of the matrices are of size ``n×n``.
The vector `AA` contains ``A_1,...``.

# Example

```julia-repl
julia> A0=[1.0 3; 4 5]; A1=A0.+one(2); A2=ones(2,2);
julia> pep=PEP([A0,A1,A2])
julia> compute_Mder(pep,3)-(A0+A1*3+A2*9)
2×2 Array{Float64,2}:
 0.0  0.0
 0.0  0.0
```

See also [`polyeig`](methods.md#NonlinearEigenproblems.NEPSolver.polyeig), [`companion`](methods.md#NonlinearEigenproblems.NEPSolver.companion), [`ChebPEP`](@ref), [`interpolate`](@ref).
"""
struct PEP <: AbstractSPMF{AbstractMatrix}
    n::Int
    A::Array   # Monomial coefficients of PEP
end


function PEP(AA::Array)
    n=size(AA[1],1)
    AA=reshape(AA,size(AA,1))
    return PEP(n,AA)
end

# Computes the sum ``Σ_i M_i V f_i(S)`` for a PEP
function compute_MM(nep::PEP,S,V)
    T=promote_type(promote_type(eltype(nep.A[1]),eltype(S)),eltype(V))
    local Z
    if (issparse(nep))
        Z=spzeros(T,size(V,1),size(V,2))
        Si=sparse(one(T)*I, size(S,1), size(S,1))
    else
        Z=zeros(T,size(V,1),size(V,2))
        Si=Matrix(one(T)*I, size(S,1), size(S,1))
    end
    for i=1:size(nep.A,1)
        Z+=nep.A[i]*V*Si;
        Si=Si*S;
    end
    return Z
end




# Compute the ith derivative of a PEP
function compute_Mder(nep::PEP,λ::Number,i::Integer=0)
    if (issparse(nep))
        Z=spzeros(eltype(nep.A[1]),size(nep,1),size(nep,1));
    else
        Z=zeros(eltype(nep.A[1]),size(nep,1),size(nep,1));
    end
    for j=(i+1):size(nep.A,1)
        # Derivatives of monimials
        Z+= nep.A[j]*(λ^(j-i-1)*factorial(j-1)/factorial(j-i-1))
    end
    return Z
end

#  Fetch the Av's, since they are not explicitly stored in PEPs
function get_Av(nep::PEP)
    return nep.A;
end
#  Fetch the Fv's, since they are not explicitly stored in PEPs
function get_fv(nep::PEP)
    fv=Vector{Function}(undef, size(nep.A,1))
    # Construct monomial functions
    for i=1:size(nep.A,1)
        if (i==1); # optimization for constant and linear term
            fv[1] = S -> one(S);
        elseif (i==2);
            fv[2]=S->S;
        else
            # we need to introuce j otherwise the function is not typestable
            j=i-1; # power of the coefficient
            fv[i]=S->S^j;
        end
    end
    return fv;
end


"""
    interpolate([T=ComplexF64,] nep::NEP, intpoints::Array)

Interpolates a NEP in the points `intpoints` and returns a [`PEP`](@ref), i.e., a polynomial eigenvalue problem in a monomial basis. See [`ChebPEP`](@ref) for Chebyshev interpolation. The optional argument `T` is the type in which the matrices of the PEP should be defined.

See also [`ChebPEP`](@ref).
"""
interpolate(nep::NEP, intpoints::Array) = interpolate(ComplexF64, nep, intpoints)
function interpolate(::Type{T}, nep::NEP, intpoints::Array) where {T<:Number}

    n = size(nep, 1)
    d = length(intpoints)

    V = zeros(T,d,d) #Vandermonde matrix
    pwr = ones(d,1)
    for i = 1:d
        V[:,i] = pwr
        pwr = pwr.*intpoints
    end

    if (issparse(nep)) #If Sparse, do elementwise interpolation
        b = Vector{SparseMatrixCSC{T}}(undef, d)
        AA = Vector{SparseMatrixCSC{T}}(undef, d)
        V = factorize(V) # Will be used multiple times, factorize

        for i=1:d
            b[i] = compute_Mder(nep, intpoints[i])
        end

        # OBS: The following lines and hence the following method assumes that Sparsity-structure is the same!
        nnz_AA = nnz(b[1])
        for i=1:d
            AA[i] = copy(b[1])
        end

        f = zeros(d,1)
        for i = 1:nnz_AA
            for j = 1:d
                f[j] = b[j].nzval[i]
            end
            a = \(V,f)
            for j = 1:d
                AA[j].nzval[i] = a[j]
            end
        end

    else # If dense, use Vandermonde
        b = zeros(T,n*d,n)
        AA = Vector{Matrix{T}}(undef,d)
        (L, U, p) = lu(V)

        LL = kron(L, SparseMatrixCSC(I,(n,n)))
        UU = kron(U, SparseMatrixCSC(I,(n,n)))

        for i = 1:d
            b[(1:n).+(i-1)*n,:] =  compute_Mder(nep,intpoints[p[i]])
        end

        A = \(UU, \(LL,b))

        for i = 1:d
            AA[i] = A[(1:n).+(i-1)*n,:]
        end
    end

    return PEP(AA)
end


include("types_cheb_pep.jl");
