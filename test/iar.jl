using NonlinearEigenproblemsTest
using NonlinearEigenproblems
using Test
using IterativeSolvers
using LinearAlgebra

# The user can create his own orthogonalization function to use in IAR
function doubleGS_function!(VV, vv, h)
    h[:]=VV'*vv; vv[:]=vv-VV*h; g=VV'*vv; vv[:]=vv-VV*g;
    h[:] = h[:]+g[:]; β=norm(vv); vv[:]=vv/β; return β
end
# Then it is needed to create a type to access to this function
abstract type DoubleGS <: IterativeSolvers.OrthogonalizationMethod end
# And then introduce a function dispatch for this new type in order to use
# the defined orthogonalization function
import IterativeSolvers.orthogonalize_and_normalize!
function orthogonalize_and_normalize!(V,v,h,::Type{DoubleGS})
    doubleGS_function!(V, v, h) end

@testset "IAR" begin
    dep=nep_gallery("dep0");
    n=size(dep,1);

    @bench @testset "accuracy eigenpairs" begin
        (λ,Q)=iar(dep,σ=3,Neig=5,v=ones(n),
                  displaylevel=0,maxit=100,tol=eps()*100,errmeasure=ResidualErrmeasure);
        verify_lambdas(5, dep, λ, Q, eps()*100)
    end

    @testset "Compute as many eigenpairs as possible (Neig=Inf)" begin
        (λ,Q)=iar(dep,σ=3,Neig=Inf,v=ones(n),
                  displaylevel=0,maxit=38,tol=eps()*100);
        verify_lambdas(3, dep, λ, Q, eps()*100)
    end

    @testset "orthogonalization" begin
        # NOW TEST DIFFERENT ORTHOGONALIZATION METHODS

        @bench @testset "DGKS" begin
            (λ,Q,err,V)=iar(dep,orthmethod=DGKS,σ=3,Neig=5,v=ones(n),displaylevel=0,maxit=100,tol=eps()*100)
            @test opnorm(V'*V - I) < 1e-6
        end

        @bench @testset "User provided doubleGS" begin
            (λ,Q,err,V)=iar(dep,orthmethod=DoubleGS,σ=3,Neig=5,v=ones(n),displaylevel=0,maxit=100,tol=eps()*100)
            @test opnorm(V'*V - I) < 1e-6
        end

        @bench @testset "ModifiedGramSchmidt" begin
            (λ,Q,err,V)=iar(dep,orthmethod=ModifiedGramSchmidt,σ=3,Neig=5,v=ones(n),displaylevel=0,maxit=100,tol=eps()*100)
            @test opnorm(V'*V - I) < 1e-6
        end

        @bench @testset "ClassicalGramSchmidt" begin
            (λ,Q,err,V)=iar(dep,orthmethod=ClassicalGramSchmidt,σ=3,Neig=5,v=ones(n),displaylevel=0,maxit=100,tol=eps()*100)
            @test opnorm(V'*V - I) < 1e-6
        end
    end

    @testset "Errors thrown" begin
        np=100;
        dep=nep_gallery("dep0",np);
        @test_throws NEPCore.NoConvergenceException (λ,Q)=iar(dep,σ=3,Neig=6,v=ones(np),
                  displaylevel=0,maxit=7,tol=eps()*100);
    end

end
