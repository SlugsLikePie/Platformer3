extends CharacterBody2D

# Signals
signal velocity_updated
signal position_updated

# General input consts
const DEADBAND = 0.5

# lr movement consts
const GROUND_MAX_SPEED := 150
const GROUND_ACCELERATION := 6000 / 2
const GROUND_DECELERATION := 9000 / 2
const GROUND_ZERO_VELOCITY_THRESHOLD := 120 / 2
const AIR_MAX_SPEED := GROUND_MAX_SPEED
const AIR_ACCELERATION := GROUND_ACCELERATION * 0.75
const AIR_DECELERATION := GROUND_DECELERATION * 0.75
const AIR_ZERO_VELOCITY_THRESHOLD := GROUND_ZERO_VELOCITY_THRESHOLD

# ud movement consts
const CLIMB_MAX_SPEED := 200
const MAX_GROUND_JUMPS := 1
const MAX_AIR_JUMPS := 1
const CLIMB_ACCELERATION := 4000 / 2
const CLIMB_DECELERATION := 10000 / 2
const CLIMB_ZERO_THRESHOLD := 150 / 2
const SLIDE_PASSIVE_MAX_SPEED := 400 / 2
const SLIDE_PASSIVE_ACCELERATION := 1000 / 2
const SLIDE_ACTIVE_SPEED_OFFSET := 100 / 2
const SLIDE_ACTIVE_ACCELERATION_OFFSET := 100 / 2

# Dash consts
const DASH_VELOCITY_SCALE = 1.9 * 2
const MAX_DASHES := 1
const DASH_START_SPEED := 3000 / DASH_VELOCITY_SCALE
const DASH_END_SPEED := 100.0
const DASH_MAX_DURATION := 0.14 / 4 * DASH_VELOCITY_SCALE
const DASH_COOLDOWN_DURATION := 0.2

# Jump consts
const GROUND_JUMP_SPEED := 300 / 2
const AIR_JUMP_SPEED := 250 / 2
const CLIMBING_JUMP_VELOCITY := Vector2(200, 500) / 2
const SLIDING_JUMP_VELOCITY := Vector2(200, 100) / 2
const JUMP_CANCEL_SPEED := 200 # UNUSED CURRENTLY PROBABLY DELETE
const JUMP_MAX_DURATION := 0.1

# Grab consts
const GRAB_VELOCITY := 1 # UNUSED CURRENTLY

# Player state 
enum State {
	IDLING,
	WALKING,
	WALLING,
	DASHING,
	JUMPING,
	FALLING
}

enum Walking_Substate { }

enum Walling_Substate {
	SLOW_SLIDING,
	PASSIVE_SLIDING,
	FAST_SLIDING,
	CLIMBING,
	JUMPING
}

enum Dashing_Substate {
	UP,
	UP_RIGHT,
	RIGHT,
	DOWN_RIGHT,
	DOWN,
	DOWN_LEFT,
	LEFT,
	UP_LEFT,
}

enum Jumping_Substate { 
	GROUND_JUMPING,
	CLIMB_JUMPING,
	SLIDE_JUMPING,
	AIR_JUMPING
}

enum Falling_Substate {
	SLOW_FALLING,
	PASSIVE_FALLING,
	FAST_FALLING
}

# Physics vars
var gravity := Vector2(0, 0)

# Environment info vars
var is_on_ground := false
var is_on_left_wall := false
var is_on_right_wall := false

# Movement vars
var is_facing_right = true
var lr_input_axis := Input.get_axis("left", "right")
var ud_input_axis := Input.get_axis("up", "down")

# Dash vars
var is_dash_just_pressed := Input.is_action_just_pressed("dash")
var dashes := 1 # Change MAX_DASHES to increase number of dashes
var can_dash = false
var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_input_vector := Vector2.ZERO
var dash_start_position := Vector2.ZERO
var dash_end_position := Vector2.ZERO

# Jump vars
var is_jump_pressed := Input.is_action_pressed("jump")
var is_jump_just_pressed := Input.is_action_just_pressed("jump")
var is_jump_just_released := Input.is_action_just_released("jump")
var ground_jumps := MAX_GROUND_JUMPS
var air_jumps := MAX_AIR_JUMPS
var is_jumping := false
var can_ground_jump := false
var can_air_jump := false
var jump_timer := 0.0
var ground_jump_cooldown_timer := 0.0
var air_jump_cooldown_timer := 0.0
var jump_start_location := "ground"

# Grab vars
var is_grab_inverted := true
var is_grab_pressed := (Input.is_action_pressed("grab") or is_grab_inverted) and not (Input.is_action_pressed("grab") and is_grab_inverted)
var can_wall := false
var is_climbing := false
var is_sliding := false

# State vars
var state := State.IDLING
var walking_substate := Walking_Substate
var walling_substate := Walling_Substate.PASSIVE_SLIDING
var dashing_substate := Dashing_Substate
var jumping_substate := Jumping_Substate.GROUND_JUMPING

# func _process(delta: float) -> void:

# MOVE USER INPUTS TO A _INPUT/_UNHANDLES_INPUT FUNC OR SOMETHING PROBABLY
func get_inputs() -> void:
	lr_input_axis = Input.get_axis("left", "right")
	ud_input_axis = Input.get_axis("up", "down")

	is_dash_just_pressed = Input.is_action_just_pressed("dash")

	is_jump_pressed = Input.is_action_pressed("jump")
	is_jump_just_pressed = Input.is_action_just_pressed("jump")
	
	is_grab_pressed = (Input.is_action_pressed("grab") or is_grab_inverted) and not (Input.is_action_pressed("grab") and is_grab_inverted)

func apply_ground_walking(delta: float) -> void:
	if velocity.x <= GROUND_MAX_SPEED and lr_input_axis > DEADBAND:
		if velocity.x + lr_input_axis * GROUND_ACCELERATION * delta <= GROUND_MAX_SPEED:
			velocity.x += lr_input_axis * GROUND_ACCELERATION * delta
		else:
			velocity.x = GROUND_MAX_SPEED
	elif velocity.x >= -GROUND_MAX_SPEED and lr_input_axis < -DEADBAND:
		if velocity.x + lr_input_axis * GROUND_ACCELERATION * delta >= -GROUND_MAX_SPEED:
			velocity.x += lr_input_axis * GROUND_ACCELERATION * delta
		else:
			velocity.x = -GROUND_MAX_SPEED
	else:
		if velocity.x > GROUND_ZERO_VELOCITY_THRESHOLD:
			velocity.x -= GROUND_DECELERATION * delta
		elif velocity.x < -GROUND_ZERO_VELOCITY_THRESHOLD:
			velocity.x += GROUND_DECELERATION * delta
		else:
			velocity.x = 0

func apply_air_walking(delta: float) -> void:
	if velocity.x <= AIR_MAX_SPEED and lr_input_axis > DEADBAND:
		if velocity.x + lr_input_axis * AIR_ACCELERATION * delta <= AIR_MAX_SPEED:
			velocity.x += lr_input_axis * AIR_ACCELERATION * delta
		else:
			velocity.x = AIR_MAX_SPEED
	elif velocity.x >= -AIR_MAX_SPEED and lr_input_axis < -DEADBAND:
		if velocity.x + lr_input_axis * AIR_ACCELERATION * delta >= -AIR_MAX_SPEED:
			velocity.x += lr_input_axis * AIR_ACCELERATION * delta
		else:
			velocity.x = -AIR_MAX_SPEED
	else:
		if velocity.x > AIR_ZERO_VELOCITY_THRESHOLD:
			velocity.x -= AIR_DECELERATION * delta
		elif velocity.x < -AIR_ZERO_VELOCITY_THRESHOLD:
			velocity.x += AIR_DECELERATION * delta
		else:
			velocity.x = 0

func _physics_process(delta: float) -> void:
	# Signals emit
	velocity_updated.emit(delta, velocity)
	position_updated.emit(delta, position)
	
	# HID acquisition
	get_inputs()

	# Physics configuration
	gravity = get_gravity()

	# Ability acquisition
	can_dash = is_dash_just_pressed and not is_dashing and dashes > 0
	can_wall = is_on_left_wall or is_on_right_wall
	can_ground_jump = ground_jumps > 0 and not is_jumping and (is_on_ground or can_wall)
	can_air_jump = air_jumps > 0 and not is_jumping
	
	if is_on_ground or is_climbing or is_sliding:
			ground_jumps = MAX_GROUND_JUMPS
			air_jumps = MAX_AIR_JUMPS
	
	print(air_jumps)
	# Player state 	
	match state:
		State.IDLING:
			# print("IDLING")
			# State handling
			
			
			# State transition handling
			if abs(lr_input_axis) > 0 or not is_on_ground:
				state = State.WALKING
			
			if is_grab_pressed and can_wall:
				state = State.WALLING

			if is_dash_just_pressed:
				state = State.DASHING
			
			if is_jump_pressed:
				state = State.JUMPING

			if not is_on_ground:
				state = State.FALLING

		State.WALKING:
			# print("WALKING")
			# State handling
			apply_ground_walking(delta)
					
			
			# State transition handling
			if abs(lr_input_axis) == 0 and velocity == Vector2.ZERO:
				state = State.IDLING

			if is_grab_pressed and can_wall:
				state = State.WALLING
			
			if is_dash_just_pressed:
				state = State.DASHING
			
			if is_jump_pressed:
				state = State.JUMPING

			if not is_on_ground:
				state = State.FALLING

		State.WALLING:
			# print("WALLING")
			# State handling
			
			
			# State transition handling
			if not can_wall or not is_grab_pressed:
				state = State.WALKING

			if is_jump_pressed:
				state = State.JUMPING
			
		State.DASHING:
			# print("DASHING")
			# State handling
			
			
			# State transition handling
			if is_on_ground or not is_dashing:
				state = State.WALKING

			if can_wall:
				state = State.WALLING

		State.JUMPING:
			# print("JUMPING")
			# State handling
			apply_air_walking(delta)

			if can_ground_jump:
				if is_jump_pressed:
					is_jumping = true
					jump_timer = 0.0
			
				# Substate selection
				if is_on_ground:
					jumping_substate = Jumping_Substate.GROUND_JUMPING
					ground_jumps -= 1

				elif is_climbing:
					jumping_substate = Jumping_Substate.CLIMB_JUMPING
					ground_jumps -= 1

				elif is_sliding:
					jumping_substate = Jumping_Substate.SLIDE_JUMPING
					ground_jumps -= 1
				
			elif can_air_jump:
				if is_jump_pressed:
					is_jumping = true
					jump_timer = 0.0
				jumping_substate = Jumping_Substate.AIR_JUMPING
				air_jumps -= 1

			if is_jumping and clamp(jump_timer / JUMP_MAX_DURATION, 0, 1) < 1  and is_jump_pressed:
				jump_timer += delta
				match jumping_substate:
					Jumping_Substate.GROUND_JUMPING:
						print("GROUND_JUMPING")
						velocity.y = -GROUND_JUMP_SPEED

					Jumping_Substate.CLIMB_JUMPING:
						# print("CLIMB_JUMPING")
						velocity.y = -CLIMBING_JUMP_VELOCITY.y

					Jumping_Substate.SLIDE_JUMPING:
						# print("SLIDE_JUMPING")
						velocity.y = -SLIDING_JUMP_VELOCITY.y
					
					Jumping_Substate.AIR_JUMPING:
						print("AIR_JUMPING")
						velocity.y = -AIR_JUMP_SPEED
			else:
				is_jumping = false

			# State transition handling
			if not is_jumping and is_on_ground:
				state = State.WALKING

			if not is_jumping and not is_on_ground:
				state = State.FALLING

		State.FALLING:
			# print("FALLING")
			# State handling // NEED TO IMPLEMENT SUBSTATES
			apply_air_walking(delta) 
			velocity.y += gravity.y * delta

			if is_on_ground:
				state = State.WALKING
			
			if is_jump_just_pressed:
				state = State.JUMPING

	# TODO CASES PAST HERE MOSTLY, OLD CODE
	
	is_climbing = is_grab_pressed and (can_wall) 
	is_sliding = not is_grab_pressed and (can_wall)
	
	
	# Add dashing
	# Starts dash
	if can_dash:
		dash_input_vector = Input.get_vector("left", "right", "up", "down")
		dash_timer = 0.0
		velocity = Vector2.ZERO
		is_dashing = true
		dashes -= 1

	# Moves player through dash
	if is_dashing:
		dash_timer += delta
		var percent_complete = clamp(dash_timer / DASH_MAX_DURATION, 0, 1)
		if dash_input_vector != Vector2.ZERO:
			velocity = dash_input_vector * lerp(DASH_START_SPEED, DASH_END_SPEED, percent_complete)
		else:
			if is_facing_right:
				velocity = Vector2.RIGHT * lerp(DASH_START_SPEED, DASH_END_SPEED, percent_complete)
			else:
				velocity = Vector2.LEFT * lerp(DASH_START_SPEED, DASH_END_SPEED, percent_complete)
		# Ends dash
		if percent_complete >= 1:
			dash_timer = 0
			dash_cooldown_timer = 0
			is_dashing = false

	if is_on_floor() and clamp(dash_cooldown_timer / DASH_COOLDOWN_DURATION, 0, 1) >= 1 and not is_dashing:
		dashes = MAX_DASHES
	elif not is_dashing:
		dash_cooldown_timer += delta
		
	# Disables this block of code if the player is dashing or jumping to prevent other movements
	if not is_dashing:
		# Flips the direction the player is facing based off of user input
		if lr_input_axis > DEADBAND:
			is_facing_right = true
		elif lr_input_axis < -DEADBAND:
			is_facing_right = false
			
		# Add gravity
		if not is_on_floor():
			# Normal gravity
			# if not is_on_left_wall and not is_on_right_wall:
				# velocity += gravity * delta
			# Sliding gravity
			if is_sliding:
				if velocity.y + (SLIDE_PASSIVE_ACCELERATION + SLIDE_ACTIVE_ACCELERATION_OFFSET * ud_input_axis) * delta <= SLIDE_PASSIVE_MAX_SPEED + ud_input_axis * SLIDE_ACTIVE_SPEED_OFFSET:
					velocity.y += (SLIDE_PASSIVE_ACCELERATION + SLIDE_ACTIVE_ACCELERATION_OFFSET * ud_input_axis) * delta
				else:
					velocity.y = SLIDE_PASSIVE_MAX_SPEED + ud_input_axis * SLIDE_ACTIVE_SPEED_OFFSET

		# Add wall climbing
		if is_climbing:
			if velocity.y <= CLIMB_MAX_SPEED and ud_input_axis > DEADBAND:
				if velocity.y + ud_input_axis * CLIMB_ACCELERATION * delta <= CLIMB_MAX_SPEED:
					velocity.y += ud_input_axis * CLIMB_ACCELERATION * delta
				else:
					velocity.y = CLIMB_MAX_SPEED
			elif velocity.y >= -CLIMB_MAX_SPEED and ud_input_axis < -DEADBAND:
				if velocity.y + ud_input_axis * CLIMB_ACCELERATION * delta >= -CLIMB_MAX_SPEED:
					velocity.y += ud_input_axis * CLIMB_ACCELERATION * delta
				else:
					velocity.y = -CLIMB_MAX_SPEED
			else:
				if velocity.y > CLIMB_ZERO_THRESHOLD:
					velocity.y -= CLIMB_DECELERATION * delta
				elif velocity.y < -CLIMB_ZERO_THRESHOLD:
					velocity.y += CLIMB_DECELERATION * delta
				else:
					velocity.y = 0

		# Add jumping # NEED TO REPLACE IS_ON_FLOOR W/ AREA CHECK AT SOME POINT # NEED TO ADD VARIABLE HEIGHT JUMPING
		# NEED TO IMPLEMENT SUPERS/HYPERS? WHICH REQUIRES MODIFYING DASH (REWRITE TO NOT USE LERP AND TO ADD VELO INSTEAD OF SETTING)
		# if is_on_floor() or is_climbing or is_sliding:
		# 	ground_jumps = MAX_GROUND_JUMPS
		# 	air_jumps = MAX_AIR_JUMPS
		
		# if Input.is_action_just_released("jump"):
		# 	is_jump_just_released = true
		
		# if is_jump_pressed and ground_jumps > 0 and not is_jumping and (is_on_floor() or is_climbing or is_sliding):
		# 	if is_on_floor():
		# 		jump_start_location = "ground"
		# 		ground_jumps -= 1
		# 	elif is_climbing:
		# 		if lr_input_axis == 0:
		# 			jump_start_location = "climbing"
		# 		ground_jumps -= 1
		# 	elif is_sliding:
		# 		if lr_input_axis == 0:
		# 			jump_start_location = "sliding"
		# 		ground_jumps -= 1
		# 	jump_timer = 0.0
		# 	is_jumping = true
		# elif is_jump_pressed and air_jumps > 0 and not is_jumping and is_jump_just_released:
		# 	jump_start_location = "air"
		# 	air_jumps -= 1
		# 	jump_timer = 0.0
		# 	is_jumping = true
			
		# if is_jumping and clamp(jump_timer / JUMP_MAX_DURATION, 0, 1) < 1  and is_jump_pressed:
		# 	jump_timer += delta
		# 	is_jump_just_released = false
		# 	if jump_start_location == "ground":
		# 		velocity.y = -GROUND_JUMP_SPEED
		# 	elif jump_start_location == "climbing":
		# 		if lr_input_axis == 0:
		# 			velocity.y = -CLIMBING_JUMP_VELOCITY.y
		# 	elif jump_start_location == "sliding":
		# 		if lr_input_axis == 0:
		# 			velocity.y = -SLIDING_JUMP_VELOCITY.y
		# 	elif jump_start_location == "air":
		# 		velocity.y = -AIR_JUMP_SPEED
		# else:
		# 	is_jumping = false

	move_and_slide()

func _on_left_wall_detection_area_2d_body_entered(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_left_wall = true


func _on_left_wall_detection_area_2d_body_exited(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_left_wall = false


func _on_right_wall_detection_area_2d_body_entered(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_right_wall = true


func _on_right_wall_detection_area_2d_body_exited(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_right_wall = false


func _on_ground_detection_area_2d_body_entered(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_ground = true
	

func _on_ground_detection_area_2d_body_exited(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_ground = false
