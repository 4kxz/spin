extends Control

@export var ball: BallBody

@onready var linear_velocity: Label = $Container/LinearVelocity
@onready var angular_velocity: Label = $Container/AngularVelocity
@onready var torque0: Label = $Container/Torque0
@onready var torque1: Label = $Container/Torque1
@onready var gear: Label = $Container/Gear


func _process(_delta: float) -> void:
	# Linear velocity
	var lv := roundi(ball.linear_velocity.length())
	@warning_ignore("integer_division")
	var lv_bars :=  '|'.repeat(lv / 20)
	linear_velocity.set_text("Linear velocity: %4d %s" % [lv, lv_bars])
	# Angular velocity
	var av := roundi(ball.angular_velocity)
	var av_bars :=  '|'.repeat(abs(av))
	angular_velocity.set_text("Angular velocity: %4d %s" % [av, av_bars])
	# Torque Gear 0
	var t0 := roundi(ball.gear_torque[0])
	@warning_ignore("integer_division")
	var t0_bars :=  '|'.repeat(abs(t0 / 100))
	torque0.set_text("Torque 0: %4d %s" % [t0, t0_bars])
	# Torque Gear 1
	var t1 := roundi(ball.gear_torque[1])
	@warning_ignore("integer_division")
	var t1_bars :=  '|'.repeat(abs(t1 / 100))
	torque1.set_text("Torque 1: %4d %s" % [t1, t1_bars])
	# Gear
	gear.set_text("Gear: %s" % ball.current_gear)
