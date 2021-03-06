extends RigidBody2D

export var speed = 400

var fire_range = 0

var fire_rotation = 0

var fire_damage = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	gravity_scale = 0
	apply_impulse(Vector2(), Vector2(speed, 0).rotated(fire_rotation))
	disappear()

func init(angle, damage, fr):
	fire_rotation = angle
	fire_damage = damage
	fire_range = fr
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func disappear():
	yield(get_tree().create_timer(ceil(float(fire_range) / float(speed))), "timeout")
	queue_free()

func _on_CannonBall_body_entered(body):
	if body.has_method("type"):
		if body.type() == "ship":
			body.call("hit", fire_damage)
			self.hide()
		if body.type() == "city":
			print("hit city")
			self.hide()
			
