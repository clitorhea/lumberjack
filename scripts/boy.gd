extends BaseCharacter


func _ready() -> void:
	# Set boy-specific movement values
	move_speed = 250.0
	acceleration = 1200.0
	friction = 1000.0
	
	super._ready()
	add_to_group("boy")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func get_input() -> void:
	input_vector.x = Input.get_axis("move_left","move_right")
	input_vector.y = Input.get_axis("move_up" , "move_down")
	
func update_animation() -> void : 
	if is_moving:
		play_animation("walk")
	else:
		play_animation("idle")

# Play animation with direction suffix and handle sprite flipping for left movement
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
	
	# Handle left direction by using right animations and flipping sprite
	if facing_direction == "left":
		animation_direction = "right"
		should_flip = true
	
	var full_animation_name = prefix + animation_direction
	
	# Only change animation if it's different from current or flip state changed
	if animated_sprite.animation != full_animation_name or animated_sprite.flip_h != should_flip:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(full_animation_name):
			animated_sprite.flip_h = should_flip
			animated_sprite.play(full_animation_name)
		else:
			push_warning("Animation not found: " + full_animation_name)
