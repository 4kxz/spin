class_name BallBody extends RigidBody2D

const GEARS = [
	# plot max(-0.0035*x**2 + 4.5*x + 2000, 0), max(-0.0019*x**2 + 3*x + 1500, 0), max(-0.0008*x**2 + 1.9*x + 600, 0), x=0..4000
	{"a": -0.0035, "b": 4.5, "t_min": 2000},
	{"a": -0.0019, "b": 3, "t_min": 1500},
	{"a": -0.0008, "b": 1.9, "t_min": 600},
]

@export var control_point: ControlPoint
@export var jump_impulse := 500
@export var dust_particles: GPUParticles2D
@export var dust_frequency := 24
@export var dust_speed := 5
@export var dust_trigger_speed := 1500.0
@export var sprite: Sprite2D
@export var blur_start := 10
@export var blur_intensity := 0.2
@export var camera: PhantomCamera2D
@export var camera_target: Marker2D
@export var camera_speed := 1.5
@export var camera_distance := 500
@export var gear_auto_shift := true
@export var gear_delay_period := 0.35
@export var gear_cooldown_period := 2.4
@export var gear_shift_slack := 1.2
@export var energy_air_gain := 0.008
@export var chain: Chain
@export var chain_strength := 2000.0
@export var chain_energy_drain := 0.1

var energy: float = 0:
	set(value):
		energy = clampf(value, 0, 1)
var current_gear: int = 0
var gear_cooldown_timer: float = 0
var gear_torque: Array[float]
var previous_angle: float = 0
var previous_velocity := Vector2.ZERO
var dust_particle_timer: float = 0
var air_time: float = 0
var is_grounded: bool = true

@onready var clash_audio: AudioStreamPlayer2D = $Clash
@onready var jump_audio: AudioStreamPlayer2D = $Jump
@onready var chain_audio: AudioStreamPlayer2D = $Chain
@onready var dust_period = 1.0 / dust_frequency


func _ready() -> void:
	for i in GEARS.size():
		gear_torque.append(0)


func _process(delta: float) -> void:
	# Camera
	var zoom := sqrt(1.0 / (1.0 + linear_velocity.length() / 1000.0))
	camera.set_zoom(lerp(camera.zoom, Vector2(zoom, zoom), delta))
	var x := minf(linear_velocity.length() / camera_distance, 1)
	var camera_offset := (1/(1+(x/(1-x))**-2)) * camera_distance * linear_velocity.normalized()
	camera_target.position = lerp(camera_target.position, camera_offset, camera_speed * delta)
	# Chain
	if chain.is_flying() or chain.is_hooked():
		energy -= chain_energy_drain * delta
		if is_zero_approx(energy) or not Input.is_action_pressed("special"):
			chain.release()


func _physics_process(delta: float) -> void:
	air_time += delta
	# Gear cooldown
	gear_cooldown_timer += delta
	# Dust particles
	dust_particle_timer += delta
	# Motion blur
	var blur_amount := maxf((absf(angular_velocity) - blur_start) / blur_start * blur_intensity, 0)
	sprite.material.set_shader_parameter("amount", blur_amount)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var has_contact := state.get_contact_count() > 0
	if has_contact and position.y < state.get_contact_collider_position(0).y:
		if air_time > 1.0 and previous_velocity.length() > 100:
			clash_audio.play()
		air_time = 0
	is_grounded = air_time < 0.2
	# Angular delta
	var speed := linear_velocity.length()
	for i in GEARS.size():
		var gear = GEARS[i]
		gear_torque[i] = maxf(gear.a * speed ** 2 + gear.b * speed + gear.t_min, 1)
	var angle_delta := control_point.angle - previous_angle
	if angle_delta > PI:
		angle_delta -= 2 * PI
	elif angle_delta < -PI:
		angle_delta += 2 * PI
	previous_angle = control_point.angle
	# Gear shifting
	if gear_auto_shift and gear_cooldown_timer >= gear_cooldown_period:
		for i in GEARS.size():
			if gear_torque[i] > gear_torque[current_gear] * gear_shift_slack:
				get_tree().create_timer(gear_delay_period).timeout.connect(_set_gear.bind(i))
				gear_cooldown_timer = 0
	# Chain
	if chain.is_hooked():
		var chain_velocity = chain.hook.global_position - global_position
		if chain_velocity.y > 0:
			chain_velocity *= 0.5
		state.apply_central_force(chain_velocity.normalized() * chain_strength)
	# Apply forces
	var torque_multiplier := 0.9 if is_grounded else 0.5
	state.apply_torque_impulse(gear_torque[current_gear] * angle_delta * torque_multiplier)
	# Dust particles
	if has_contact and previous_velocity.length() >= dust_trigger_speed and dust_particle_timer >= dust_period:
		var dust_transform = Transform2D(0, state.get_contact_collider_position(0))
		var dust_velocity = linear_velocity / dust_speed
		dust_particles.emit_particle(
			dust_transform,
			-dust_velocity,
			Color.WHITE,
			Color.WHITE,
			GPUParticles2D.EmitFlags.EMIT_FLAG_POSITION | GPUParticles2D.EMIT_FLAG_VELOCITY,
		)
		dust_particle_timer = 0
	previous_velocity = linear_velocity
	# Add energy
	if not is_grounded:
		energy += absf(angle_delta * energy_air_gain)


func _input(event: InputEvent) -> void:
	var new_gear := current_gear
	if event.is_action_pressed("jump") and is_grounded:
		apply_central_impulse(Vector2.UP * jump_impulse)
		jump_audio.play()
	elif event.is_action_pressed("special") and energy > 0:
		chain.shoot(position.direction_to(get_global_mouse_position()))
		chain_audio.play()
	elif event.is_action_pressed("gear_up"):
		new_gear = min(current_gear + 1, 1)
	elif event.is_action_pressed("gear_down"):
		new_gear = max(current_gear - 1, 0)
	if new_gear != current_gear:
		_set_gear(new_gear)


func _set_gear(i: int) -> void:
	current_gear = i
	gear_cooldown_period = 0.0
