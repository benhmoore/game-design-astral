extends Camera2D

var shake_time = 0.2
var shake_intensity = 1.5
var shake_speed = 50.0

export var follow_speed: float = 0.5
export var zoom_speed: float = 1.0
export var max_zoom: float = 1.1
export var min_zoom: float = 1.0
export var zoom_border: float = 400.0

onready var player: KinematicBody2D = get_node("/root/Node2D/PlayerCharacter")
onready var flash: ColorRect = $ColorRect

var following_player = true

var sway = Vector2.ZERO
var sway_target = Vector2.ZERO
var sway_speed = 2.0
var sway_timer = 0

var current_zoom = Vector2(1, 1)

func shake():
	var original_position = position
	var timer = 0.0
	while timer < shake_time:
		position = original_position + Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)) * shake_intensity
		timer += 1.0 / shake_speed
		yield(get_tree().create_timer(1.0 / shake_speed), "timeout")
	position = original_position

func flash_screen():
	flash.show()
	yield(get_tree().create_timer(0.1), "timeout")
	flash.hide()

func _process(delta):
	if following_player:
		# Calculate the new position for the camera
		var target_position = player.global_position
		var current_position = global_position
		
		# Only move the camera if the player gets close to the camera's edge
		if (target_position - current_position).abs().x > zoom_border or (target_position - current_position).abs().y > zoom_border:
			var new_position = current_position.linear_interpolate(target_position, delta * follow_speed)
			global_position = new_position
		else:
			global_position = current_position

		# Only add camera sway when player is moving
		if player.motion.length() > 0:
			# Update the sway position
			if sway_timer == 0:
				sway_target = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)) * 0.6
				sway_timer = 100
			else:
				sway = sway.linear_interpolate(sway_target, delta * sway_speed)
				sway_timer -= 1

			# Add the sway to the camera position
			global_position += sway

			# Calculate the new zoom level based on the player's velocity
			var new_zoom = lerp(min_zoom, max_zoom, player.motion.length() / player.max_speed)
			new_zoom = Vector2(new_zoom, new_zoom)
			current_zoom = current_zoom.linear_interpolate(new_zoom, delta * zoom_speed)

			# Set the new zoom level
			zoom = current_zoom
		else:
			# Set the zoom level to the default value when the player is not moving
			current_zoom = current_zoom.linear_interpolate(Vector2(min_zoom, min_zoom), delta * zoom_speed)
			zoom = current_zoom

func set_following_player(follow: bool):
	following_player = follow
