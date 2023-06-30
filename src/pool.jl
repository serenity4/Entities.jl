struct EntityPool # not thread-safe
  counter::Counter
  free::Vector{EntityID}
end

EntityPool() = EntityPool(Counter(), EntityID[])

function new!(pool::EntityPool)
  !isempty(pool.free) && return pop!(pool.free)
  next_entity!(pool.counter)
end

function Base.delete!(pool::EntityPool, id::EntityID)
  push!(pool.free, id)
  pool
end

function Base.empty!(pool::EntityPool)
  empty!(pool.free)
  reset!(pool.counter)
  pool
end
