extends CanvasLayer

const PauseScreen = preload("res://scenes/game_ui/PauseMenu.tscn")

func _on_Button_pressed():
	$ui_click.play()
	var pause_menu = PauseScreen.instance()
	add_child(pause_menu)

onready var player: KinematicBody2D = get_tree().get_root().get_node("PlayerCharacter")
onready var health_bar = get_node_or_null("Display/HealthBar")
onready var current_ammo_bar = get_node_or_null("Display/CurrentAmmoBar")

# Called when the node enters the scene tree for the first time.

func _process(_delta):
	if get_tree().get_root().get_node("PlayerCharacter") != null:
		player = get_tree().get_root().get_node("PlayerCharacter").property	
		if player:
				player.connect("health_changed", self, "_on_player_health_changed")
				player.connect("ammo_changed", self, "_on_player_ammo_changed")
				
func _on_player_health_changed():
	health_bar.value = player.health
	
func _on_player_ammo_changed():
	current_ammo_bar.value = player.current_ammo
