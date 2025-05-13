extends CharacterBody2D

# Signals
signal velocity_updated

# Genderal input consts
const DEADBAND = 0.5

# lr movement consts
const GROUND_MAX_SPEED := 400
const GROUND_ACCELERATION := 6000
const GROUND_DECELERATION := 9000
const GROUND_ZERO_THRESHOLD := 120
const AIR_MAX_SPEED := GROUND_MAX_SPEED
const AIR_ACCELERATION := GROUND_ACCELERATION * 0.75
const AIR_DECELERATION := GROUND_DECELERATION * 0.75
const AIR_ZERO_THRESHOLD := GROUND_ZERO_THRESHOLD

# ud movement consts
const CLIMB_MAX_SPEED := 200
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

# Jump consts
const GROUND_JUMP_SPEED := 500
const JUMP_CANCEL_SPEED := 200
const WALL_JUMP_VELOCITY := Vector2(0, 500)


# Grab consts
const GRAB_VELOCITY := 1 # UNUSED CURRENTLY

# Physics vars
var gravity = Vector2(0, 0)

# Movement vars
var is_facing_right = true
var lr_input := Input.get_axis("left", "right")
var ud_input := Input.get_axis("up", "down")

# Dash vars
var dash_input := Input.is_action_just_pressed("dash")
var dashes := 1 # Change MAX_DASHES to increase number of dashes
var is_dashing := false
var dash_timer := 0.0
var dash_input_vector := Vector2.ZERO
var dash_start_position := Vector2.ZERO
var dash_end_position := Vector2.ZERO

# Jump vars
var jump_input := Input.is_action_just_pressed("jump")
var is_jumping := false # NOT USED YET

# Grab vars
var is_grab_inverted := true
var grab_input := (Input.is_action_pressed("grab") or is_grab_inverted) and not (Input.is_action_pressed("grab") and is_grab_inverted)
var is_on_left_wall := false
var is_on_right_wall := false
var is_climbing := false
var is_sliding := false

#func _process(delta: float) -> void:

func _physics_process(delta: float) -> void:
	velocity_updated.emit(delta, velocity)
	
	gravity = get_gravity() * 1.3
	
	lr_input = Input.get_axis("left", "right")
	ud_input = Input.get_axis("up", "down")

	dash_input = Input.is_action_just_pressed("dash")

	jump_input = Input.is_action_just_pressed("jump")
	
	grab_input = (Input.is_action_pressed("grab") or is_grab_inverted) and not (Input.is_action_pressed("grab") and is_grab_inverted)
	is_climbing = grab_input and (is_on_left_wall or is_on_right_wall)
	is_sliding = not grab_input and (is_on_left_wall or is_on_right_wall)
	
	# Add dashing
	# Starts dash
	if dash_input and not is_dashing and dashes > 0:
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
			is_dashing = false
	# Disables this block of code if the player is dashing to prevent other movements
	if not is_dashing:
		# Flips the direction the player is facing based off of user input
		if lr_input > DEADBAND:
			is_facing_right = true
		elif lr_input < -DEADBAND:
			is_facing_right = false
			
		# Add gravity
		if not is_on_floor():
			# Normal gravity
			if not is_on_left_wall and not is_on_right_wall:
				velocity += gravity * delta
			# Sliding gravity
			elif is_sliding:
				print((SLIDE_PASSIVE_ACCELERATION + SLIDE_ACTIVE_ACCELERATION_OFFSET * ud_input) * delta)
				if velocity.y + (SLIDE_PASSIVE_ACCELERATION + SLIDE_ACTIVE_ACCELERATION_OFFSET * ud_input) * delta <= SLIDE_PASSIVE_MAX_SPEED + ud_input * SLIDE_ACTIVE_SPEED_OFFSET:
					velocity.y += (SLIDE_PASSIVE_ACCELERATION + SLIDE_ACTIVE_ACCELERATION_OFFSET * ud_input) * delta
				else:
					velocity.y = SLIDE_PASSIVE_MAX_SPEED + ud_input * SLIDE_ACTIVE_SPEED_OFFSET

		# Add wall climbing
		if grab_input and (is_on_left_wall or is_on_right_wall): # IS CLIMBING GOES HERE
			if velocity.y <= CLIMB_MAX_SPEED and ud_input > DEADBAND:
				if velocity.y + ud_input * CLIMB_ACCELERATION * delta <= CLIMB_MAX_SPEED:
					velocity.y += ud_input * CLIMB_ACCELERATION * delta
				else:
					velocity.y = CLIMB_MAX_SPEED
			elif velocity.y >= -CLIMB_MAX_SPEED and ud_input < -DEADBAND:
				if velocity.y + ud_input * CLIMB_ACCELERATION * delta >= -CLIMB_MAX_SPEED:
					velocity.y += ud_input * CLIMB_ACCELERATION * delta
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
			dashes = MAX_DASHES
			if velocity.x <= GROUND_MAX_SPEED and lr_input > DEADBAND:
				if velocity.x + lr_input * GROUND_ACCELERATION * delta <= GROUND_MAX_SPEED:
					velocity.x += lr_input * GROUND_ACCELERATION * delta
				else:
					velocity.x = GROUND_MAX_SPEED
			elif velocity.x >= -GROUND_MAX_SPEED and lr_input < -DEADBAND:
				if velocity.x + lr_input * GROUND_ACCELERATION * delta >= -GROUND_MAX_SPEED:
					velocity.x += lr_input * GROUND_ACCELERATION * delta
				else:
					velocity.x = -GROUND_MAX_SPEED
			else:
				if velocity.x > GROUND_ZERO_THRESHOLD:
					velocity.x -= GROUND_DECELERATION * delta
				elif velocity.x < -GROUND_ZERO_THRESHOLD:
					velocity.x += GROUND_DECELERATION * delta
				else:
					velocity.x = 0
		else:
			if velocity.x <= AIR_MAX_SPEED and lr_input > DEADBAND:
				if velocity.x + lr_input * AIR_ACCELERATION * delta <= AIR_MAX_SPEED:
					velocity.x += lr_input * AIR_ACCELERATION * delta
				else:
					velocity.x = AIR_MAX_SPEED
			elif velocity.x >= -AIR_MAX_SPEED and lr_input < -DEADBAND:
				if velocity.x + lr_input * AIR_ACCELERATION * delta >= -AIR_MAX_SPEED:
					velocity.x += lr_input * AIR_ACCELERATION * delta
				else:
					velocity.x = -AIR_MAX_SPEED
			else:
				if velocity.x > AIR_ZERO_THRESHOLD:
					velocity.x -= AIR_DECELERATION * delta
				elif velocity.x < -AIR_ZERO_THRESHOLD:
					velocity.x += AIR_DECELERATION * delta
				else:
					velocity.x = 0

		# Add jumping # NEED TO REPLACE IS_ON_FLOOR W/ AREA CHECK AT SOME POINT # NEED TO ADD VARIABLE HEIGHT JUMPING
		# Ground jumping
		if jump_input:
			if is_on_floor():
				velocity.y = -GROUND_JUMP_SPEED
			elif is_on_left_wall:
				print("left wall jump")
			elif is_on_right_wall:
				print("right wall jump")

	move_and_slide()
	


func _on_left_wall_detection_area_2d_body_entered(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_left_wall = true


func _on_left_wall_detection_area_2d_body_exited(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_left_wall = false


func _on_right_wall_detection_area_2d_2_body_entered(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_right_wall = true


func _on_right_wall_detection_area_2d_2_body_exited(body: Node2D) -> void:
	if body.get_name() != "Player2D":
		is_on_right_wall = false
