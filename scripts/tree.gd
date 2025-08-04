# Tree.gd
extends StaticBody2D
class_name GameTree

signal tree_chopped()
signal health_changed(new_health: int)

@export var max_health: int = 3
@export var wood_amount: int = 5
@export var respawn_time: float = 30.0  # Set to 0 to disable respawn

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

var current_health: int
var is_chopped: bool = false
var reserved_by = null  # Reference to NPC that reserved this tree

func _ready() -> void:
	current_health = max_health
	add_to_group("trees")
	add_to_group("choppable")
	print("Tree added to group at position: ", global_position)
	
	# Hide health bar initially
	if health_bar:
		health_bar.visible = false
		health_bar.max_value = max_health
		health_bar.value = current_health

func take_damage(damage: int) -> void:
	if is_chopped:
		return
		
	current_health -= damage
	health_changed.emit(current_health)
	
	# Show health bar when damaged
	if health_bar:
		health_bar.visible = true
		health_bar.value = current_health
	
	# Visual feedback
	_play_hit_effect()
	
	if current_health <= 0:
		_chop_down()

func _play_hit_effect() -> void:
	# Shake effect
	var tween = create_tween()
	var original_pos = position
	for i in range(3):
		tween.tween_property(self, "position", original_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.05)
		tween.tween_property(self, "position", original_pos, 0.05)
	
	# Flash white (if using modulate)
	animated_sprite.modulate = Color.WHITE * 1.5
	await get_tree().create_timer(0.1).timeout
	animated_sprite.modulate = Color.WHITE

func _chop_down() -> void:
	is_chopped = true
	reserved_by = null  # Clear reservation when tree is chopped
	tree_chopped.emit()
	
	# Disable collision
	collision_shape.set_deferred("disabled", true)
	
	# Play falling animation if available
	if animated_sprite.sprite_frames.has_animation("fall"):
		animated_sprite.play("fall")
		await animated_sprite.animation_finished
	
	# Drop wood (optional - create wood pickup scene)
	_drop_wood()
	
	# Hide or remove tree
	visible = false
	
	# Respawn after time
	if respawn_time > 0:
		await get_tree().create_timer(respawn_time).timeout
		_respawn()
	else:
		queue_free()

func _drop_wood() -> void:
	# Implement wood dropping logic here
	# You could instantiate wood pickup items
	pass

func _respawn() -> void:
	is_chopped = false
	reserved_by = null  # Clear any lingering reservation
	current_health = max_health
	visible = true
	collision_shape.disabled = false
	
	if health_bar:
		health_bar.visible = false
		health_bar.value = max_health
	
	if animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func get_chop_position() -> Vector2:
	# Return position where NPC should stand to chop
	return global_position

func is_choppable() -> bool:
	return not is_chopped

func is_available() -> bool:
	return not is_chopped and reserved_by == null

func reserve_for_npc(npc) -> bool:
	if is_available():
		reserved_by = npc
		return true
	return false

func release_reservation() -> void:
	reserved_by = null

func is_reserved_by(npc) -> bool:
	return reserved_by == npc
