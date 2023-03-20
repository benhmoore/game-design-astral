extends Node

export var health: int = 20 setget set_health

func set_health(value):
	health = value
	if health <= 0:
		health = 0
		emit_signal("no_health")

signal no_health
