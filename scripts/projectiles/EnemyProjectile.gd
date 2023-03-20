extends Area2D

export(int) var SPEED: int = 1500
export(int) var damage = 10
export(Vector2) var knockback_vector = Vector2.ZERO
export(float) var knockback_multiplier = 1.5
var shooter = self

signal hit

export var hit_particles: PackedScene
export(PackedScene) var EnemyProjectile


func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	if shooter.is_in_group("enemy"):
		direction = global_position.direction_to(get_tree().get_nodes_in_group("player")[0].global_position)
	global_position += direction * SPEED * delta


func get_knockback_vector():
	return Vector2.RIGHT.rotated(rotation).normalized() * knockback_multiplier

func destroy():
	queue_free()

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
	queue_free()
