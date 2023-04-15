module Entities

const EntityID = Int32

include("pool.jl")
include("data.jl")

export EntityID, EntityPool, ComponentStorage

end # module
