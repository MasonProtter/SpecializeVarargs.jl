[![Build Status](https://travis-ci.com/MasonProtter/SpecializeVarargs.jl.svg?branch=master)](https://travis-ci.com/MasonProtter/SpecializeVarargs.jl)

# SpecializeVarargs.jl

SpecializeVarargs.jl does one thing: force to julia to create and specialize on a given number of varadic arguments. This is likely only useful to people doing very complicated codegen in high performance situations, e.g. in Cassette overdub methods like those used in [ForwardDiff2.jl](https://github.com/YingboMa/ForwardDiff2.jl). 

Here's a [Cassette.jl](https://github.com/jrevels/Cassette.jl) example where SpecializeVarargs.jl can give a performance boost:
```julia
using SpecializeVarargs
using Cassette

Cassette.@context TraceCtx

mutable struct Trace
    current::Vector{Any}
    stack::Vector{Any}
    Trace() = new(Any[], Any[])
end

@specialize_vararg 5 function enter!(t::Trace, args...)
    pair = args => Any[]
    push!(t.current, pair)
    push!(t.stack, t.current)
    t.current = pair.second
    return nothing
end

function exit!(t::Trace)
    t.current = pop!(t.stack)
    return nothing
end

Cassette.prehook(ctx::TraceCtx, args...) = enter!(ctx.metadata, args...)
Cassette.posthook(ctx::TraceCtx, args...) = exit!(ctx.metadata)

trace = Trace()
x, y, z = rand(3)
f(x, y, z) = x*y + y*z

julia> @btime Cassette.overdub(TraceCtx(metadata = trace), () -> f(x, y, z))
  3.315 μs (41 allocations: 1.48 KiB)
0.2360528466104866
```
Now let's redefine the `enter!` function using SpecializeVarargs:
```julia
julia> @specialize_vararg 5 function enter!(t::Trace, args...)
           pair = args => Any[]
           push!(t.current, pair)
           push!(t.stack, t.current)
           t.current = pair.second
           return nothing
       end
enter! (generic function with 6 methods)

julia> @btime Cassette.overdub(TraceCtx(metadata = trace), () -> f(x, y, z))
  1.540 μs (27 allocations: 1.17 KiB)
0.2360528466104866
```
Nice!

### What is the macro doing?
<details>
 <summaryClick me! ></summary>
<p>

The macro `@specialize_vararg`, called like `@specialize_vararg N fdef` where `N` is an integer literal and `fdef` is a varadic function definition, will create literal methods for the function defined in `fdef` for up to `N` arguments before falling back on a traditional vararg definition. We can exapand the macro to see what exaclt it's doing:
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
</p>
</details>
### Nested macros
<details>
 <summaryClick me! ></summary>
<p>
SpecializeVarargs can handle functions defined with macros in front of them as well (e.g. `@inbounds`), and will forward those macros to the created methods:
```julia
julia> @macroexpand1 @specialize_vararg 3 @foo @bar function f(x::T, args...) where T
           typeof(args)
       end
quote
    @foo @bar(function f(x::T, var"##arg1#415"::var"##T1#416"; ) where {T, var"##T1#416"}
                args = (var"##arg1#415",)
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
</p>
</details>
### Fallback code
<details>
 <summaryClick me! ></summary>
<p>
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
</p>
</details>
### Vararg type constraints
<details>
 <summaryClick me! ></summary>
<p>
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
</p>
</details>
