extends Node

onready var HUD_visible = true

func _onready():
	set_process_input(true)

func _input(event):
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if event.is_action_pressed("global_restart"):
		get_tree().change_scene("assets/test/test.tscn")

	if event.is_action_pressed("global_exit") && not OS.has_feature("HTML5"):
		get_tree().quit()
	
	if event.is_action_pressed("global_fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen

	if event.is_action_pressed("global_help"):
		var HUD = get_node("/root/test/HUD")
		HUD.visible = not HUD.visible
		HUD_visible = HUD.visible
