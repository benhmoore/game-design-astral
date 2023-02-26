extends Area2D

export(int) var SPEED: int = 500

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += direction * SPEED * delta

func destroy():
	queue_free()

func _on_Projectile_body_entered(_body: PhysicsBody2D) -> void:
	# if body.is_in_group("enemies"):
	destroy()

func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	queue_free()
