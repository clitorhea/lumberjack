extends BaseCharacter
class_name blue_pawn_npc

enum State {
	IDLE,
	SEARCHING_TREE,
	MOVING_TO_TREE,
	CHOPPING,
	RETURNING_HOME
}

@export_group("Lumberjack Settings")
@export var chop_damage: int = 1
@export var chop_range: float = 50.0
@export var search_range: float = 300.0
@export var chop_cooldown: float = 1.0
@export var home_position: Vector2
@export var wood_capacity: int = 20

@export_group("Behavior")
@export var return_home_when_full: bool = true
@export var idle_time_range: Vector2 = Vector2(2.0, 5.0)  # Random idle between searches

var current_state: State = State.IDLE
var target_tree = null
var wood_carried: int = 0
var chop_timer: float = 0.0
var idle_timer: float = 0.0

# For debug visualization
@export var show_debug: bool = false

func _ready() -> void:
	super._ready()
	add_to_group("npcs")
	add_to_group("lumberjacks")
	
	# Set home position to starting position if not set
	if home_position == Vector2.ZERO:
		home_position = global_position
	
	# Start with idle state
	_enter_state(State.IDLE)

func _physics_process(delta: float) -> void:
	# Update base movement
	super._physics_process(delta)
	
	# Handle state-specific logic
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.SEARCHING_TREE:
			_process_searching()
		State.MOVING_TO_TREE:
			_process_moving_to_tree(delta)
		State.CHOPPING:
			_process_chopping(delta)
		State.RETURNING_HOME:
			_process_returning_home(delta)
	
	if show_debug:
		queue_redraw()

func get_input() -> void:
	# Input is handled by AI state machine
	pass

func _enter_state(new_state: State) -> void:
	# Exit current state
	match current_state:
		State.CHOPPING:
			play_animation("chopping")
	
	current_state = new_state
	
	# Enter new state
	match new_state:
		State.IDLE:
			idle_timer = randf_range(idle_time_range.x, idle_time_range.y)
			input_vector = Vector2.ZERO
		State.SEARCHING_TREE:
			_search_for_tree()
		State.MOVING_TO_TREE:
			pass  # Movement handled in process
		State.CHOPPING:
			input_vector = Vector2.ZERO
			chop_timer = 0.0
		State.RETURNING_HOME:
			pass  # Movement handled in process

func _process_idle(delta: float) -> void:
	idle_timer -= delta
	if idle_timer <= 0:
		if wood_carried >= wood_capacity and return_home_when_full:
			_enter_state(State.RETURNING_HOME)
		else:
			_enter_state(State.SEARCHING_TREE)

func _process_searching() -> void:
	_search_for_tree()

func _search_for_tree() -> void:
	print ("searching for tree... : ")
	if TreeManager.instance == null:
		print("ERROR: TreeManager.instance is null!")
		return
	var closest_tree = TreeManager.instance.get_closest_tree(global_position, search_range)
	print ("Closest tree found: ", closest_tree) 
	if closest_tree:
		print("Tree position: ", closest_tree.global_position)
		print("NPC position: ", global_position)
		target_tree = closest_tree
		_enter_state(State.MOVING_TO_TREE)
	else:
		# No tree found, go back to idle
		print ("No tree found, go back to idle")
		_enter_state(State.IDLE)

func _process_moving_to_tree(delta: float) -> void:
	if not target_tree or not target_tree.is_choppable():
		_enter_state(State.SEARCHING_TREE)
		return
	
	var distance = get_distance_to(target_tree.get_chop_position())
	
	if distance <= chop_range:
		_enter_state(State.CHOPPING)
	else:
		# Move towards tree
		input_vector = get_direction_to(target_tree.get_chop_position())

func _process_chopping(delta: float) -> void:
	if not target_tree or not target_tree.is_choppable():
		_enter_state(State.SEARCHING_TREE)
		return
	
	# Face the tree
	var dir_to_tree = get_direction_to(target_tree.global_position)
	if dir_to_tree.length() > 0:
		last_direction = dir_to_tree
		update_facing_direction()
	
	chop_timer += delta
	if chop_timer >= chop_cooldown:
		chop_timer = 0.0
		_perform_chop()

func _perform_chop() -> void:
	if not target_tree:
		return
	
	# Play chop animation
	play_oneshot_animation("chopping", false)
	
	# Deal damage to tree
	target_tree.take_damage(chop_damage)
	
	# Check if tree was destroyed
	if not target_tree.is_choppable():
		wood_carried += target_tree.wood_amount
		target_tree = null
		
		# Decide next action
		if wood_carried >= wood_capacity and return_home_when_full:
			_enter_state(State.RETURNING_HOME)
		else:
			_enter_state(State.SEARCHING_TREE)

func _process_returning_home(delta: float) -> void:
	var arrived = move_toward_position(home_position, delta, 20.0)
	
	if arrived:
		_deposit_wood()
		_enter_state(State.IDLE)

func _deposit_wood() -> void:
	# Add your wood storage logic here
	print("Deposited " + str(wood_carried) + " wood")
	wood_carried = 0

func process_custom_animation() -> void:
	# Override base animation for chopping state
	if current_state == State.CHOPPING and animated_sprite.animation != "chopping":
		return  # Don't override chop animation

func _draw() -> void:
	if not show_debug:
		return
	
	# Draw search range
	draw_arc(Vector2.ZERO, search_range, 0, TAU, 32, Color(0, 1, 0, 0.2), 2.0)
	
	# Draw chop range
	draw_arc(Vector2.ZERO, chop_range, 0, TAU, 16, Color(1, 0, 0, 0.3), 2.0)
	
	# Draw line to target
	if target_tree:
		draw_line(Vector2.ZERO, to_local(target_tree.global_position), Color.YELLOW, 2.0)
	
	# Draw state text
	var state_text = State.keys()[current_state]
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(-50, -40), state_text + " Wood: " + str(wood_carried), 
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

# Optional: Get status for UI or debugging
func get_status() -> String:
	return State.keys()[current_state] + " - Wood: " + str(wood_carried) + "/" + str(wood_capacity)
