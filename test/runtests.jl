using Test, SpecializeVarargs

@specialize_vararg 3 function goo(x::T, args...) where T
    +(args...)
end

@test goo(1,2,3,4,5) == 14


@specialize_vararg 4 @inline function f(x::T, args...) where T
    typeof(args)
end

@test f(1,2,3.0,4) == Tuple{Int64,Float64,Int64}
@test length(methods(f))   == 4
@test length(methods(goo)) == 3



@specialize_vararg 4 @inline(function h(args...) where T
    *(args...)
end) fallback = return false

@test h(1,2,3.0)          == 6.0
@test length(methods(f))  == 4
@test h(1,2,3,4,5)        == false


@specialize_vararg 3 function g(args::T...) where {T<:Int}
    *(args...)
end
@test g(1,2)         == 2
@test g(1,2,3,4,5,6) == 720
