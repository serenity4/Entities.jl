primitive type ComponentID 32 end

ComponentID(id::UInt32) = reinterpret(ComponentID, id)
ComponentID(id::Integer) = ComponentID(convert(UInt32, id))

mutable struct Counter
  val::Int
end
Counter() = Counter(0)
next!(counter::Counter) = (counter.val += 1)
next_component!(counter::Counter) = ComponentID(next!(counter))
