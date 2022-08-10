#TODO cotton stuffing comes out on death
#TODO lerp lifting the box on head
#TODO sometimes when frog jumps with box from ends then starts rolling and loses box


extends RigidBody2D

const SPEED = 300
const RUN_FACTOR = 1.5
const GRAVITY = 10 * 3
const JUMP_FORCE = 50
const ACCELERATION_FACTOR = 0.8
const SWING_POWER = 9
const SWING_POINT_DISTANCE = 400
const ROLL_SPEED = 15


var _SPEED = SPEED
var _ROLL_SPEED = ROLL_SPEED
onready var motion = Vector2.ZERO

onready var swinging = false
onready var tongue = $"../tongue"
onready var tongue_ray = $"../tongue_ray"
onready var groundray = $"../groundray"
onready var holdray = $"../holdray"
onready var ceilingray = $"../ceilingray"
onready var dust = $"../dust"
onready var tongue_end = Vector2.ZERO
onready var tongue_begin = Vector2.ZERO
onready var tongue_start = $tongue_start
onready var blood = $blood

onready var swing_zone_turn = 1

onready var anchor = null
onready var second_anchor = null
onready var swing = null
onready var joint = null
onready var dancing = false
onready var jumping = false
onready var dead = false
onready var canmove = true
onready var held_object = null

var anchors = []

var rolling = false
var initial_swing = true

func _ready():
	$death_timer.stop()

func _integrate_forces(state):
	
	if dead: return
	
	tongue.set_point_position(0, tongue_start.get_global_transform().origin\
	 - get_parent().get_global_transform().origin)
	

	rolling = Input.is_action_pressed("move_roll")
	
	if Input.is_action_pressed("move_run") and not dancing:
		_SPEED = SPEED*RUN_FACTOR
		_ROLL_SPEED = ROLL_SPEED*RUN_FACTOR
		$sprite.speed_scale = lerp($sprite.speed_scale, 2 + RUN_FACTOR, ACCELERATION_FACTOR)
		$footstep.set_pitch_scale(RUN_FACTOR)
	else:
		_SPEED = SPEED
		_ROLL_SPEED = ROLL_SPEED
		$sprite.speed_scale = lerp($sprite.speed_scale, 2, ACCELERATION_FACTOR)
		$footstep.set_pitch_scale(0.95)
	
	if swinging:
		
		rolling = false
		
		if initial_swing and anchor:
			joint = anchor.get_node("joint")
			swing = joint.get_node(joint.get_node_b())
			#$swing_timer.start()
			swing.reset_to_position(get_global_transform())
			initial_swing = false
			tongue_end = tongue_start.get_global_transform().origin - get_parent().get_global_transform().origin
			call_deferred("set_mode", RigidBody2D.MODE_RIGID)
			
			#yield($swing_timer, "timeout")
	else:
		initial_swing = true
		
	var direction = Input.get_action_strength("move_right") \
	- Input.get_action_strength("move_left")
	
	if not direction or not groundray.is_colliding():
		if $footstep.is_playing(): $footstep.stop()
		if dust.is_emitting(): dust.set_emitting(false)
	
	if swinging and anchor:
		tongue_begin = get_position() - tongue_start.get_position()
		tongue_end = lerp(tongue_end + tongue_begin.direction_to(\
		anchor.get_global_transform().origin - get_parent().get_global_transform().origin),\
		anchor.get_global_transform().origin - get_parent().get_global_transform().origin, 0.25)
		tongue.set_point_position(1, tongue_end)
		
		swing.apply_central_impulse(Vector2(direction*SWING_POWER,0))
		#TODO MAGIC NUMBER
		if not held_object: swing.set_angular_velocity(direction*3)
		if not tongue.visible: tongue.show()
	else:
		tongue_begin = tongue_start.get_global_transform().origin - get_parent().get_global_transform().origin
		tongue_end = lerp(tongue_end, tongue_begin - tongue_end.direction_to(tongue_begin),\
		 0.25)
		tongue.set_point_position(1, tongue_end)
	
	
	if not swinging:
		anchor = null
		for child in anchors:
			
			tongue_ray.set_cast_to(child.get_global_transform().get_origin() - get_global_transform().origin)
			
			var dist = tongue_begin.distance_to(child.get_global_transform().get_origin() - get_parent().get_global_transform().origin)
			if dist < SWING_POINT_DISTANCE and not tongue_ray.is_colliding():
				anchor = child
				break


	if Input.is_action_just_pressed("move_jump"):
		
		if anchor:
			var dist = tongue_begin.distance_to(anchor.get_global_transform().origin - get_parent().get_global_transform().origin)
			if dist < SWING_POINT_DISTANCE and not tongue_ray.is_colliding():
				if $swing_cooldown.is_stopped():
					swinging = true
					$swing_cooldown.start()
					anchor.get_node("swish").play()
				else:
					if get_mode() == RigidBody2D.MODE_CHARACTER && groundray.is_colliding() && \
					abs(state.transform.get_rotation()) < 0.1:
						if not jumping:
							$jump_timer.start()
							jumping = true
		else:
			if get_mode() == RigidBody2D.MODE_CHARACTER && groundray.is_colliding() &&\
			abs(state.transform.get_rotation()) < 0.1:
				if not jumping:
					$jump_timer.start()
					jumping = true
	
	if Input.is_action_just_released("move_jump"):
		if not swinging:
			$swing_cooldown.stop()
		swinging = false
		if second_anchor:
			anchor = second_anchor
			second_anchor = null
	

	if not swinging:
		if canmove:
			motion.x = lerp(motion.x, _SPEED * direction, ACCELERATION_FACTOR)
			if abs(direction) and groundray.is_colliding():
				if groundray.get_collider().is_in_group("DIRT"):
					if not $footstep.is_playing() and not rolling and abs(state.transform.get_rotation()) < 0.1:
						$footstep.play()
					if not dust.is_emitting(): dust.set_emitting(true)
			
		if ceilingray.is_colliding() and jumping and not held_object:
			jumping = false
		
		
		if groundray.is_colliding() and not jumping:
			canmove = true
			#var gnl = groundray.get_collision_normal()
			motion.y = 0
			motion.y += motion.x  * cos(groundray.get_collision_normal().angle())
		else:
				
			var bodies = get_colliding_bodies()
			var ground_contact = false
			#var ceiling_contact = true
			var l = 0
			var idx = 0
			var a = 0
			var v = 0
			for body in bodies:
				if body.is_in_group("GROUND")and state.get_contact_count() > 0:
					
					if state.get_contact_count() > idx:
						l = state.get_contact_local_normal(idx).x
						v = state.get_contact_local_normal(idx).y
						a = abs(rad2deg(state.get_contact_local_normal(idx).angle()))
					
					if v < 0:
						ground_contact = true
						break
				idx += 1
			
			if a > 100:
				canmove = false

			
			if not ground_contact and not jumping:
				motion.y += GRAVITY
			if jumping:
				canmove = true
				motion.y -= JUMP_FORCE
			
			if ground_contact and not jumping:
				motion.x = lerp(motion.x, _SPEED * sign(l), ACCELERATION_FACTOR)
				rolling = true

	
	if swing:
		if swinging:
			motion = swing.linear_velocity
			var av = lerp(swing.angular_velocity, swing.angular_velocity, swing.angular_damp)
			state.set_angular_velocity(av)
		else:
			swing.set_angular_velocity(0)
			swing.set_linear_velocity(Vector2.ZERO)
			motion = lerp(motion, Vector2.ZERO, swing.linear_damp)
			var av = lerp(state.angular_velocity, 0, swing.angular_damp)
			state.set_angular_velocity(av)
			
	
	if direction || jumping:
		dancing = false

	if not swinging and not dancing:
		if direction:
			$sprite.scale.x = abs($sprite.scale.x)*sign(direction)
			$sprite.animation = "run"
			if rolling:
				state.set_angular_velocity(_ROLL_SPEED * direction)
			elif abs(state.transform.get_rotation()) >= 0.1:
				state.set_angular_velocity(_ROLL_SPEED * direction)
			else:
				$sprite.animation = "run"
				call_deferred("set_mode", RigidBody2D.MODE_CHARACTER)
		else:
			if rolling:
				state.set_angular_velocity(0)
				$sprite.animation = "idle"
				if abs(state.transform.get_rotation()) >= 0.1:
					$sprite.animation = "air"
				else:
					$sprite.animation = "idle"
			elif abs(state.transform.get_rotation()) >= 0.1:
				state.set_angular_velocity(_ROLL_SPEED * direction)
				$sprite.animation = "air"
			else:
				state.set_angular_velocity(0)
				$sprite.animation = "idle"
				call_deferred("set_mode", RigidBody2D.MODE_CHARACTER)
				
	
	if Input.is_action_just_pressed("move_dance"):
		if not abs(state.transform.get_rotation()) >= 0.1:
			dancing = true
			tongue.hide()
			$sprite.animation = "dance"
	
	
	if not groundray.is_colliding():
		$sprite.animation = "air"
	
	
	if direction:
		if direction < 0:
			holdray.cast_to =Vector2(-abs(holdray.cast_to.x), holdray.cast_to.y)
		else:
			holdray.cast_to = Vector2(abs(holdray.cast_to.x), holdray.cast_to.y)
	
	if Input.is_action_just_pressed("move_action"):
		if not held_object:
			if holdray.is_colliding() and groundray.is_colliding() and not swinging and not rolling and not jumping:
				if abs(state.transform.get_rotation()) < 0.1:
					var obj = holdray.get_collider()
					if obj.is_in_group("OBJECT"):
						obj.custom_integrator = true
						obj.set_angular_velocity(0)
						obj.set_linear_velocity(Vector2.ZERO)
						held_object = obj
						$hold.set_remote_node(obj.get_path())
		else:
			#TODO make this vector2 a constant
			var vl = state.get_linear_velocity() + Vector2(100,-100)
			var al = state.get_angular_velocity()
			
			if $sprite.scale.x < 0:
					vl.x = -abs(vl.x)

			held_object.set_linear_velocity(vl)
			held_object.set_angular_velocity(al)
			
			held_object.custom_integrator = false
			held_object.set_sleeping(false)
			held_object = null
			$hold.set_remote_node("")
	
	if held_object:
		state.set_angular_velocity(0)
		held_object.set_angular_velocity(0)
	
		if abs(state.transform.get_rotation()) > 0.1:
			held_object.custom_integrator = false
			held_object.set_sleeping(false)
			held_object = null
			$hold.set_remote_node("")
	
	if rolling and held_object:
		held_object.custom_integrator = false
		held_object.set_sleeping(false)
		held_object = null
		$hold.set_remote_node("")
	
	
	#TODO SET SIZE OF EXTENTS OF SWING_ZONE SWING COL TO SWING_POINT_DISTANCE
	if direction: swing_zone_turn = direction
	$swing_zone.set_position(Vector2((SWING_POINT_DISTANCE - 100) * swing_zone_turn,0))
	
	state.set_linear_velocity(motion)
	
	if anchor:
		var dist = tongue_begin.distance_to(anchor.get_global_transform().origin - get_parent().get_global_transform().origin)
		if dist < SWING_POINT_DISTANCE:
			anchor.get_node("ColorRect").color = Color(1,0,0,1)

func on_death(_clean = true):
	
	if held_object:
		held_object.custom_integrator = false
		held_object.set_sleeping(false)
		held_object = null
		$hold.set_remote_node("")
	$sprite.animation = "air"
	dead = true
	rolling = true
	tongue.hide()
	custom_integrator = false
	call_deferred("set_mode", RigidBody2D.MODE_RIGID)
	#TODO if not _clean: blood.set_emitting(true)
	$death_timer.call_deferred("start")

func _on_froggie_body_entered(body):
	
	if body.is_in_group("TRAP"):
		on_death(false)

func _on_jump_timer_timeout():
	jumping = false

func _on_death_timer_timeout():
	var _r = get_tree().change_scene("res://assets/test/test.tscn")

