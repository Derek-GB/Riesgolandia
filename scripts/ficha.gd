extends Node2D

var waypoints: Array[Vector2] = []
var current_index: int = 0

@export var speed: float = 300.0

signal reached_end
signal stepped_on(index: int)


func setup(board_waypoints: Array[Vector2]) -> void:
	waypoints = board_waypoints
	current_index = 0

	print("Ficha: setup - recibiendo waypoints:", waypoints.size())

	if waypoints.size() > 0:
		global_position = waypoints[0]
	else:
		push_warning("Ficha: no recibió waypoints")


func move_steps(steps: int) -> void:
	if waypoints.is_empty():
		push_warning("Ficha: no hay waypoints para moverse")
		return

	if steps <= 0:
		return

	print("Ficha: move_steps llamado con pasos =", steps, " current_index =", current_index)

	for i in range(steps):
		if current_index >= waypoints.size() - 1:
			print("Ficha: llegó al final en index", current_index)
			reached_end.emit()
			return

		current_index += 1

		print("Ficha: moviendo a índice", current_index, " posición:", waypoints[current_index])

		await _move_to(waypoints[current_index])

		stepped_on.emit(current_index)

	if current_index >= waypoints.size() - 1:
		print("Ficha: llegó a la meta")
		reached_end.emit()


func _move_to(target: Vector2) -> void:
	if speed <= 0:
		global_position = target
		return

	var distance := global_position.distance_to(target)
	var duration := distance / speed

	if duration < 0.05:
		duration = 0.05

	var tween := create_tween()

	tween.tween_property(
		self,
		"global_position",
		target,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
