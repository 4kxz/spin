extends RigidBody2D

@export var dust_velocity := 1000.0
@export var particles_per_second := 24
@export var dust_particles: GPUParticles2D
@export var blur_start := 15
@export var blur_intensity := 0.05
@export var wheel_sprite: Sprite2D

var next_particle := 0.0
var velocity := 0.0


func _physics_process(delta: float) -> void:
	next_particle += delta
	var blur_amount := maxf(0.0, absf(angular_velocity) - blur_start) * blur_intensity
	wheel_sprite.material.set_shader_parameter("amount", blur_amount)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var prev_velocity = velocity
	velocity = linear_velocity.length()
	if prev_velocity < dust_velocity:
		return
	if next_particle < (1.0 / particles_per_second):
		return
	if state.get_contact_count():
		next_particle = 0.0
		dust_particles.emit_particle(
			Transform2D(0, state.get_contact_collider_position(0)),
			-linear_velocity / 5.0,
			Color.WHITE,
			Color.WHITE,
			GPUParticles2D.EmitFlags.EMIT_FLAG_POSITION | GPUParticles2D.EMIT_FLAG_VELOCITY,
		)
