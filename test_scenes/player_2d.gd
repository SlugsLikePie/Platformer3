extends CharacterBody2D

var DEADBAND = 0.5

# lr movement consts
const GROUND_MAX_SPEED := 600	
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

# Dash consts
const NUM_DASHES := 1
const DASH_START_SPEED := 3000
const DASH_END_SPEED := 100
const DASH_MAX_DURATION := 0.125

# Jump consts
const JUMP_VELOCITY := 500

# Grab consts
const GRAB_VELOCITY := 1000

# Movement vars
var is_facing_right = true

# Dash vars
var dashes := 1
var is_dashing := false
var dash_timer := 0.0
var dash_input_vector := Vector2.ZERO
var dash_start_position := Vector2.ZERO
var dash_end_position := Vector2.ZERO

# Grab vars
var is_on_left_wall := false
var is_on_right_wall := false

#func _process(delta: float) -> void:

func _physics_process(delta: float) -> void:
	var lr_input := Input.get_axis("left", "right")
	var ud_input := Input.get_axis("up", "down")

	var dash_input := Input.is_action_just_pressed("dash")

	var jump_input := Input.is_action_just_pressed("jump")
	
	var grab_input := Input.is_action_pressed("grab")

	# Add dashing
	if dash_input and not is_dashing and dashes > 0:
		dash_input_vector = Input.get_vector("left", "right", "up", "down")
		dash_timer = 0
		velocity = Vector2.ZERO
		is_dashing = true
		dashes -= 1

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

		if percent_complete >= 1:
			dash_timer = 0
			is_dashing = false

	if not is_dashing:
		# Flips the direction the player is facing based off of user input
		if lr_input > DEADBAND:
			is_facing_right = true
		elif lr_input < -DEADBAND:
			is_facing_right = false
	
	if not is_dashing:
		# Add gravity
		if not is_on_floor():
			if not is_on_left_wall and not is_on_right_wall:
				velocity += get_gravity() * delta
			elif not grab_input and (is_on_left_wall or is_on_right_wall):
				if velocity.y >= 0:
					velocity += get_gravity() / 5 * delta
				else:
					velocity.y = 0
			# Add wall climbing
		if grab_input and (is_on_left_wall or is_on_right_wall):
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
				# Add wall jumping

		# Apply left & right inputs:
		if is_on_floor():
			dashes = NUM_DASHES
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

		# Add floor jumping
		if is_on_floor():
			if jump_input:
				velocity.y = -JUMP_VELOCITY

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
