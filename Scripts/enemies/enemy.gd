
# #####################
# # enemy     .SCRIPT #
# #####################

class_name Enemy
extends CharacterBody2D

# Horizontal speed in pixels per second.
const max_speed:float = 300.0
@export var speed:float = max_speed
# Vertical acceleration in pixel per second squared.
@export var gravity:float = 2000.0
# Vertical speed applied when jumping.
@export var jump_impulse:float = 1200.0

var particles_res:Resource = preload("res://Scenes/Enemies/hit_particles.tscn")

var Head_hit1_img:CompressedTexture2D = preload("res://Assets/Enemy/monster_1/enemy_head1.png")
var Head_hit2_img:CompressedTexture2D = preload("res://Assets/Enemy/monster_1/enemy_head2.png")
var Head_hit3_img:CompressedTexture2D = preload("res://Assets/Enemy/monster_1/enemy_head3.png")
var texture_nr:int = 0

@onready var hurt_sounds = [load("res://Assets/Sounds/Enemy2/Hurt1.wav"),
	load("res://Assets/Sounds/Enemy2/Hurt2.wav"),
	load("res://Assets/Sounds/Enemy2/Hurt3.wav")]

var screen_size : Vector2
var gun_fire:bool = false

var direction:String = "L"
var move_left:bool = false
var move_right:bool = false

var weapon : Sprite2D
var previous_state : String
var health:int = 100
const health_max:int = 100
var gold_amount:int = 0

var on_screen:bool = false
var see_Player:bool = false

const contact_distance:float = 1100.0
const follow_distance:float = 2000.0
const change_direction_distance:float = 200.0

var first_hero_catch:bool = false

var head:Node

var collision:KinematicCollision2D 

signal somebody_hitme
signal enemy2_death
var player_collision_point:Vector2

var drone:CharacterBody2D

@onready var flying_drone:Resource = preload("res://Scenes/Enemies/Flying _drone/Flying_drone.tscn")
@onready var Chat:Resource = preload("res://Scenes/CloudChat/Chat.tscn")
var chat_instance:Node2D

func _ready():
	gv.enemy_fsm = $EnemyStateMachine
	#drone = get_parent().get_node("Flying_drone")
	screen_size = get_viewport_rect().size
	gold_amount = randi_range(1,1125)
	head = get_node("CanvasGroup/Torso/Head")
	previous_state = ""
	gv.Enemy_position = position
	gv.Enemy_global_position = global_position
	scale.x = scale.y * 1
	direction = "L"
	print("Enemy: ready ...")
	print("Enemy: distance to Hero: " + str(int(position.distance_to(gv.Hero_global_position))))
	#print("Enemy state:" + gv.enemy_fsm.estate.name)
	#$Say.visible = false
	var Drone2:CharacterBody2D = flying_drone.instantiate()
	#get_tree().root.add_child(Drone2)
	get_tree().root.add_child.call_deferred(Drone2)
	Drone2.connect('on_boss_position', _drone_on_me_position)
	Drone2.connect('on_kill', _drone_on_kill)
	#boom.connect('early_hit', _on_bomb_early_hit)
	Drone2.visible = true
	print("Drone2: ready " + Drone2.name)

	

func _drone_on_kill():
	print("Enemy: they destroy my drone !")	
	await get_tree().create_timer(2.5).timeout 
	var Drone2:CharacterBody2D = flying_drone.instantiate()
	get_tree().root.add_child.call_deferred(Drone2)
	Drone2.connect('on_boss_position', _drone_on_me_position)
	Drone2.connect('on_kill', _drone_on_kill)
	Drone2.visible = true
	print("Next Drone: ready " + Drone2.name)
	

func _drone_on_me_position():
	previous_state = gv.enemy_fsm.estate.name
	gv.enemy_fsm.transition_to("Release_drone")
	print("Enemy: reload drone bomb")
	


func _process(_delta: float) -> void:
	pass
	

func _physics_process(_delta):
	gv.Enemy_position = position
	gv.Enemy_global_position = global_position
	
			
func PlayerActivity():
	pass			
	
func hit():
	print("enemy: somebody hit me by bullet!")
	emit_signal("somebody_hitme")
	
	if $Recover_Health.is_stopped() == true:
		$Recover_Health.start()
	
	var _particle:Node2D = particles_res.instantiate()
	_particle.position.x = global_position.x + randi_range(-30,60)
	_particle.position.y = global_position.y + randi_range(-30,60)
	_particle.rotation = global_rotation
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)
		
	if direction == "L":
		position.x += 20
	if direction == "R":
		position.x -= 20	
	if health > 0:
		health -= 10 # DAMAGE RATE   
	if health <= 0:
		emit_signal("enemy2_death")
		queue_free()  		

	if health in range(50,71):
		if texture_nr != 2:
			head.texture = Head_hit2_img
			texture_nr = 2
			speed = max_speed * 0.7
	
	if health in range(0,49):
		if texture_nr != 3:
			head.texture = Head_hit3_img
			texture_nr = 3
			speed = max_speed * 0.4			
			
		

	
func _on_recover_health_timeout() -> void:
	if health < 100:
		health += 1
	if health > 97:
		head.texture = Head_hit1_img
		texture_nr = 1
		speed = max_speed
		$Recover_Health.stop()
	
	if health in range(50,71):
		if texture_nr != 2:
			head.texture = Head_hit2_img
			texture_nr = 2
			speed = max_speed * 0.7	
	
	if health in range(0,49):
		if texture_nr != 3:
			head.texture = Head_hit3_img
			texture_nr = 3
			speed = max_speed * 0.4			

func _on_eyes_range_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		see_Player = true
		print("Enemy: YES I see:  " + body.name + "  now")

func _on_eyes_range_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		see_Player = false
		print("Enemy: NOT see:  " + body.name + "  now")

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	on_screen = true

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	on_screen = false






#if $SeeCast2D.is_colliding():
#		if $SeeCast2D.get_collider().name == "Player":
#			print("enemy: ray hit Player")
#			# get_collision_point()
#			emit_signal("me_see_player")
#			print("enemy: distance to player --> " + str(int(position.distance_to($SeeCast2D.get_collision_point()))))
#		else:
#			print("enemy: ray hit --> " + $SeeCast2D.get_collider().name)	
#





# match health:
#		69, 70, 71, 72:
#			head.texture = Head_hit2_img
#			speed *= 0.7
#		49, 50, 51, 52:
#			head.texture = Head_hit2_img
#			speed *= 0.7

#if health < 70 and health > 50:
#			if texture_nr != 2:
#				head.texture = Head_hit2_img
#				texture_nr = 2
#				speed *= 0.7
#if health < 50 and health > 0:
#			if texture_nr  != 3:
#				head.texture = Head_hit3_img
#				texture_nr = 3
#				speed *= 0.4
				
				
				
				
				









