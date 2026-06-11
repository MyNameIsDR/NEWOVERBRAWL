extends Camera2D

@onready var p1 = get_parent().get_node("FOX")

#called when the node enteres the scene tree for the first time
func _ready():
	pass #replace with function body
	
#called every frame. "delta" is the elapsed time since the pervious frame
func _physics_process(delta):
	self.position = p1.position
