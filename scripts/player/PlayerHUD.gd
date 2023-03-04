extends CanvasLayer

const pause_screen = preload("res://scenes/game_ui/PauseMenu.tscn")

func _on_PauseButton_pressed():
	var pause_menu = pause_screen.instance()
	add_child(pause_menu)
