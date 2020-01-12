# SpecializeVarargs.jl

SpecializeVarargs.jl does one thing: force to julia to create and specialize on a given number of varadic arguments. This is likely only useful to people doing very complicated codegen in high performance situations.

```julia
julia> using SpecializeVarargs

julia> @macroexpand @specialize_vararg 3 f(x, my_varargs...) = length(my_varargs)
quote
    function f(x, var"##arg1#457"::var"##T1#458"; ) where var"##T1#458"
        my_varargs = (Symbol("##arg1#457"),)
        #= REPL[32]:1 =#
        length(my_varargs)
    end
    function f(x, var"##arg1#459"::var"##T1#461", var"##arg2#460"::var"##T2#462"; ) where {var"##T1#461", var"##T2#462"}
        my_varargs = (Symbol("##arg1#459"), Symbol("##arg2#460"))
        #= REPL[32]:1 =#
        length(my_varargs)
    end
    function f(x, var"##464"::var"##T1#467", var"##465"::var"##T2#468", var"##466"::var"##T3#469", var"##args#463"...; ) where {var"##T1#467", var"##T2#468", var"##T3#469"}
        my_varargs = (var"##464", var"##465", var"##466", var"##args#463"...)
        #= REPL[32]:1 =#
        length(my_varargs)
    end
end
```
SpecializeVarargs can handle functions defined with macros in front of them as well, and will forward those macros to the created methods:
```julia
julia> @macroexpand1 @specialize_vararg 3 @foo @bar function f(x::T, args...) where T
           typeof(args)
       end
quote
    @foo @bar(function f(x::T, var"##arg1#519"::var"##T1#520"; ) where {T, var"##T1#520"}
                args = (var"##arg1#519",)
                #= REPL[5]:2 =#
                typeof(args)
            end)
    @foo @bar(function f(x::T, var"##arg1#521"::var"##T1#523", var"##arg2#522"::var"##T2#524"; ) where {T, var"##T1#523", var"##T2#524"}
                args = (var"##arg1#521", var"##arg2#522")
                #= REPL[5]:2 =#
                typeof(args)
            end)
    @foo @bar(function f(x::T, var"##526"::var"##T1#529", var"##527"::var"##T2#530", var"##528"::var"##T3#531", var"##args#525"...; ) where {T, var"##T1#529", var"##T2#530", var"##T3#531"}
                args = (var"##526", var"##527", var"##528", var"##args#525"...)
                #= REPL[5]:2 =#
                typeof(args)
            end)
end
```
