extends KinematicBody2D

export var max_speed = 150
export var acceleration = 1500
export var projectile_scene: PackedScene
export var knockback_force = 250
export var friction = 2000

var motion = Vector2.ZERO

func _physics_process(delta):
	var input_vector = get_input_vector()
	
	# Calculate the player's new motion based on input and acceleration
	var new_motion = motion
	if input_vector != Vector2.ZERO:
		new_motion += input_vector.normalized() * acceleration * delta
	new_motion = new_motion.limit_length(max_speed)
	
	# If the player is not holding down a movement key and is not experiencing knockback, gradually slow them down with friction
	if input_vector == Vector2.ZERO:
		var friction_force = motion.normalized() * friction * delta
		print("friction_force: ", friction_force.length())
		print("motion: ", motion.length())
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

	if Input.is_action_just_pressed("action_shoot"):
		var projectile_direction = global_position.direction_to(get_global_mouse_position())
		shoot(projectile_direction)
		knockback(projectile_direction)

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

func shoot(projectile_dir: Vector2 = Vector2.ZERO):
	var projectile = projectile_scene.instance()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position

	var projectile_rot = projectile_dir.angle()
	projectile.rotation = projectile_rot

func knockback(projectile_dir: Vector2 = Vector2.ZERO):
	motion += -projectile_dir * knockback_force
