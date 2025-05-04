extends CharacterBody2D

var DEADBAND = 0.5

const GROUND_MAX_SPEED := 600	
const GROUND_INITIAL_SPEED := 6
const GROUND_ACCELERATION := 6000
const GROUND_DECELERATION := 9000
const GROUND_ZERO_THRESHOLD := 200
const GROUND_OVERSPEED_DECELERATION := 5

const AIR_MAX_SPEED := GROUND_MAX_SPEED
const AIR_INITIAL_SPEED := 4
const AIR_ACCELERATION := GROUND_ACCELERATION * 0.75
const AIR_DECELERATION := GROUND_DECELERATION * 0.75
const AIR_ZERO_THRESHOLD := GROUND_ZERO_THRESHOLD
const AIR_OVERSPEED_DECELERATION := 5

const DASH_START_SPEED := 3000
const DASH_END_SPEED := 100
const DASH_MAX_DURATION := 0.125

const JUMP_VELOCITY := 500

var is_facing_right = true

var can_dash = true
var is_dashing := false
var dash_timer := 0.0
var dash_input_vector := Vector2.ZERO
var dash_start_position := Vector2.ZERO
var dash_end_position := Vector2.ZERO

#func _process(delta: float) -> void:

func _physics_process(delta: float) -> void:
	var lr_input := Input.get_axis("left", "right")

	var dash_input := Input.is_action_just_pressed("dash")

	var jump_input := Input.is_action_just_pressed("jump")

	# Add dashing
	if dash_input and not is_dashing and can_dash:
		dash_input_vector = Input.get_vector("left", "right", "up", "down")
		dash_timer = 0
		velocity = Vector2.ZERO
		is_dashing = true
		can_dash = false

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

		# Add gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Apply left & right inputs
		if is_on_floor():
			can_dash = true 
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

		# Add jumping
		if is_on_floor():
			if jump_input:
				velocity.y = -JUMP_VELOCITY

	move_and_slide()
