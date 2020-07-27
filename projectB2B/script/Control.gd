extends Control

onready var crossHeir = $crossHeir
onready var fpsLabel = $fpsLabel
onready var hpBar = $hpBar
onready var players = $players
onready var scoreLabel = $scoreLabel

func _ready():
	pass

func _process(delta):
	fpsLabel.text = str(Engine.get_frames_per_second())
	hpBar.value = Globals.HP
	scoreLabel.text = str(Globals.score)
	
	for p in Globals.players_score:
		players.get_node(p+"/score").text = str(Globals.players_score[p])

func _input(event):
	if Input.is_action_just_pressed("playerInfo"):
		players.show()
	if Input.is_action_just_released("playerInfo"):
		players.hide()

