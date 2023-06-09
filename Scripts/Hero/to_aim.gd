extends PlayerState

var walk = false
var walk_speed  

func enter(_msg := {}) -> void:
	player.velocity = Vector2.ZERO
	walk_speed = player.speed/2
	
	if get_node("../../snd_sit").playing != true:
			get_node("../../snd_sit").play()	
	
	get_node("../../snd_walk").stop()
	get_node("../../snd_fall").stop()
	
	get_node("../../AnimationPlayer").stop()
	get_node("../../AnimationPlayer").play("target_up")
		

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("Air")
		return
	
	if gv.Hero_is_paused == true:
		state_machine.transition_to("Idle")
		return		
				
	if Input.is_action_pressed("ui_right"):
		gv.Hero_direction = Vector2.RIGHT
		player.velocity.x = walk_speed
		walk = true
		#print_debug(walk) 
	
	if Input.is_action_pressed("ui_left"):
		#gv.Hero_direction = Vector2.LEFT
		player.velocity.x = -walk_speed
		walk = true	
	
	if Input.is_action_just_released("ui_right"):		
		walk = false
		player.velocity.x = 0
		get_node("../../AnimationPlayer").stop()
		get_node("../../snd_walk").stop()
		#print_debug(walk) 
		#print_debug("release key right") 
		
	if Input.is_action_just_released("ui_left"):		
		walk = false
		player.velocity.x = 0
		get_node("../../AnimationPlayer").stop()
		get_node("../../snd_walk").stop()		

#	
	if walk == true:
		get_node("../../AnimationPlayer").play("target_up_walk")
		if get_node("../../snd_walk").playing != true:
			get_node("../../snd_walk").play()			
		
	player.velocity.y += player.gravity * delta
	player.move_and_slide()
			

	if Input.is_action_just_pressed("ui_up"):
		state_machine.transition_to("Idle")
		

func _one_shot_timer_example():
	print("timer start")
	await get_tree().create_timer(1.0).timeout
	print("timer end")
