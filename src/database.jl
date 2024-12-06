struct ECSDatabase
  components::Dict{ComponentID,ComponentStorage}
  component_names::Union{Nothing, Dict{ComponentID, Symbol}}
  entity_names::Union{Nothing, Dict{EntityID, Symbol}}
end

ECSDatabase(; component_names = nothing, entity_names = nothing) = ECSDatabase(Dict(), component_names, entity_names)

Base.broadcastable(ecs::ECSDatabase) = Ref(ecs)

function Base.show(io::IO, ecs::ECSDatabase)
  n = length(ecs.components)
  print(io, ECSDatabase, '(', n, " component type", n == 1 ? "" : "s", ')')
end

function Base.show(io::IO, ::MIME"text/plain", ecs::ECSDatabase)
  n = length(ecs.components)
  iszero(n) && return print(io, ECSDatabase, " (empty)")
  unique_entities = unique(foldl((x, (id, storage)) -> append!(x, values(storage.entities)), ecs.components; init = EntityID[]))
  print(io, ECSDatabase, " with ", length(unique_entities), " total entities and ", length(ecs.components), " component types:")
  for (component, storage) in sort(pairs(ecs.components), by = x -> reinterpret(UInt32, x))
    name = isnothing(ecs.component_names) ? nothing : get(ecs.component_names, component, nothing)
    nc = length(storage)
    print(io, "\n⬤ ", component, ' ', isnothing(name) ? '(' : "(name: $name, ", "type: ", eltype(storage), ", ", nc, " component", nc ≤ 1 ? ")" : "s)")
  end
end

get_column!(ecs::ECSDatabase, component::ComponentID, ::Type{T}) where {T} = get!(ComponentStorage{T}, ecs.components, component)::ComponentStorage{T}

Base.insert!(ecs::ECSDatabase, entity::EntityID, component::ComponentID, item, ::Type{T} = typeof(item)) where {T} = insert!(get_column!(ecs, component, T), entity, item)
Base.insert!(ecs::ECSDatabase, entity, component::ComponentID, item, ::Type{T} = typeof(item)) where {T} = insert!(ecs, convert(EntityID, entity), component, item, T)
Base.delete!(ecs::ECSDatabase, entity::EntityID, component::ComponentID) = delete!(ecs.components[component], entity)
Base.delete!(ecs::ECSDatabase, entity, component::ComponentID) = delete!(ecs, convert(EntityID, entity), component)
Base.delete!(ecs::ECSDatabase, entity::EntityID, component::ComponentID, ::Type{T}) where {T} = delete!(ecs.components[component]::ComponentStorage{T}, entity)
Base.delete!(ecs::ECSDatabase, entity, component::ComponentID, ::Type{T}) where {T} = delete!(ecs, convert(EntityID, entity), component, T)
Base.getindex(ecs::ECSDatabase, entity::EntityID, component::ComponentID) = getindex(ecs.components[component], entity)
Base.getindex(ecs::ECSDatabase, entity, component::ComponentID) = getindex(ecs, convert(EntityID, entity)::EntityID, component)
Base.getindex(ecs::ECSDatabase, entity::EntityID, component::ComponentID, ::Type{T}) where {T} = getindex(ecs.components[component]::ComponentStorage{T}, entity)
Base.getindex(ecs::ECSDatabase, entity, component::ComponentID, ::Type{T}) where {T} = getindex(ecs, convert(EntityID, entity)::EntityID, component, T)

Base.setindex!(ecs::ECSDatabase, value, entity::EntityID, component::ComponentID, ::Type{T} = typeof(value)) where {T} = get_column!(ecs, component, T)[entity] = value
Base.setindex!(ecs::ECSDatabase, value, entity, component::ComponentID, ::Type{T} = typeof(value)) where {T} = setindex!(ecs, value, convert(EntityID, entity)::EntityID, component, T)
Base.haskey(ecs::ECSDatabase, entity::EntityID, component::ComponentID) = haskey(ecs.components[component], entity)
Base.haskey(ecs::ECSDatabase, entity, component::ComponentID) = haskey(ecs.components[component], convert(EntityID, entity)::EntityID)
Base.haskey(ecs::ECSDatabase, entity::EntityID, component::ComponentID, ::Type{T}) where {T} = haskey(ecs.components[component]::ComponentStorage{T}, entity)
Base.haskey(ecs::ECSDatabase, entity, component::ComponentID, ::Type{T}) where {T} = haskey(ecs, convert(EntityID, entity)::EntityID, component, T)

Base.setindex!(ecs::ECSDatabase, storage::ComponentStorage, col::ComponentID) = setindex!(ecs.components, storage, col)

function Base.empty!(ecs::ECSDatabase)
  empty!(ecs.components)
  ecs
end

function Base.delete!(ecs::ECSDatabase, entity::EntityID)
  for storage in values(ecs.components)
    haskey(storage, entity) && delete!(storage, entity)
  end
end

function ComponentStorage{T}(ecs::ECSDatabase, id::ComponentID) where {T}
  haskey(ecs.components, id) || throw(KeyError(id))
  storage = ecs.components[id]
  !isa(storage, ComponentStorage{T}) && throw(ArgumentError("Expected components associated with $id to be of type $T, found components of type $(eltype(storage)) instead"))
  storage
end

component_iterator(ecs::ECSDatabase, id::ComponentID, ::Type{T}) where {T} = ComponentStorage{T}(ecs, id)

@generated function component_iterator(ecs::ECSDatabase, ids, ::Type{T}) where {T}
  # T <: Type || error("Type expected as last argument")
  # T = T.parameters[1]
  T <:Tuple || error("Tuple type expected, got $(repr(T))")
  Ts = fieldtypes(T)
  ex = quote
    length(ids) == $(length(Ts)) || throw(ArgumentError("The number of requested component ids and the number of tuple elements of the requested type do not match: $(length(ids)) ≠ " * $(string(length(Ts)))))
  end
  vars = [gensym("col") for _ in 1:length(Ts)]
  for (i, (Tt, var)) in enumerate(zip(Ts, vars))
    push!(ex.args, :($var = ComponentStorage{$Tt}(ecs, ids[$i])))
  end
  push!(ex.args, Expr(:call, :ColumnIterator, Expr(:tuple, vars...)))
  ex
end

struct ColumnIterator{T<:Tuple}
  columns::T
end

Base.IteratorEltype(::Type{<:ColumnIterator}) = Base.HasEltype()
Base.eltype(::Type{ColumnIterator{T}}) where {T} = Tuple{eltype.(fieldtypes(T))...}
Base.IteratorSize(::Type{<:ColumnIterator}) = Base.SizeUnknown()

@forward_methods ColumnIterator field = typeof(_) Base.eltype Base.IteratorEltype Base.IteratorSize

function Base.iterate(it::ColumnIterator, state = 1)
  col, cols... = it.columns
  for i in state:length(col)
    entity = col.entities[UInt32(i)]
    vals = ntuple(length(cols)) do j
      get(cols[j], entity, nothing)
    end
    any(isnothing, vals) && continue
    return ((col[i], vals...)::Tuple{eltype.(it.columns)...}, i + 1)
  end
end

components(ecs::ECSDatabase, ids, T) = components(component_iterator(ecs, ids, T))
components(storage::ComponentStorage) = storage.components
components(it::ColumnIterator) = collect(it)
