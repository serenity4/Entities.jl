module EntitiesDataFramesExt

using Entities
using Entities: remap_type_for_dataframe_display, remap_value_for_dataframe_display
import DataFrames: DataFrame

function DataFrame(ecs::ECSDatabase; remap = false)
  entities = Set{EntityID}()
  columns = Pair{ComponentID, Dict{EntityID,<:Any}}[]
  for (component_id, storage) in sort!(collect(pairs(ecs.components)); by = x -> reinterpret(UInt32, first(x)))
    T = eltype(ecs.components[component_id])
    CT = remap || T === EntityID ? remap_type_for_dataframe_display(T) : Union{Missing, T}
    data = Dict{EntityID,CT}()
    push!(columns, component_id => data)
    for entity in collect(values(storage.entities))
      push!(entities, entity)
      value = storage[entity]
      data[entity] = remap || isa(value, EntityID) ? remap_value_for_dataframe_display(value) : value
    end
  end
  entities = collect(entities)
  df_columns = Pair{Symbol, <:Vector}[]
  for (component_id, data) in columns
    name = isnothing(ecs.component_names) ? Symbol(component_id) : get(ecs.component_names, component_id, Symbol(component_id))
    CT = eltype(values(data))
    push!(df_columns, name => CT[get(data, entity, missing) for entity in entities])
  end
  !isnothing(ecs.entity_names) && pushfirst!(df_columns, :Name => Union{Symbol, Missing}[get(ecs.entity_names, entity, missing) for entity in entities])
  perm = sortperm(entities, by = x -> reinterpret(UInt32, x))
  DataFrame([name => data[perm] for (name, data) in df_columns])
end

end # module
