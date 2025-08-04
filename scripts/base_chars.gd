extends CharacterBody2D
class_name BaseCharacter

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Movement variables
@export var move_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

# State tracking
var is_moving: bool = false
var last_direction: Vector2 = Vector2.DOWN
var current_speed: float = 0.0
var facing_direction: String = "down"  # For animation purposes

# Input variables (to be overridden in inherited scripts)
var input_vector: Vector2 = Vector2.ZERO
var move_direction: Vector2 = Vector2.ZERO

# Animation settings
@export var animation_prefix_idle: String = "idle_"
@export var animation_prefix_walk: String = "walk_"

# Optional: Movement constraints
@export var four_directional: bool = false

# Called when the node enters the scene tree
func _ready() -> void:
	# Ensure we have an AnimatedSprite2D
	if not animated_sprite:
		push_error("No AnimatedSprite2D found as child! Please add one or set the reference manually.")
	
	# Play default idle animation
	play_animation("idle")

# Main physics process
func _physics_process(delta: float) -> void:
	# Get input (override get_input() in inherited scripts)
	get_input()
	
	# Process movement direction
	process_movement_direction()
	
	# Handle movement
	handle_movement(delta)
	
	# Update states
	update_states()
	
	# Move the character
	move_and_slide()
	
	# Update animations based on movement
	update_animation()
	
	# Additional processing (override in inherited scripts)
	process_custom_animation()
	process_audio()

# Override this method in inherited scripts to handle input
func get_input() -> void:
	# Example for player character:
	# input_vector.x = Input.get_axis("move_left", "move_right")
	# input_vector.y = Input.get_axis("move_up", "move_down")
	
	# For NPCs, you might set these based on AI logic
	pass

# Process the movement direction based on input
func process_movement_direction() -> void:
	move_direction = input_vector.normalized()
	
	# Apply movement constraints if enabled
	if four_directional and move_direction.length() > 0:
		# Lock to 4 directions
		if abs(move_direction.x) > abs(move_direction.y):
			move_direction = Vector2(sign(move_direction.x), 0)
		else:
			move_direction = Vector2(0, sign(move_direction.y))

# Handle movement with acceleration and friction
func handle_movement(delta: float) -> void:
	if move_direction.length() > 0:
		# Apply acceleration
		velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
		last_direction = move_direction
		is_moving = true
		
		# Update facing direction for animations
		update_facing_direction()
	else:
		# Apply friction
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		is_moving = false
	
	# Update current speed
	current_speed = velocity.length()

# Update the facing direction based on movement
func update_facing_direction() -> void:
	facing_direction = get_4way_direction(last_direction)

# Get 4-way direction string from vector
func get_4way_direction(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			return "right"
		else:
			return "left"
	else:
		if direction.y > 0:
			return "down"
		else:
			return "up"


# Update states
func update_states() -> void:
	is_moving = current_speed > 10.0

# Main animation update function
func update_animation() -> void:
	if is_moving:
		play_animation("walk")
	else:
		play_animation("idle")

# Play animation with direction suffix
func play_animation(base_name: String) -> void:
	if not animated_sprite:
		return
	
	var prefix = ""
	if base_name == "idle":
		prefix = animation_prefix_idle
	elif base_name == "walk":
		prefix = animation_prefix_walk
	
	var animation_direction = facing_direction
	var should_flip = false 
	
	if facing_direction == "left" : 
		animation_direction = "right"
		should_flip = true 
	
	var full_animation_name = prefix + animation_direction
	
	# Only change animation if it's different from current
	if animated_sprite.animation != full_animation_name or animated_sprite.flip_h != should_flip:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(full_animation_name):
			animated_sprite.flip_h = should_flip
			animated_sprite.play(full_animation_name)
		else:
			push_warning("Animation not found: " + full_animation_name)

# Override this for custom animations (attacks, special moves, etc.)
func process_custom_animation() -> void:
	pass

# Override this for audio
func process_audio() -> void:
	pass

# Play a one-shot animation and return to idle/walk
func play_oneshot_animation(animation_base: String, return_to_idle: bool = true) -> void:
	if not animated_sprite:
		return
		
	var full_animation_name = animation_base + "_" + facing_direction
	
	if animated_sprite.sprite_frames.has_animation(full_animation_name):
		animated_sprite.play(full_animation_name)
		
		# Connect to animation_finished if not already connected
		if not animated_sprite.animation_finished.is_connected(_on_oneshot_animation_finished):
			animated_sprite.animation_finished.connect(_on_oneshot_animation_finished.bind(return_to_idle), CONNECT_ONE_SHOT)

# Called when one-shot animation finishes
func _on_oneshot_animation_finished(return_to_idle: bool) -> void:
	if return_to_idle:
		update_animation()

# Utility functions
func is_idle() -> bool:
	return not is_moving

func apply_knockback(force: Vector2) -> void:
	velocity += force

func stop_movement() -> void:
	velocity = Vector2.ZERO
	input_vector = Vector2.ZERO
	move_direction = Vector2.ZERO

func get_direction_to(target_position: Vector2) -> Vector2:
	return (target_position - global_position).normalized()

func get_distance_to(target_position: Vector2) -> float:
	return global_position.distance_to(target_position)

func has_line_of_sight_to(target_position: Vector2, collision_mask: int = 1) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target_position)
	query.collision_mask = collision_mask
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func move_toward_position(target_position: Vector2, delta: float, arrival_distance: float = 10.0) -> bool:
	var distance = get_distance_to(target_position)
	if distance > arrival_distance:
		input_vector = get_direction_to(target_position)
		return false
	else:
		input_vector = Vector2.ZERO
		return true

# Get the current animation base name (without direction)
func get_current_animation_base() -> String:
	if not animated_sprite or not animated_sprite.animation:
		return ""
	
	var current = animated_sprite.animation
	for direction in ["up", "down", "left", "right"]:
		current = current.replace("_" + direction, "")
	
	return current
