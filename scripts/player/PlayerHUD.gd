extends CanvasLayer

const PauseScreen = preload("res://scenes/game_ui/PauseMenu.tscn")

func _on_Button_pressed():
	var pause_menu = PauseScreen.instance()
	add_child(pause_menu)

onready var player: KinematicBody2D = get_node_or_null("/root/Node2D/PlayerCharacter")
onready var health_bar = get_node_or_null("Display/HealthBar")
onready var current_ammo_bar = get_node_or_null("Display/CurrentAmmoBar")

# Called when the node enters the scene tree for the first time.

func _process(_delta):
	if not player:
		player = get_node_or_null("/root/Node2D/PlayerCharacter")
		if player:
			player.connect("health_changed", self, "_on_player_health_changed")
			player.connect("current_ammo_changed", self, "_on_player_current_ammo_changed")
			
func _on_player_health_changed():
	health_bar.value = player.health
	
func _on_player_current_ammo_changed():
	current_ammo_bar.value = player.current_ammo
