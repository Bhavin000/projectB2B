extends Node




sync func show_lobby():
	Engine.time_scale = 0.1
	$timers/game_time.stop()
	$Control.show()

func _on_lobby_pressed():
	get_tree().get_root().get_node("lobby").show()
	if get_tree().is_network_server():
		get_tree().get_root().get_node("lobby/players/start").disabled = false
	else:
		get_tree().get_root().get_node("lobby/players/ready").disabled = false
	queue_free()
