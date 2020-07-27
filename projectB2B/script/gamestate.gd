extends Node

const DEFAULT_PORT = 4042
const MAX_PLAYER = 6
var player_info_pos = 40

var HP :int = 100
var score :int = 0

var groups = ["A","B","C","D","E","F"]

onready var map = preload("res://scenes/main.tscn")

var players = {}
var player_name = "player"
var players_score = {}

signal list_changed()

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	

func host(name):
	player_name = name
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYER)
	get_tree().set_network_peer(peer)
	emit_signal("list_changed")

func join(ip,name):
	player_name = name
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)

func _player_connected(id):
	rpc_id(id, "register_player", player_name)

remote func register_player(player):
	var id = get_tree().get_rpc_sender_id()
	players[id] = player
	emit_signal("list_changed")

func _player_disconnected(id):
	players.erase(id)
	emit_signal("list_changed")

func get_player_list():
	return players.values()

remote func pre_config_game(spawn_point):
	get_tree().get_root().get_node("lobby").hide()
	var idx = get_tree().get_root().get_node("lobby").idx
	if idx > -1:
		var world = map.instance()
		get_tree().get_root().add_child(world)
	
		var _player = preload("res://scenes/player/player.tscn")
		for p in spawn_point:
			var spawn = world.get_node("position/"+str(spawn_point[p])).global_transform
			world.get_node("position/"+str(spawn_point[p])).set_name(str(p))
			var player = _player.instance()
			player.set_name(str(p))
			player.global_transform = spawn
			player.set_network_master(p)
			
			player.group = groups[spawn_point[p]]
			
			world.get_node("players").add_child(player)
			
			world.get_node("players_info/players/"+str(spawn_point[p])).show()
			world.get_node("players_info/players/"+str(spawn_point[p])).set_name(str(p))
			players_score[str(p)] = 0
			
			
			if p == get_tree().get_network_unique_id():
				#player.set_player_name(player_name)
				world.get_node("players_info/players/"+str(p)).text = player_name
			else:
				#player.set_player_name(players[p])
				world.get_node("players_info/players/"+str(p)).text = players[p]
			
			
	
var players_ready = []

remote func player_ready(id):
	players_ready.append(id)

func All_client_ready():
	if len(players_ready) == players.size():
		return true
	return false

func begin_game():
	assert(get_tree().is_network_server())
	if All_client_ready():
		var spawn_point = {}
		spawn_point[1] = 1 #server
		var spawn_idx = 2
		for i in players:
			spawn_point[i] = spawn_idx
			spawn_idx += 1
		
		for p in players:
			rpc_id(p, "pre_config_game", spawn_point)
		pre_config_game(spawn_point)
		players_ready.clear()
		get_tree().get_root().get_node("lobby/players/start").disabled = true
