extends Node2D

var laser
var laser_start
var missile
var sfx

func _ready():
	laser = $laser
	laser_start = get_node("weapon/laser_start")
	missile = preload("res://assets/weapons/missile.tscn")
	sfx = get_node("weapon/laser_start/sfx")
	
	set_process_input(true)
	set_physics_process(true)

func fire_missile():
	
	var mpos = get_global_mouse_position()
	
	var to_vec = get_position() + $weapon.get_position() + mpos - $weapon.get_global_position()
	var from_vec = get_position() + $weapon.get_position() + laser_start.get_global_position() - $weapon.get_global_position()
	
	var m = missile.instance()
	m.set_position(from_vec)
	get_parent().add_child(m)
	m.apply_central_impulse(from_vec.direction_to(to_vec) * 1000)
	

func _input(event):
	
	if event.is_action_pressed("move_fire"):
		sfx.play()
		fire_missile()

func _process(_delta):
	
	var mpos = get_global_mouse_position()
	var mod = -1
	
	
	if mpos.x < get_global_position().x:
		$weapon.scale = Vector2(1,-1)
	else:
		$weapon.scale = Vector2(1,1)
		
	
	$weapon.look_at(mpos)
	
	laser.set_point_position(0, laser_start.get_global_position() - $weapon.get_position() - $weapon.get_global_position() )
	laser.set_point_position(1, mpos - $weapon.get_position() - $weapon.get_global_position())
