[![Build Status](https://travis-ci.com/MasonProtter/SpecializeVarargs.jl.svg?branch=master)](https://travis-ci.com/MasonProtter/SpecializeVarargs.jl)

# SpecializeVarargs.jl

SpecializeVarargs.jl does one thing: force to julia to create and specialize on a given number of varadic arguments. This is likely only useful to people doing very complicated codegen in high performance situations, e.g. in Cassette overdub methods like those used in [ForwardDiff2.jl](https://github.com/YingboMa/ForwardDiff2.jl). 

```julia
julia> using SpecializeVarargs

julia> @macroexpand @specialize_vararg 3 f(x, my_varargs...) = length(my_varargs)
quote
    function f(x, var"##arg1#402"::var"##T1#403"; ) where var"##T1#403"
        my_varargs = (var"##arg1#402",)
        length(my_varargs)
    end
    function f(x, var"##arg1#404"::var"##T1#406", var"##arg2#405"::var"##T2#407"; ) where {var"##T1#406", var"##T2#407"}
        my_varargs = (var"##arg1#404", var"##arg2#405")
        length(my_varargs)
    end
    function f(x, var"##arg1#409"::var"##T1#412", var"##arg2#410"::var"##T2#413", var"##arg3#411"::var"##T3#414", var"##args#408"...; ) where {var"##T1#412", var"##T2#413", var"##T3#414"}
        my_varargs = (var"##arg1#409", var"##arg2#410", var"##arg3#411", var"##args#408"...)
        length(my_varargs)
    end
end

```
### Nested macros
SpecializeVarargs can handle functions defined with macros in front of them as well (e.g. `@inbounds`), and will forward those macros to the created methods:
```julia
julia> @macroexpand1 @specialize_vararg 3 @foo @bar function f(x::T, args...) where T
           typeof(args)
       end
quote
    @foo @bar(function f(x::T, var"##arg1#415"::var"##T1#416"; ) where {T, var"##T1#416"}
                args = (var"##arg1#415",)
                #= REPL[3]:2 =#
                typeof(args)
            end)
    @foo @bar(function f(x::T, var"##arg1#417"::var"##T1#419", var"##arg2#418"::var"##T2#420"; ) where {T, var"##T1#419", var"##T2#420"}
                args = (var"##arg1#417", var"##arg2#418")
                typeof(args)
            end)
    @foo @bar(function f(x::T, var"##arg1#422"::var"##T1#425", var"##arg2#423"::var"##T2#426", var"##arg3#424"::var"##T3#427", var"##args#421"...; ) where {T, var"##T1#425", var"##T2#426", var"##T3#427"}
                args = (var"##arg1#422", var"##arg2#423", var"##arg3#424", var"##args#421"...)
                typeof(args)
            end)
end
```
### Fallback code
You can specify fallback code which is only run in the case where splatting occurs. You do this by including code like `fallback = ...` after the function definition
```julia
julia> @macroexpand1 @specialize_vararg 2 function h(args...)
           *(args...)
       end fallback = return false
quote
    function h(var"##arg1#428"::var"##T1#429"; ) where var"##T1#429"
        args = (var"##arg1#428",)
        (*)(args...)
    end
    function h(var"##arg1#431"::var"##T1#433", var"##arg2#432"::var"##T2#434", var"##args#430"...; ) where {var"##T1#433", var"##T2#434"}
        args = (var"##arg1#431", var"##arg2#432", var"##args#430"...)
        return false
        (*)(args...)
    end
end
```
Notice that in the second method above, the function will just immediately exit and return `false`. 

### Vararg type constraints
The `@specialize_vararg` macro also supports adding type constraints to the varargs:
```julia
julia> @macroexpand1 @specialize_vararg 3 function g(args::T...) where {T<:Int}
           *(args...)
       end
quote
    function g(var"##arg1#435"::var"##T1#436"; ) where {T <: Int, var"##T1#436" <: T}
        args = (var"##arg1#435",)
        (*)(args...)
    end
    function g(var"##arg1#437"::var"##T1#439", var"##arg2#438"::var"##T2#440"; ) where {T <: Int, var"##T1#439" <: T, var"##T2#440" <: T}
        args = (var"##arg1#437", var"##arg2#438")
        (*)(args...)
    end
    function g(var"##arg1#442"::var"##T1#445", var"##arg2#443"::var"##T2#446", var"##arg3#444"::var"##T3#447", var"##args#441"::T...; ) where {T <: Int, var"##T1#445" <: T, var"##T2#446" <: T, var"##T3#447" <: T}
        args = (var"##arg1#442", var"##arg2#443", var"##arg3#444", var"##args#441"...)
        (*)(args...)
    end
end
```
