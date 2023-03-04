extends CanvasLayer

const PauseScreen = preload("res://scenes/game_ui/PauseMenu.tscn")

func _on_Button_pressed():
	var pause_menu = PauseScreen.instance()
	add_child(pause_menu)
