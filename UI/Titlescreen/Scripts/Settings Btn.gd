extends Button

@export var path = ""
@onready var label = get_node("Label")

func _on_SettingsButton_focus_entered():
	add_theme_color_override("font_outline_color", Color("#614FFF"))

func _on_SettingsButton_focus_exited():
	add_theme_color_override("font_outline_color", Color(0, 0))

func _on_pressed():
	if (path != ""):
		get_tree().change_scene_to_file(path)
	
func _on_Area2D_area_entered(area):
	emit_signal("focus_entered")

func _on_Area2D_area_exited(area):
	emit_signal("focus_exited")
