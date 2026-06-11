extends Area2D

@export var LASER_SPEED = 1500
@onready var parent = get_parent()
@export var duration = 60
@export var damage = 3

var frame = 0
var dir_x = 1
var dir_y = 0
var player_list = []

func _ready():
	player_list.append(parent)
	set_process(true)

func _process(delta):
	frame += floor(delta * 60)
	if frame == duration:
		queue_free()
	var motion = (Vector2(dir_x, dir_y).normalized() * LASER_SPEED)
	set_position(get_position() + motion * delta)
	position.direction_to(motion)
	set_rotation_degrees(rad_to_deg(Vector2(dir_x, dir_y).angle()))

func dir(directionx, directiony):
	dir_x = directionx
	dir_y = directiony

func _on_body_entered(body):
	if not (body in player_list):
		print('hit')
		body.percentage += damage
		queue_free()
