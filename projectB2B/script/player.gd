extends KinematicBody

onready var boolet := $Armature/Skeleton/Camera/boolet

onready var handRik :SkeletonIK = $Armature/Skeleton/handR
onready var handLik :SkeletonIK = $Armature/Skeleton/handL
onready var cam :Camera = $Armature/Skeleton/Camera
onready var raycast :RayCast = $Armature/Skeleton/Camera/RayCast
onready var anim :AnimationTree = $AnimationTree
onready var weapon_anim :AnimationPlayer = $weaponsAnimation
onready var head_bone := $Armature/Skeleton/head
onready var timer = $Timer
onready var line = $Armature/Skeleton/Camera/line3d
var ammoLabel

onready var handR :Position3D = $Armature/Skeleton/IK/handR
onready var handL :Position3D = $Armature/Skeleton/IK/handL

var respown_point :Transform


var group

remote var movement_dir :Vector2
remote var player_pos :Vector3

const GRAVITY = -16.75
const JUMP = 7
var crouch :float = 0

var direction :Vector2 = Vector2()
const direction_limit :int = 5

const snap_dir = Vector3.DOWN
const snap_value = 16
var snap_vector :Vector3

var velocity :Vector3 = Vector3()
remote var movement_speed :float

const default_m_speed = 15.0
const crouch_m_speed = 5.0

var mouse_sensitivity :float = 0.1

enum state{
	IDLE,
	JUMP,
	CROUCH
}
remote var playerState = state.IDLE

enum{
	KNIFE1,
	PISTOL1,
	SHOTGUN1,
	AR1,
	SNIPER1
}
onready var weapons = {
	KNIFE1:get_node("Armature/Skeleton/Camera/weapon_holder/knife1"),
	PISTOL1:get_node("Armature/Skeleton/Camera/weapon_holder/pistol1"),
	SHOTGUN1:get_node("Armature/Skeleton/Camera/weapon_holder/shotgun1"),
	AR1:get_node("Armature/Skeleton/Camera/weapon_holder/AR1"),
	SNIPER1:get_node("Armature/Skeleton/Camera/weapon_holder/sniper1")
}
var weapon_dmg = {
	KNIFE1:50,
	PISTOL1:40,
	SHOTGUN1:100,
	AR1:50,
	SNIPER1:160
}
var weapon_shoot_timer = {
	KNIFE1:0.5,
	PISTOL1:0.1,
	SHOTGUN1:0.5,
	AR1:0.2,
	SNIPER1:0.7
}
var weapon_anim_name = {
	KNIFE1:"",
	PISTOL1:"pistol1_recoil",
	SHOTGUN1:"shotgun1_recoil",
	AR1:"ar1_recoil",
	SNIPER1:"sniper1_recoil"
}
var gun_scopeOn_anim = {
	AR1:"ar1_scope_in_recoil",
	SNIPER1:"sniper1_recoil"
}
var current_weapon = PISTOL1
var weaponBought = WeaponDetails.weapon
var scopeOn :bool = false

var maxGunAmmo = {
	PISTOL1:20,
	SHOTGUN1:7,
	AR1:30,
	SNIPER1:5
}
var gun_line_drawn_time = {
	PISTOL1:0.06,
	SHOTGUN1:0.07,
	AR1:0.05,
	SNIPER1:0.09
}

var gunPoint
var gun_ammo :int = maxGunAmmo[current_weapon]
var can_shoot :bool = true
var reloading :bool = false



func _ready():
	respown_point = global_transform
	add_to_group(group)
	boolet.add_to_group(group)
	set_process(false)
	if is_network_master():
		cam.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		set_process(true)
	gunPoint = weapons[current_weapon].get_node("gunPoint")
	handR.global_transform = weapons[current_weapon].get_node("handR").global_transform
	handL.global_transform = weapons[current_weapon].get_node("handL").global_transform
	handRik.start()
	handLik.start()
	anim.get("parameters/playback").start("movement")
	ammoLabel = get_parent().get_parent().get_node("players_info/gunAmmoLabel")
	ammoLabel.text = str(gun_ammo)

 ##all input events for weapon##

func _input(event):
	if is_network_master() and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		if event is InputEventMouseMotion:
			var drag :Vector2 = event.relative
			cam_rotation(drag)
			rpc_unreliable("cam_rotation", drag)
		
		if Input.is_action_just_pressed("knife"):
			weapon_change(KNIFE1)
			rpc("weapon_change", KNIFE1)
			ammoLabel.text = str(0)
		if Input.is_action_just_pressed("weapon"):
			weapon_change(weaponBought)
			rpc("weapon_change", weaponBought)
			ammoLabel.text = str(gun_ammo)
		if Input.is_action_just_pressed("reload"):
			if current_weapon != KNIFE1:
				gun_ammo = maxGunAmmo[current_weapon]
				ammoLabel.text = str(gun_ammo)

remote func cam_rotation(drag):
	self.rotate_y(deg2rad(drag.x * mouse_sensitivity * -1))
	cam.rotation.x -= deg2rad(drag.y * mouse_sensitivity)
	cam.rotation.x = clamp(cam.rotation.x, deg2rad(-60), deg2rad(60))
	hand_movement()

func hand_movement():
	handR.global_transform = weapons[current_weapon].get_node("handR").global_transform
	handL.global_transform = weapons[current_weapon].get_node("handL").global_transform

func weapon_changed(wp):
	if is_network_master():
		weapon_change(wp)
		rpc("weapon_change", wp)

remote func weapon_change(weapon):
	for weapon in weapons.keys():
		weapons[weapon].visible = false
	current_weapon = weapon
	weapons[current_weapon].visible = true
	handR.global_transform = weapons[current_weapon].get_node("handR").global_transform
	handL.global_transform = weapons[current_weapon].get_node("handL").global_transform

func _process(delta):
	if WeaponDetails.weapon != weaponBought:
		weaponBought = WeaponDetails.weapon
		scopeOn = false
		weapon_anim.play("defaultCamera")
		weapon_change(weaponBought)
		rpc("weapon_change", weaponBought)
		gun_ammo = maxGunAmmo[weaponBought]
		if weaponBought != KNIFE1:
			ammoLabel.text = str(gun_ammo)
		else:
			ammoLabel.text = str(0)

func _physics_process(delta):
	stateMovement()
	_player_movement(delta)
	if is_network_master() and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		_action()
	_animation()
	##movement##

func _player_movement(delta):
	if is_network_master():
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		
		if Input.is_action_pressed("jump"):
			if is_on_floor():
				velocity.y = JUMP
				playerState = state.JUMP
				rpc_unreliable("state_change", state.JUMP)
		
		if Input.is_action_pressed("crouch"):
			playerState = state.CROUCH
			rpc("state_change", state.CROUCH)
		else:
			playerState = state.IDLE
			rpc("state_change", state.IDLE)
		
		if is_on_ceiling():
			velocity.y = -2
		
		if Input.is_action_pressed("forward"):
			direction.y -= 1
		elif Input.is_action_pressed("backward"):
			direction.y += 1
		else:
			direction.y = 0
		
		if Input.is_action_pressed("left"):
			direction.x -= 1
		elif Input.is_action_pressed("right"):
			direction.x += 1
		else:
			direction.x = 0
		
		rset_unreliable("movement_dir", direction)
		rset_unreliable("player_pos", global_transform.origin)
	else:
		direction = movement_dir
		global_transform.origin = player_pos
	
	direction.y = clamp(direction.y, -direction_limit, direction_limit)
	direction.x = clamp(direction.x, -direction_limit, direction_limit)
	
	var DIR = Vector2()
	DIR = direction.normalized().rotated(-rotation.y)

	velocity.z = DIR.y * movement_speed
	velocity.x = DIR.x * movement_speed
	
	move_and_slide(velocity, Vector3.UP, true)

puppet func state_change(st):
	playerState = st

func stateMovement():
	match playerState:
		state.IDLE:
			movement_speed = default_m_speed
			crouch = 0
		state.JUMP:
			pass
		state.CROUCH:
			movement_speed = crouch_m_speed
			if crouch < 1:
				crouch += 0.1
			else:
				crouch = 1

func _animation():
	anim.set("parameters/movement/idle-walk/blend_amount", abs(direction.y))
	anim.set("parameters/movement/crouch-crouchWalk/blend_amount", abs(direction.y))
	match playerState:
		state.IDLE:
			anim.set("parameters/movement/idle-crouch/blend_amount", 0)
		state.JUMP:
			pass
		state.CROUCH:
			anim.set("parameters/movement/idle-crouch/blend_amount", crouch)
	hand_movement()

func _action():
	if not reloading:
		match current_weapon:
			KNIFE1:
				pass
			PISTOL1:
				if Input.is_action_just_pressed("shoot"):
					if can_shoot and raycast.is_colliding():
						prepare_boolet()
			SHOTGUN1:
				if Input.is_action_just_pressed("shoot"):
					if can_shoot and raycast.is_colliding():
						prepare_boolet()
			AR1:
				if Input.is_action_pressed("shoot"):
					if can_shoot and raycast.is_colliding():
						prepare_boolet()
				if Input.is_action_just_pressed("scope_on"):
					if can_shoot and not scopeOn:
						if weapon_anim.current_animation != "ar1_scope_in":
							weapon_anim.play("ar1_scope_in")
							scopeOn = true
				if Input.is_action_just_released("scope_on"):
					if weapon_anim.current_animation != "ar1_default":
						weapon_anim.play("ar1_default")
						scopeOn = false
			SNIPER1:
				if Input.is_action_just_pressed("shoot"):
					if can_shoot and raycast.is_colliding():
						prepare_boolet()
				if Input.is_action_just_pressed("scope_on"):
					if can_shoot and not scopeOn:
						if weapon_anim.current_animation != "sniper1_scope_in":
							weapon_anim.play("sniper1_scope_in")
							scopeOn = true
					elif scopeOn:
						if weapon_anim.current_animation != "sniper1_default":
							weapon_anim.play("sniper1_default")
						scopeOn = false

func prepare_boolet():
	if gun_ammo > 0:
		gunPoint = weapons[current_weapon].get_node("gunPoint")
		var current_pos = gunPoint.global_transform.origin
		var target_pos = raycast.get_collision_point()
		rpc("_boolet_shoot", current_pos, target_pos)
		can_shoot = false
		timer.wait_time = weapon_shoot_timer[current_weapon]
		timer.start()
		gun_ammo -= 1
		ammoLabel.text = str(gun_ammo)

sync func _boolet_shoot(current_pos, target_pos):
	if scopeOn:
		if weapon_anim.current_animation != gun_scopeOn_anim[current_weapon]:
			weapon_anim.play(gun_scopeOn_anim[current_weapon])
	else:
		if weapon_anim.current_animation != weapon_anim_name[current_weapon]:
			weapon_anim.play(weapon_anim_name[current_weapon])
	
	line.points = [current_pos, target_pos]
	line.startTimer(gun_line_drawn_time[current_weapon])
	line.show()
	boolet.transform.origin = current_pos
	boolet.look_at_from_position(current_pos,target_pos, Vector3.UP)
	boolet.dmg = weapon_dmg[current_weapon]
	boolet.hit()

func dmg_taken(dmg):
	if is_network_master():
		var id = get_tree().get_rpc_sender_id()
		Globals.HP -= dmg
		if Globals.HP <= 0:
			player_died()
			rpc("player_died")
			Globals.HP = 100
			rpc_id(id, "score_increse")

puppet func score_increse():
	Globals.score += 1
	update_score(get_name(), Globals.score)
	rpc("update_score", get_name(), Globals.score)

remote func update_score(id, val):
	Globals.players_score[id] = val

puppet func player_died():
	global_transform = respown_point

func _on_Timer_timeout():
	can_shoot = true

func _on_Timer2_timeout():
	pass
