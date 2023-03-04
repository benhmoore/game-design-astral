extends Control

func _ready() -> void:
	get_tree().paused = true

func _on_ContinueButton_pressed():
	hide()
	get_tree().paused = false
	queue_free()

func _on_QuitButton_pressed():
	get_tree().paused = false
	get_tree().quit()
