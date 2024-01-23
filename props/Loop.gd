extends Node2D

@onready var right = $RightBody
@onready var left = $LeftBody


func _on_left_body_entered(body):
	left.collision_layer = 0
	right.collision_layer = 1


func _on_right_body_entered(body):
	right.collision_layer = 0
	left.collision_layer = 1


func _on_top_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	right.collision_layer = 1
	left.collision_layer = 1
