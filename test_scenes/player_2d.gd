extends CharacterBody2D

# Signals
signal velocity_updated

# General input consts
const DEADBAND = 0.5

# lr movement consts
const GROUND_MAX_SPEED := 400
const GROUND_ACCELERATION := 6000
const GROUND_DECELERATION := 9000
const GROUND_ZERO_VELOCITY_THRESHOLD := 120
const AIR_MAX_SPEED := GROUND_MAX_SPEED
const AIR_ACCELERATION := GROUND_ACCELERATION * 0.75
const AIR_DECELERATION := GROUND_DECELERATION * 0.75
const AIR_ZERO_VELOCITY_THRESHOLD := GROUND_ZERO_VELOCITY_THRESHOLD

# ud movement consts
const CLIMB_MAX_SPEED := 200
const MAX_GROUND_JUMPS := 1
const MAX_AIR_JUMPS := 1
const CLIMB_ACCELERATION := 4000
const CLIMB_DECELERATION := 10000
const CLIMB_ZERO_THRESHOLD := 150
const SLIDE_PASSIVE_MAX_SPEED := 400
const SLIDE_PASSIVE_ACCELERATION := 1000
const SLIDE_ACTIVE_SPEED_OFFSET := 100
const SLIDE_ACTIVE_ACCELERATION_OFFSET := 100

# Dash consts
const DASH_VELOCITY_SCALE = 1.9
const MAX_DASHES := 1
const DASH_START_SPEED := 3000 / DASH_VELOCITY_SCALE
const DASH_END_SPEED := 100.0
const DASH_MAX_DURATION := 0.14 * DASH_VELOCITY_SCALE
const DASH_COOLDOWN_DURATION := 0.2

# Jump consts
const GROUND_JUMP_SPEED := 300
const AIR_JUMP_SPEED := 250
const WALL_CLIMBING_JUMP_VELOCITY := Vector2(200, 500)
const WALL_SLIDING_JUMP_VELOCITY := Vector2(200, 100)
const JUMP_CANCEL_SPEED := 200 # UNUSED CURRENTLY PROBABLY DELETE
const JUMP_MAX_DURATION := 0.1

# Grab consts
const GRAB_VELOCITY := 1 # UNUSED CURRENTLY

# Player state 
enum State {
	IDLING,
	WALKING,
	DASHING,
	JUMPING,
	WALLING,
	FALLING
}

enum Walking_Substate {
	AIR_WALKING,
	GROUND_WALKING
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

enum Jumping_Substate { }

enum Walling_Substate {
	SLOW_SLIDING,
	PASSIVE_SLIDING,
	FAST_SLIDING,
	CLIMBING,
	JUMPING
}

enum Falling_Substate {
	SLOW_FALLING,
	PASSIVE_FALLING,
	FAST_FALLING
}

# Physics vars
var gravity = Vector2(0, 0)

# Environment info vars
var is_on_ground := false
var is_on_left_wall := false
var is_on_right_wall := false

# Movement vars
var is_facing_right = true
var lr_input_axis := Input.get_axis("left", "right")
var ud_input_axis := Input.get_axis("up", "down")

# Dash vars
var is_dash_input_just_pressed := Input.is_action_just_pressed("dash")
var dashes := 1 # Change MAX_DASHES to increase number of dashes
var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_input_vector := Vector2.ZERO
var dash_start_position := Vector2.ZERO
var dash_end_position := Vector2.ZERO

# Jump vars
var is_jump_input_pressed := Input.is_action_pressed("jump")
var is_jump_just_released = Input.is_action_just_released("jump")
var ground_jumps := MAX_GROUND_JUMPS
var air_jumps := MAX_AIR_JUMPS
var is_jumping := false
var jump_timer := 0.0
var ground_jump_cooldown_timer := 0.0
var air_jump_cooldown_timer := 0.0
var jump_start_location := "ground"

# Grab vars
var is_grab_inverted := true
var is_grab_input_pressed := (Input.is_action_pressed("grab") or is_grab_inverted) and not (Input.is_action_pressed("grab") and is_grab_inverted)
var is_climbing := false
var is_sliding := false

# State vars
var state := State.IDLING
var walking_substate := Walking_Substate.GROUND_WALKING
#var dashing_substate := Dashing_Substate
#var jumping_substate := Jumping_Substate
var walling_substate := Walling_Substate.PASSIVE_SLIDING
var falling_substate := Falling_Substate.PASSIVE_FALLING

#func _process(delta: float) -> void:

# MOVE USER INPUTS TO A _INPUT/_UNHANDLES_INPUT FUNC OR SOMETHING PROBABLY
func get_inputs() -> void:
	lr_input_axis = Input.get_axis("left", "right")
	ud_input_axis = Input.get_axis("up", "down")

	is_dash_input_just_pressed = Input.is_action_just_pressed("dash")

	is_jump_input_pressed = Input.is_action_pressed("jump")
	
	is_grab_input_pressed = (Input.is_action_pressed("grab") or is_grab_inverted) and not (Input.is_action_pressed("grab") and is_grab_inverted)


func _physics_process(delta: float) -> void:
	# Debug outputs
	velocity_updated.emit(delta, velocity)
	
	get_inputs()

	gravity = get_gravity()
	
	# STATE MACHINE REWRITE
	print(lr_input_axis)
	# Player state 	
	match state:
		State.IDLING:
			print("IDLING")
			# State handling
			
			
			# State transition handling
			if abs(lr_input_axis) > 0:
				state = State.WALKING
			
			if is_dash_input_just_pressed:
				state = State.DASHING
			
			if is_jump_input_pressed:
				state = State.JUMPING
			
			if is_grab_input_pressed:
				state = State.WALLING
			
			if not is_on_ground:
				state = State.FALLING
			
		State.WALKING:
			print("WALKING")
			# State handling
			
			
			# State transition handling
			if abs(lr_input_axis) == 0:
				state = State.IDLING
			
			if is_dash_input_just_pressed:
				state = State.DASHING
			
			if is_jump_input_pressed:
				state = State.JUMPING
			
			if is_grab_input_pressed:
				state = State.WALLING
			
			# SHOULD BE HANDLED BY SUBSTATE
			#if not is_on_ground:
				#state = State.FALLING
			
		State.DASHING:
			print("DASHING")
		State.JUMPING:
			print("JUMPING")
		State.WALLING:
			print("WALLING")
		State.FALLING:
			print("FALLING")
	
	# TODO CASES PAST HERE MOSTLY, OLD CODE
	
	is_climbing = is_grab_input_pressed and (is_on_left_wall or is_on_right_wall) 
	is_sliding = not is_grab_input_pressed and (is_on_left_wall or is_on_right_wall)
	
	
	# Add dashing
	# Starts dash
	if is_dash_input_just_pressed and not is_dashing and dashes > 0:
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
			if not is_on_left_wall and not is_on_right_wall:
				velocity += gravity * delta
			# Sliding gravity
			elif is_sliding:
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

		# Apply left & right inputs:
		if is_on_floor():
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
		else:
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
		# Add jumping # NEED TO REPLACE IS_ON_FLOOR W/ AREA CHECK AT SOME POINT # NEED TO ADD VARIABLE HEIGHT JUMPING
		# NEED TO IMPLEMENT SUPERS/HYPERS? WHICH REQUIRES MODIFYING DASH (REWRITE TO NOT USE LERP AND TO ADD VELO INSTEAD OF SETTING)
		if is_on_floor() or is_climbing or is_sliding:
			ground_jumps = MAX_GROUND_JUMPS
			air_jumps = MAX_AIR_JUMPS
		
		if Input.is_action_just_released("jump"):
			is_jump_just_released = true
		
		if is_jump_input_pressed and ground_jumps > 0 and not is_jumping and (is_on_floor() or is_climbing or is_sliding):
			if is_on_floor():
				jump_start_location = "ground"
				ground_jumps -= 1
			elif is_climbing:
				if lr_input_axis == 0:
					jump_start_location = "climbing"
				ground_jumps -= 1
			elif is_sliding:
				if lr_input_axis == 0:
					jump_start_location = "sliding"
				ground_jumps -= 1
			jump_timer = 0.0
			is_jumping = true
		elif is_jump_input_pressed and air_jumps > 0 and not is_jumping and is_jump_just_released:
			jump_start_location = "air"
			air_jumps -= 1
			jump_timer = 0.0
			is_jumping = true
			
		if is_jumping and clamp(jump_timer / JUMP_MAX_DURATION, 0, 1) < 1  and is_jump_input_pressed:
			jump_timer += delta
			is_jump_just_released = false
			if jump_start_location == "ground":
				velocity.y = -GROUND_JUMP_SPEED
			elif jump_start_location == "climbing":
				if lr_input_axis == 0:
					velocity.y = -WALL_CLIMBING_JUMP_VELOCITY.y
			elif jump_start_location == "sliding":
				if lr_input_axis == 0:
					velocity.y = -WALL_SLIDING_JUMP_VELOCITY.y
			elif jump_start_location == "air":
				velocity.y = -AIR_JUMP_SPEED
		else:
			is_jumping = false

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
