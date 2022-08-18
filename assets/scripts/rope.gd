extends Node2D

export(float) var JOINT_SOFTNESS = 0.7
export(int) var SEGMENT_WIDTH = 32
export(int) var LINE_WIDTH = 6
export(int) var SEGMENT_HEIGHT = 4


func _ready():
	
	$rope.set_width(LINE_WIDTH)
	
	var start = $begin.get_position()
	var end = $end.get_position()
	#var v = start.direction_to(end) * start.distance_to(end)
	
	var segcount = ceil(start.distance_to(end)/SEGMENT_WIDTH)
	
	var lo = null
	
	for segn in range(0,segcount):
		var rb = RigidBody2D.new()
		rb.name = str(segn)
		rb.set_position(Vector2( (SEGMENT_WIDTH)*(segn) + SEGMENT_WIDTH/2,0))
		rb.add_to_group("ROPE")
		rb.set_collision_layer_bit(0, false)
		rb.set_collision_layer_bit(7, true)
		#rb.set_collision_layer_bit(1,true)
		rb.set_collision_mask_bit(0, true)
		rb.set_collision_mask_bit(1, false)
		#rb.set_collision_mask_bit(5, true)
		var col = CollisionShape2D.new()
		var j = PinJoint2D.new()
		j.set_softness(JOINT_SOFTNESS)
		j.set_position(Vector2( (SEGMENT_WIDTH)*(segn),0))
		j.name = str(segn)
		col.one_way_collision = true
		var colshape = RectangleShape2D.new()
		colshape.set_extents(Vector2(SEGMENT_WIDTH/2, SEGMENT_HEIGHT))
		col.set_shape(colshape)
		rb.add_child(col)

		$joints.add_child(j)
		$segments.add_child(rb)
		
		if lo:
			j.set_node_a(lo.get_path())
		else:
			j.set_node_a($begin.get_path())
		j.set_node_b(rb.get_path())
		
		lo = rb
	
	if lo:
		var ljn = PinJoint2D.new()
		ljn.name = "end"
		ljn.set_softness(JOINT_SOFTNESS)
		ljn.set_position($end.get_position())
		ljn.set_node_a(lo.get_path())
		ljn.set_node_b($end.get_path())
		$joints.add_child(ljn)
	
func _process(_delta):
	var list = []
	
	list.append($begin.get_position())
	
	for segment in $segments.get_children():
		list.append($segments.get_position() + segment.get_position())
	
	list.append($end.get_position())
	
	$rope.set_points(list)

