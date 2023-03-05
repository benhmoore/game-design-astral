extends KinematicBody2D

# PlayerCharacter signals
signal health_changed # Emitted whenever heal() or damage() is called
signal ammo_changed # Emitted whenever ammo is added or removed
signal player_death # Emitted when the player's health reaches 0

# Player movement variables
export var max_speed = 325
export var acceleration = 2000
export var friction = 1750
var is_moving = false
var is_sprinting = false

# Player health variables
var health:float = 6 setget set_health
export var lives = 3
var low_health_timer = 0

# Player emote variables
enum emotes {
	EXLAIM,
	QUESTION,
	LOVE,
	IDLE
}
var current_emote = emotes.IDLE

# Player shooting variables
export var projectile_scene: PackedScene
export var max_ammo = 10
export var knockback_force = 175
var current_ammo:float = 0 setget set_current_ammo
var is_shooting = false
var gun_recharge_timer = 0

# Audio players
onready var shoot_audio_player = get_node("ShootAudioPlayer")
onready var footsteps_audio_player = get_node("FootstepsAudioPlayer")
onready var effect_audio_player = get_node("EffectAudioPlayer")
onready var danger_audio_player = get_node("DangerAudioPlayer")

# References to other nodes
onready var camera = get_node("PlayerCamera")
onready var damage_effect = get_node("DamageEffect")
onready var emote = get_node("EmoteSprite")

# Used to determine the player's current motion
var motion = Vector2.ZERO

func _process(delta:float):
	""" Updates player health and ammo. """

	# If the player's health is low, play low health sound effect
	# and display a damage effect
	low_health_timer += delta
	if low_health_timer > 0.1:
		if health < 3 and health > 0.1:
			if low_health_timer >= max(0.4,(pow(health, 1.5) / 5)):

				# Play the low health sound effect
				danger_audio_player.play()
				
				# Flash the damage effect
				flash_low_health()

				low_health_timer = 0
				
	# If the player's health is 0, emit the player_death signal
	# and enable the damage effect indefinitely
	# Otherwise, gradually decrease the player's health
	if health <= 0:
		damage_effect.modulate = Color(1, 0.58, 0.43,1)
		emit_signal("player_death")
	else:
		# If the player is sprinting, decrease their health faster
		if is_sprinting:
			set_health(health - (delta * 0.4))
		else:
			set_health(health - (delta * 0.1))

	# If health is 1, display exclaimation emote
	if health <= 1:
		emote_exclaim()
	elif current_emote == emotes.EXLAIM:
		emote_idle()

	
	# If the play is not shooting, and their ammo is less than 10,
	# gradually recharge their ammo
	if current_ammo < 10:
		if is_shooting == false:
			
			# Recharge the players ammo to a maximum of 10
			var new_ammo = min(current_ammo + (delta*15), max_ammo)
			set_current_ammo(new_ammo)
			if new_ammo >= 10:
				play_sound("assets/sounds/reloaded.wav", 2)

	# If the player is shooting, play the shooting sound effect,
	# spawn a projectile, and decrease the player's ammo
	if Input.is_action_pressed("action_shoot"):
		var mouse_direction = global_position.direction_to(get_global_mouse_position())
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
		
func flash_low_health(duration:float=0.2):
	""" Flashes the damage effect. """
	# Display the damage effect for 0.3 sec
	damage_effect.modulate = Color(1, 0.58, 0.43,1)
	yield(get_tree().create_timer(duration), "timeout") 
	damage_effect.modulate = Color(1, 1, 1, 1)


func set_current_ammo(new_value:float):
	""" Sets the player's current ammo. """
	current_ammo = new_value
	emit_signal("ammo_changed")
	
func _physics_process(delta:float):
	""" Updates player movement and plays the footsteps sound effect. """

	# Move the player
	calculate_movement(delta)
	
	# Play the footsteps sound effect if the player is moving
	if motion != Vector2.ZERO:
		if not footsteps_audio_player.playing:

			# Increase the pitch of the footsteps sound effect if the player is sprinting
			if is_sprinting:
				footsteps_audio_player.pitch_scale = 1.3
			else:
				footsteps_audio_player.pitch_scale = 1
			footsteps_audio_player.play()
	else:
		footsteps_audio_player.stop()

func calculate_movement(delta:float):
	# Get the player's input and mouse position
	var input_vector = get_input_vector()
	var mouse_position = get_global_mouse_position()

	# Determine which sprite to use based on distance from the player to the mouse position
	var sprite_animation = "idle.front.right"
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
	
	# If the player is holding down a movement key, accelerate them in that direction
	if input_vector != Vector2.ZERO:
		new_motion += input_vector.normalized() * acceleration * delta
	
		# Limit the player's speed to max_speed
		new_motion = new_motion.limit_length(max_speed)

		# If the player is holding down the sprint key, increase their speed by 50%
		var sprint_multiplier = 1
		is_sprinting = false
		if Input.is_action_pressed("action_sprint"):
			sprint_multiplier = 1.5
			is_sprinting = true
		new_motion = new_motion * sprint_multiplier
	
	# If the player is not holding down a movement key 
	# and is not experiencing knockback, 
	# gradually slow them down with friction
	if input_vector == Vector2.ZERO:
		var friction_force = motion.normalized() * friction * delta
		if friction_force.length() > motion.length():
			new_motion = Vector2.ZERO
		else:
			new_motion -= friction_force

	# Move the player based on their new motion
	if move_and_collide(motion * delta) != null:
		motion = Vector2.ZERO
	else:
		motion = new_motion

func get_input_vector():
	""" Returns a normalized vector representing the player's directional input. """
	
	var input_vector = Vector2.ZERO
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
	
	# Normalize the input vector to ensure that 
	# diagonal movement is not faster than horizontal/vertical movement
	return input_vector.normalized()

func shoot(projectile_dir: Vector2 = Vector2.ZERO, deviation_angle = 0):
	""" Spawns a projectile in the direction of the mouse cursor and initiates knockback. """
	
	# If the player has no ammo, play the empty sound effect and return
	# Otherwise, decrease the player's ammo
	if current_ammo < 0.1:
		play_sound("assets/sounds/battery_collect_full.wav", 1)
		return
	else:
		set_current_ammo(current_ammo-0.8)
	
	# Simulate recoil by applying a force in the opposite direction of the projectile
	knockback(projectile_dir, deviation_angle)
	
	# Spawn a projectile in the direction of the mouse cursor
	var projectile = projectile_scene.instance()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position

	# Rotate the projectile to face the mouse cursor
	var projectile_rot = projectile_dir.angle() + deviation_angle
	projectile.rotation = projectile_rot
	
	# Load and play the sound effect
	shoot_audio_player.pitch_scale = rand_range(1.2, 1.4)
	shoot_audio_player.play()
	
	# Shake the camera
	camera.flash_screen()
	
	set_health(health - 0.05)

func emote_exclaim(duration:float=-1):
	""" Displays the exclamation mark emote. """
	emote.frame = 0
	emote.show()
	current_emote = emotes.EXLAIM
	if duration > 0:
		yield(get_tree().create_timer(duration), "timeout")
		emote_idle()

func emote_question(duration:float=-1):
	""" Displays the question mark emote. """
	emote.frame = 1
	emote.show()
	current_emote = emotes.QUESTION
	if duration > 0:
		yield(get_tree().create_timer(duration), "timeout")
		emote_idle()

func emote_love(duration:float=-1):
	""" Displays the heart emote. """
	emote.frame = 2
	emote.show()
	current_emote = emotes.LOVE
	if duration > 0:
		yield(get_tree().create_timer(duration), "timeout")
		emote_idle()

func emote_idle():
	""" Displays the exclamation mark emote. """
	emote.hide()
	current_emote = emotes.IDLE

func damage(decrease_amount:float=1):
	""" Decreases the player's health and plays the damage visual and sound effect. """

	# Play damage visual effect
	damage_effect.modulate = Color(1, 0, 0, 1)
	yield(get_tree().create_timer(0.1), "timeout")
	damage_effect.modulate = Color(1, 1, 1, 1)
	yield(get_tree().create_timer(0.05), "timeout")
	damage_effect.modulate = Color(1, 0, 0, 1)
	yield(get_tree().create_timer(0.1), "timeout")
	damage_effect.modulate = Color(1, 1, 1, 1)
	
	# Decrease the player's health
	set_health(health - decrease_amount)

	# Play the hurt sound effect
	play_sound("assets/sounds/hurt_1.wav")
	
func heal(increase_amount:float=1):
	""" Increases the player's health and plays the heal visual and sound effect. """
	if (health >= 10): # If already full on health, don't try to increment
		play_sound("assets/sounds/battery_collect_full.wav")
		return
	var new_health = health + increase_amount
	set_health(new_health)
	
	# Play health visual effect
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
	
func play_sound(sound_path, pitch:float=1):
	var collect_sound = load(sound_path)
	effect_audio_player.stream = collect_sound
	effect_audio_player.pitch_scale = pitch
	effect_audio_player.play()
	
func set_health(new_value):
	health = min(new_value, 10)
	emit_signal("health_changed")


func _on_PlayerCharacter_player_death():
	pass # Replace with function body.
