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
# REWORK PASSIVE AND ACTIVE TO HAVE SEPERATE UP/DOWN VARIABLES
const SLIDE_PASSIVE_MAX_SPEED := 400 / 2
const SLIDE_PASSIVE_ACCELERATION := 1000 / 2
const SLIDE_SLOW_MAX_SPEED := 300 / 2
const SLIDE_SLOW_ACCELERATION := 1000 / 2
const SLIDE_FAST_MAX_SPEED := 500 / 2
const SLIDE_FAST_ACCELERATION := 1000 / 2

# Dash consts
const DASH_VELOCITY_SCALE = 1.9 * 2
const MAX_DASHES := 2
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

# Falling consts
const GRAVITY := 900.0
const SLOW_FALLING_ACCELERATION := 100
const FAST_FALLING_ACCELERATION := 200

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
	CLIMBING
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
var falling_substate := Falling_Substate.PASSIVE_FALLING

# func _process(delta: float) -> void:

# MOVE USER INPUTS TO A _INPUT/_UNHANDLED_INPUT FUNC OR SOMETHING PROBABLY
func get_inputs() -> void:
	lr_input_axis = Input.get_axis("left", "right")
	ud_input_axis = Input.get_axis("up", "down")

	is_dash_just_pressed = Input.is_action_just_pressed("dash")

	is_jump_pressed = Input.is_action_pressed("jump")
	is_jump_just_pressed = Input.is_action_just_pressed("jump")
	
	is_grab_pressed = (Input.is_action_pressed("grab") or is_grab_inverted) and not (Input.is_action_pressed("grab") and is_grab_inverted)

func apply_ground_walking(delta: float) -> void:
	if lr_input_axis > DEADBAND:
		is_facing_right = true
	elif lr_input_axis < -DEADBAND:
		is_facing_right = false

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
	if lr_input_axis > DEADBAND:
		is_facing_right = true
	elif lr_input_axis < -DEADBAND:
		is_facing_right = false

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

func apply_dash(delta: float, percent_complete: float, direction: Vector2):
	# if is_dashing:
		dash_timer += delta
		
		velocity = direction * lerp(DASH_START_SPEED, DASH_END_SPEED, percent_complete)
		# var percent_complete = clamp(dash_timer / DASH_MAX_DURATION, 0, 1)
		# if dash_input_vector != Vector2.ZERO:
		# 	velocity = dash_input_vector * lerp(DASH_START_SPEED, DASH_END_SPEED, percent_complete)
		# else:
		# 	if is_facing_right:
		# 		velocity = Vector2.RIGHT * lerp(DASH_START_SPEED, DASH_END_SPEED, percent_complete)
		# 	else:
		# 		velocity = Vector2.LEFT * lerp(DASH_START_SPEED, DASH_END_SPEED, percent_complete)
		# # Ends dash
		# if percent_complete >= 1:
		# 	dash_timer = 0
		# 	dash_cooldown_timer = 0
		# 	is_dashing = false	

func exit_dash():
	dash_timer = 0.0
	dash_cooldown_timer = 0
	is_dashing = false

func _physics_process(delta: float) -> void:
	# Signals emit
	velocity_updated.emit(delta, velocity)
	position_updated.emit(delta, position)
	
	# HID acquisition
	get_inputs()

	# Ability acquisition
	can_dash = not is_dashing and dashes > 0
	can_wall = is_on_left_wall or is_on_right_wall
	can_ground_jump = ground_jumps > 0 and not is_jumping and (is_on_ground or can_wall)
	can_air_jump = air_jumps > 0 and not is_jumping

	# CHANGE TO BE BASED OFF OF CURRENT STATE, PROBABLY
	is_climbing = is_grab_pressed and (can_wall) 
	is_sliding = not is_grab_pressed and (can_wall)
	
	if is_on_ground or is_climbing or is_sliding:
			ground_jumps = MAX_GROUND_JUMPS
			air_jumps = MAX_AIR_JUMPS

	if is_on_ground and clamp(dash_cooldown_timer / DASH_COOLDOWN_DURATION, 0, 1) >= 1 and not is_dashing:
		dashes = MAX_DASHES

	if not is_dashing:
		dash_cooldown_timer += delta

	print(dash_timer)

	# Player state 	
	match state:
		State.IDLING:
			# print("IDLING")
			# State handling
			# WOAH IT DOES NOTHING HERE (YET)
			
			# State transition handling
			if abs(lr_input_axis) > 0 or not is_on_ground:
				state = State.WALKING
			
			if can_wall:
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

			if can_wall:
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

			#  IMPLEMENT SO THAT THE PLAYER IS FACING AWAY FROM THE WALL THEY ARE ON
			# if lr_input_axis > DEADBAND:
			# 	is_facing_right = true
			# elif lr_input_axis < -DEADBAND:
			# 	is_facing_right = false

			if is_grab_pressed:
				walling_substate = Walling_Substate.CLIMBING

			elif ud_input_axis > DEADBAND:
				walling_substate = Walling_Substate.FAST_SLIDING
			
			elif ud_input_axis < -DEADBAND:
				walling_substate = Walling_Substate.SLOW_SLIDING
			
			else:
				walling_substate = Walling_Substate.PASSIVE_SLIDING

			match walling_substate:
				Walling_Substate.SLOW_SLIDING:
					print("SLOW_SLIDING")
					velocity.y = SLIDE_SLOW_MAX_SPEED

					if abs(lr_input_axis) > 0:
						state = State.WALKING

				Walling_Substate.PASSIVE_SLIDING:
					print("PASSIVE_SLIDING")
					velocity.y = SLIDE_PASSIVE_MAX_SPEED
					
					if abs(lr_input_axis) > 0:
						state = State.WALKING

				Walling_Substate.FAST_SLIDING:
					print("FAST_SLIDING")
					velocity.y = SLIDE_FAST_MAX_SPEED

					if abs(lr_input_axis) > 0:
						state = State.WALKING					

				Walling_Substate.CLIMBING:
					print("CLIMBING")
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
				
			# State transition handling
			if not can_wall: 
				state = State.WALKING
			
			if is_dash_just_pressed:
				state = State.DASHING

			if is_jump_pressed:
				state = State.JUMPING
			
		State.DASHING:
			print("DASHING")
			# State handling
			# Starts dash
			if can_dash:
				dash_input_vector = Input.get_vector("left", "right", "up", "down")
				dash_timer = 0.0
				velocity = Vector2.ZERO
				is_dashing = true
				dashes -= 1

			var percent_complete = clamp(dash_timer / DASH_MAX_DURATION, 0, 1)

			print(percent_complete)

			# Moves player through dash # PUT STATE MACHINE IMP. HERE, WHERE THE STATE IS PASSED INTO THE METHOD CALL
			if is_dashing:
				apply_dash(delta, percent_complete, Vector2.RIGHT)
			
			if percent_complete >= 1:
				exit_dash()	
			# State transition handling
			# if is_on_ground and not is_dashing: OLD
			# 	state = State.WALKING

			if not is_dashing:
				state = State.WALKING

			# POTENTIAL SUPER IMP.
			# if is_dashing and is_jump_pressed:
			# 	state = State.JUMPING
			# 	velocity.x *= 2

			if can_wall:
				exit_dash()
				state = State.WALLING

		State.JUMPING:
			# print("JUMPING")
			# State handling
			apply_air_walking(delta)

			#  NEED TO ADD JUMP COOLDOWN SOMEWHERE
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
					jumping_substate = Jumping_Substate.SLIDE_JUMPING # NEED TO ADD HORIZONTAL COMPONENT
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
						# print("GROUND_JUMPING")
						velocity.y = -GROUND_JUMP_SPEED

					Jumping_Substate.CLIMB_JUMPING:
						# print("CLIMB_JUMPING")
						velocity.y = -CLIMBING_JUMP_VELOCITY.y

					Jumping_Substate.SLIDE_JUMPING:
						# print("SLIDE_JUMPING")
						velocity.y = -SLIDING_JUMP_VELOCITY.y
					
					Jumping_Substate.AIR_JUMPING:
						# print("AIR_JUMPING")
						velocity.y = -AIR_JUMP_SPEED
			else:
				is_jumping = false

			# State transition handling
			if not is_jumping and is_on_ground:
				state = State.WALKING

			if not is_jumping and is_grab_pressed and can_wall:
				state = State.WALLING
				
			if is_dash_just_pressed: # NOT WORKING FOR SOME REASON
				state = State.DASHING
				is_jumping = false

			if not is_jumping and not is_on_ground:
				state = State.FALLING

		State.FALLING:
			# print("FALLING")
			# State handling
			apply_air_walking(delta) 

			if ud_input_axis > DEADBAND:
				falling_substate = Falling_Substate.FAST_FALLING

			elif ud_input_axis < -DEADBAND:
				falling_substate = Falling_Substate.SLOW_FALLING
			
			else:
				falling_substate = Falling_Substate.PASSIVE_FALLING

			match falling_substate:
				Falling_Substate.SLOW_FALLING:
					# print("SLOW_FALLING")
					velocity.y += (GRAVITY - SLOW_FALLING_ACCELERATION) * delta
				
				Falling_Substate.PASSIVE_FALLING:
					# print("PASSIVE_FALLING")
					velocity.y += GRAVITY * delta
				
				Falling_Substate.FAST_FALLING:
					# print("FAST_FALLING")
					velocity.y += (GRAVITY + FAST_FALLING_ACCELERATION) * delta

			if is_on_ground:
				state = State.WALKING

			if can_wall:
				state = State.WALLING

			if is_dash_just_pressed:
				state = State.DASHING
			
			if is_jump_just_pressed:
				state = State.JUMPING

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
