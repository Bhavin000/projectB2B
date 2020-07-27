extends Control

var idx = 0

func _ready():
	Globals.connect("list_changed", self, "_refresh_lobby")
	$players.hide()

func _on_host_pressed():
	if $connect/name.text != "":
		var name = $connect/name.text
		Globals.host(name)
	
	$connect.hide()
	$players.show()
	$players/start.show()
	$players/maps.show()
	$players/ready.hide()

func _on_join_pressed():
	if $connect/name.text != "":
		var name = $connect/name.text
		var ip = "127.0.0.1"
		Globals.join(ip,name)
	
	$connect.hide()
	$players.show()
	$players/start.hide()
	$players/maps.hide()
	$players/ready.show()

func _refresh_lobby():
	$players/list.clear()
	var players = Globals.get_player_list()
	players.sort()
	var me = $connect/name.text
	$players/list.add_item(me)
	for p in players:
		$players/list.add_item(str(p))


func _on_start_pressed():
	Globals.begin_game()
	#$players/start.disabled = true

func _on_maps_item_selected(index):
	idx = index
	$players/start.show()

func _on_ready_pressed():
	Globals.rpc("player_ready", get_tree().get_network_unique_id())
	$players/ready.disabled = true
