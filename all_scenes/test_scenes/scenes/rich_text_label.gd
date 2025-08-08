extends RichTextLabel

func _on_player_2d_velocity_updated(delta, player_2d_velocity) -> void:
	text = "Velocity: %s" % player_2d_velocity