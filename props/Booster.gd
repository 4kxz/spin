extends Area2D

@export var impulse_strength := 1000.0

@onready var audio = $AudioStreamPlayer2D


func _on_body_entered(body: Node2D):
	if body is BallBody:
		body.apply_central_impulse(body.linear_velocity.normalized() * impulse_strength)
		audio.play()
