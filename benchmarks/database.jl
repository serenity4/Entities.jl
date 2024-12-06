using Entities
using Entities: new!
using BenchmarkTools: @btime

pool = EntityPool()
ecs = ECSDatabase(component_names = Dict())
c1 = ComponentID(1)
ecs.component_names[c1] = :floating_point_value
storage = ComponentStorage{Float64}()
ecs[c1] = storage
entity1 = new!(pool)
insert!(ecs, entity1, c1, 1.0)

@btime $ecs[$entity1, $c1] # should be slightly slower than the next benchmark
@btime $ecs[$entity1, $c1, Float64]
@btime $ecs[$entity1, $c1] = 2.0
