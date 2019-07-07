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



(NOTE: `@get` and `@set` have to be implemented as macros in order to get access to the calling module. 😢)

---------

## Ideas to explore

We could also support a "friending" notion, where you can also share access with other modules that you expect to be able to access it. Maybe supporting something like some of these options:
```julia
    @private x::Int                      # only accessible from @__MODULE__
    @private(..SisterModule, y::Int)     # accessible from @__MODULE__ and SisterModule
    @private(:(AnotherPkg.SubMod) z::Int   # accessible from @__MODULE__ and AnotherPkg.SubMod, even if AnotherPkg isn't loaded yet
```
