primitive type EntityID 32 end

EntityID(id::UInt32) = reinterpret(EntityID, id)
EntityID(id::Integer) = EntityID(convert(UInt32, id))

primitive type ComponentID 32 end

ComponentID(id::UInt32) = reinterpret(ComponentID, id)
ComponentID(id::Integer) = ComponentID(convert(UInt32, id))

mutable struct Counter
  val::Int
end
Counter() = Counter(0)
next!(counter::Counter) = (counter.val += 1)
reset!(counter::Counter) = (counter.val = 0)
Base.getindex(counter::Counter) = counter.val

next_component!(counter::Counter) = ComponentID(next!(counter))
next_entity!(counter::Counter) = EntityID(next!(counter))
