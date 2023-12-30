extends Node2D

@onready var line: Line2D = $Line2D
@export var body: RigidBody2D
@export var force_multiplier := 2500
@export var jump_multiplier := 500

var previous_angle := 0.0

@onready var camera: PhantomCamera2D = $PhantomCamera2D
@onready var target: Marker2D = $Node2D/CameraTarget


func _process(delta: float) -> void:
	var angle := get_angle_to(get_global_mouse_position())
	line.rotation = angle
	var delta_angle := angle - previous_angle
	if delta_angle > PI:
		delta_angle -= 2 * PI
	elif delta_angle < -PI:
		delta_angle += 2 * PI
	body.apply_torque_impulse(delta_angle * force_multiplier)
	previous_angle = angle
	var target_position := body.linear_velocity
	target_position.y /= 2
	target.position = lerp(target.position, body.linear_velocity, delta * 2)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		var jump_direction = position.direction_to(get_global_mouse_position())
		body.apply_central_impulse(jump_direction * jump_multiplier)
