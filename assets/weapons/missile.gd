extends RigidBody2D

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	
	var bodies = get_colliding_bodies()
	
	if bodies:
		queue_free()
