extends Node2D

@onready var mapa = $Mapa
@onready var ficha = $Mapa/Ficha
@onready var dado = $Dado
@onready var dado_label: Label = $DadoLabel
@onready var btn_salir: Button = $Salir
@onready var btn_tirar_3: Button = $Tirar_3
@onready var btn_reiniciar: Button = $Reiniciar

# =====================================================
# SONIDOS
# =====================================================
@onready var dice_sound: AudioStreamPlayer = $DiceSound
@onready var move_sound: AudioStreamPlayer = $MoveSound

var game_over: bool = false


# =====================================================
# READY
# =====================================================
func _ready() -> void:

	var wp: Array[Vector2] = mapa.get_waypoints()

	print("Main: waypoints cargados =", wp.size())

	ficha.setup(wp)

	GameManager.register_token(ficha)

	print("Main: ficha registrada en GameManager")

	dado.dice_rolled.connect(_on_dice_rolled)

	print("Main: conectado dado a _on_dice_rolled")

	ficha.reached_end.connect(_on_ficha_reached_end)

	GameManager.turn_changed.connect(_on_turn_changed)

	# =====================================================
	# SONIDO POR CADA PASO
	# =====================================================
	ficha.stepped_on.connect(_on_ficha_stepped)

	dado_label.text = "Tira el dado"

	# =====================================================
	# BOTONES
	# =====================================================
	btn_salir.pressed.connect(_on_salir)
	btn_tirar_3.pressed.connect(_on_tirar_3)
	btn_reiniciar.pressed.connect(_on_reiniciar)

	print("Main: _ready completo")


# =====================================================
# SONIDO PASO
# =====================================================
func _on_ficha_stepped(_index: int) -> void:

	move_sound.play()


# =====================================================
# SALIR
# =====================================================
func _on_salir() -> void:

	get_tree().quit()


# =====================================================
# BOTÓN TIRAR 3
# =====================================================
func _on_tirar_3() -> void:

	if game_over:
		return

	# =====================================================
	# SONIDO DEL DADO
	# =====================================================
	dice_sound.play()

	# Pequeña espera para que se escuche primero
	await get_tree().create_timer(0.15).timeout

	dado_label.text = "Tiraste un 3"

	dado.set_locked(true)

	await GameManager.on_dice_rolled(3)

	if not game_over:
		dado.set_locked(false)


# =====================================================
# REINICIAR
# =====================================================
func _on_reiniciar() -> void:

	GameManager.tokens.clear()
	GameManager.current_player = 0
	GameManager.is_player_moving = false
	GameManager.minijuego_activo = false

	get_tree().reload_current_scene()


# =====================================================
# DADO
# =====================================================
func _on_dice_rolled(n: int) -> void:

	if game_over:
		return

	# =====================================================
	# SONIDO DEL DADO
	# =====================================================
	dice_sound.play()

	# Espera pequeña antes de animar
	await get_tree().create_timer(0.15).timeout

	print("Dado:", n)

	dado_label.text = "Tiraste un %d" % n

	dado.set_locked(true)

	print("Main: llamando a GameManager.on_dice_rolled para mover ficha")

	await GameManager.on_dice_rolled(n)

	if not game_over:
		dado.set_locked(false)


# =====================================================
# CAMBIO DE TURNO
# =====================================================
func _on_turn_changed(player_index: int) -> void:

	print("Turno del jugador", player_index + 1)


# =====================================================
# META
# =====================================================
func _on_ficha_reached_end() -> void:

	print("¡Llegaste a la meta!")

	game_over = true

	dado_label.text = "¡Meta!"

	dado.set_locked(true)
