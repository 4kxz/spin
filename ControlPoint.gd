class_name ControlPoint extends Marker2D

@export var sensitivity := 4.0
@export var max_distance := 25

var angle := 0.0

@onready var line = $Line


func _process(delta: float) -> void:
	var mouse_position := get_global_mouse_position()
	angle = global_position.angle_to_point(mouse_position)
	if global_position.distance_to(mouse_position) > max_distance:
		global_position = lerp(global_position, mouse_position, delta * sensitivity)
	line.rotation = angle
