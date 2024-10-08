"""
Contiguous storage of components keyed by entity.

Components may be used directly by systems without having to
refer to individual entities, to avoid cache-unfriendly indirections caused by lookups.

!!! note
    Component sharing among multiple entities is not yet supported. When a component is inserted for
    a new entity, and this component has been previously inserted for a different entity that is still
    present, then the component will be stored at another memory location. Component sharing can be
    achieved at the moment using a mutable component type, though performance will be severely degraded
    as mutable components will not be stored inline in memory (it is the pointers to such components which
    will be stored contiguously).
"""
struct ComponentStorage{T}
  components::Vector{T}
  indices::Dict{EntityID, UInt32} # entity -> index
  entities::Dict{UInt32, EntityID} # index -> entity
end

@forward_interface ComponentStorage{T} field = :components interface = [indexing, iteration] omit = [getindex, eltype]
@forward_methods ComponentStorage field = :components Base.iterate(_, args...) Base.getindex(_, i::Integer)

Base.eltype(::Type{ComponentStorage{T}}) where {T} = T
@forward_methods ComponentStorage field = typeof(_) Base.eltype

ComponentStorage{T}() where {T} = ComponentStorage(T[], Dict{EntityID, UInt32}(), Dict{UInt32, EntityID}())

function Base.getindex(storage::ComponentStorage, entity::EntityID)
  i = storage.indices[entity]
  iszero(i) && throw(KeyError(entity))
  storage[i]
end
Base.haskey(storage::ComponentStorage, i::Integer) = in(i, eachindex(storage.components))
Base.haskey(storage::ComponentStorage, entity::EntityID) = !iszero(get(storage.indices, entity, UInt32(0)))
Base.get(storage::ComponentStorage, key, default) = haskey(storage, key) ? storage[key] : default

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
  storage.indices[entity] = 0
  n = lastindex(storage.components)
  if index == n
    pop!(storage.components)
  else
    # Swap `index` and `n`, then delete `n`.
    storage.components[index] = pop!(storage.components)
    storage.entities[index] = storage.entities[n]
    storage.indices[storage.entities[n]] = index
  end
  haskey(storage.entities, n) && delete!(storage.entities, n)
  storage
end
