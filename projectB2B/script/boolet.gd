extends Spatial

onready var raycast = $RayCast

var dmg :int
var canHit :bool = true

func hit():
	var area = raycast.get_collider()
	if area and area is Area:
		for g in Globals.groups:
			if self.is_in_group(g) and area.get_parent().get_parent().get_parent().get_parent().is_in_group(g):
				canHit = false
		if canHit:
			if area.get_parent().get_parent().get_parent().get_parent().has_method("dmg_taken"):   #area/bone/skeleton/armature/player
				match area.name:
					"head":
						dmg = dmg
					"chest":
						dmg = int(dmg*0.8)
					"torso":
						dmg = int(dmg*0.6)
					"hand":
						dmg = int(dmg*0.7)
					"leg":
						dmg = int(dmg*0.5)
				area.get_parent().get_parent().get_parent().get_parent().dmg_taken(dmg)


