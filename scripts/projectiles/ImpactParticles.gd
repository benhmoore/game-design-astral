extends CPUParticles2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_CPUParticles2D_ready():
	set_process_internal(true)
	get_node("Timer").start()


func _on_Timer_timeout():
	queue_free()
