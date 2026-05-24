extends Node3D

var waypoints: Array[Vector3] = []

@export var path_node: Node3D # Arrastra aquí el nodo "Camino" desde el Inspector

func _ready() -> void:
	_build_waypoints()
	print("Board: waypoints cargados =", waypoints.size())

func _build_waypoints() -> void:
	waypoints.clear()

	if path_node == null:
		push_error("Board: path_node está vacío. Arrastra el nodo Camino en el Inspector.")
		return

	for child in path_node.get_children():
		if child is Marker3D:
			waypoints.append(child.global_position)
			print("Board: waypoint[", waypoints.size() - 1, "] =", child.global_position)

	print("Board: build complete, total waypoints =", waypoints.size())

func get_waypoints() -> Array[Vector3]:
	return waypoints
