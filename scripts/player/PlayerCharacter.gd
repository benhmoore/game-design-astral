extends KinematicBody2D

signal health_changed # Emitted whenever heal() or damage() is called
signal current_ammo_changed
signal player_death

export var max_speed = 325
export var acceleration = 2000
export var projectile_scene: PackedScene
export var knockback_force = 175
export var friction = 1750

export var lives = 3

export var health_increment = 1
var health:float = 6 setget set_health

onready var shoot_audio_player = get_node("ShootAudioPlayer")
onready var footsteps_audio_player = get_node("FootstepsAudioPlayer")
onready var effect_audio_player = get_node("EffectAudioPlayer")
onready var danger_audio_player = get_node("DangerAudioPlayer")

export var max_ammo = 10
var current_ammo:float = 0 setget set_current_ammo

var motion = Vector2.ZERO

var gun_recharge_timer = 0
var low_health_timer = 0

var is_shooting = false

func _process(delta):
	low_health_timer += delta
	if low_health_timer > 0.1:
		if health < 3 and health > 0:
			if low_health_timer >= (pow(health, 1.5) / 5):
				#danger_audio_player.pitch_scale = max(0.5,health * 0.3)
				danger_audio_player.play()
				var damage_effect = get_node("DamageEffect")
				damage_effect.modulate = Color(1, 0.58, 0.43,1)
				yield(get_tree().create_timer(0.3), "timeout")
				damage_effect.modulate = Color(1, 1, 1, 1)
				low_health_timer = 0
				
	# Update health or display constant damage effect
	if health <= 0:
		var damage_effect = get_node("DamageEffect")
		damage_effect.modulate = Color(1, 0.58, 0.43,1)
		emit_signal("player_death")
	else:
		set_health(health - (delta * 0.2))
	
	if current_ammo < 10:
		if is_shooting == false:
			var new_ammo = min(current_ammo + (delta*15), max_ammo)
			set_current_ammo(new_ammo)
		
func set_current_ammo(new_value:float):
	current_ammo = new_value
	emit_signal("current_ammo_changed")
	
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
	var sprint_multiplier = 1
	if Input.is_action_pressed("action_sprint"):
		sprint_multiplier = 1.5
		
	if input_vector != Vector2.ZERO:
		new_motion += input_vector.normalized() * acceleration * delta
	new_motion = new_motion.limit_length(max_speed)
	new_motion = new_motion * sprint_multiplier
	
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

	if Input.is_action_pressed("action_shoot"):
		is_shooting = true
		if gun_recharge_timer > 1:
			var projectile_direction = mouse_direction
			var deviation_angle = rand_range(-0.05, 0.05)  # choose a random deviation angle
			shoot(projectile_direction, deviation_angle)
			gun_recharge_timer = 0
		else:
			gun_recharge_timer += delta * (4 + current_ammo)
	else:
		is_shooting = false

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
	if Input.is_action_just_pressed("ui_up"):
		damage()
	
	# Normalize the input vector to ensure that diagonal movement is not faster than horizontal/vertical movement
	return input_vector.normalized()

func shoot(projectile_dir: Vector2 = Vector2.ZERO, deviation_angle = 0):
	
	if current_ammo < 0.1:
		play_sound("assets/sounds/battery_collect_full.wav", 1)
		return
	else:
		set_current_ammo(current_ammo-0.8)
	
	knockback(projectile_dir, deviation_angle)
		
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
	
	set_health(health - 0.05)
	
func damage():
	
	# Play damage visual effect
	var damage_effect = get_node("DamageEffect")
	damage_effect.modulate = Color(1, 0, 0, 1)
	yield(get_tree().create_timer(0.1), "timeout")
	damage_effect.modulate = Color(1, 1, 1, 1)
	yield(get_tree().create_timer(0.05), "timeout")
	damage_effect.modulate = Color(1, 0, 0, 1)
	yield(get_tree().create_timer(0.1), "timeout")
	damage_effect.modulate = Color(1, 1, 1, 1)
	
	set_health(health - health_increment)
	
func heal(health_amount:float):
	if (health >= 10): # If already full on health, don't try to increment
		play_sound("assets/sounds/battery_collect_full.wav", 1)
		return
	var new_health = health + health_amount
	set_health(new_health)
	
	# Play health visual effect
	var damage_effect = get_node("DamageEffect")
	damage_effect.modulate = Color(0, 1, 0.8, 1)
	yield(get_tree().create_timer(0.05), "timeout")
	damage_effect.modulate = Color(1, 1, 1, 1)
	yield(get_tree().create_timer(0.05), "timeout")
	damage_effect.modulate = Color(0, 1, 0.8, 1)
	yield(get_tree().create_timer(0.05), "timeout")
	damage_effect.modulate = Color(1, 1, 1, 1)
	
	# Adjust pitch based on new_health value
	var scaled_pitch = 2 + (new_health / 50)
	play_sound("assets/sounds/battery_collect.wav", scaled_pitch)
	if new_health >= 10:
		play_sound("assets/sounds/health_full.wav", 2)

func knockback(projectile_dir: Vector2 = Vector2.ZERO, deviation_angle: float = 0):
	var knockback_dir = projectile_dir.rotated(deviation_angle)  # apply deviation to projectile direction
	motion += -knockback_dir * knockback_force
	
func play_sound(sound_path, pitch):
	var collect_sound = load(sound_path)
	effect_audio_player.stream = collect_sound
	effect_audio_player.pitch_scale = pitch
	effect_audio_player.play()
	
func set_health(new_value):
	health = min(new_value, 10)
	emit_signal("health_changed")
