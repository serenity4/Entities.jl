using Entities
using Entities: new!, component_iterator, ColumnIterator
using Test

@testset "Entities.jl" begin
  @testset "Entity pool" begin
    pool = EntityPool()
    entity1 = new!(pool)
    @test EntityID(pool.counter[]) == entity1
    entity2 = new!(pool)
    @test EntityID(pool.counter[]) == entity2
    delete!(pool, entity1)
    @test pool.free == [entity1]
    entity3 = new!(pool)
    @test entity3 == entity1
    @test EntityID(pool.counter[]) == entity2
    @test isempty(pool.free)
    @test new!(pool) == EntityID(pool.counter[]) == EntityID(3)
  end

  @testset "Per-entity contiguous component storage" begin
    pool = EntityPool()
    entity1 = new!(pool)
    storage = ComponentStorage{Float64}()
    insert!(storage, entity1, 2.5)
    @test storage[entity1] == 2.5
    @test haskey(storage, entity1)
    @test_throws "already has a component assigned" insert!(storage, entity1, 3.0)
    storage[entity1] = 4.0
    @test storage[entity1] == 4.0
    delete!(storage, entity1)
    @test !haskey(storage, entity1)
    entity2 = new!(pool)
    entity3 = new!(pool)
    storage[entity1] = 1.0
    storage[entity2] = 2.0
    storage[entity3] = 3.0
    @test storage.components == [1.0, 2.0, 3.0]
    @test collect(storage) == storage.components
    @test length(storage) == 3
    delete!(storage, entity1)
    @test storage.components == [3.0, 2.0]
    @test collect(storage) == storage.components
    @test length(storage) == 2
  end

  @testset "ECSDatabase" begin
    pool = EntityPool()
    ecs = ECSDatabase()
    c1 = add_column!(ecs)
    storage = ComponentStorage{Float64}()
    ecs[c1] = storage
    entity1 = new!(pool)
    insert!(ecs, entity1, c1, 1.0)
    @test ComponentStorage{Float64}(ecs, c1) === storage
    @test component_iterator(ecs, c1, Float64) === storage
    ret = components(ecs, c1, Float64)
    @test ret == [1.0]
    @test eltype(ret) === Float64
    @test ecs[entity1, c1] === 1.0
    entity2 = new!(pool)
    c2 = add_column!(ecs)
    insert!(ecs, entity2, c2, :a)
    @test ecs[entity2, c2] === :a
    ecs[entity2, c2] = :b
    ret = components(ecs, c2, Symbol)
    @test ret == [:b]
    @test eltype(ret) === Symbol
    @test component_iterator(ecs, (c1, c2), Tuple{Float64, Symbol}) isa ColumnIterator{Tuple{ComponentStorage{Float64}, ComponentStorage{Symbol}}}
    ret = components(ecs, (c1, c2), Tuple{Float64, Symbol})
    @test isempty(ret)
    ecs[entity2, c1] = 2.0
    ret = components(ecs, (c1, c2), Tuple{Float64, Symbol})
    @test ret == [(2.0, :b)]
    @test eltype(ret) === Tuple{Float64, Symbol}
    c3 = add_column!(ecs)
    insert!(ecs, entity2, c3, "ha")
    @test ecs[entity2, c3] === "ha"
    ret = components(ecs, (c1, c2, c3), Tuple{Float64, Symbol, String})
    @test ret == ret == [(2.0, :b, "ha")]
  end
end;
