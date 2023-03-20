extends KinematicBody2D

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200 
export var WANDER_TARGET_RANGE = 6
export(PackedScene) var EnemyDeathParticles


enum {
	IDLE,
	WANDER,
	CHASE
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

var state = IDLE

onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var player_detection_zone = $PlayerDetectionZone
onready var hurtbox = $HurtBox
onready var soft_collision = $SoftCollision
onready var wander_controller = $WanderController
onready var animation_player = $AnimationPlayer
onready var particles_instance = $EnemyDeathParticles

func _ready():
	state = pick_random_state([IDLE, WANDER])
	add_to_group("enemy")
	hurtbox.connect("hit", self, "_on_hit")
	stats.connect("no_health", self, "_on_Stats_no_health")
	
func _on_hit():
	print("Enemy's hurtbox has been hit")
	
func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander()
		
		WANDER:
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander()
			accelerate_towards_point(wander_controller.target_position, delta)
			if global_position.distance_to(wander_controller.target_position) <= WANDER_TARGET_RANGE:
				update_wander()
		
		CHASE:
			var player = player_detection_zone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
			else:
				state = IDLE
	
	if soft_collision.is_colliding():
		velocity += soft_collision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)

func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func seek_player():
	if player_detection_zone.can_see_player():
		state = CHASE

func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wander_controller.start_wander_timer(rand_range(1, 3))

func pick_random_state(state_list: Array):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Stats_no_health():
	var particles_instance = EnemyDeathParticles.instance()
	get_parent().add_child(particles_instance)
	particles_instance.global_position = global_position
	particles_instance.one_shot = true
	particles_instance.emitting = true
	queue_free()

func _on_HurtBox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 120
	hurtbox.start_invincibility(0.4)

func _on_HurtBox_invincibility_started():
	animation_player.play("Start")

func _on_HurtBox_invincibility_ended():
	animation_player.play("Stop")

