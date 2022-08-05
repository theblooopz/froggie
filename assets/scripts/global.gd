extends Node

func _onready():
	set_process_input(true)

func _input(event):
	
	if event.is_action_pressed("global_restart"):
		get_tree().change_scene("assets/test/test.tscn")

	if event.is_action_pressed("global_exit"):
		get_tree().quit()
	
	if event.is_action_pressed("global_fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
