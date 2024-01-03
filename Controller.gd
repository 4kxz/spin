extends Node2D

const GEAR_RATIOS = [2.0, 1.0]
const GEAR_COLORS = [Color.BLUE, Color.RED]

@export var body: RigidBody2D
@export var force_multiplier := 2500
@export var jump_multiplier := 500
@export var camera: PhantomCamera2D
@export var camera_target_sensitivity := 2.0
@export var control_point: ControlPoint

var gear := 0
var previous_angle := 0.0

@onready var camera_target: Marker2D = $CameraScale/CameraTarget


func _process(delta: float) -> void:
	camera_target.position = lerp(
		camera_target.position,
		body.linear_velocity,
		delta * camera_target_sensitivity,
	)


func _physics_process(_delta) -> void:
	var angle_delta := control_point.angle - previous_angle
	if angle_delta > PI:
		angle_delta -= 2 * PI
	elif angle_delta < -PI:
		angle_delta += 2 * PI
	previous_angle = control_point.angle
	body.apply_torque_impulse(angle_delta * force_multiplier * GEAR_RATIOS[gear])
	var zoom := sqrt(1.0 / (1.0 + body.linear_velocity.length() / 1000.0))
	camera.set_zoom(lerp(camera.zoom, Vector2(zoom, zoom), 0.01))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		var jump_direction = position.direction_to(get_global_mouse_position())
		body.apply_central_impulse(jump_direction * jump_multiplier)
	elif event.is_action_pressed("gear_up"):
		gear = min(gear + 1, 1)
	elif event.is_action_pressed("gear_down"):
		gear = max(gear - 1, 0)
