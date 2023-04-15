using Entities
using Entities: new!
using Test

@testset "Entities.jl" begin
  @testset "Entity pool" begin
    pool = EntityPool()
    entity1 = new!(pool)
    @test pool.counter == entity1
    entity2 = new!(pool)
    @test pool.counter == entity2
    delete!(pool, entity1)
    @test pool.free == [entity1]
    entity3 = new!(pool)
    @test entity3 == entity1
    @test pool.counter == entity2
    @test isempty(pool.free)
    @test new!(pool) == pool.counter == EntityID(3)
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
end
