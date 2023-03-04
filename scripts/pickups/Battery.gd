extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var magnet_speed = 1500
onready var tween = get_node("Tween")
var colliding_body

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func are_positions_close(position1: Vector2, position2: Vector2, epsilon: float) -> bool:
	return position1.distance_squared_to(position2) < epsilon * epsilon

func _process(delta: float) -> void:
	if colliding_body and colliding_body.name == "PlayerCharacter":
		if are_positions_close(position, colliding_body.position, 40):
			# Code to execute when the battery is close enough to the player
			
			colliding_body.heal(colliding_body.health_increment)
			queue_free()

func _on_BatteryArea2D_body_entered(body):
	if body.name == "PlayerCharacter":
		var target_pos = body.position
		var distance = position.distance_to(target_pos)
		var duration = distance / magnet_speed
		tween.interpolate_property(self, "position", position, target_pos, duration, Tween.TRANS_LINEAR)
		tween.start()
		colliding_body = body

