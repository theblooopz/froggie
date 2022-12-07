#TODO cotton stuffing comes out on death (soma wants this)
#TODO lerp lifting the box on head
#TODO drawing in _process and game logic in _physics_process/_integrate_forces
#TODO weird jumps when hitting ceilings
#TODO make froggie heavier when he's holding objects
#TODO do I need to worry about delta multiplying?

#TODO IMPORTANT STILL NEED TO FIX IT CONNECTING TO THE WRONG SWING SOMETIMES


extends RigidBody2D

onready var easy_mode = global.get_play_mode()

const SPEED = 25 * 1000
const RUN_FACTOR = 1.5
const JUMP_FORCE = 3000
const ACCELERATION_FACTOR = 0.8
const DECELLERATION_FACTOR = 0.8
const SWING_POWER = 9
const SWING_POINT_DISTANCE = 400
const ROLL_SPEED = 15 * 50

onready var FROGGIE_MASS = get_mass()


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

onready var swing_zone_turn = 1

onready var anchor = null
onready var swing = null
onready var joint = null
onready var dancing = false
onready var jumping = false
onready var dead = false
onready var canmove = true
onready var held_object = null
onready var slope = 0
onready var grounded = false
onready var ground_h_velocity = 0

onready var default_zoom = Vector2(1.15,1.15)
onready var camera = null

onready var camera_zoom = Vector2(1,1)
onready var camera_zoom_to = default_zoom
onready var camera_zoom_out = Vector2(1.33,1.33)

var anchors = []

var rolling = false

func _ready():
	$death_timer.stop()


	camera = get_parent().get_node("camera")
	#print(camera)
	yield(get_tree(), "idle_frame")
	camera.set_enable_follow_smoothing(true)
	camera.reset_smoothing()
	
	set_process(true)

func jump(state):
	
		if get_mode() == RigidBody2D.MODE_CHARACTER &&\
		abs(state.transform.get_rotation()) < 0.1:
			if not jumping:
				if groundray.is_colliding():
						if groundray.get_collider().is_in_group("GROUND") or\
						groundray.get_collider().is_in_group("ROPE"):
							$jump_timer.start()
							jumping = true
				elif grounded:
						$jump_timer.start()
						jumping = true


func apply_gravity(state, direction):
	
	var step = state.get_step()
	
	motion.x -= ground_h_velocity
	ground_h_velocity = 0
	
	motion.x = lerp(motion.x, 0, DECELLERATION_FACTOR) * step
	
	#if not groundray.is_colliding():
	var bodies = get_colliding_bodies()
	var idx = 0
	var ground_idx = -1
	for body in bodies:
		if (body.is_in_group("GROUND") or body.is_in_group("ROPE")) and state.get_contact_count() > 0:
			
			if state.get_contact_count() > idx:
				var a = state.get_contact_local_normal(idx)
				if a.dot(Vector2(0, -1)) > 0.6:
					grounded = true
					ground_idx = idx
					break
				else:
					grounded = false
		else:
			grounded = false
			
		idx += 1
	
	if grounded:
		ground_h_velocity = state.get_contact_collider_velocity_at_position(ground_idx).x
		motion.x += ground_h_velocity * step
		motion.y = 0
	else:
		if not jumping:
			motion += state.get_total_gravity() * step
	
	if jumping:
		motion.y -= JUMP_FORCE * step
	
	if canmove:
		var s = _SPEED*direction
		motion.x += lerp(motion.x, s, ACCELERATION_FACTOR) *step


func _process(delta):
	camera_zoom = lerp(camera_zoom,camera_zoom_to,delta)
	camera.set_zoom(camera_zoom)

func _integrate_forces(state):
	
	if dead: return
	
	var step = state.get_step()

	
	anchors = $swing_zone.get_overlapping_bodies()
	
	tongue.set_point_position(0, tongue_start.get_global_transform().origin\
	 - get_parent().get_global_transform().origin)
	
	rolling = Input.is_action_pressed("move_roll")
	
	if Input.is_action_pressed("move_run") and not dancing:
		_SPEED = SPEED*RUN_FACTOR
		_ROLL_SPEED = ROLL_SPEED*RUN_FACTOR
		#TODO 2 is a magic number
		$sprite.speed_scale = lerp($sprite.speed_scale, 2 + RUN_FACTOR, ACCELERATION_FACTOR)
		$footstep.set_pitch_scale(RUN_FACTOR)
	else:
		_SPEED = SPEED
		_ROLL_SPEED = ROLL_SPEED
		$sprite.speed_scale = lerp($sprite.speed_scale, 2, ACCELERATION_FACTOR)
		$footstep.set_pitch_scale(0.95)
	
	if Input.is_action_just_pressed("move_grapple"):
		
		rolling = false

		if anchor:
			
			joint = anchor.get_node("joint")
			#yield(get_tree(), "idle_frame")
			swing = joint.get_node(joint.get_node_b())
			#$swing_timer.start()
			
			swing.reset_to_position(get_global_transform(), state.linear_velocity, state.angular_velocity)
			tongue_end = tongue_start.get_global_transform().origin - get_parent().get_global_transform().origin
			call_deferred("set_mode", RigidBody2D.MODE_RIGID)
			#yield($swing_timer, "timeout")

		
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
		
		if swing:
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
				if anchor:
					if dist < tongue_begin.distance_to(anchor.get_global_transform().get_origin()- get_parent().get_global_transform().origin):
						anchor = child
				else:
					anchor = child


	if Input.is_action_just_pressed("move_grapple"):
		if anchor:
			var dist = tongue_begin.distance_to(anchor.get_global_transform().origin - get_parent().get_global_transform().origin)
			if dist < SWING_POINT_DISTANCE and not tongue_ray.is_colliding():
				if $swing_cooldown.is_stopped():
					swinging = true
					$swing_cooldown.start()
					anchor.get_node("swish").play()
					camera_zoom_to = camera_zoom_out
				else:
					jump(state)
		else:
			jump(state)
		
	if Input.is_action_just_released("move_grapple"):
		if not swinging:
			$swing_cooldown.stop()
		swinging = false
		camera_zoom_to = default_zoom
	
	if Input.is_action_just_pressed("move_jump"):
		jump(state)
	
	apply_gravity(state, direction)

	#if not swinging:
#	if canmove:
#		if abs(direction) and groundray.is_colliding():
#			if groundray.get_collider().is_in_group("DIRT"):
#				if not $footstep.is_playing() and not rolling and abs(state.transform.get_rotation()) < 0.1:
#					$footstep.play()
#				if not dust.is_emitting(): dust.set_emitting(true)
#			else:
#				if dust.is_emitting(): dust.set_emitting(false)
#
#	var flag = false
#	if not swinging:
#		if groundray.is_colliding() and not jumping:
#			canmove = true
#			var grb = groundray.get_collider()
#			if grb.is_in_group("ROPE"): flag = true
#			if grb.is_in_group("BOUNCE") and grb.has_method("get_bounce_power"):
#				pass
#				#TODO NEED TO ADD BOUNCE
#			elif not flag:
#				motion.y = 0
#				motion.y += motion.x  * cos(groundray.get_collision_normal().angle())
#
#		else:
#
#			var bodies = get_colliding_bodies()
#			contacts.ground_contact = false
#			contacts.rope_contact = false
#			#var ceiling_contact = true
#			var l = 0
#			var idx = 0
#			var a = 0
#			var v = 0
#			for body in bodies:
#				if body.is_in_group("GROUND") and state.get_contact_count() > 0:
#
#					if state.get_contact_count() > idx:
#						l = state.get_contact_local_normal(idx).x
#						v = state.get_contact_local_normal(idx).y
#						a = abs(rad2deg(state.get_contact_local_normal(idx).angle()))
#
#					if v < 0:
#						contacts.ground_contact = true
#
#				if body.is_in_group("ROPE") and state.get_contact_count() > 0:
#
#					if state.get_contact_count() > idx:
#						l = state.get_contact_local_normal(idx).x
#						v = state.get_contact_local_normal(idx).y
#						a = abs(rad2deg(state.get_contact_local_normal(idx).angle()))
#
#					if v < 0:
#						contacts.rope_contact= true
#
#				idx += 1
#
#			if a > 100:
#				canmove = false
#
#
#			if not contacts.ground_contact and not jumping:
#				motion.y += GRAVITY
#
#			if jumping: 
#				canmove = true
#				motion.y -= JUMP_FORCE
#
#			if contacts.ground_contact and not jumping:
#				motion.x = lerp(motion.x, _SPEED * sign(l), ACCELERATION_FACTOR)
#				rolling = true
#
#			if contacts.rope_contact and not jumping:
#				motion.y = 0
#				canmove = true

	if ceilingray.is_colliding() and not held_object:
		jumping = false
	
	
	if swing:
		if swinging:
			motion = swing.linear_velocity
			var av = lerp(swing.angular_velocity, swing.angular_velocity, swing.angular_damp)
			state.set_angular_velocity(av)
		else:
			#swing.set_angular_velocity(0)
			#swing.set_linear_velocity(Vector2.ZERO)
			#swing.reset_to_position(swing.get_global_transform(), state.get_linear_velocity(), state.get_angular_velocity())
			swing.reset_to_original()

			#motion = lerp(motion, Vector2.ZERO, swing.linear_damp)
			#var av = lerp(state.angular_velocity, 0, swing.angular_damp)
			#state.set_angular_velocity(av)
			
	
	if direction || jumping:
		dancing = false

	if not swinging and not dancing:
		if direction:
			$sprite.scale.x = abs($sprite.scale.x)*sign(direction)
			$sprite.animation = "run"
			if rolling:
				state.set_angular_velocity(_ROLL_SPEED * direction * step)
			elif abs(state.transform.get_rotation()) >= 0.1:
				state.set_angular_velocity(_ROLL_SPEED * direction * step)
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
				#TODO maybe too easy???
				#state.set_angular_velocity(_ROLL_SPEED * sign($sprite.scale.x) * step)
				state.set_angular_velocity(_ROLL_SPEED * direction)
				$sprite.animation = "air"
			else:
				state.set_angular_velocity(0)
				$sprite.animation = "idle"
				call_deferred("set_mode", RigidBody2D.MODE_CHARACTER)
				
	
	if Input.is_action_just_pressed("move_dance") or dancing:
		if not abs(state.transform.get_rotation()) >= 0.1 and not held_object:
			if not swinging:
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
						obj.set_collision_mask_bit(8, false)
						obj.custom_integrator = true
						obj.set_angular_velocity(0)
						obj.set_linear_velocity(Vector2.ZERO)
						set_mass(obj.get_mass() + FROGGIE_MASS)
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
			held_object.set_collision_mask_bit(8, true)
			held_object.custom_integrator = false
			held_object.set_sleeping(false)
			set_mass(FROGGIE_MASS)
			held_object = null
			$hold.set_remote_node("")
	
	if held_object:
		state.set_angular_velocity(0)
		held_object.set_angular_velocity(0)
	
		if abs(state.transform.get_rotation()) > 0.1:
			held_object.custom_integrator = false
			held_object.set_collision_mask_bit(8, true)
			held_object.set_sleeping(false)
			set_mass(FROGGIE_MASS)
			held_object = null
			$hold.set_remote_node("")
	
	if rolling and held_object:
		held_object.set_collision_mask_bit(8, true)
		held_object.custom_integrator = false
		held_object.set_sleeping(false)
		set_mass(FROGGIE_MASS)
		held_object = null
		$hold.set_remote_node("")
	
	
	#TODO SET SIZE OF EXTENTS OF SWING_ZONE SWING COL TO SWING_POINT_DISTANCE
	if not easy_mode:
		if direction: swing_zone_turn = direction
		$swing_zone.set_position(Vector2((SWING_POINT_DISTANCE - 100) * swing_zone_turn,0))
	else:
		$swing_zone.set_position(Vector2.ZERO)
	$swing_zone.get_node("swing_col").get_shape().set_radius(SWING_POINT_DISTANCE)
	
	state.set_linear_velocity(motion)
	
#	if anchor:
#		var dist = tongue_begin.distance_to(anchor.get_global_transform().origin - get_parent().get_global_transform().origin)
#		if dist < SWING_POINT_DISTANCE:
#			anchor.get_node("ColorRect").color = Color(1,0,0,1)


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
	var _r = get_tree().reload_current_scene()
