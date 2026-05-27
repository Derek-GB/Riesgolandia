extends Node3D

var waypoints: Array[Vector3] = []
var current_index: int = 0
@export var speed: float = 8.0
@export var jump_height: float = 1.2

signal reached_end
signal stepped_on(index: int)

# =========================================================
# SETUP
# =========================================================
func setup(board_waypoints: Array[Vector3]) -> void:
	waypoints = board_waypoints
	current_index = 0
	print("Ficha: setup - recibiendo waypoints:", waypoints.size())
	if waypoints.size() > 0:
		global_position = waypoints[0]
	else:
		push_warning("Ficha: no recibió waypoints")

# =========================================================
# MOVER PASOS HACIA ADELANTE
# =========================================================
func move_steps(steps: int) -> void:
	if waypoints.is_empty():
		push_warning("Ficha: no hay waypoints para moverse")
		return
	if steps <= 0:
		return
	print("Ficha: move_steps llamado con pasos =", steps, " current_index =", current_index)
	for i in range(steps):
		# =========================================================
		# SI ES EL ÚLTIMO WAYPOINT, NO AVANZAR MÁS
		# =========================================================
		if current_index >= waypoints.size() - 1:
			print("Ficha: ya está en el último waypoint, no avanza más")
			return
		current_index += 1
		print("Ficha: moviendo a índice", current_index, " posición:", waypoints[current_index])
		await _move_to(waypoints[current_index])
		stepped_on.emit(current_index)

# =========================================================
# MOVER PASOS HACIA ATRÁS
# =========================================================
func move_back(steps: int) -> void:
	if waypoints.is_empty():
		return
	for i in range(steps):
		if current_index <= 0:
			return
		current_index -= 1
		print("Ficha: retrocediendo a índice", current_index)
		await _move_to(waypoints[current_index])

# =========================================================
# MOVER A POSICIÓN CON SALTO
# =========================================================
func _move_to(target: Vector3) -> void:
	if speed <= 0:
		global_position = target
		return
	var start: Vector3 = global_position
	var distance: float = start.distance_to(target)
	var duration: float = max(0.09, distance / speed)
	var elapsed: float = 0.0
	while elapsed < duration:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		var t: float = min(elapsed / duration, 1.0)
		var horizontal: Vector3 = start.lerp(target, t)
		var height: float = sin(t * PI) * jump_height
		global_position = Vector3(horizontal.x, height, horizontal.z)
	global_position = target
