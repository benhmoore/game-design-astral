extends Control

var scene_path_to_load

func _ready():
	for button in $Menu/CenterRow/Buttons.get_children():
		button.connect("pressed", self, "_on_Button_pressed", [button.scene_to_load])
	
func _on_Button_pressed(scene_to_load):
	$ui_click.play()
	scene_path_to_load = scene_to_load
	get_tree().change_scene(scene_path_to_load)

func _on_QuitGameButton_pressed():
	$ui_click.play()
	get_tree().quit()
