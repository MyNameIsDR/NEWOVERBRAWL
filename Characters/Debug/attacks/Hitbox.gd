extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):

	if body == get_parent().owner_character:
		print("IGNORED OWNER")
		return

	if body.is_in_group("Character"):
		print("PLAYER DETECTED")
		body.slip_stun()
