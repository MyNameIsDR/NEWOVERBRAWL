extends CharacterBody2D

#GLOBAL VARS
var frame = 0
@export var vibration = 0
@export var id: int

#ATTRIBUTES
@export var percentage = 0
@export var stocks = 3
@export var weight = 100
var freezeframes = 0

#BUFFERS
var l_cancel = 0
var cooldown = 0
var shield_buffer = 0

#KNOCKBACK
var hdecay
var vdecay
var knockback
var hitstun
var connected:bool

#GROUND VARS
var dash_duration = 10

#LANDING VARS
var landing_frames = 0
var lag_frames = 0
var down_buffer = 0

#AIR VARS
var jump_squat = 3
var fastfall = false
var airJump = 0
@export var airJumpMax = 1

#LEDGE VARS
var last_ledge = false
var regrab = 30
var catch = false

#HITBOX VARS
@export var hitbox: PackedScene
@export var projectile: PackedScene
@export var grabbox: PackedScene
@export var hitbox_scene: PackedScene
var selfState

#TEMPORARY VARIABLES
var hit_pause = 0
var hit_pause_dur = 0
var temp_pos = Vector2(0,0)
var temp_vel = Vector2(0,0)

#ATTACKS
var projectile_cooldown = 0
var grabbing = false

#ONREADY VARS
@onready var Ground_L = get_node("Raycasts/Ground_L")
@onready var Ground_R = get_node("Raycasts/Ground_R")
@onready var anim = $Sprite2D/AnimationPlayer
@onready var Ledge_Grab_F = get_node("Raycasts/Ledge_Grab_F")
@onready var Ledge_Grab_B = get_node("Raycasts/Ledge_Grab_B")
@onready var gun_pos = get_node("gun_pos")
@onready var hurtbox = %Hurtbox
@onready var parrybox = %Parrybox

var jab_hitbox = null
var jab_active = false

#FOX'S MAIN ATTRIBUTES
var RUNSPEED = 340 * 2
var DASHSPEED = 390 * 2
var WALKSPEED = 200 * 2
var GRAVITY = 1800 * 2
var JUMPFORCE = 500 * 2
var MAX_JUMPFORCE = 800 * 2
var DOUBLEJUMPFORCE = 1000 * 2
var MAXAIRSPEED = 300 * 2
var AIR_ACCEL = 25 * 2
var FALLSPEED = 60 * 2
var FALLINGSPEED = 600 * 2
var MAXFALLSPEED = 600 * 2
var TRACTION = 40 * 2
var ROLL_DISTANCE = 350 * 2
var air_dodge_speed = 500 * 2
var UP_B_LAUNCHSPEED = 700 * 2

func create_hitbox(width, height, damage, angle, base_kb, kb_scaling, duration, type, points, angle_flipper, hitlag=1):
	var hitbox_instance = hitbox.instantiate()
	self.add_child(hitbox_instance)
	#rotates the points
	if direction() == 1:
		hitbox_instance.set_parameters(width, height, damage, angle, base_kb, kb_scaling, duration, type, points, angle_flipper, hitlag)
	else:
		var flip_x_points = Vector2(-points.x, points.y)
		hitbox_instance.set_parameters(width, height, damage, -angle+180, base_kb, kb_scaling, duration, type, flip_x_points, angle_flipper, hitlag)
	return hitbox_instance

func create_grabbox(width,height,damage,duration,points):
	var grabbox_instance = grabbox.instantiate()
	self.add_child(grabbox_instance)
	#rotates the points
	if direction() == 1:
		grabbox_instance.set_parameters(width, height, damage, duration, points)
	else:
		var flip_x_points = Vector2(-points.x, points.y)
		grabbox_instance.set_parameters(width,height,damage,duration,flip_x_points)
	return grabbox_instance

func create_projectile(dir_x, dir_y, point):
	#Instance projectile
	var projectile_instance = projectile.instantiate()
	projectile_instance.player_list.append(self)
	get_parent().add_child(projectile_instance)
	#sets position
	gun_pos.set_position(point)
	#Flips the direction
	if direction() == 1:
		projectile_instance.dir(dir_x, dir_y)
		projectile_instance.set_global_position(gun_pos.get_global_position())
	else:
		gun_pos.position.x = -gun_pos.position.x
		projectile_instance.dir(-(dir_x), dir_y)
		projectile_instance.set_global_position(gun_pos.get_global_position())
	return projectile_instance


@onready var states = $State

func updateframes(delta):
	frame += floor(delta * 60)
	l_cancel -= floor(delta * 60)
	clampi(l_cancel, 0, l_cancel)
	cooldown -= floor(delta * 60)
	cooldown = clampi(cooldown, 0, cooldown)
	if not Input.is_action_pressed("shield_%s" % id):
		shield_buffer = 0
	elif Input.is_action_pressed("shield_%s" % id):
		shield_buffer += floor(delta * 60)
	if freezeframes > 0:
		freezeframes -= floor(delta * 60)	
	freezeframes = clampi(freezeframes, 0, freezeframes)

func turn(direction):
	var dir = 0
	if direction:
		dir = -1
	else:
		dir = 1
	$Sprite2D.set_flip_h(direction)
	Ledge_Grab_F.set_target_position(Vector2(dir*abs(Ledge_Grab_F.get_target_position().x), Ledge_Grab_F.get_target_position().y))
	Ledge_Grab_F.position.x = dir * abs(Ledge_Grab_F.position.x)
	Ledge_Grab_B.position.x = dir * abs(Ledge_Grab_B.position.x)
	Ledge_Grab_B.set_target_position(Vector2(-dir*abs(Ledge_Grab_F.get_target_position().x), Ledge_Grab_F.get_target_position().y))	
	
func direction():
	if Ledge_Grab_F.get_target_position().x > 0:
		return 1
	else:
		return -1

func _frame():
	frame = 0
	
func play_animation(animation_name):
	anim.play(animation_name)
	
func reset_Jumps():
	airJump = airJumpMax	

func reset_ledge():
	last_ledge = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass 

func _physics_process(delta):
	$Frames.text = str(frame)

#SPECIAL ATTACKS
func NEUTRAL_SPECIAL():
	var vibration = 2
	if frame == 4:
		create_projectile(1,0,Vector2(46,3))
	if frame == 14:
		return true

#TILT ATTACKS
func DOWN_TILT():
	var vibration = 1
	if frame == 5:
		create_hitbox(40, 20, 8, 90, 3, 120, 3, "normal", Vector2(60,34), 0, 1)
	if frame >= 10:
		return true

func UP_TILT():
	var vibration = 1
	if frame == 5:
		create_hitbox(48, 68, 8, 90, 50, 100, 3, "normal", Vector2(-22,-15), 0, 1)
	if frame >= 12:
		return true

func FORWARD_TILT():
	var vibration = 1
	if frame == 3:
		create_hitbox(52, 20, 6, 60, 40, 150, 3, "normal", Vector2(22, 8), 0, 1)
	if frame >= 8:
		return true

func JAB():
	var vibration = 1
	#if frame == 1 and !hitbox_created:
	#	var hitbox = hitbox_scene.instantiate()
	#	hitbox.attack_type = "jab"
	#	add_child(hitbox)
	#	hitbox_created = true
	if frame == 2:
		create_grabbox(30, 40, 0, 3, Vector2(63,0))
	if frame == 5:
		if grabbing == true:
			return false
	if frame >= 20:
	#	hitbox_created = false
		return true
		
func JAB_1():
	var vibration = 3	
	if frame == 1:
		grabbing = false
		create_grabbox(30, 40, 0, 13, Vector2(63, 0))
	if frame == 12:
		create_hitbox(40, 20, 9, 90, 4000, 20, 9, "normal", Vector2(48, 8), 0, 0	)
	if  frame == 32:
		return true

func _hit_pause(delta):
		if hit_pause < hit_pause_dur:
			self.position = temp_pos
			hit_pause += floor((1*delta)*60)
		else:
			if temp_vel != Vector2(0,0):
				self.velocity.x = temp_vel.x
				self.velocity.y = temp_vel.y
				temp_vel = Vector2(0,0)
			hit_pause_dur = 0
			hit_pause = 0

func NAIR():
	var vibration = 1
	if frame == 1:
		create_hitbox(56,56,12,361,0,100,3,'normal',Vector2(0,0),0,.4)
	if frame > 1:
		if connected == true:
			#print("sweetspot")
			if frame == 36:
				connected = false
				return true
		else:
			if frame == 5:
				create_hitbox(46,56,9,361,0,100,10,'normal',Vector2(0,0),0,.1)
			if frame == 36:
				return true

func UAIR():
	var vibration = 1
	if frame == 2:
		create_hitbox(32,36,5,90,130,0,2,'normal',Vector2(0,-45),0,.1)
	if frame == 6:
		create_hitbox(56,46,10,90,20,108,3,'normal',Vector2(0,-48),0,.2)
	if frame == 15:
		return true

func BAIR():
	var vibration = 1
	if frame == 2:
		create_hitbox(52,55,15,45,1,100,5,'normal',Vector2(-47,7),6,1)
	if frame > 1:
		if connected == true:
			#print("sweetspot")
			if frame == 18:
				connected = false
				return true
		else:
			if frame == 7:
				create_hitbox(52,55,5,45,3,140,10,'normal',Vector2(-47,7),6,1)
			if frame == 18:
				return true

func FAIR():
	vibration = 1
	if frame == 2:
		create_hitbox(35,47,3,76,10,150,3,'normal',Vector2(60,-7),0,1)
	if frame == 11:
		create_hitbox(35,47,3,76,10,150,3,'normal',Vector2(60,-7),0,1)
	if frame == 18:
		return true

func DAIR():
	var vibration = 1
	if frame == 2:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 3:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 5:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 7:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 9:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 11:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 14:
		create_hitbox(36,58,4,45,12,120,2,'normal',Vector2(28,17),0,1)
	if frame == 17:
		return true
