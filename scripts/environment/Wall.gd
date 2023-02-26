extends KinematicBody2D

onready var hit_audio_player = get_node("HitAudioPlayer")
signal hit

func _on_WallBlock_hit():
	var random_pitch_adjust = rand_range(2.6, 3.8)
	hit_audio_player.pitch_scale = random_pitch_adjust
	hit_audio_player.play()
