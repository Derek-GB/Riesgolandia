extends Node

# =========================================================
# MINIJUEGO
# =========================================================
const MAP_PUZZLE = preload("res://scenes/MapPuzzle.tscn")

var minijuego_activo: bool = false
var mensaje_label: Label


# =========================================================
# VARIABLES ORIGINALES
# =========================================================
var tokens: Array = []
var current_player: int = 0
var is_player_moving: bool = false

signal turn_changed(player_index: int)


# =========================================================
# READY
# =========================================================
func _ready() -> void:

	# Esperar a que cargue main.tscn
	await get_tree().process_frame

	var scene = get_tree().current_scene

	# Buscar MensajeLabel automáticamente
	if scene.has_node("MensajeLabel"):

		mensaje_label = scene.get_node("MensajeLabel")

		mensaje_label.visible = false


# =========================================================
# REGISTRAR TOKENS
# =========================================================
func register_token(token: Node) -> void:

	if token in tokens:
		return

	print("GameManager: registrando token:", token)

	tokens.append(token)


# =========================================================
# CUANDO EL DADO TERMINA
# =========================================================
func on_dice_rolled(n: int) -> void:

	# Si hay minijuego abierto
	if minijuego_activo:
		print("GameManager: minijuego activo")
		return

	print(
		"GameManager: on_dice_rolled recibido ->",
		n,
		" is_player_moving =",
		is_player_moving,
		" tokens =",
		tokens.size()
	)

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

	print(
		"GameManager: token activo ->",
		active_token,
		" índice jugador ->",
		current_player
	)

	# =====================================================
	# MOVER FICHA
	# =====================================================
	await active_token.move_steps(n)

	print("GameManager: movimiento completado para token")

	# =====================================================
	# REVISAR CASILLA
	# =====================================================
	# IMPORTANTE:
	# Tu ficha debe tener una variable:
	# current_index
	# =====================================================

	if active_token.current_index == 3:

		await activar_casilla_3()

	is_player_moving = false

	_next_turn()


# =========================================================
# CASILLA 3
# =========================================================
func activar_casilla_3() -> void:

	print("GameManager: jugador cayó en casilla 3")

	minijuego_activo = true

	# =====================================================
	# MOSTRAR MENSAJE
	# =====================================================
	if mensaje_label:

		mensaje_label.visible = true

		mensaje_label.text = "¡Debes restaurar el mapa!"

	# =====================================================
	# CREAR PUZZLE
	# =====================================================
	var puzzle = MAP_PUZZLE.instantiate()

	# Agregar a la escena principal
	get_tree().current_scene.add_child(puzzle)

	puzzle.position = Vector2.ZERO

	# =====================================================
	# ESPERAR A QUE TERMINE
	# =====================================================
	await puzzle.puzzle_completed

	print("GameManager: puzzle completado")

	# =====================================================
	# ELIMINAR PUZZLE
	# =====================================================
	puzzle.queue_free()

	# =====================================================
	# MENSAJE FINAL
	# =====================================================
	if mensaje_label:

		mensaje_label.text = "¡Mapa restaurado!"

		await get_tree().create_timer(2.0).timeout

		mensaje_label.visible = false

	minijuego_activo = false


# =========================================================
# CAMBIAR TURNO
# =========================================================
func _next_turn() -> void:

	if tokens.is_empty():
		return

	current_player = (current_player + 1) % tokens.size()

	print(
		"GameManager: siguiente turno -> jugador",
		current_player + 1
	)

	turn_changed.emit(current_player)
