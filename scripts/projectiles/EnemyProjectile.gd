extends Area2D

export(int) var SPEED: int = 300
export(int) var damage = 10
export(Vector2) var knockback_vector = Vector2.ZERO
export(Vector2) var initial_direction = knockback_vector
export(float) var knockback_multiplier = 1.5
var shooter = self
export(int) var ran = 0

signal hit

export var hit_particles: PackedScene
export(PackedScene) var EnemyProjectile


func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	if ran == 0:
		initial_direction = global_position.direction_to(get_tree().get_nodes_in_group("player")[0].global_position)
		ran = 1
	else:
		direction = initial_direction
	global_position += direction * SPEED * delta


func get_knockback_vector():
	return Vector2.RIGHT.rotated(rotation).normalized() * knockback_multiplier

func destroy():
	pass;
	
func set_shooter(shooter):
	self.shooter = shooter


func _on_Projectile_body_entered(body: PhysicsBody2D) -> void:
	if body.is_in_group("walls") || body.is_in_group("player"):
		shooter = self
		body.emit_signal("hit")
		print("Enemy _on_Projectile_body_entered", body)
		var hit = hit_particles.instance()
		get_tree().current_scene.add_child(hit)
		hit.global_transform.origin = global_transform.origin + Vector2(15,0)
		hit.global_rotation = get_rotation() + PI
		destroy()


func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	pass;
