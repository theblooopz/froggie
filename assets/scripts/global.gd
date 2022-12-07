extends Node

onready var INFOc_visible = true
onready var easy_mode = true

func _onready():
	set_process_input(true)

func _input(event):
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
	if event.is_action_pressed("global_restart"):
		var _r = get_tree().reload_current_scene()

	if event.is_action_pressed("global_exit") && not OS.has_feature("HTML5"):
		get_tree().quit()
	
	if event.is_action_pressed("global_fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen

	if event.is_action_pressed("global_help"):
		var INFOc = get_node("/root/test/HUD/info_container")
		INFOc.visible = not INFOc.visible
		INFOc_visible = INFOc.visible
	
	if event.is_action_pressed("global_mode"):
		set_play_mode()

func get_play_mode():
	
	var label = get_node("/root/test/HUD/info_container/panel/ModeLabel")
	var froggie = get_node("/root/test/player/froggie")
	froggie.easy_mode = easy_mode
	if not froggie.easy_mode:
		label.set_bbcode("Current mode = [color=red]HARD[/color]")
	else:
		label.set_bbcode("Current mode = [color=green]EASY[/color]")
		
	return easy_mode
		
func set_play_mode():
		var label = get_node("/root/test/HUD/info_container/panel/ModeLabel")
		var froggie = get_node("/root/test/player/froggie")
		froggie.easy_mode = not froggie.easy_mode
		easy_mode = froggie.easy_mode

		if not froggie.easy_mode:
			label.set_bbcode("Current mode = [color=red]HARD[/color]")
		else:
			label.set_bbcode("Current mode = [color=green]EASY[/color]")
