extends KinematicBody2D

export var max_speed = 300
export var acceleration = 2000
export var projectile_scene: PackedScene
export var knockback_force = 175
export var friction = 1750

onready var shoot_audio_player = get_node("ShootAudioPlayer")
onready var footsteps_audio_player = get_node("FootstepsAudioPlayer")

var motion = Vector2.ZERO

func _physics_process(delta):
	var input_vector = get_input_vector()
	var mouse_position = get_global_mouse_position()
	var mouse_direction = global_position.direction_to(get_global_mouse_position())
	var sprite_animation = "idle.front.right"
	
	# Determine which sprite to use based on distance from the player to the mouse position
	var distance = global_position.distance_to(mouse_position)
	if distance > 64:
		sprite_animation = "idle.back.right" if mouse_position.y < global_position.y else "idle.front.right"
		if mouse_position.x < global_position.x:
			sprite_animation = sprite_animation.replace(".right", ".left")
	else:
		sprite_animation = "idle.front.right" if mouse_position.x > global_position.x else "idle.front.left"
	
	# Set the sprite animation based on the distance from the player to the mouse position
	var animated_sprite = get_node("DamageEffect/AnimatedSprite")
	animated_sprite.animation = sprite_animation
	
	# Calculate the player's new motion based on input and acceleration
	var new_motion = motion
	if input_vector != Vector2.ZERO:
		new_motion += input_vector.normalized() * acceleration * delta
	new_motion = new_motion.limit_length(max_speed)
	
	# If the player is not holding down a movement key and is not experiencing knockback, gradually slow them down with friction
	if input_vector == Vector2.ZERO:
		var friction_force = motion.normalized() * friction * delta
		if friction_force.length() > motion.length():
			new_motion = Vector2.ZERO
		else:
			new_motion -= friction_force
	# Move the player based on their new motion
	var collision_info = move_and_collide(motion * delta)
	if collision_info != null:
		motion = Vector2.ZERO
	else:
		motion = new_motion
		
	if motion != Vector2.ZERO:
		if not footsteps_audio_player.playing:
			footsteps_audio_player.play()
	else:
		footsteps_audio_player.stop()

	if Input.is_action_just_pressed("action_shoot"):
		var projectile_direction = mouse_direction
		var deviation_angle = rand_range(-0.05, 0.05)  # choose a random deviation angle
		shoot(projectile_direction, deviation_angle)
		knockback(projectile_direction, deviation_angle)


func get_input_vector():
	var input_vector = Vector2.ZERO
	
	# Check for movement keys and update the input vector accordingly
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	
	# Normalize the input vector to ensure that diagonal movement is not faster than horizontal/vertical movement
	return input_vector.normalized()

func shoot(projectile_dir: Vector2 = Vector2.ZERO, deviation_angle = 0):
	var projectile = projectile_scene.instance()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position

	var projectile_rot = projectile_dir.angle() + deviation_angle
	projectile.rotation = projectile_rot
	
	# Load and play the sound effect
	shoot_audio_player.pitch_scale = rand_range(1.2, 1.4)
	shoot_audio_player.play()
	
	# Shake the camera
	var camera = get_node("PlayerCamera")
	# camera.shake()
	camera.flash_screen()
	
func damage():
	var damage_effect = get_node("DamageEffect")
	damage_effect.modulate = Color(1, 0, 0, 1)
	yield(get_tree().create_timer(0.1), "timeout")
	damage_effect.modulate = Color(1, 1, 1, 1)
	

func knockback(projectile_dir: Vector2 = Vector2.ZERO, deviation_angle: float = 0):
	var knockback_dir = projectile_dir.rotated(deviation_angle)  # apply deviation to projectile direction
	motion += -knockback_dir * knockback_force

