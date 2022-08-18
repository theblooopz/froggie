extends Node

export var ZOOM = Vector2(0.75,0.75)
export var froggiePath: NodePath
var froggie

func _ready():
	froggie = get_node(froggiePath)

func _on_Dialog_dialogic_signal(value):
	if value == "zoom_in":
		froggie.camera_zoom_to = ZOOM
	if value == "zoom_out":
		froggie.camera_zoom_to = froggie.default_zoom
