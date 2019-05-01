module Encapsulation

export @encapsulate, @get, @set

using Rematch
macro encapsulate(expr)
    (@__MODULE__).encapsulate(expr)
end

expr_fieldname(x::Symbol) = x
expr_fieldname(x::Expr) = x.args[1]

function encapsulate(expr::Expr)
    @assert expr.head == :struct
    mutable = expr.args[1]
    type = expr.args[2]
    esctype = esc(type)
    structbody = expr.args[end]
    privates = []
    for (i,a) in enumerate(structbody.args)
        structbody.args[i] = @match a begin
            Expr(:macrocall, [Symbol("@private"), line, field]) => begin
                push!(privates, expr_fieldname(field))
                field
            end
            _ => a
        end
    end
    privateerrors = [:(if s == $(QuoteNode(v)); error($("$v is a private field of $type")); end) for v in privates]
    secretcode = QuoteNode(gensym("accesskey"))
    quote
        $(esc(expr))
        # These functions are @inline to allow the compiler to eliminate the secretcode
        # test. Since the modulename is a constant, the test will compile away.
        @inline function Base.getproperty(t::$esctype, s::Symbol; secretcode=nothing)
            # This test will compile away so this should be free.
            if secretcode != @__MODULE__
                $(privateerrors...)
            end
            Base.getfield(t, s)
        end

        # As above, @inline to allow secretcode check to compile away.
        @inline function $(@__MODULE__).getproperty_encapsulated(t::$esctype, s::Symbol, m::Module)
            Base.getproperty(t, s; secretcode=m)
        end

        $(if mutable
            quote
                @inline function Base.setproperty!(t::$esctype, s::Symbol, v; secretcode=nothing)
                    # This test will compile away so this should be free.
                    if secretcode != @__MODULE__
                        $(privateerrors...)
                    end
                    Base.setfield!(t, s, v)
                end

                # As above, @inline to allow secretcode check to compile away.
                @inline function $(@__MODULE__).setproperty!_encapsulated(t::$esctype, s::Symbol, v, m::Module)
                    Base.setproperty!(t, s, v; secretcode=m)
                end
            end
        end)
    end
end

# Base function defined in Encapsulation module
function getproperty_encapsulated(t, s, _)
    Base.getproperty(t, s)
end
function setproperty!_encapsulated(t, s, v, _)
    Base.setproperty!(t, s, v)
end

# TODO: Move the check into the macro to make the compiler's job easier!
# Make getproperty raise an error and call getfield here instead w/ correct Module.
# COULD require using `@get()` all the time to save performance?
macro get(expr)
    @assert expr.head == :.
    t = esc(expr.args[1])
    s = esc(expr.args[2])
    :(
        $(@__MODULE__).getproperty_encapsulated($t, $s, $__module__)
    )
end
macro set(expr)
    @assert expr.head == :(=)
    @assert expr.args[1].head == :(.)
    t = esc(expr.args[1].args[1])
    s = esc(expr.args[1].args[2])
    v = esc(expr.args[2])
    :(
        $(@__MODULE__).setproperty!_encapsulated($t, $s, $v, $__module__)
    )
end

end
