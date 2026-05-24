extends Node

var tokens: Array = []
var current_player: int = 0
var is_player_moving: bool = false

signal turn_changed(player_index: int)


func register_token(token: Node) -> void:
	if token in tokens:
		return

	print("GameManager: registrando token:", token)
	tokens.append(token)


func on_dice_rolled(n: int) -> void:
	print("GameManager: on_dice_rolled recibido ->", n, " is_player_moving =", is_player_moving, " tokens =", tokens.size())

	if is_player_moving:
		print("GameManager: movimiento abortado - ya se está moviendo una ficha")
		return

	if tokens.is_empty():
		print("GameManager: movimiento abortado - no hay tokens registrados")
		return

	if current_player >= tokens.size():
		current_player = 0

	is_player_moving = true

	var active_token = tokens[current_player]

	print("GameManager: token activo ->", active_token, " índice jugador ->", current_player)

	await active_token.move_steps(n)

	print("GameManager: movimiento completado para token")

	is_player_moving = false

	_next_turn()


func _next_turn() -> void:
	if tokens.is_empty():
		return

	current_player = (current_player + 1) % tokens.size()

	print("GameManager: siguiente turno -> jugador", current_player + 1)

	turn_changed.emit(current_player)
