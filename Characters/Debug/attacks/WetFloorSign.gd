extends CharacterBody2D

var gravity = 1200

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity = Vector2.ZERO

	move_and_slide()
