module Entities

using ForwardMethods

include("identifiers.jl")
include("pool.jl")
include("storage.jl")
include("database.jl")

export EntityID, EntityPool, ComponentID, ComponentStorage, ECSDatabase, add_column!, components

end # module
