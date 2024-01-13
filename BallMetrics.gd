extends Control

@export var ball: BallBody

var torque_labels: Array[Label]

@onready var container = %Container
@onready var linear_velocity: Label = %LinearVelocity
@onready var angular_velocity: Label = %AngularVelocity
@onready var air_time: Label = %AirTime


func _ready() -> void:
	torque_labels = []
	for i in ball.GEARS.size():
		var label := Label.new()
		torque_labels.append(label)
		container.add_child(label)


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
	# Air time
	air_time.set_text("Air time: %.1f" % ball.air_time)
	air_time.add_theme_color_override("font_color", Color.RED if ball.air_time > 0.2 else Color.WHITE)
	# Gears
	for i in ball.gear_torque.size():
		var t := roundi(ball.gear_torque[i])
		@warning_ignore("integer_division")
		var t_bars :=  '|'.repeat(abs(t / 100))
		torque_labels[i].set_text("Gear %d: %4d %s" % [i, t, t_bars])
		var color := Color.GREEN if ball.current_gear == i else Color.WHITE
		torque_labels[i].add_theme_color_override("font_color", color)
