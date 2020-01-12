module SpecializeVarargs

export @specialize_vararg

using MacroTools: MacroTools, splitdef, combinedef, @capture

macro specialize_vararg(n::Int, fdef::Expr, fallback=false)
    @assert n > 0

    macros = Symbol[]
    while fdef.head == :macrocall && length(fdef.args) == 3
        push!(macros, fdef.args[1])
        fdef = fdef.args[3]
    end
    
    d = splitdef(fdef)
    args = d[:args][end]
    @assert d[:args][end] isa Expr && d[:args][end].head == Symbol("...") && d[:args][end].args[] isa Symbol  
    args_symbol = d[:args][end].args[]

    fdefs = Expr(:block)

    for i in 1:n-1
        di = deepcopy(d)
        pop!(di[:args])
        args = Tuple(gensym("arg$j") for j in 1:i)
        Ts   = Tuple(gensym("T$j")   for j in 1:i)

        args_with_Ts = ((arg, T) -> :($arg :: $T)).(args, Ts)
        
        di[:whereparams] = (di[:whereparams]..., Ts...)

        push!(di[:args], args_with_Ts...)
        pushfirst!(di[:body].args, :($args_symbol = $(Expr(:tuple, args...))))
        cfdef = combinedef(di)
        mcfdef = isempty(macros) ? cfdef : foldr((m,f) -> Expr(:macrocall, m, nothing, f), macros, init=cfdef)
        push!(fdefs.args, mcfdef)
    end

    di = deepcopy(d)
    pop!(di[:args])
    args = tuple((gensym() for j in 1:n)..., :($(gensym("args"))...))
    Ts   = Tuple(gensym("T$j")   for j in 1:n)

    args_with_Ts = (((arg, T) -> :($arg :: $T)).(args[1:end-1], Ts)..., args[end])
    
    di[:whereparams] = (di[:whereparams]..., Ts...)

    push!(di[:args], args_with_Ts...)
    if fallback != false
        @assert fallback isa Expr && fallback.head == :(=) && fallback.args[1] == :fallback
        pushfirst!(di[:body].args, fallback.args[2])
    end
    pushfirst!(di[:body].args, :($args_symbol = $(Expr(:tuple, args...))))

    cfdef = combinedef(di)
    mcfdef = isempty(macros) ? cfdef : foldr((m,f) -> Expr(:macrocall, m, nothing, f), macros, init=cfdef)
    push!(fdefs.args, mcfdef)

    esc(fdefs)
end

end # module
