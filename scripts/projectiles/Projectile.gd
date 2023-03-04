extends Area2D

export(int) var SPEED: int = 1500
signal hit

export var hit_particles: PackedScene

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += direction * SPEED * delta

func destroy():
	queue_free()

func _on_Projectile_body_entered(body: PhysicsBody2D) -> void:
	if body.is_in_group("walls"):
		body.emit_signal("hit")
		var hit = hit_particles.instance()
		get_tree().current_scene.add_child(hit)
		hit.global_transform.origin = global_transform.origin + Vector2(15,0)
		hit.global_rotation = get_rotation() + PI

		destroy()

func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	queue_free()
