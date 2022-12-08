extends StaticBody2D

func _ready():
	var col = CollisionPolygon2D.new()
	var poly = $Polygon2D.get_polygon()
	$Polygon2D.set_offset(Vector2(0,-5))
	col.set_polygon(poly)
	add_child(col)
	
	var lic = LightOccluder2D.new()
	lic.occluder = OccluderPolygon2D.new()
	lic.occluder.set_polygon(poly)
	add_child(lic)
	
	#$grassline.points = []
	
	#do_outline($Polygon2D)

func do_outline(poly):
	
	var count = 0
	var vects = poly.get_polygon()
	var lvs = PoolVector2Array()
	for v1 in vects:
		if vects.size()-1 < count+1: break
		var v2 = vects[count+1]
		
		var a = 0
		if v1.distance_to(v2) != 0:
			a = acos( (v2.x - v1.x)/(v1.distance_to(v2)) )

		a = abs(a)
		if rad2deg(a) > 95 and rad2deg(a) < 215:
			lvs.push_back(v1)

		
		count+=1
	$grassline.set_points(lvs)
	$grassline.show()
	print($grassline.points)
