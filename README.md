# SpecializeVarargs.jl

SpecializeVarargs.jl does one thing: force to julia to create and specialize on a given number of varadic arguments. This is likely only useful to people doing very complicated codegen in high performance situations.

```julia
julia> @macroexpand @specialize_vararg 3 f(x, my_varargs...) = length(my_varargs)
quote
    function f(x, var"##arg1#617"::var"##T1#618"; ) where var"##T1#618"
        my_varargs = (var"##arg1#617",)
        #= REPL[17]:1 =#
        length(my_varargs)
    end
    function f(x, var"##arg1#619"::var"##T1#621", var"##arg2#620"::var"##T2#622"; ) where {var"##T1#621", var"##T2#622"}
        my_varargs = (var"##arg1#619", var"##arg2#620")
        #= REPL[17]:1 =#
        length(my_varargs)
    end
    function f(x, var"##624"::var"##T1#627", var"##625"::var"##T2#628", var"##626"::var"##T3#629", var"##args#623"...; ) where {var"##T1#627", var"##T2#628", var"##T3#629"}
        my_varargs = (var"##624", var"##625", var"##626", var"##args#623"...)
        #= REPL[17]:1 =#
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
