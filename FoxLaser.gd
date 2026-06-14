extends Area2D

@export var LASER_SPEED = 1500
@onready var parent = get_parent()
@export var duration = 60
@export var damage = 3

#KNOCKBACK attributes
@export var angle = 60
@export var base_kb = 3860
@export var kb_scaling = 1
@export var type = "normal"
@export var percentage = 0
@export var weight = 100
@export var ratio = 1
@export var hitlag_modifier = 3
var knockbackVal
@export var vibration = 0

var frame = 0
var dir_x = 1
var dir_y = 0
var player_list = []

#degrees > radiu
const angleConversion = PI / 180

func dir(directionx, directiony):
	dir_x = directionx
	if dir_x < 0:
		angle = -angle+180
	else:
		angle = angle
	dir_y = directiony

func _ready():
	player_list.append(parent)
	set_process(true)

func _physics_process(delta):
	frame += floor(delta * 60)
	if frame == duration:
		queue_free()
	var motion = (Vector2(dir_x, dir_y).normalized() * LASER_SPEED)
	set_position(get_position() + motion * delta)
	position.direction_to(motion)
	
	set_rotation_degrees(rad_to_deg(Vector2(dir_x, dir_y).angle()))

func _on_body_entered(body):
	if not (body in player_list):
		var vibration = 2
		if vibration == 0: #jab
			Input.start_joy_vibration(0, 0.5, 0.5, 0.1)
		elif vibration == 1: #tilt
			Input.start_joy_vibration(0, 0.7, 0.7, 0.10)
		elif vibration == 2: #projectile
			Input.start_joy_vibration(0, 0.8, 1.0, 0.05)
		elif vibration == 3: #smash
			Input.start_joy_vibration(0, 1, 1.0, 0.4)
		var charstate
		charstate = body.get_node("StateMachine")
		knockbackVal = knockback(body.percentage, damage, body.weight, kb_scaling, base_kb, 1)
		body.percentage += damage		
		body.knockback = knockbackVal
		body.hitstun = getHitstun(knockbackVal/0.3)
		body._frame()
		
		charstate.state = charstate.states.HITFREEZE
		charstate.hitfreeze(hitlag(damage,hitlag_modifier),[getHorizontalVelocity (knockbackVal, -angle), getVerticalVelocity (knockbackVal, -angle), getHorizontalDecay(angle), getVerticalDecay(angle)])
		queue_free()

func knockback(p,d,w,ks,bk,r):
	percentage = p
	damage = d
	weight = w
	kb_scaling = ks
	base_kb = bk
	ratio = r
	return ((((((((percentage/10) +(percentage*damage/20))*(200/ (weight+100)) *1.4) +18)*(kb_scaling))+base_kb)*1))*0.004 #smash ultimate version

func getHorizontalDecay (angle): #The rate at which the opponent will slow down after knockback
	var decay = 0.051 * cos(angle * angleConversion) #Rate of decay is 0.051, to get horizontal rate; multiply by horizontal(cos) angle in radians
	decay = round(decay * 100000) / 100000 #Round to a whole number
	decay = decay * 1000 #Enlarge the rate of decay
	return decay

func getVerticalDecay (angle):
	var decay = 0.051 * sin(angle * angleConversion)
	decay = round(decay * 100000) / 100000
	decay = decay * 1000
	return abs(decay)

func getHorizontalVelocity (knockback, angle): #Function gets the horizontal knockback speed with total knockback and angle
	var initialVelocity = knockback * 30; #Gets the initial velocity by multiplying knockback by 30
	var horizontalAngle = cos(angle * angleConversion); #Horizontal angle is calculated by cos formula, angle conversion puts the angle in Radians
	var horizontalVelocity = initialVelocity * horizontalAngle; #Horizontal velocity is found by multiplying initial velocity by horizontal angle
	horizontalVelocity = round(horizontalVelocity * 100000) / 100000; #Round to a whole number
	return horizontalVelocity;

func getVerticalVelocity (knockback, angle):
	var initialVelocity = knockback * 30;
	var verticalAngle = sin(angle * angleConversion);
	var verticalVelocity = initialVelocity * verticalAngle;
	verticalVelocity = round(verticalVelocity * 100000) / 100000;
	return verticalVelocity;

func getHitstun(knockback):
	#return floor(knockback * 0.533);
	return floor(knockback * 0.4);
	
func hitlag(d,hit):
	damage = d
	hitlag_modifier = hit
	return floor((((floor(d) * 0.65) + 6) * hit))
