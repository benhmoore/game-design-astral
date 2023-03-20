extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print("Pad ready")
	connect("body_entered", self, "_on_TeleportPad_area_entered")


func _on_TeleportPad_area_entered(area: Area2D):
		print("Pad entered")
		var target_scene = load("res://scenes/Level3.tscn")
		get_tree().change_scene_to(target_scene)
