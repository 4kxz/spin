extends CanvasLayer

@export var ball: BallBody

var time := 0.0

@onready var timer: Label = %Timer
@onready var energy: ProgressBar = %Energy


func _process(delta: float):
	time += delta
	var minutes := int(time / 60)
	var seconds := fposmod(time, 60)
	timer.text = "%d:%05.2f" % [minutes, seconds]
	energy.ratio = ball.energy
