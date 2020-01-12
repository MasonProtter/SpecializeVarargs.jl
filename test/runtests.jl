using Test, SpecializeVarargs

@specialize_vararg 3 function goo(x::T, args...) where T
    +(args...)
end

@test goo(1,2,3,4,5) == 14


@specialize_vararg 4 @inline function f(x::T, args...) where T
    typeof(args)
end

@test f(1,2,3.0,4) == Tuple{Int64,Float64,Int64}
@test length(methods(f))   == 5
@test length(methods(goo)) == 4
