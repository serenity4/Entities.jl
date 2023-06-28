module Entities

using ForwardMethods
const EntityID = Int32

include("pool.jl")
include("storage.jl")
include("components.jl")
include("database.jl")

export EntityID, EntityPool, ComponentID, ComponentStorage, ECSDatabase, add_column!, components

end # module
