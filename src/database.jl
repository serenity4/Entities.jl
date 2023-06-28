struct ECSDatabase
  components::Dict{ComponentID,ComponentStorage}
  counter::Counter
end

ECSDatabase() = ECSDatabase(Dict(), Counter())

add_column!(ecs::ECSDatabase) = next_component!(ecs.counter)

Base.insert!(ecs::ECSDatabase, entity::EntityID, component::ComponentID, item) = insert!(get!(() -> ComponentStorage{typeof(item)}(), ecs.components, component), entity, item)
Base.delete!(ecs::ECSDatabase, entity::EntityID, component::ComponentID) = delete!(ecs.components[component], entity)
Base.getindex(ecs::ECSDatabase, entity::EntityID, component::ComponentID) = getindex(ecs.components[component], entity)
Base.haskey(ecs::ECSDatabase, entity::EntityID, component::ComponentID) = haskey(ecs.components[component], entity)

for f in ()
  @eval $f(ecs::ECSDatabase, entity::EntityID, component::ComponentID, args...) = $f(ecs.components[component], entity, args...)
end
Base.setindex!(ecs::ECSDatabase, storage::ComponentStorage, col::ComponentID) = setindex!(ecs.components, storage, col)

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
      get(cols[i], j, nothing)
    end
    any(isnothing, vals) && continue
    return ((col[i], vals...)::Tuple{eltype.(it.columns)...}, i + 1)
  end
end

components(ecs::ECSDatabase, ids, T) = components(component_iterator(ecs, ids, T))
components(storage::ComponentStorage) = storage.components
components(it::ColumnIterator) = collect(it)
