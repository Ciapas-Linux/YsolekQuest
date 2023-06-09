extends CharacterBody2D

var x_distance_to_hero:float = 0
var y_distance_to_hero:float = 0
var x_distance_to_boss:float = 0
var y_distance_to_boss:float = 0
var move:bool = true
var target_position:bool = false
var on_boss_position_X:bool = false
var on_boss_position_Y:bool = false
var distance_vector:Vector2
var distance_vector_boss:Vector2
var speed:float = 250.0
var Drone_health:int = 100
var Drone_destroy:bool = false

enum States {FIND_HERO, GO_BASE, GO_BOSS, NO_BOSS, START, STOP}
var current_state : int = States.START

signal on_hit_position
signal on_boss_position
signal on_base_position
signal on_kill

var screen_size : Vector2
var enemy2:Enemy
var bomb:Resource = preload("res://Scenes/Enemies/Flying _drone/Bomb2.tscn")
var boom:Area2D

func _ready():
	speed = randi_range(200,350)
	$Explosion.stop()
	$Explosion.visible = false
	$Drone_explosion.stop()
	$Drone_explosion.visible = false
	screen_size = get_viewport_rect().size
	# enemy2 = get_parent().get_node("Enemy")
	enemy2 = get_tree().root.get_node("Stage1/Enemy")
	$drone_snd.play()
	position.x = enemy2.global_position.x
	position.y = enemy2.global_position.y - 200
	print("Flying drone: ready ...") 
	
func _physics_process(_delta):
	match current_state:
		States.STOP:
			_process_on_state_stop(_delta)
		States.START:
			_process_on_state_start(_delta)	
		States.FIND_HERO:
			_process_on_state_find_hero(_delta)
		States.GO_BASE:
			_process_on_state_go_base(_delta)
		States.GO_BOSS:
			_process_on_state_go_boss(_delta)
		States.NO_BOSS:
			_process_on_state_NO_boss(_delta)					

# Randomize Y velocity
func _on_timer_timeout() -> void:
	velocity.y = randf_range(-100,100)
	speed = randi_range(200,350)
	print("Drone X: " + str(int(position.x)) + " Drone Y: " + str(int(position.y)))
	if position.y > 0:
		velocity.y = -100
#
#	if position.y < -300:
#		velocity.y = 100	

# Start flying ...
@warning_ignore("unused_parameter")
func _process_on_state_start(delta: float) -> void:
	velocity.y = -350
	velocity.x = randf_range(-20,20)
	
	if global_position.y <= -300:
		velocity.y = 0
		$TimerRnd_Y.start()
		current_state = States.FIND_HERO
	
	#print(global_position.y) 
	move_and_slide()
	
@warning_ignore("unused_parameter")
func _process_on_state_NO_boss(delta: float) -> void:
	#velocity.y = -50
		
	if global_position.y <= -250:
		velocity.y = 0
		
	if global_position.x < 500 :
			scale.x = scale.y * -1
			velocity.x = speed
	if global_position.x > 2500:
			scale.x = scale.y * 1
			velocity.x = -speed		
	
	move_and_slide()
	
func _on_timer_no_boss_timeout() -> void:
	velocity.y = randf_range(-100,100)
	velocity.x = randf_range(-100,100)		

@warning_ignore("unused_parameter")
func _process_on_state_go_boss(delta: float) -> void:
	distance_vector_boss = global_position  - gv.Enemy_global_position
	x_distance_to_boss = abs(distance_vector_boss.x)
	y_distance_to_boss = abs(distance_vector_boss.y)
		
	if x_distance_to_boss < 10:
		velocity.x = 0
		#move = false
		on_boss_position_X = true
		
		
	if on_boss_position_X == true:
		if y_distance_to_boss > 200:
			velocity.y = speed
		if y_distance_to_boss < 160:
			on_boss_position_Y = true
				
		
	if on_boss_position_Y == true:	
		emit_signal("on_boss_position")
		$LoadBomb.start()
		on_boss_position_Y = false
		current_state = States.START
			
		
	if x_distance_to_boss > 80:
		on_boss_position_X = false
		if gv.Enemy_global_position.x < global_position.x:
			scale.x = scale.y * 1
			velocity.x = -speed
		if gv.Enemy_global_position.x > global_position.x:
			scale.x = scale.y * -1
			velocity.x = speed
	
	move_and_slide()					
	

@warning_ignore("unused_parameter")
func _process_on_state_find_hero(delta: float) -> void:
	distance_vector = global_position  - gv.Hero_global_position
	x_distance_to_hero = abs(distance_vector.x)
	y_distance_to_hero = abs(distance_vector.y)
	#print(x_distance_to_hero) 
	
	if x_distance_to_hero < 10:
		velocity.x = 0
		move = false
		#await get_tree().create_timer(0.5).timeout
		target_position = true
		emit_signal("on_hit_position")
		current_state = States.GO_BOSS
		
	if x_distance_to_hero > 80:
		move = true	
	
	if move == true:
		if gv.Hero_global_position.x < global_position.x:
			scale.x = scale.y * 1
			velocity.x = -speed
		if gv.Hero_global_position.x > global_position.x:
			scale.x = scale.y * -1
			velocity.x = speed	
	
	move_and_slide()


@warning_ignore("unused_parameter")  
func _process_on_state_go_base(delta: float) -> void:
	pass

@warning_ignore("unused_parameter")
func _process_on_state_stop(delta: float) -> void:
	pass


func _on_drone_bullet_hit_me() -> void:
	Drone_health -= 20
	print("Drone: bullet hit drone ...")
	if Drone_destroy == false:
		if Drone_health <= 0:
			$Drone/DroneSprite.visible = false
			$Drone_explosion.visible = true
			$Drone_explosion.play()
			$Explosion.visible = true
			$Explosion.play()
			$snd_explode.play()
			Drone_destroy = true

func _on_explosion_animation_finished() -> void:
	$drone_snd.stop()
	emit_signal("on_kill")
	print("Drone: player kill drone")
	queue_free()
		
func _on_drone_explosion_animation_finished() -> void:
	pass
	#queue_free()
	

func _on_bomb_early_hit() -> void:
	$drone_snd.stop()
	boom.get_node("snd_fall").stop()
	print("Drone: bullet hit bomb! and kill drone.")
	$Drone/DroneSprite.visible = false
	$Drone_explosion.visible = true
	$Explosion.visible = true
	$Drone_explosion.play()
	$Explosion.play()
	$snd_explode.play()
	Drone_health = 0 
	# queue_free()

func _on_bomb_drop_bomb() -> void:
	await get_tree().create_timer(1.0).timeout
	current_state = States.GO_BOSS
	print("Drone: go to boss ...") 

# instantiate create new bomb
func _on_load_bomb_timeout() -> void:
	boom = bomb.instantiate()
	get_tree().root.add_child(boom)
	boom.connect('early_hit', _on_bomb_early_hit)
	print("Bomb: ready " + boom.name) 
	
	
func _on_enemy_enemy_2_death() -> void:
	$TimerRnd_Y.stop()
	$TimerNoBoss.start()
	if get_tree().root.has_node("Bomb2") == true:
		emit_signal("on_hit_position")
	current_state = States.NO_BOSS
	print("flying drone: boss is dead") 
	

	
	
	
# get_parent().add_child(boom)
# boom.connect('hit', _on_player_hit)
# on_position.connect(boom.)
# new_thing.signal_name.connect(method_to_call)
# boom.on_po.connect(on_position)
# connect("on_position", boom, "_on_position")
# boom.transform = get_node("BombSpawn").global_transform



#
#func _physics_process(delta):
#	#velocity.x = 50
#	#global_position.x = drone.global_position.x
#	#global_position.y = drone.global_position.y
#	#gravity = randf_range(70,200)
#	#velocity.y += gravity * delta
#	#if gv.Hero_global_position.x == global_position.x:
#		#velocity.x = 0
#
#	#distance_to_hero = 	global_position.distance_to(gv.Hero_global_position)
#	distance_vector = global_position  - gv.Hero_global_position
#	x_distance_to_hero = abs(distance_vector.x)
#	print(x_distance_to_hero) 
#
#	if x_distance_to_hero < 10:
#		velocity.x = 0
#		move = false
#		position_arm = true
#		emit_signal("on_position")
#
#	if x_distance_to_hero > 50:
#		move = true	
#
#	if move == true:
#		if gv.Hero_global_position.x < global_position.x:
#			scale.x = scale.y * 1
#			velocity.x = -speed
#
#		if gv.Hero_global_position.x > global_position.x:
#			scale.x = scale.y * -1
#			velocity.x = speed	
#
#
#	#player_distance = global_position.distance_to(gv.Hero_global_position)
#	move_and_slide()





















