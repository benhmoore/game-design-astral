extends Area2D

var invincible = false setget set_invincible

onready var timer = $Timer
onready var collision_shape = $CollisionShape2D

signal invincibility_started
signal invincibility_ended

func set_invincible(value):
	invincible = value
	if invincible == true:
		emit_signal("invincibility_started")
	else:
		emit_signal("invincibility_ended")

func start_invincibility(duration):
	self.invincible = true
	timer.start(duration)

func _on_Timer_timeout():
	self.invincible = false

func _on_HurtBox_invincibility_started():
	collision_shape.set_deferred("disabled", true)

func _on_HurtBox_invincibility_ended():
	collision_shape.disabled = false
