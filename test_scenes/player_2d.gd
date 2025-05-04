extends CharacterBody2D

var DEADBAND = 0.5
# test
@export var GROUND_MAX_SPEED = 600	
@export var GROUND_INITIAL_SPEED = 6
@export var GROUND_ACCELERATION = 6000
@export var GROUND_DECELERATION = 6000
@export var GROUND_ZERO_THRESHOLD = 200
@export var GROUND_OVERSPEED_DECELERATION = 5

@export var AIR_MAX_SPEED = GROUND_MAX_SPEED
@export var AIR_INITIAL_SPEED = 4
@export var AIR_ACCELERATION = GROUND_ACCELERATION * 0.75
@export var AIR_DECELERATION = GROUND_DECELERATION * 0.75
@export var AIR_ZERO_THRESHOLD = GROUND_ZERO_THRESHOLD
@export var AIR_OVERSPEED_DECELERATION = 5

@export var JUMP_VELOCITY = 500

#func _process(delta: float) -> void:

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	print(velocity)
	
	# Apply left & right inputs
	var lr_input = Input.get_axis("left", "right")
	if is_on_floor():
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
		if Input.is_action_just_pressed("jump"):
			velocity.y = -JUMP_VELOCITY

	move_and_slide()
