extends Position2D

# Declare member variables here. Examples:
export var default_cannon_gun_position = float(80)

# Called when the node enters the scene tree for the first time.
func _ready():
	$CannonGunPosition.transform.x = Vector2(default_cannon_gun_position, 0)

func get_position():
	return $CannonGunPosition.get_global_position()

func show_gun_fire():
	$CannonGunFireSmoke.set_emitting(true)
