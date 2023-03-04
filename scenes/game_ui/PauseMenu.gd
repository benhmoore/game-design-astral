extends CanvasLayer

func _ready() -> void:
	get_tree().paused = true;

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		visible = true
		get_tree().paused = true

func _on_Button_pressed():
	hide()
	get_tree().paused = false
	
func _on_Button2_pressed():
	get_tree().paused = false
	get_tree().quit()
