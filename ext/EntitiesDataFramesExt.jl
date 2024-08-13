module EntitiesDataFramesExt

using Entities
import DataFrames: DataFrame

function DataFrame(ecs::ECSDatabase)
  entities = Set{EntityID}()
  columns = Pair{ComponentID, Dict{EntityID,Any}}[]
  for (component_id, storage) in sort!(collect(pairs(ecs.components)); by = x -> reinterpret(UInt32, first(x)))
    data = Dict{EntityID,Any}()
    push!(columns, component_id => data)
    for entity in collect(values(storage.entities))
      push!(entities, entity)
      data[entity] = storage[entity]
    end
  end
  entities = collect(entities)
  df_columns = Pair{Symbol, <:Vector}[]
  for (component_id, data) in columns
    name = isnothing(ecs.component_names) ? Symbol(component_id) : get(ecs.component_names, component_id, Symbol(component_id))
    T = eltype(ecs.components[component_id])
    push!(df_columns, name => Union{T, Missing}[get(data, entity, missing) for entity in entities])
  end
  !isnothing(ecs.entity_names) && pushfirst!(df_columns, :Name => Union{Symbol, Missing}[get(ecs.entity_names, entity, missing) for entity in entities])
  perm = sortperm(entities, by = x -> reinterpret(UInt32, x))
  DataFrame([name => data[perm] for (name, data) in df_columns])
end

end # module
