class_name Chain extends Node2D

@export var hook: CharacterBody2D
@export var speed: float = 50

var _direction: Vector2
var _flying = false
var _hooked = false

@onready var links = $Links


func shoot(direction: Vector2) -> void:
	_direction = direction.normalized()
	_hooked = false
	_flying = true
	hook.global_position = global_position


func release() -> void:
	_flying = false
	_hooked = false


func is_hooked() -> bool:
	return _hooked


func is_flying() -> bool:
	return _flying


func _process(_delta: float) -> void:
	visible = _flying or _hooked
	hook.visible = visible
	if not visible:
		return
	links.global_position = hook.global_position
	links.rotation = global_position.angle_to_point(hook.global_position) + PI / 2
	links.region_rect.size.y = global_position.distance_to(hook.global_position)
	hook.rotation = links.rotation


func _physics_process(_delta: float) -> void:
	if _flying:
		var collision = hook.move_and_collide(_direction * speed)
		if collision:
			_hooked = true
			_flying = false
