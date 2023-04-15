# Contiguous storage of components keyed by entity.
# Components may be used directly by systems without having to
# refer to individual entities.
struct ComponentEntry{T}
  components::Vector{T}
  indices::Dict{EntityID, UInt32} # entity -> index
  entities::Dict{UInt32, EntityID} # index -> entity
end

Base.length(entry::ComponentEntry) = length(entry.components)
Base.iterate(entry::ComponentEntry, args...) = iterate(entry.components, args...)

ComponentEntry{T}() where {T} = ComponentEntry(T[], Dict{EntityID, UInt32}(), Dict{UInt32, EntityID}())

Base.getindex(entry::ComponentEntry, entity::EntityID) = entry.components[entry.indices[entity]]

Base.haskey(entry::ComponentEntry, entity::EntityID) = !iszero(get(entry.indices, entity, UInt32(0)))

Base.insert!(entry::ComponentEntry{T}, entity::EntityID, data) where {T} = insert!(entry, entity, convert(T, data)::T)
function Base.insert!(entry::ComponentEntry{T}, entity::EntityID, data::T) where {T}
  haskey(entry, entity) && error("Entity $entity already has a component assigned")
  entry[entity] = data
end

Base.setindex!(entry::ComponentEntry{T}, data, entity::EntityID) where {T} = setindex!(entry, convert(T, data)::T, entity)
function Base.setindex!(entry::ComponentEntry{T}, data::T, entity::EntityID) where {T}
  index = get(entry.indices, entity, UInt32(0))

  if !iszero(index)
    # Update existing component.
    entry.components[index] = data
    return entry
  end

  # Allocate new component.
  index = length(entry.components) + 1
  entry.indices[entity] = index
  entry.entities[index] = entity
  push!(entry.components, data)
  entry
end

function Base.delete!(entry::ComponentEntry, entity::EntityID)
  index = get(entry.indices, entity, UInt32(0))
  # Don't do anything if the entity does not have a component.
  iszero(index) && return entry
  delete!(entry.indices, entity)
  n = lastindex(entry.components)
  if index == n
    pop!(entry.components)
  else
    # Swap `index` and `n`, then delete `n`.
    entry.components[index] = pop!(entry.components)
    entry.entities[index] = entry.entities[n]
  end
  haskey(entry.entities, n) && delete!(entry.entities, n)
  entry
end
