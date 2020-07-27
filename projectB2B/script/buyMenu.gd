extends Control

onready var buyButton = $Panel/Panel/buyButton
onready var buyValue = $Panel/Panel/buyValue
onready var totalValue = $Panel/totalValue

var totalValue_amt :int = 10000

var weaponCost :Array = [100, 200, 500, 1000]

var idx :int = -1

func _ready():
	hide()
	buyButton.disabled = true
	buyValue.hide()

func _input(event):
	if Input.is_action_just_pressed("buy"):
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_buyButton_pressed():
	
	WeaponDetails.weapon = WeaponDetails.weaponIdx[idx]

func _on_close_pressed():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	


func _on_0_pressed():
	idx = 0
	buyValue.show()
	buyButton.disabled = false

func _on_1_pressed():
	idx = 1
	buyValue.show()
	buyButton.disabled = false

func _on_2_pressed():
	idx = 2
	buyValue.show()
	buyButton.disabled = false

func _on_3_pressed():
	idx = 3
	buyValue.show()
	buyButton.disabled = false
