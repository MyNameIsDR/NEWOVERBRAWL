extends Area2D

@export var stun_time := 0.5
@export var slip_force := Vector2(200, -100)

func _on_body_entered(body):
	if body.is_in_group("players"):
		body.apply_stun(stun_time)
		body.velocity += slip_force
