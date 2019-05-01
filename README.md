# Encapsulation.jl

Early experiments around adding access modifiers to julia structs.

## Example
Mark `X.x` as a private field, so it can only be accessed inside this module.
```julia
@encapsulate struct X
    @private x::Int
    y::Int
end
```

Accesses must use the `@get` and `@set` macros, and will only succeed from inside the module that defined the struct.
```julia
    @get(xm.x)
```
