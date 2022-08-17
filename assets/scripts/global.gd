extends Node

onready var HUD_visible = true
onready var easy_mode = true

func _onready():
	set_process_input(true)
	set_play_mode()

func _input(event):
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if event.is_action_pressed("global_restart"):
		var _r = get_tree().reload_current_scene()

	if event.is_action_pressed("global_exit") && not OS.has_feature("HTML5"):
		get_tree().quit()
	
	if event.is_action_pressed("global_fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen

	if event.is_action_pressed("global_help"):
		var HUD = get_node("/root/test/HUD")
		HUD.visible = not HUD.visible
		HUD_visible = HUD.visible
	
	if event.is_action_pressed("global_mode"):
		set_play_mode()
		
func set_play_mode():
		var label = get_node("/root/test/HUD/info_container/panel/ModeLabel")
		if easy_mode:
			label.set_bbcode("Current mode = [color=red]HARD[/color]")
			easy_mode = false
		else:
			label.set_bbcode("Current mode = [color=green]EASY[/color]")
			easy_mode = true
		
		get_node("/root/test/player/froggie").easy_mode = easy_mode
