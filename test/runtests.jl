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
    entry = ComponentEntry{Float64}()
    insert!(entry, entity1, 2.5)
    @test entry[entity1] == 2.5
    @test haskey(entry, entity1)
    @test_throws "already has a component assigned" insert!(entry, entity1, 3.0)
    entry[entity1] = 4.0
    @test entry[entity1] == 4.0
    delete!(entry, entity1)
    @test !haskey(entry, entity1)
    entity2 = new!(pool)
    entity3 = new!(pool)
    entry[entity1] = 1.0
    entry[entity2] = 2.0
    entry[entity3] = 3.0
    @test entry.components == [1.0, 2.0, 3.0]
    @test collect(entry) == entry.components
    @test length(entry) == 3
    delete!(entry, entity1)
    @test entry.components == [3.0, 2.0]
    @test collect(entry) == entry.components
    @test length(entry) == 2
  end
end
