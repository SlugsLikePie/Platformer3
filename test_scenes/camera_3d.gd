extends Camera3D

func _on_player_2d_position_updated(delta, playerPosition2D) -> void:
	print(position, playerPosition2D)
	position.x = playerPosition2D.x * 0.01
	position.y = -playerPosition2D.y * 0.01

	# position.x = playerPosition2D.x
	# position.y = -playerPosition2D.y


#1.15
