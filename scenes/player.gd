extends CharacterBody2D

# ================= STATES =================
enum States { FLOOR, AIR, WALL }
var state: States = States.AIR

#================== animations ==============
var next_anim
var current_anim
var input_dir := Input.get_axis("ui_left", "ui_right")

# ================= FLOOR =================
@export var run_speed := 600.0
@export var floor_acceleration := 2000.0

# ================= AIR =================
@export var air_speed := 600.0
@export var air_acceleration := 2000.0
@export var gravity := 3500.0
@export var max_fall_speed := 3000.0

# ================= JUMP =================

@export var jump_cut := 0.3
@export var cayote = 0.15
@export var can_jump =false
@export var max_jump_force = -2000 # vertical speed applied when jump happens
@export var friction = 4000  
var land_timer = 0.03 


# ================= WALL =================
@export var wall_slide_speed := 200.0
@export var wall_friction := 4000.0
@export var wall_leave_time := 0.1
var wall_timer := 0.0

# ================= COMBAT =================
var health := 100
var knock_back := Vector2.ZERO

# ================= PHYSICS =================
func _physics_process(delta: float) -> void:
	match state:
		
		
		States.FLOOR:
			
			cayote = 1  # reset coyote timer when on floor
			can_jump=true
			if not is_on_floor():
				state = States.AIR 
				cayote -= delta          # decrease coyote timer when leaving floor
				cayote = max(cayote,0)  # ensure it doesn't go below 0
					  # switch to air state
			movement(delta, run_speed, floor_acceleration)  # handle floor movement
		States.AIR:
			if is_on_floor():
				state = States.FLOOR
			elif $wall_check.is_colliding():
				state= States.WALL
			can_jump=false 
			land_timer=   0.05
			 # if landing, switch back to floor state
			movement(delta, air_speed, air_acceleration)
			
		
		States.WALL:
			if is_on_floor():
				state= States.FLOOR
			elif not $wall_check.is_colliding():
				get_tree().create_timer(wall_timer).timeout.connect(func():
					state = States.AIR)
			velocity.y= move_toward(velocity.y, 0, friction*delta)
			can_jump=true
			movement(delta, air_speed, air_acceleration)
			
		
		
			
			  # handle air movement
	#testing knockback
	jump(delta)           # handle jumping logic
	apply_gravity(delta)
	move_and_slide()  
	update_animation(delta)     # move the character according to velocity

# ----- MOVEMENT FUNCTION -----
# Handles horizontal input and animations
func movement(d, speed, acceleration):
	if Input.is_action_pressed("ui_left"):
		velocity.x = move_toward(velocity.x, -speed, acceleration*d)  # accelerate left
		$AnimatedSprite2D.flip_h= false
		$wall_check.rotation = PI # flip sprite horizontally

	elif Input.is_action_pressed("ui_right"):
		velocity.x = move_toward(velocity.x, speed, acceleration*d)   # accelerate right
		$AnimatedSprite2D.flip_h= true
		$wall_check.rotation = 0

	else:
		# No input: slow down toward 0 velocity smoothly
		velocity.x = move_toward(velocity.x, 0, 2*acceleration*d)

	# Clamp horizontal speed to max/min based on current speed parameter
	velocity.x = clamp(velocity.x, -speed, speed)
	velocity.y = clamp(velocity.y, max_jump_force, -max_jump_force)


# ----- GRAVITY FUNCTION -----
# Applies gravity to the player when in the air
func apply_gravity(d):
	if not is_on_floor():
		velocity.y += gravity*d 
# increase downward velocity

func jump(d):
	
	# Start jump if on floor or within coyote time window
	if (is_on_floor() or cayote > 0 or is_on_wall()) and can_jump and Input.is_action_just_pressed("ui_up"):       # start jump weight timer
		velocity.y = max_jump_force
		can_jump = false

	# Variable jump height: reduce upward velocity if jump button released early
	if Input.is_action_just_released("ui_up") and velocity.y < 0:
		velocity.y *= jump_cut
		
func attack():
	if Input.is_action_just_pressed("attack"):
		next_anim = 'attack1'
	
# ================= ANIMATION =================
func update_animation(d) -> void:
	var next_anim := ""
	
	if Input.is_action_pressed("attack"):
		next_anim= "attack1"
		
	elif state == States.FLOOR :
		next_anim = "land"
		land_timer -= d
		land_timer = max(land_timer, 0)
		if land_timer ==0:
			if abs(velocity.x) <30 :
				next_anim = "idle"
			else:
				next_anim = "run"
	elif state == States.WALL:
		next_anim = "wall"
	else:
		if velocity.y < 0:
			next_anim = "jump"
		else:
			next_anim = "fall"
	# 🔑 Only change animation if it is different
	if next_anim != current_anim:
		$AnimationPlayer.play(next_anim)
		current_anim = next_anim
