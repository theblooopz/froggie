extends RigidBody2D

const SPEED = 300
const RUN_FACTOR = 1.5
const GRAVITY = 10 * 3
const JUMP_FORCE = 50
const ACCELERATION = 0.8
const SWING_POWER = 9
const SWING_POINT_DISTANCE = 350
const ROLL_SPEED = 15


var _SPEED = SPEED
var _ROLL_SPEED = ROLL_SPEED
onready var motion = Vector2.ZERO

onready var swinging = false
onready var tongue = $"../tongue"
onready var tongue_ray = $"../tongue_ray"
onready var groundray = $"../groundray"
onready var tongue_end = Vector2.ZERO
onready var tongue_begin = Vector2.ZERO
onready var tongue_start = $tongue_start

onready var swing_zone_turn = 1

onready var anchor = null
onready var second_anchor = null
onready var swing = null
onready var joint = null
onready var dancing = false
onready var jumping = false

var anchors = []

var rolling = false
var initial_swing = true


func _integrate_forces(state):
	
	tongue.set_point_position(0, tongue_start.get_global_transform().origin - get_parent().get_global_transform().origin)
	
	rolling = Input.is_action_pressed("move_roll")
	
	if Input.is_action_pressed("move_run"):
		_SPEED = SPEED*RUN_FACTOR
		_ROLL_SPEED = ROLL_SPEED*RUN_FACTOR
		$sprite.speed_scale = 2 + RUN_FACTOR
	else:
		_SPEED = SPEED
		_ROLL_SPEED = ROLL_SPEED
		$sprite.speed_scale = 2
	
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
	
	
	if swinging and anchor:
		tongue_begin = get_position() - tongue_start.get_position()
		tongue_end = lerp(tongue_end + tongue_begin.direction_to(\
		anchor.get_global_transform().origin - get_parent().get_global_transform().origin),\
		anchor.get_global_transform().origin - get_parent().get_global_transform().origin, 0.25)
		tongue.set_point_position(1, tongue_end)
		
		swing.apply_central_impulse(Vector2(direction*SWING_POWER,0))
		#TODO MAGIC NUMBER
		swing.set_angular_velocity(direction*3)
		if not tongue.visible: tongue.show()
	else:
		tongue_begin = tongue_start.get_global_transform().origin - get_parent().get_global_transform().origin
		tongue_end = lerp(tongue_end, tongue_begin - tongue_end.direction_to(tongue_begin),\
		 0.25)
		tongue.set_point_position(1, tongue_end)
	
	
	if not swinging:
		for child in anchors:
			
			tongue_ray.set_cast_to(child.get_global_transform().get_origin() - get_global_transform().origin)
			
			var dist = tongue_begin.distance_to(child.get_global_transform().get_origin() - get_parent().get_global_transform().origin)
			if dist < SWING_POINT_DISTANCE and not tongue_ray.is_colliding():
				anchor = child
				break
			else:
				anchor = null


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
		motion.x = lerp(motion.x, _SPEED * direction, ACCELERATION)
		if groundray.is_colliding() and not jumping:
			var gnl = groundray.get_collision_normal()
			motion.y = 0
			motion.y += motion.x  * cos(groundray.get_collision_normal().angle())
		else:
			if not jumping:
				motion.y += GRAVITY
			else:
				motion.y -= JUMP_FORCE

	
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
				#state.set_angular_velocity(0)
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
	
	#TODO SET SIZE OF EXTENTS OF SWING_ZONE SWING COL TO SWING_POINT_DISTANCE
	if direction: swing_zone_turn = direction
	$swing_zone.set_position(Vector2((SWING_POINT_DISTANCE - 100) * swing_zone_turn,0))
	
	state.set_linear_velocity(motion)
	
	if anchor:
		var dist = tongue_begin.distance_to(anchor.get_global_transform().origin - get_parent().get_global_transform().origin)
		if dist < SWING_POINT_DISTANCE:
			anchor.get_node("ColorRect").color = Color(1,0,0,1)
	

func _on_froggie_body_entered(body):
	
	if body.is_in_group("TRAP"):
		get_tree().change_scene("res://assets/test/test.tscn")


func _on_jump_timer_timeout():
	jumping = false

