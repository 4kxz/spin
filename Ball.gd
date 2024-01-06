class_name BallBody extends RigidBody2D

const GEARS = [
	{"a": -0.01, "b": 6, "t_min": 5000},
	{"a": -0.001, "b": 3, "t_min": 500},
]

@export var control_point: ControlPoint
@export var jump_impulse := 500
@export var dust_particles: GPUParticles2D
@export var dust_frequency := 24
@export var dust_speed := 5
@export var dust_trigger_velocity := 1000.0
@export var sprite: Sprite2D
@export var blur_start := 5
@export var blur_intensity := 0.1
@export var camera: PhantomCamera2D
@export var camera_target: Marker2D
@export var camera_speed := 0.1
@export var gear_auto_shift := true
@export var gear_delay_period := 1.0
@export var gear_cooldown_period := 2.0
@export var gear_shift_slack := 1.1  # 10%

var current_gear := 0
var gear_cooldown_timer := 0.0
var gear_torque := [0.0, 0.0]
var previous_angle := 0.0
var previous_velocity := 0.0
var dust_particle_timer := 0.0
var is_grounded := false

@onready var dust_period = 1.0 / dust_frequency


func _process(delta: float) -> void:
	# Camera
	var zoom := sqrt(1.0 / (1.0 + linear_velocity.length() / 1000.0))
	camera.set_zoom(lerp(camera.zoom, Vector2(zoom, zoom), delta))
	camera_target.position = lerp(camera_target.position, linear_velocity, camera_speed * delta)


func _physics_process(delta: float) -> void:
	# Gear cooldown
	gear_cooldown_timer += delta
	# Dust particles
	dust_particle_timer += delta
	# Motion blur
	var blur_amount := maxf((absf(angular_velocity) - blur_start) / blur_start * blur_intensity, 0)
	sprite.material.set_shader_parameter("amount", blur_amount)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
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
			if gear_torque[i] > gear_torque[current_gear] + gear_shift_slack:
				get_tree().create_timer(gear_delay_period).timeout.connect(_set_gear.bind(i))
				gear_cooldown_timer = 0
	# Apply forces
	is_grounded = state.get_contact_count() > 0
	if is_grounded:
		state.apply_torque_impulse(gear_torque[current_gear] * angle_delta)
	else:
		# Air control
		var torque_multiplier = 0.5 if signf(angle_delta) == signf(angular_velocity) else 1.5
		state.apply_torque_impulse(gear_torque[current_gear] * angle_delta * torque_multiplier)
	# Dust particles
	if is_grounded and previous_velocity >= dust_trigger_velocity and dust_particle_timer >= dust_period:
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
	previous_velocity = linear_velocity.length()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		var jump_direction = position.direction_to(get_global_mouse_position())
		apply_central_impulse(jump_impulse * jump_direction)
	elif event.is_action_pressed("gear_up"):
		current_gear = min(current_gear + 1, 1)
	elif event.is_action_pressed("gear_down"):
		current_gear = max(current_gear - 1, 0)


func _set_gear(i: int) -> void:
	current_gear = i
