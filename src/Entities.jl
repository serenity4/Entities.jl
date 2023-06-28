module Entities

using ForwardMethods
const EntityID = Int32

include("pool.jl")
include("storage.jl")
include("components.jl")
include("database.jl")

export EntityID, EntityPool, ComponentStorage, ECSDatabase, add_column!, components

end # module
