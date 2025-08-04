extends Node
class_name TreeManager

# Singleton for managing all trees
static var instance: TreeManager

func _enter_tree() -> void:
	instance = self
	print("TreeManager instance created")

func get_closest_tree(from_position: Vector2, max_distance: float = INF):
	var trees = get_tree().get_nodes_in_group("trees")
	print("TreeManager: Found ", trees.size(), " trees in group")
	var closest_tree = null
	var closest_distance: float = max_distance
	
	for tree in trees:
		if not tree.is_choppable():
			continue
			
		var distance = from_position.distance_to(tree.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_tree = tree
	
	return closest_tree

func get_closest_available_tree(from_position: Vector2, max_distance: float = INF):
	var trees = get_tree().get_nodes_in_group("trees")
	print("TreeManager: Found ", trees.size(), " trees in group")
	var closest_tree = null
	var closest_distance: float = max_distance
	
	for tree in trees:
		if not tree.is_available():
			continue
			
		var distance = from_position.distance_to(tree.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_tree = tree
	
	return closest_tree

func get_trees_in_range(from_position: Vector2, range: float):
	var trees_in_range = []
	var trees = get_tree().get_nodes_in_group("trees")
	
	for tree in trees:
		if not tree.is_choppable():
			continue
			
		if from_position.distance_to(tree.global_position) <= range:
			trees_in_range.append(tree)
	
	return trees_in_range
