extends Node

func get_first_node_in_group(group: String):
	var nodes = get_tree().get_nodes_in_group(group)
	
	assert(len(nodes) > 0)
	
	return nodes[0]

func get_parent_of_type(obj: Node3D, class_to_search: String):
	var parent: Node3D
	parent = obj
	while true:
		if parent.is_class(class_to_search):
			return parent
		
		parent = parent.get_parent()
		assert(parent)
