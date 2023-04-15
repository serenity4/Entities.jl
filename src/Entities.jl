module Entities

const EntityID = Int32

include("pool.jl")
include("storage.jl")

export EntityID, EntityPool, ComponentStorage

end # module
