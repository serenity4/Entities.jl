mutable struct EntityPool # not thread-safe
  counter::EntityID
  const free::Vector{EntityID}
end

EntityPool() = EntityPool(EntityID(0), EntityID[])

function new!(pool::EntityPool)
  !isempty(pool.free) && return pop!(pool.free)
  pool.counter += EntityID(1)
end

function Base.delete!(pool::EntityPool, id::EntityID)
  push!(pool.free, id)
  pool
end

function Base.empty!(pool::EntityPool)
  empty!(pool.free)
  pool.counter = 0
  pool
end
