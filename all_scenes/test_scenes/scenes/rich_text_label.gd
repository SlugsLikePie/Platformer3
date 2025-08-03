extends RichTextLabel

func _on_player_2d_velocity_updated(delta, velocity) -> void:
	text = "Velocity: %s" % velocity
