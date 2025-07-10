primitive type EntityID 32 end

EntityID(id::UInt32) = reinterpret(EntityID, id)
EntityID(id::Integer) = EntityID(convert(UInt32, id))

Base.broadcastable(id::EntityID) = Ref(id)

Base.Int64(entity::EntityID) = Int64(reinterpret(UInt32, entity))
Base.isless(a::EntityID, b::EntityID) = isless(Int64(a), Int64(b))
Base.:(+)(a::EntityID, b::Integer) = EntityID(Int64(a) + b)
Base.:(+)(a::Integer, b::EntityID) = b + a
Base.convert(::Type{Int64}, entity::EntityID) = Int64(entity)

primitive type ComponentID 32 end

ComponentID(id::UInt32) = reinterpret(ComponentID, id)
ComponentID(id::Integer) = ComponentID(convert(UInt32, id))

Base.broadcastable(id::ComponentID) = Ref(id)

mutable struct Counter
  val::UInt64
end
Counter() = Counter(0)
next!(counter::Counter) = (counter.val += 1)
reset!(counter::Counter) = (counter.val = 0)
Base.getindex(counter::Counter) = counter.val
Base.setindex!(counter::Counter, val) = setproperty!(counter, :val, val)

next_entity!(counter::Counter) = EntityID(next!(counter))
