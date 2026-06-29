extends Node2D

@onready var line = $Line

func _ready():
	print("LINE NODE:", line)
	
var tape_length := 0
var target_length := 150
var facing := 1

func _physics_process(delta):
	if tape_length < target_length:
		tape_length += 800 * delta
		tape_length = min(tape_length, target_length)
		update_line()

func update_line():
	line.points = [
		Vector2.ZERO,
		Vector2(tape_length * facing, 0)
	]

func set_length(length):
	tape_length = length
	update_line()

func extend(delta):
	tape_length += 1000 * delta
	tape_length = clamp(tape_length, 150, 1000)
	update_line()
	print("Final length:", tape_length)
