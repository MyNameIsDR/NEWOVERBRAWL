extends Node2D

@onready var line = $Line

var tape_length = 50

func _ready():
	line.points = [
		Vector2.ZERO,
		Vector2(tape_length, 0)
	]

func extend(delta):
	tape_length += 400 * delta
	tape_length = clamp(tape_length, 50, 400)

	line.points[1] = Vector2(tape_length, 0)
