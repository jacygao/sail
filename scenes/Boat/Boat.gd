extends KinematicBody2D

export var team = 1

export var id = "player_boat_1"

var default_boat_id = "brigantine"
export (Texture) var boat_sprite = load(Ship_Meta.get_asset_path(default_boat_id))

var default_wrack_id = "wrack"
export (Texture) var wrack_sprite = load(Ship_Meta.get_asset_path(default_wrack_id)) 

# navigation speed
export var default_speed = 100
var speed = 0

# acceleration speed
export (float) var default_acceleration = 1
var acceleration = default_acceleration

# turnning speed
export (float) var default_rotation_speed = 1
var rotation_speed = 0

var steering_angle = 30

var friction = -0.9
var drag = -0.0015
var braking = -1

var wheel_base = 100
var steer_angle

var traction_fast = 0.1  # High-speed traction

# default health
export var max_durability = 10
var durability = 0

# Setting cannon gun related attributes.
# These values are now in the CannonGun nodes as well but 
# they will still need to be set in order to customise
export (int) var fire_damage = 0
export var fire_max_range = 400
export var fire_blind_range = 100
export var fire_rate = 2.0

# speed sets to 0 when true
var is_anchor_on = true

var static_velocity = Vector2()
var angle = 0

# navigation control variables
var cur_rotation = 0
var rotation_dir = 0
var velocity = Vector2()

var smoke = preload("res://scenes/Boat/Smoke.tscn")
var cannon_ball = preload("res://scenes/CannonBall/CannonBall.tscn")

# v2
# when player is in BATTLING state, cannons fire at the target node.
var target_node = null

# target_direction defines the direction the player ship is moving towards.
var target_direction = Vector2()

# TODO: Making these constant shared
enum {IDLE, MOVING, ATTACKING, ATTACKED, BATTLING, SINKING, FLEEING, DOCKING}

# default player state to IDLE
var player_state = IDLE

signal is_sinking
signal battle_victory(node)
signal state_changed(state)
signal is_hit(damage)

# Called when the node enters the scene tree for thes first time.
func _ready():
	$CannonGunRight.rotation_degrees = 0
	$CannonGunLeft.rotation_degrees = 180
	$AnimatedBoatSprite.texture = boat_sprite

func init_node(damage:int, max_health:int, cur_health:int, max_speed:int):
	fire_damage = damage
	max_durability = max_health
	durability = cur_health
	default_speed = max_speed

# Meta Getters
func type():
	return "ship"
	
func id():
	return id

func team():
	return team

func state():
	return player_state

func set_state(s):
	player_state = s
	emit_signal("state_changed", s)

func set_state_idle():
	set_state(IDLE)
	target_node = null

func set_state_moving_toward_mouse_position():
	target_node = null
	target_direction = get_global_mouse_position() - get_global_position()
	set_state(MOVING)
	
func set_state_moving(direction):
	target_node = null
	target_direction = direction
	set_state(MOVING)

func set_state_docking(target):
	target_node = target
	set_state(DOCKING)
	
func set_state_attacked():
	set_state(ATTACKED)

func set_state_attacking(target):
	set_state(ATTACKING)
	target_node = target
	$HostileController.append(target)
	
func set_state_battling(node):
	set_state(BATTLING)
	target_node = node
	print("battle has started")
	
func set_state_sinking():
	set_state(SINKING)
	
func set_default_state():
	set_state_idle()
	
# ensures the angle is netween -179 and 180 degrees
func angle_tidy(a):
	if a > 180:
		a = (360 - a) * -1
	if a < -180:
		a = 360 - a * -1
	return a

func anchor_on():
	rotation_speed = 0
	is_anchor_on = true
	set_state_idle()
	
func anchor_off():
	rotation_speed = default_rotation_speed
	is_anchor_on = false

# Change the target whenever a touch event happens.
func _input(event):
	rotation_dir = 0
	if event.is_action_pressed('ui_right'):
		rotation_dir += 1
	if event.is_action_pressed('ui_left'):
		rotation_dir -= 1
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if player_state == SINKING:
		return
	if durability == 0:
		print(id(), " boat has sunk")
		sink()
		# TODO: player boat has sunk.. what now?
		
func _physics_process(delta):
	match player_state:
		IDLE:
			move_animate(delta)
		MOVING:
			move_animate(delta)
		ATTACKING:
			attack_animate(delta)
		BATTLING:
			battle_animate(delta)
		SINKING:
			pass
		DOCKING:
			move_animate(delta)

func move_animate(delta):
	if target_node != null || target_direction != null:
		move_and_rotate_animate(delta)
	else:
		set_default_state()

func attack_animate(delta):
	move_and_rotate_animate(delta)

# Activates when boat is in battle
func battle_animate(delta):
	if target_node.state() == SINKING:
		set_state(IDLE)
		emit_signal("battle_victory", target_node)
		target_node = null
	else:
		move_and_rotate_animate(delta)

func move_and_rotate_animate(delta):
	apply_friction()
	accelerate()
	steer(delta)
	
	move_and_slide(velocity)

func get_rotation_speed():
	return speed/default_speed * default_rotation_speed

func steer(delta):
	# Calculate steering direction
	var target_direction = get_target_direction()
	
	var turn = 0
	# turn boat right
	var relative_angle = velocity.angle_to(target_direction)
	# disable boat steering within blind angles
	var blind_angle = deg2rad(179)
	
	if relative_angle < blind_angle && relative_angle > blind_angle*-1:
		if relative_angle < 0 :
			turn += 1
		# turn boat left
		elif relative_angle > 0:
			turn-= 1
		
	steer_angle = turn * deg2rad(steering_angle)

	# Calculate velocity
	velocity = transform.x * speed
	var rear_wheel = position - transform.x * wheel_base / 2.0
	var front_wheel = position + transform.x * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_angle) * delta
	var new_heading = (front_wheel - rear_wheel).normalized()
	velocity = velocity.linear_interpolate(new_heading * velocity.length(), traction_fast)
	rotation = new_heading.angle()
		
func accelerate():
	if !is_anchor_on:
		if speed > default_speed:
			speed = default_speed
		elif speed < default_speed:
			speed += acceleration
	else:
		if speed < 0:
			speed = 0
		else:
			speed += braking
			
func apply_friction():
	if velocity.length() < 5:
		velocity = Vector2.ZERO
	var friction_force = velocity * friction
	var drag_force = velocity * velocity.length() * drag
	if velocity.length() < 100:
		friction_force *= 3
	velocity += drag_force + friction_force
	
func get_target_direction():
	if target_node != null:
		target_direction = target_node.get_position() - get_global_position()
	if player_state == BATTLING:
		return target_direction.rotated(deg2rad(90))
	return target_direction
	
func fire_animate_left(target):
	if $HostileController.has(target.id()):
		fire_animate($CannonGunLeft/CannonGunAngle, target)
		
func fire_animate_right(target):
	if $HostileController.has(target.id()):
		fire_animate($CannonGunRight/CannonGunAngle, target)
	
# Fires an animated cannon ball at a given vector position
func fire_animate(gun, target):
	var cannon_ball_ins = cannon_ball.instance()
	var angle = (target.get_global_position() - get_global_position()).angle()
	cannon_ball_ins.position = gun.get_node("CannonGunPosition").get_global_position()
	cannon_ball_ins.init(angle, fire_damage, fire_max_range)
	gun.show_gun_fire()
	get_parent().get_parent().add_child(cannon_ball_ins)
	
func hit(damage):
	durability -= damage
	$Fire.set_emitting(true)
	$HealthDisplay.update_healthbar(durability)
	$DamageController.show_value(damage, true)
	emit_signal("is_hit", damage)

func sink():
	speed = 0
	rotation_speed = 0
	$AnimatedBoatSprite.texture = wrack_sprite
	set_state_sinking()
	emit_signal("is_sinking")
	
func update_health_display():
	$HealthDisplay.update_max_health(max_durability)
	$HealthDisplay.update_healthbar(durability)

func _on_CollisionDetector_body_entered(body):
	if body.has_method("id") && body.id() != id():
		if body.has_method("type") && body.type() == "ship":
			if state() == ATTACKING || state() == ATTACKED:
				# battle starts
				set_state_battling(body)

func _on_CollisionDetector_body_exited(body):
	if body.has_method("id") && body.id() != id():
		if body.has_method("type") && body.type() == "ship":
			if state() == ATTACKING || state() == ATTACKED:
				# battle starts
				set_state_attacking(body)

func _on_CannonGunLeft_fire(target):
	fire_animate_right(target)

func _on_CannonGunRight_fire(target):
	fire_animate_left(target)
