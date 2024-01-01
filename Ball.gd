extends RigidBody2D

@export var particles: GPUParticles2D
@export var dust_velocity := 400.0


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var length = linear_velocity.length()
	if length < dust_velocity:
		return
	for i in state.get_contact_count():
		if randf() < length / dust_velocity * 0.15:
			particles.emit_particle(
				Transform2D(0, state.get_contact_collider_position(i)),
				-linear_velocity / 5.0,
				Color.WHITE,
				Color.WHITE,
				GPUParticles2D.EmitFlags.EMIT_FLAG_POSITION | GPUParticles2D.EMIT_FLAG_VELOCITY,
			)
