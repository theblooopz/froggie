extends StaticBody2D

export(Vector2) var bounce_power

func get_bounce_power():
	print(bounce_power)
	return bounce_power

func _on_Area2D_body_entered(body):
	if not body.is_in_group("PLAYER"):
		var v = body.get_linear_velocity() + bounce_power
		body.set_linear_velocity(v)
	$sfx.play()
