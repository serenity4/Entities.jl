struct EntityPool # not thread-safe
  counter::Counter
  free::Vector{EntityID}
  limit::UInt32
end

EntityPool(; limit = typemax(UInt32)) = EntityPool(Counter(), EntityID[], limit)

function new!(pool::EntityPool)
  !isempty(pool.free) && return pop!(pool.free)
  pool.counter[] < pool.limit || error("Pool limit reached")
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
