extends Area2D

export(int) var SPEED: int = 1500
signal hit

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += direction * SPEED * delta

func destroy():
	queue_free()

func _on_Projectile_body_entered(body: PhysicsBody2D) -> void:
	if body.is_in_group("walls"):
		body.emit_signal("hit")
		destroy()

func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	queue_free()
