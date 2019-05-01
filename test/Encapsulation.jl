using Test

include("../src/Encapsulation.jl")


module TestModule

import ..Encapsulation: @encapsulate, @get, @set

@encapsulate struct X
    @private x::Int
    y::Int
end

struct X2
    x::Int
    y::Int
end

@encapsulate mutable struct XM
    @private x::Int
    y::Int
end

# X(1,3).x  # Error: x is a private field of X
@get X(1,3).x
X(1,3).y

@get(XM(2,3).x)

@set XM(3,3).x = 5
x = XM(1,3)
@set(x.x = 5)
# @set(X(2,3).x = 5)  # Error: type X is immutable

x

end


@testset "Optimizes away" begin
    @eval TestModule read(xm::XM) = @get(xm.x)
    @eval TestModule read(x2::X2) = @get(x2.x)

    TestModule.read(TestModule.XM(2,3))
    code_native(TestModule.read, (TestModule.XM,))  # These are equal, not sure how to test.
    code_native(TestModule.read, (TestModule.X2,))  # These are equal, not sure how to test.
end


module M
import ..Encapsulation: @encapsulate, @get, @set
import ..TestModule: X, XM
# X(1,3).x  # Error: x is a private field of X
# @get X(1,3).x  # Error: x is a private field of X
X(1,3).y

# @set(XM(2,3).x = 5)  # Error: x is a private field of XM
# @set(X(2,3).x = 5)  # Error: x is a private field of X
XM(1,3).y = 2
end
