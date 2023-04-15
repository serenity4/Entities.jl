"""
Contiguous storage of components keyed by entity.

Components may be used directly by systems without having to
refer to individual entities.
"""
struct ComponentStorage{T}
  components::Vector{T}
  indices::Dict{EntityID, UInt32} # entity -> index
  entities::Dict{UInt32, EntityID} # index -> entity
end

Base.length(storage::ComponentStorage) = length(storage.components)
Base.iterate(storage::ComponentStorage, args...) = iterate(storage.components, args...)

ComponentStorage{T}() where {T} = ComponentStorage(T[], Dict{EntityID, UInt32}(), Dict{UInt32, EntityID}())

Base.getindex(storage::ComponentStorage, entity::EntityID) = storage.components[storage.indices[entity]]

Base.haskey(storage::ComponentStorage, entity::EntityID) = !iszero(get(storage.indices, entity, UInt32(0)))

Base.insert!(storage::ComponentStorage{T}, entity::EntityID, data) where {T} = insert!(storage, entity, convert(T, data)::T)
function Base.insert!(storage::ComponentStorage{T}, entity::EntityID, data::T) where {T}
  haskey(storage, entity) && error("Entity $entity already has a component assigned")
  storage[entity] = data
end

Base.setindex!(storage::ComponentStorage{T}, data, entity::EntityID) where {T} = setindex!(storage, convert(T, data)::T, entity)
function Base.setindex!(storage::ComponentStorage{T}, data::T, entity::EntityID) where {T}
  index = get(storage.indices, entity, UInt32(0))

  if !iszero(index)
    # Update existing component.
    storage.components[index] = data
    return storage
  end

  # Allocate new component.
  index = length(storage.components) + 1
  storage.indices[entity] = index
  storage.entities[index] = entity
  push!(storage.components, data)
  storage
end

function Base.delete!(storage::ComponentStorage, entity::EntityID)
  index = get(storage.indices, entity, UInt32(0))
  # Don't do anything if the entity does not have a component.
  iszero(index) && return storage
  delete!(storage.indices, entity)
  n = lastindex(storage.components)
  if index == n
    pop!(storage.components)
  else
    # Swap `index` and `n`, then delete `n`.
    storage.components[index] = pop!(storage.components)
    storage.entities[index] = storage.entities[n]
  end
  haskey(storage.entities, n) && delete!(storage.entities, n)
  storage
end
