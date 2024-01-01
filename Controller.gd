extends Node2D

const GEAR_RATIOS = [2.0, 1.0]
const GEAR_COLORS = [Color.BLUE, Color.RED]

@onready var line: Line2D = $Line2D
@export var body: RigidBody2D
@export var force_multiplier := 2500
@export var jump_multiplier := 500
@export var camera: PhantomCamera2D

var previous_angle := 0.0
var gear := 1

@onready var target: Marker2D = $CameraScale/CameraTarget


func _process(delta: float) -> void:
	var target_position := body.linear_velocity
	target_position.y /= 2
	target.position = lerp(target.position, body.linear_velocity, delta * 2)


func _physics_process(_delta) -> void:
	var angle := get_angle_to(get_global_mouse_position())
	var delta_angle := angle - previous_angle
	previous_angle = angle
	if delta_angle > PI:
		delta_angle -= 2 * PI
	elif delta_angle < -PI:
		delta_angle += 2 * PI
	body.apply_torque_impulse(delta_angle * force_multiplier * GEAR_RATIOS[gear])
	line.rotation = angle
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
	line.default_color = GEAR_COLORS[gear]
