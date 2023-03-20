extends Camera2D

const PauseScreen = preload("res://scenes/game_ui/PauseMenu.tscn")

var shake_time = 0.2
var shake_intensity = 1.5
var shake_speed = 50.0

export var follow_speed: float = 0.5
export var zoom_speed: float = 0.3
export var max_zoom: float = 1.3
export var min_zoom: float = 1.0
export var zoom_border: float = 400.0

var should_recenter_camera = false

onready var player: KinematicBody2D = get_node("/root/Main/WorldSort/PlayerCharacter")
onready var flash: ColorRect = get_node("GunFlashRect")

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
	yield(get_tree().create_timer(0.05), "timeout")
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
			should_recenter_camera = true
		else:
			# Set the zoom level to the default value when the player is not moving
			current_zoom = current_zoom.linear_interpolate(Vector2(min_zoom, min_zoom), delta * zoom_speed)
			zoom = current_zoom
			if not should_recenter_camera:
				should_recenter_camera = true

	# Recenter the camera on the player if necessary
	if should_recenter_camera:
		var target_position = player.global_position + Vector2(150, 0)
		var current_position = global_position
		if (target_position - current_position).length() > 1:
			global_position = current_position.linear_interpolate(target_position, delta * follow_speed * 4.0)


func set_following_player(follow: bool):
	following_player = follow
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var pause_menu = PauseScreen.instance()
		add_child(pause_menu)
