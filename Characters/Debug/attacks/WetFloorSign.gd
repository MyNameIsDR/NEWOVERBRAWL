extends CharacterBody2D

var owner_character

var gravity = 1200

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)
	
func _on_timer_timeout():
	queue_free()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity = Vector2.ZERO

	move_and_slide()
