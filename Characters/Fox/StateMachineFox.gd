extends StateMachine
@onready var id = get_parent().id

func _ready():
	add_state('STAND')
	add_state('RUN')
	add_state('JUMP_SQUAT')
	add_state('SHORT_HOP')
	add_state('TURN')
	add_state('FULL_HOP')
	add_state('DASH')
	add_state('MOONWALK')
	add_state('WALK')
	add_state('CROUCH')
	add_state('AIR')
	add_state('LANDING')
	add_state('LEDGE_CATCH')
	add_state('LEDGE_HOLD')
	add_state('LEDGE_CLIMB')
	add_state('LEDGE_JUMP')
	add_state('LEDGE_ROLL')
	add_state('HITFREEZE')
	add_state('HITSTUN')
	add_state("PARRY")
	add_state("ROLL_RIGHT")
	add_state("ROLL_LEFT")
	add_state('GRABBED')
	add_state('STUNNED')	
	add_state('GROUND_ATTACK')
	add_state('JAB')
	add_state('JAB_1')	
	add_state('DOWN_TILT')
	add_state('UP_TILT')
	add_state('FORWARD_TILT')
	add_state('NEUTRAL_SPECIAL')	
	add_state('AIR_ATTACK')
	add_state('NAIR')
	add_state('UAIR')
	add_state('BAIR')
	add_state('FAIR')
	add_state('DAIR')
	call_deferred("set_state", states.STAND)

func state_logic(delta):
	parent.updateframes(delta)
	parent._physics_process(delta)
	if parent.regrab > 0:
		parent.regrab -= 1
	parent._hit_pause(delta)

func get_transition(delta):
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `Vector2.ZERO`
	parent.set_up_direction(Vector2.UP)
	parent.move_and_slide()
	
	if Input.is_action_just_pressed("attack_%s" % id) && TILT() == true:
		parent._frame()
		return states.GROUND_ATTACK
	
	if Landing() == true:
		parent._frame()
		return states.LANDING
	
	if Falling() == true:
		return states.AIR
		
	if Ledge() == true:
		parent._frame()
		return states.LEDGE_CATCH
	else:
		parent.reset_ledge()
		
	if Input.is_action_just_pressed("special_%s" % id) && SPECIAL() == true:
		parent._frame()
		return states.NEUTRAL_SPECIAL

	if Input.is_action_just_pressed("attack_%s" % id) && AIREAL() == true:
		if Input.is_action_pressed("up_%s" % id):
			parent._frame()
			return states.UAIR
		if Input.is_action_pressed("down_%s" % id):
			parent._frame()
			return states.DAIR
		match parent.direction():
			1:
				if Input.is_action_pressed("left_%s" % id):
					parent._frame()
					return states.BAIR
				if Input.is_action_pressed("right_%s" % id):
					parent._frame()
					return states.FAIR
			-1:
				if Input.is_action_pressed("right_%s" % id):
					parent._frame()
					return states.BAIR
				if Input.is_action_pressed("left_%s" % id):
					parent._frame()
					return states.FAIR
		parent._frame()
		return states.NAIR	

	if Input.is_action_just_pressed("shield_%s" % id) && AIREAL() && parent.cooldown == 0:
		parent.l_cancel = 11
		parent.cooldown = 40
		print("L cancel is true")
		
	if Input.is_action_pressed("shield_%s" % id) && can_roll() == true && parent.cooldown == 0 && parent.shield_buffer == 2:
		if Input.is_action_pressed("right_%s" % id):
			parent._frame()
			return states.ROLL_RIGHT
		elif Input.is_action_pressed("left_%s" % id):
			parent._frame()
			return states.ROLL_LEFT
		else:
			parent._frame()
			return states.PARRY

	match state:
		states.STAND:
			parent.reset_Jumps()
			if Input.is_action_just_pressed("jump_%s" % id):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_pressed("down_%s" % id):
				parent._frame()
				return states.CROUCH
			if Input.get_action_strength("right_%s" % id) == 1:
				parent.velocity.x = parent.RUNSPEED
				parent._frame()
				parent.turn(false)
				return states.DASH
			if Input.get_action_strength("left_%s" % id) == 1:
				parent.velocity.x = -parent.RUNSPEED
				parent._frame()
				parent.turn(true)
				return states.DASH
			if parent.velocity.x > 0 and state == states.STAND:
				parent.velocity.x += -parent.TRACTION*1
				parent.velocity.x = clampf(parent.velocity.x,0,parent.velocity.x)
			elif parent.velocity.x < 0 and state == states.STAND:
				parent.velocity.x += parent.TRACTION*1
				parent.velocity.x = clampf(parent.velocity.x,parent.velocity.x,0)
				
		states.JUMP_SQUAT:
			if parent.frame == parent.jump_squat:
				if not Input.is_action_pressed("jump_%s" % id):
					parent.velocity.x = lerpf(parent.velocity.x,0,0.08)
					parent._frame()
					return states.SHORT_HOP
				else:
					parent.velocity.x = lerpf(parent.velocity.x,0,0.08)
					parent._frame()
					return states.FULL_HOP
					
		states.SHORT_HOP:
			parent.velocity.y = -parent.JUMPFORCE
			parent._frame()
			return states.AIR
			
		states.FULL_HOP:
			parent.velocity.y = -parent.MAX_JUMPFORCE
			parent._frame()
			return states.AIR
			
		states.DASH:
			if Input.is_action_pressed("jump_%s" % id):
				parent._frame()
				return states.JUMP_SQUAT
					
			elif Input.is_action_pressed("left_%s" % id):
				if parent.velocity.x > 0:
					parent._frame()
				parent.velocity.x = -parent.DASHSPEED
				if parent.frame <= parent.dash_duration-1:
					if Input.is_action_just_pressed("down%s" % id):
						parent._frame()
						return states.MOONWALK
					parent.turn(true)
					return states.DASH
				else:
					parent.turn(true)
					parent._frame()
					return states.RUN
					
			elif Input.is_action_pressed("right_%s" % id):
				if parent.velocity.x < 0:
					parent._frame()
				parent.velocity.x = parent.DASHSPEED
				if parent.frame <= parent.dash_duration-1:
					if Input.is_action_just_pressed("down%s" % id):
						parent._frame()
						return states.MOONWALK
					parent.turn(false)
					return states.DASH
				else:
					parent.turn(false)
					parent._frame()
					return states.RUN
			else:
				if parent.frame >= parent.dash_duration-1:
					for state in states:
						if state != "JUMP_SQUAT":
							parent._frame()
							return states.STAND
							
		states.RUN:
			if Input.is_action_just_pressed("jump_%s" % id):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_pressed("down_%s" % id):
				parent._frame()
				return states.CROUCH
			if Input.get_action_strength("left_%s" % id):
				if parent.velocity.x <= 0:
					parent.velocity.x = -parent.RUNSPEED
					parent.turn(true)
				else:
					parent._frame()
					return states.TURN
			
			elif Input.get_action_strength("right_%s" % id):
				if parent.velocity.x >= 0:
					parent.velocity.x = parent.RUNSPEED
					parent.turn(false)
				else:
					parent._frame()
					return states.TURN
			
			else:
				parent._frame()
				return states.STAND
				
		states.TURN:
			if Input.is_action_just_pressed("jump_%s" % id):
				parent._frame()
				return states.JUMP_SQUAT
			if parent.velocity.x > 0:
				parent.turn(true)
				parent.velocity.x += -parent.TRACTION*2
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0:
				parent.turn(false)
				parent.velocity.x += parent.TRACTION*2
				parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			else:
				if not Input.is_action_pressed("left_%s" % id) and not	Input.is_action_pressed("right_%s" % id):
					parent._frame()
					return states.STAND
				else:
					parent._frame()
					return states.RUN		
			
		states.MOONWALK:
			if Input.is_action_just_pressed("jump_%s" % id):
				parent._frame()
				return states.JUMP_SQUAT
			
			elif Input.is_action_just_pressed("left_%s" % id) && parent.direction() == 1:
				if parent.velocity.x > 0:
					parent._frame()
				parent.velocity.x += -parent.AIR_ACCEL * Input.get_action_strength("left_%s" % id)
				parent.velocity.x = clampf(parent.velocity.x, -parent.DASHSPEED*1.4, parent.velocity.x)
				if parent.frame <= parent.dash_duration*2:
					parent.turn(false)
					return states.MOONWALK
				else:
					parent.turn(true)
					parent._frame()
					return states.STAND
					
			elif Input.is_action_pressed("right_%s" % id) && parent.direction == -1:
				if parent.velocity.x < 0:
					parent._frame()
				parent.velocity.x += parent.AIR_ACCEL * Input.get_action_strength("right_%s" % id)
				parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, parent.DASHSPEED*1.5)
				if parent.frame <= parent.dash_duration*2:
					parent.turn(true)
					return states.MOONWALK
				else:
					parent.turn(false)
					parent._frame()
					return states.STAND
				
			else:
				if parent.frame >= parent.dash_duration-1:
					for state in states:
						if states != "JUMP_SQUAT":
							return states.STAND
				
		
		states.WALK:
			if Input.is_action_just_pressed("jump_%s" % id):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_pressed("down_%s" % id):
				parent._frame()
				return states.CROUCH
			if Input.get_action_strength("left_%s" % id):
				parent.velocity.x = -parent.WALKSPEED * Input.get_action_strength("left_%s" % id)
				parent.turn(true)
			elif Input.get_action_strength("right_%s" % id):
				parent.velocity.x = parent.WALKSPEED * Input.get_action_strength("left_%s" % id)
				parent.turn(false)
			else:
				parent._frame()
				return states.STAND
				
		states.CROUCH:		
			if Input.is_action_just_pressed("jump_%s" % id):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_released("down_%s" % id):
				parent._frame()
				return states.STAND
			elif parent.velocity.x > 0:
				if parent.velocity.x > parent.RUNSPEED:
					parent.velocity.x += -(parent.TRACTION*4)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				else:
					parent.velocity.x += -(parent.TRACTION/2)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)	
			elif parent.velocity.x < 0:				
				if abs(parent.velocity.x) > parent.RUNSPEED:
					parent.velocity.x += (parent.TRACTION/4)
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
				else:
					parent.velocity.x += (parent.TRACTION/2)
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)

		states.AIR:
			AIRMOVEMENT()
			if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
				parent.fastfall = false
				parent.velocity.x = 0
				parent.velocity.y = -parent.DOUBLEJUMPFORCE
				parent.airJump -= 1
				if Input.is_action_pressed("left_%s" % id):
					parent.velocity.x = -parent.MAXAIRSPEED
				elif Input.is_action_pressed("right_%s" % id):
					parent.velocity.x = parent.MAXAIRSPEED
			if Input.is_action_just_pressed("special_%s" % id):
				parent._frame()
				return states.NEUTRAL_SPECIAL

		states.LANDING:
			if parent.frame == 1:
				if parent.l_cancel > 0:
					parent.lag_frames = floor(parent.lag_frames/2)
			if parent.frame <= parent.landing_frames + parent.lag_frames:
				if parent.velocity.x > 0:
					parent.velocity.x = parent.velocity.x - parent.TRACTION/2
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x = parent.velocity.x + parent.TRACTION/2
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
				if Input.is_action_just_pressed("jump_%s" % id): #and Input.is_action_pressed("shield"):
					parent._frame()
					return states.JUMP_SQUAT
			else:
				if Input.is_action_pressed("down_%s" % id):
					parent.lag_frames = 0
					parent._frame()
					parent.reset_Jumps()
					return states.CROUCH
				else:
					parent._frame()
					parent.lag_frames = 0
					parent.reset_Jumps()
					return states.STAND
				parent.lag_frames = 0

		states.LEDGE_CATCH:
			if parent.frame > 7:
				parent.lag_frames = 0
				parent.reset_Jumps()
				parent._frame()
				return states.LEDGE_HOLD

		states.LEDGE_HOLD:
			if parent.frame >= 390: #3.5 seconds
				self.parent.position.y += -25
				parent._frame()
				return states.AIR #LATER ITS "TUMBLE"
			if Input.is_action_just_pressed("down_%s" % id):
				parent.fastfall = true
				parent.regrab = 30
				parent.reset_ledge()
				self.parent.position.y += -25
				parent.catch = false
				parent._frame()
				return states.AIR
				
			#Facing right
			elif parent.Ledge_Grab_F.get_target_position().x > 0:
				if Input.is_action_just_pressed("left_%s" % id):
					parent.velocity.x = (parent.AIR_ACCEL/2)
					parent.regrab = 30
					parent.reset_ledge()
					self.parent.position.y += -25
					parent.catch = false
					parent._frame()
					return states.AIR
				elif Input.is_action_just_pressed("right_%s" % id):
					parent._frame()
					return states.LEDGE_CLIMB
				elif Input.is_action_just_pressed("shield_%s" % id):
					parent._frame()
					return states.LEDGE_ROLL
				elif Input.is_action_just_pressed("jump_%s" % id):
					parent._frame()
					return states.LEDGE_JUMP
					
			#Facing left
			elif parent.Ledge_Grab_F.get_target_position().x < 0:
				if Input.is_action_just_pressed("right_%s" % id):
					parent.velocity.x = (parent.AIR_ACCEL/2)
					parent.regrab = 30
					parent.reset_ledge()
					self.parent.position.y += -25
					parent._frame()
					return states.AIR
				elif Input.is_action_just_pressed("left_%s" % id):
					parent._frame()
					return states.LEDGE_CLIMB
				elif Input.is_action_just_pressed("shield_%s" % id):
					parent._frame()
					return states.LEDGE_ROLL
				elif Input.is_action_just_pressed("jump_%s" % id):
					parent._frame()
					return states.LEDGE_JUMP

		states.LEDGE_CLIMB:
			if parent.frame == 1:
				pass
			if parent.frame == 5:
				parent.position.y -= 25
			if parent.frame == 10:
				parent.position.y -= 25
			if parent.frame == 20:
				parent.position.y -= 25
			if parent.frame == 22:
				parent.catch == false
				parent.position.y -= 25
				parent.position.x += 50 * parent.direction()
			if parent.frame == 25:
				parent.velocity.y = 0
				parent.velocity.x = 0
				parent.move_and_collide(Vector2(parent.direction()*20, 50))
			if parent.frame == 30:
				parent.reset_ledge()
				parent._frame()
				return states.STAND	

		states.LEDGE_JUMP:
			if parent.frame > 14:
				if Input.is_action_just_pressed("attack_%s" % id):
					parent._frame()
					return states.AIR_ATTACK
				if Input.is_action_just_pressed("special_%s" % id):
					parent._frame()
					return states.SPECIAL
			if parent.frame == 5:
				parent.reset_ledge()
				parent.position.y -= 20
			if parent.frame == 10:
				parent.catch = false
				parent.position.y -= 20
				if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.airJump -= 1
					parent._frame()
					return states.AIR
			if parent.frame == 15:		
				parent.position.y -= 20
				parent.velocity.y = -parent.DOUBLEJUMPFORCE#*1.5
				parent.velocity.x += 220*parent.direction()			
				if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.airJump -= 1
					parent._frame()
					return states.AIR
			if Input.is_action_just_pressed("attack_%s" % id):
				parent._frame()
				return states.AIR_ATTACK
			elif parent.frame > 15 and parent.frame < 20:
				parent.velocity.y += parent.FALLSPEED
				if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.airJump -= 1
					parent._frame()
					return states.AIR
				if Input.is_action_just_pressed("attack_%s" % id):
					parent._frame()
					return states.AIR_ATTACK
			if parent.frame == 20:
				parent._frame()
				return states.AIR

		states.LEDGE_ROLL:
			print("roll")
			if parent.frame == 1:
				pass
			if parent.frame == 5:
				parent.position.y -= 30
			if parent.frame == 10:
				parent.position.y -= 30
			
			if parent.frame == 22:
				parent.position.y -= 30
				parent.position.x += 50*parent.direction()
				
			if parent.frame == 29:
				parent.move_and_collide(Vector2(parent.direction()*20,50))
			if parent.frame == 30:
				parent.velocity.y = 0
				parent.velocity.x = 0
				parent.reset_ledge()
				parent._frame()
				return states.STAND

		states.HITFREEZE:
			if parent.freezeframes == 0:
				parent._frame()
				parent.velocity.x = kbx
				parent.velocity.y = kby
				parent.hdecay = hd
				parent.vdecay = vd
				return states.HITSTUN
			parent.position = pos

		states.HITSTUN:
			if parent.knockback >= 0:#3 #0 IS CHANGEABLE
				var bounce = parent.move_and_collide(parent.velocity * delta)
				#if bounce:
				#	parent.velocity = parent.velocity.bounce(bounce.get_normal()) * .8
				#	parent.hitstun = round(parent.hitstun * .8)
				if parent.is_on_wall():
					parent.velocity.x = kbx - parent.velocity.x
					parent.velocity = parent.velocity.bounce(parent.get_wall_normal()) * .8
					parent.hdecay *= -1
					parent.hitstun = round(parent.hitstun * .8)
				if parent.is_on_floor():
					parent.velocity.y = kby - parent.velocity.y
					parent.velocity = parent.velocity.bounce(parent.get_floor_normal()) * .8
					parent.hitstun = round(parent.hitstun * .8)
			if parent.velocity.y < 0:
				parent.velocity.y += parent.vdecay*0.5 * Engine.time_scale
				parent.velocity.y = clampf(parent.velocity.y, parent.velocity.y, 0)
			if parent.velocity.x < 0:
				parent.velocity.x += parent.hdecay*0.4 *-1 * Engine.time_scale
				parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			elif parent.velocity.x > 0:
				parent.velocity.x -= parent.hdecay*0.4 * Engine.time_scale
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				
			if parent.frame >= parent.hitstun:
				if parent.knockback >= 24:
					parent._frame()
					return states.AIR
				else:
					parent._frame()
					return states.AIR
			elif parent.frame > 60 *5:
				return states.AIR

		states.PARRY:
			if parent.velocity.x > 0:
				parent.velocity.x += -parent.TRACTION*10
				parent.velocity.x = clampi(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0:
				parent.velocity.x += parent.TRACTION*10
				parent.velocity.x = clampi(parent.velocity.x, parent.velocity.x, 0)
			if parent.frame >= 3 && parent.frame <= 10:
				parent.hurtbox.disabled = true
				parent.parrybox.disabled = false
			if parent.frame >= 11:
				parent.hurtbox.disabled = false
				parent.parrybox.disabled = true
			if parent.frame == 30:
				parent._frame()
				return states.STAND
		
		states.ROLL_RIGHT:
			parent.turn(true)
			if parent.frame == 1:
				parent.velocity.x = 0
			if parent.frame == 4:
				parent.velocity.x = parent.ROLL_DISTANCE
				parent.hurtbox.disabled = true
			if parent.frame == 20:
				parent.hurtbox.disabled = false
			if parent.frame > 19:
				parent.velocity.x = parent.velocity.x - parent.TRACTION*5
				parent.velocity.x = clampi(parent.velocity.x, 0, parent.velocity.x)
				if parent.velocity.x == 0:
					parent.cooldown = 20
					parent.lag_frames = 10
					parent._frame()
					return states.LANDING		
		
		states.ROLL_LEFT:
			parent.turn(false)
			if parent.frame == 1:
				parent.velocity.x = 0
			if parent.frame == 4:
				parent.velocity.x = -parent.ROLL_DISTANCE
				parent.hurtbox.disabled = true
			if parent.frame == 20:
				parent.hurtbox.disabled = false
			if parent.frame > 19:
				parent.velocity.x = parent.velocity.x + parent.TRACTION*5
				parent.velocity.x = clampi(parent.velocity.x, parent.velocity.x, 0)
				if parent.velocity.x == 0:
					parent.cooldown = 20
					parent.lag_frames = 10
					parent._frame()
					return states.LANDING	
		
		states.NEUTRAL_SPECIAL:
			if AIREAL() == false:
					if parent.velocity.x > 0:
						if parent.velocity.x > parent.DASHSPEED:
							parent.velocity.x = parent.DASHSPEED
						parent.velocity.x = parent.velocity.x - parent.TRACTION*10
						parent.velocity.x = clampi(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						if parent.velocity.x < -parent.DASHSPEED:
							parent.velocity.x = -parent.DASHSPEED
						parent.velocity.x = parent.velocity.x + parent.TRACTION*10
						parent.velocity.x = clampi(parent.velocity.x,parent.velocity.x,0)

			if AIREAL() == true:
				AIRMOVEMENT()
			if parent.frame <= 1:
				if parent.projectile_cooldown == 1:
					parent.projectile_cooldown = -1
				if parent.projectile_cooldown == 0:
					parent.projectile_cooldown += 1
					parent._frame()
					parent.NEUTRAL_SPECIAL()
			if parent.frame < 14:#lines from here to return.states.NEUTRAL_SPECIAL and also the line if parent.frame == 14 r specific to Fox
				if Input.is_action_just_pressed("special_%s" % id):
					parent._frame()
					return states.NEUTRAL_SPECIAL
			if parent.NEUTRAL_SPECIAL() == true:
				if AIREAL() == true:
					return states.AIR
				if AIREAL() == false:
					if parent.frame == 14:
						parent._frame()
						return states.STAND


		states.AIR_ATTACK:
			AIRMOVEMENT()
			if Input.is_action_pressed("up_%s" % id):
				parent._frame()
				return states.UAIR
			if Input.is_action_pressed("down_%s" % id):
				parent._frame()
				return states.DAIR
			match parent.direction():
				1:
					if Input.is_action_pressed("left_%s" % id):
						parent._frame()
						return states.BAIR
					if Input.is_action_pressed("right_%s" % id):
						parent._frame()
						return states.FAIR
				-1:
					if Input.is_action_pressed("right_%s" % id):
						parent._frame()
						return states.BAIR
					if Input.is_action_pressed("left_%s" % id):
						parent._frame()
						return states.FAIR
			parent._frame()
			return states.NAIR

		states.NAIR:
			AIRMOVEMENT()
			if parent.frame == 0:
				print("nair")
				parent.NAIR()
			if parent.NAIR() == true:
				parent.lag_frames = 0
				parent._frame()
				return states.AIR
			elif parent.frame < 5:
				parent.lag_frames = 0
			elif parent.frame > 15:
				parent.lag_frames = 0
			else:
				parent.lag_frames = 7

		states.UAIR:
			AIRMOVEMENT()
			if parent.frame == 0:
				print("uair")
				parent.UAIR()
			if parent.UAIR() == true:
				parent.lag_frames = 0
				parent._frame()
				return states.AIR
			else:
				parent.lag_frames = 13

		states.BAIR:
			AIRMOVEMENT()
			if parent.frame == 0:
				print("bair")
				parent.BAIR()
			if parent.BAIR() == true:
				parent.lag_frames = 0
				parent._frame()
				return states.AIR
			else:
				parent.lag_frames = 9

		states.FAIR:
			AIRMOVEMENT()

			if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
				parent.fastfall = false
				parent.velocity.x = 0
				parent.velocity.y = -parent.DOUBLEJUMPFORCE
				parent.airJump -= 1
				if Input.is_action_pressed("left_%s" % id):
					parent.velocity.x = -parent.MAXAIRSPEED
				elif Input.is_action_pressed("right_%s" % id):
					parent.velocity.x = parent.MAXAIRSPEED
				return states.AIR
			if parent.frame == 0:
				print('fair')
				parent.FAIR()
			if parent.FAIR() == true:
				parent.lag_frames = 30
				parent._frame()
				return states.FAIR
			else:
				parent.lag_frames = 18

		states.DAIR:
			AIRMOVEMENT()
			if parent.frame == 0:
				print('bair')
				parent.DAIR()
			if parent.DAIR() == true:
				parent.lag_frames = 0
				return states.AIR
			else:
				parent.lag_frames = 17

		states.GROUND_ATTACK:
			if Input.is_action_pressed("up_%s" % id):
				parent._frame()
				return states.UP_TILT
			if Input.is_action_pressed("dtilt_%s" % id) or Input.is_action_pressed("down_%s" % id):
				parent._frame()
				return states.DOWN_TILT
			if Input.is_action_pressed("left_%s" % id):
				parent.turn(true)
				parent._frame()
				return states.FORWARD_TILT
			if Input.is_action_pressed("right_%s" % id):
				parent.turn(false)
				parent._frame()
				return states.FORWARD_TILT
			parent._frame()
			return states.JAB

		states.DOWN_TILT:
			if parent.frame == 0:
				parent.DOWN_TILT()
				pass
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION*3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION*3
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			if parent.DOWN_TILT() == true:
				if Input.is_action_pressed("down_%s" % id):
					parent._frame()
					return states.CROUCH
				else:
					parent._frame()
					return states.STAND	
		
		states.UP_TILT:
			if parent.frame == 0:
				parent.UP_TILT()
				pass
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION*3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION*3
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			if parent.UP_TILT() == true:
				if Input.is_action_pressed("up_%s" % id):
					parent._frame()
					return states.AIR
				else:
					parent._frame()
					return states.STAND	
		
		states.FORWARD_TILT:
			if parent.frame == 0:
				parent.FORWARD_TILT()
				pass
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION*3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION*3
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			if parent.FORWARD_TILT() == true:
				if Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent._frame()
					return states.RUN
				if Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent._frame()
					return states.RUN
				else:
					parent._frame()
					return states.STAND	
		
		states.JAB:
			if parent.frame <= 1:
				if parent.velocity.x > 0:
					if parent.velocity.x > parent.DASHSPEED:
						parent.velocity.x = parent.DASHSPEED
					parent.velocity.x = parent.velocity.x - parent.TRACTION*20
					parent.velocity.x = clamp(parent.velocity.x,0,parent.velocity.x)
				elif parent.velocity.x < 0:
					if parent.velocity.x < -parent.DASHSPEED:
						parent.velocity.x = -parent.DASHSPEED
					parent.velocity.x = parent.velocity.x + parent.TRACTION*20
					parent.velocity.x = clamp(parent.velocity.x,parent.velocity.x,0)
				parent.JAB()
			if parent.JAB() == true:
				if Input.is_action_pressed("down_%s" % id):
					parent._frame()
					return states.CROUCH
				else:
					parent._frame()
					return states.STAND
			if parent.JAB() == false:
				parent._frame()
				return states.JAB_1
		
		states.JAB_1:
			if parent.frame <= 1:
				if parent.velocity.x > 0:
					if parent.velocity.x > parent.DASHSPEED:
						parent.velocity.x = parent.DASHSPEED
					parent.velocity.x = parent.velocity.x - parent.TRACTION*20
					parent.velocity.x = clamp(parent.velocity.x,0,parent.velocity.x)
				elif parent.velocity.x < 0:
					if parent.velocity.x < -parent.DASHSPEED:
						parent.velocity.x = -parent.DASHSPEED
					parent.velocity.x = parent.velocity.x + parent.TRACTION*20
					parent.velocity.x = clamp(parent.velocity.x,parent.velocity.x,0)
				parent.JAB_1()
			if parent.JAB_1() == true:
				if Input.is_action_pressed("down_%s" % id):
					parent._frame()
					return states.CROUCH
				else:
					parent._frame()
					return states.STAND


		
		states.GRABBED:
			for body in get_tree().get_nodes_in_group("Character"):
				if body.name == temp_body:
					if body.get_node("StateMachine").state != temp_state:
						return states.STAND
		
		states.STUNNED:
			if parent.frame >= 60*5:#possibly make 5 a var
				parent._frame()
				return states.STAND
			else:
				if parent.is_on_floor() == true:
					if parent.velocity.x > 0:
						if parent.velocity.x > parent.DASHSPEED:
							parent.velocity.x = parent.DASHSPEED
						parent.velocity.x = parent.velocity.x - parent.TRACTION
						parent.velocity.x = clampi(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						if parent.velocity.x < -parent.DASHSPEED:
							parent.velocity.x = -parent.DASHSPEED
						parent.velocity.x = parent.velocity.x + parent.TRACTION
						parent.velocity.x = clampi(parent.velocity.x, parent.velocity.x, 0)
				if parent.is_on_floor() == false:
					AIRMOVEMENT()

func enter_state(new_state, old_state):
	match new_state:
		states.STAND:
			parent.play_animation("Idle")
			parent.states.text = str("STAND")
		states.DASH:
			parent.play_animation("Dash")
			parent.states.text = str("DASH")
		states.MOONWALK:
			parent.play_animation("Walk")
			parent.states.text = str("MOONWALK")
		states.TURN:
			parent.play_animation("Turn")
			parent.states.text = str("TURN")
		states.CROUCH:
			parent.play_animation("Crouch")
			parent.states.text = str("CROUCH")
		states.RUN:
			parent.play_animation("Run")
			parent.states.text = str("RUN")
		states.JUMP_SQUAT:
			parent.play_animation("Jump_Squat")
			parent.states.text = str("JUMP_SQUAT")
		states.SHORT_HOP:
			parent.play_animation("Air")
			parent.states.text = str("SHORT_HOP")
		states.FULL_HOP:
			parent.play_animation("Air")
			parent.states.text = str("FULL_HOP")
		states.AIR:
			parent.play_animation("Air")
			parent.states.text = str("AIR")
		states.LANDING:
			parent.play_animation("Landing")
			parent.states.text = str("LANDING")
		states.LEDGE_CATCH:
			parent.play_animation("Ledge_Catch")
			parent.states.text = str("LEDGE_CATCH")
		states.LEDGE_HOLD:
			parent.play_animation("Ledge_Catch")
			parent.states.text = str("LEDGE_HOLD")
		states.LEDGE_JUMP:
			parent.play_animation("Air")
			parent.states.text = str("LEDGE_JUMP")
		states.LEDGE_CLIMB:
			parent.play_animation("Roll_Forward")
			parent.states.text = str("LEDGE_CLIMB")
		states.LEDGE_ROLL:
			parent.play_animation("Roll_Forward")
			parent.states.text = str("LEDGE_ROLL")
		states.HITFREEZE:
			parent.play_animation("Hitstun")
			parent.states.text = str("HITFREEZE")
		states.GRABBED:
			parent.play_animation("Hitstun")
			parent.states.text = str("GRABBED")
		states.STUNNED:
			parent.play_animation("Hitstun")
			parent.states.text = str("STUNNED")
		states.HITSTUN:
			parent.play_animation("Hitstun")
			parent.states.text = str("HITSTUN")
		states.PARRY:
			parent.play_animation("Parry")
			parent.states.text = str("PARRY")
		states.ROLL_RIGHT:
			parent.play_animation("Tech_Ground")
			parent.states.text = str("ROLL_RIGHT")
		states.ROLL_LEFT:
			parent.play_animation("Tech_Ground")
			parent.states.text = str("ROLL_LEFT")
		states.AIR_ATTACK:
			parent.states.text = str("AIR_ATTACK")
		states.NEUTRAL_SPECIAL:		
			parent.play_animation("Neutral_Special")
			parent.states.text = str("NEUTRAL_SPECIAL")
		states.NAIR:		
			parent.play_animation("Nair")
			parent.states.text = str("NAIR")
		states.UAIR:
			parent.play_animation("Uair")
			parent.states.text = str("UAIR")
		states.BAIR:			
			parent.play_animation("Bair")
			parent.states.text = str("BAIR")
		states.FAIR:		
			parent.play_animation("Fair")
			parent.states.text = str("FAIR")
		states.DAIR:			
			parent.play_animation("Dair")
			parent.states.text = str("DAIR")
		states.GROUND_ATTACK:
			parent.states.text = str("GROUND_ATTACK")
		states.DOWN_TILT:
			parent.play_animation("Down_Tilt")
			parent.states.text = str("DOWN_TILT")
		states.UP_TILT:
			parent.play_animation("Up_Tilt")
			parent.states.text = str("UP_TILT")
		states.FORWARD_TILT:
			parent.play_animation("Forward_Tilt")
			parent.states.text = str("FORWARD_TILT")
		states.JAB:
			parent.play_animation("Jab")
			parent.states.text = str("JAB")
		states.JAB_1:
			parent.play_animation("Jab_1")
			parent.states.text = str("JAB_1")
		
func exit_state(old_state, new_state):
	pass

func state_includes(state_array):
	for each_state in state_array:
		if state == each_state:
			return true
	return false

func TILT():
	if state_includes([states.STAND, states.MOONWALK, states.DASH, states.RUN, states.WALK, states.CROUCH]):
		return true
		
func AIREAL():
	if state_includes([states.AIR, states.DAIR, states.NAIR, states.FAIR, states.UAIR, states.BAIR, states.NEUTRAL_SPECIAL]):
		if !(parent.Ground_L.is_colliding() and parent.Ground_R.is_colliding()):
			return true
		else:
			return false
			
func SPECIAL():
	if state_includes([states.STAND, states.WALK, states.DASH, states.RUN, states.MOONWALK, states.CROUCH]):
		return true

func AIRMOVEMENT():
	if parent.velocity.y < parent.FALLINGSPEED:
		parent.velocity.y +=parent.FALLSPEED
	if Input.is_action_pressed("down_%s" % id) and parent.velocity.y > -150 and not parent.fastfall and parent.down_buffer == 1:
		parent.velocity.y = parent.MAXFALLSPEED
		parent.fastfall = true
	if parent.fastfall == true:
		parent.set_collision_mask_value(3,false)
		parent.velocity.y = parent.MAXFALLSPEED
		
	if abs(parent.velocity.x) >= abs(parent.MAXAIRSPEED):
		if parent.velocity.x > 0:
			if Input.is_action_pressed("left_%s" % id):
				parent.velocity.x += -parent.AIR_ACCEL
			elif Input.is_action_pressed("right_%s" % id):
				parent.velocity.x = parent.velocity.x
		if parent.velocity.x < 0:
			if Input.is_action_pressed("left_%s" % id):
				parent.velocity.x = parent.velocity.x
			elif Input.is_action_pressed("right_%s" % id):
				parent.velocity.x += parent.AIR_ACCEL
				
	elif abs(parent.velocity.x) < abs(parent.MAXAIRSPEED):
		if Input.is_action_pressed("left_%s" % id):
			parent.velocity.x += -parent.AIR_ACCEL
		if Input.is_action_pressed("right_%s" % id):
			parent.velocity.x += parent.AIR_ACCEL
				
	if not Input.is_action_pressed("left_%s" % id) and not Input.is_action_pressed("right_%s" % id):
		if parent.velocity.x < 0:
			parent.velocity.x += parent.AIR_ACCEL/5
		elif parent.velocity.x > 0:
			parent.velocity.x += -parent.AIR_ACCEL/5	

func Landing():
	if state_includes([states.AIR, states.NAIR, states.DAIR, states.UAIR, states.FAIR, states.BAIR]):
		if (parent.Ground_L.is_colliding() or parent.Ground_R.is_colliding()) and parent.velocity.y >= 0:
			var collider = parent.Ground_L.get_collider()
			parent.frame = 0
			if parent.velocity.y > 0:
				parent.velocity.y = 0
			parent.fastfall = false
			return true
		
		elif (parent.Ground_R.is_colliding()) and parent.velocity.y >= 0:
			var collider2 = parent.Ground_R.get_collider()
			parent.frame = 0
			if parent.velocity.y > 0:
				parent.velocity.y = 0
			parent.fastfall = false
			return true

func Falling():
	if state_includes([states.RUN, states.WALK, states.STAND, states.CROUCH, states.DASH, states.LANDING, states.TURN, states.JUMP_SQUAT, states.MOONWALK, states.ROLL_RIGHT, states.ROLL_LEFT, states.PARRY, states.DASH]):
		if not parent.Ground_L.is_colliding() and not parent.Ground_R.is_colliding():
			return true

func Ledge():
	if state_includes([states.AIR]):
		if parent.Ledge_Grab_F.is_colliding():
			var collider = parent.Ledge_Grab_F.get_collider()
			if collider.get_node('Label').text == 'Ledge_L' and Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 && !collider.is_grabbed:
				if state_includes([states.AIR]):
					if parent.velocity.y < 0:
						return false
					parent.frame = 0
					parent.velocity.x = 0
					self.parent.position.x = collider.position.x - 20
					self.parent.position.y = collider.position.y - 2
					parent.turn(false)
					parent.reset_Jumps()
					parent.fastfall = false
					collider.is_grabbed = true
					parent.last_ledge = collider
					return true

			if collider.get_node('Label').text == 'Ledge_R' and Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 && !collider.is_grabbed:
				if state_includes([states.AIR]):
					if parent.velocity.y < 0:
						return false
					parent.frame = 0
					parent.velocity.x = 0
					self.parent.position.x = collider.position.x + 20
					self.parent.position.y = collider.position.y + 1
					parent.turn(true)
					parent.reset_Jumps()
					parent.fastfall = false
					collider.is_grabbed = true
					parent.last_ledge = collider
					return true
			
	if (parent.Ledge_Grab_B.is_colliding()):
		var collider = parent.Ledge_Grab_B.get_collider()
		if collider.get_node('Label').text == 'Ledge_L' and !Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 && !collider.is_grabbed:
			if state_includes([states.AIR]):
				if parent.velocity.y < 0:
					return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x - 20
				self.parent.position.y = collider.position.y - 1
				parent.turn(false)
				parent.reset_Jumps()
				parent.fastfall = false
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true

		if collider.get_node('Label').text == 'Ledge_R' and !Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 && !collider.is_grabbed:
			if state_includes([states.AIR]):
				if parent.velocity.y < 0:
					return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x + 20
				self.parent.position.y = collider.position.y + 1
				parent.turn(true)
				parent.reset_Jumps()
				parent.fastfall = false
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true

func can_roll():
	if state_includes([states.STAND, states.MOONWALK, states.RUN, states.WALK, states.CROUCH, states.DASH]):
		return true

var temp_body
var temp_state
func grabbed(body,state):
	temp_body = body
	temp_state = state

var kbx
var kby
var hd
var vd
var pos

func hitfreeze(duration, knocback):
	pos = parent.get_position()
	parent.freezeframes = duration
	kbx = knocback[0]
	kby = knocback[1]
	hd = knocback[2]
	vd = knocback[3]
