module TestModule

struct Location{T}
  position::NTuple{3,T}
end

struct Transform{T}
  rotation::Quaternion{T}
  translation::NTuple{3,T}
  scaling::NTuple{3,T}
end

struct Kinematics{T}
  linear_velocity::NTuple{3,T}
  angular_velocity::NTuple{3,T}
end

struct RigidBodyDynamics{T}
  mass::T
  inertia::Matrix{T}
end

struct CollisionGroup
  objects::
end

struct CollisionDynamics{T}
  active::Bool # active or passive
  collides_with::Vector{EntityID}
  bounciness::T
end

struct GravitationalDynamics{T}
  gravitational_acceleration::T
end

@group EngineEntities begin
  ::Location
  ::Location & ::Transform
  ::Location & ::Kinematics
end

struct AllEntities
  locations::ComponentStorage{Location}
  transforms::ComponentStorage{Transform}
  kinematics::ComponentStorage{Kinematics}
  dynamics::ComponentStorage{RigidBodyDynamics}
end

function transform(entities)
  for entity in entities
    if has_attribute(entity, Transform)
      entity.position = apply(entity.transform.translation, apply(entity.transform.scaling, apply(entity.transform.rotation)))
    end
  end
end

end # module
