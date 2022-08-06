extends RigidBody2D

const SPEED = 300
const RUN_FACTOR = 1.5
const GRAVITY = 10 * 3
const JUMP_FORCE = 200 * 3
const ACCELERATION = 0.8
const SWING_POWER = 9
const SWING_POINT_DISTANCE = 350
const ROLL_SPEED = 15


var _SPEED = SPEED
var _ROLL_SPEED = ROLL_SPEED
onready var motion = Vector2.ZERO

onready var swinging = false
onready var tongue = $"../tongue"
onready var groundrays = $"../groundrays"
onready var tongue_ray = $"../tongue_ray"
onready var tongue_end = Vector2.ZERO
onready var tongue_begin = Vector2.ZERO
onready var tongue_start = $tongue_start

onready var swing_zone_turn = 1

onready var anchor = null
onready var second_anchor = null
onready var swing = null
onready var joint = null
onready var dancing = false

var rolling = false
var initial_swing = true

func groundrays_colliding():
	for child in groundrays.get_children():
		if child.has_method("is_colliding"):
			if child.is_colliding():
				return true
	return false

func groundrays_normals():
	var nmls = []
	for child in groundrays.get_children():
		nmls.push_back(abs(rad2deg(child.get_collision_normal().angle())))
	return nmls

func _integrate_forces(state):
		
	
	tongue.set_point_position(0, tongue_start.get_global_transform().get_origin())

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
			swing.reset_to_position(get_transform())
			initial_swing = false
			tongue_end = tongue_start.get_global_transform().get_origin()
			call_deferred("set_mode", RigidBody2D.MODE_RIGID)
			#yield($swing_timer, "timeout")
	else:
		initial_swing = true
		
	var direction = Input.get_action_strength("move_right") \
	- Input.get_action_strength("move_left")
	
	if swinging and anchor:
		tongue_begin = tongue_start.get_global_transform().get_origin()
		tongue_end = lerp(tongue_end + tongue_begin.direction_to(anchor.get_global_transform().get_origin()),\
		 anchor.get_global_transform().get_origin(), 0.25)
		tongue.set_point_position(1, tongue_end)
		
		swing.apply_central_impulse(Vector2(direction*SWING_POWER,0))
		swing.set_angular_velocity(direction*3)
		if not tongue.visible: tongue.show()
	else:
		tongue_begin = tongue_start.get_global_transform().get_origin()
		tongue_end = lerp(tongue_end, tongue_begin - tongue_end.direction_to(tongue_begin),\
		 0.25)
		tongue.set_point_position(1, tongue_end)
	
	if groundrays_colliding() and motion.y > 0:
		motion.y = 0
	
	if not groundrays_colliding():
		motion.x = lerp(state.linear_velocity.x, _SPEED * direction, ACCELERATION)

	
	if anchor:
		tongue_ray.set_cast_to(anchor.get_global_transform().get_origin() - get_position())
	
	
	if Input.is_action_just_pressed("move_jump"):
		if anchor:
			var dist = tongue_begin.distance_to(anchor.get_global_transform().get_origin())
			if dist < SWING_POINT_DISTANCE and not tongue_ray.is_colliding():
					if $swing_cooldown.is_stopped():
						swinging = true
						$swing_cooldown.start()
			else:
				if get_mode() == RigidBody2D.MODE_CHARACTER && groundrays_colliding():
					motion.y = -JUMP_FORCE
			
		else:
			if get_mode() == RigidBody2D.MODE_CHARACTER && groundrays_colliding():
				motion.y = -JUMP_FORCE
	if Input.is_action_just_released("move_jump"):
		if not swinging:
			$swing_cooldown.stop()
		swinging = false
		if second_anchor:
			anchor = second_anchor
			second_anchor = null

		
	if swinging and swing:
		motion = swing.linear_velocity
		var av = lerp(swing.angular_velocity, swing.angular_velocity, swing.angular_damp)
		state.set_angular_velocity(av)
	else:
		if swing:
			var av = lerp(state.angular_velocity, 0, swing.angular_damp)
			state.set_angular_velocity(av)
			var lv = lerp(state.linear_velocity.x, 0, swing.linear_damp)
			motion.x += lv * 0.5
			
			swing.set_angular_velocity(0)
			swing.set_linear_velocity(Vector2.ZERO)

	if motion.y < 0: direction = 0

	if groundrays_colliding():
		motion.x = lerp(motion.x, _SPEED * direction, ACCELERATION)
	
	var nmls = groundrays_normals()
	var nmlsa = []
	for child in nmls:
		nmlsa.push_back(abs(child))

	if not groundrays_colliding():
		motion.y += GRAVITY
	else:
		if nmls and not swinging:
			if nmlsa.min() <= 0:
				if nmlsa.min() != 0:
					var idx = nmls.find(nmls.min())
					motion.y += GRAVITY * sin(deg2rad(nmls[idx]))
					motion.x += GRAVITY * cos(deg2rad(nmls[idx]))
					rolling = true
	
	if not groundrays_colliding() and not swinging:
		motion.x = lerp(motion.x, _SPEED * $sprite.scale.x, ACCELERATION)
		rolling = true
		
		
	if direction:
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
				state.set_angular_velocity(0)
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
	
	
	if not groundrays_colliding():
		$sprite.animation = "air"
	
	if direction: swing_zone_turn = direction
	$swing_zone.set_position(Vector2(300 * swing_zone_turn,0))
	
	state.set_linear_velocity(motion)

	
	if anchor:
		var dist = tongue_begin.distance_to(anchor.get_global_transform().get_origin())
		if dist < SWING_POINT_DISTANCE:
			anchor.get_node("ColorRect").color = Color(1,0,0,1)
	

func _on_froggie_body_entered(body):
	if body.has_method("collected"):
		body.collected()
		
	
	if body.get_name() == "killer":
		get_tree().change_scene("res://assets/test/test.tscn")

