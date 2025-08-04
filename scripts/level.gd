# level.gd
extends Node2D

@export var tree_scene: PackedScene = preload("res://scenes/Tree.tscn")
@export var lumberjack_scene: PackedScene = preload("res://scenes/characters/blue_pawn.tscn")

func _ready() -> void:
	# Add the TreeManager as a child
	var tree_manager = TreeManager.new()
	tree_manager.name = "TreeManager"
	add_child(tree_manager)
	
	# Spawn trees
	_create_forest()
	
	# Spawn lumberjacks
	_create_lumberjacks()

func _create_forest() -> void:
	# Method 1: Random placement
	for i in range(20):
		var tree = tree_scene.instantiate()
		tree.position = Vector2(
			randf_range(100, 1000),
			randf_range(100, 600)
		)
		add_child(tree)
	
	# Method 2: Grid placement
	for x in range(5):
		for y in range(5):
			var tree = tree_scene.instantiate()
			tree.position = Vector2(200 + x * 100, 100 + y * 100)
			add_child(tree)

func _create_lumberjacks() -> void:
	for i in range(3):
		var lumberjack = lumberjack_scene.instantiate()
		lumberjack.position = Vector2(500, 300 + i * 50)
		add_child(lumberjack)
