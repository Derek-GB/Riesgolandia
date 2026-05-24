extends Node2D

@onready var mapa = $Mapa
@onready var ficha = $Mapa/Ficha
@onready var dado = $Dado
@onready var dado_label: Label = $DadoLabel
@onready var btn_salir: Button = $Salir
@onready var btn_tirar_3: Button = $Tirar_3
@onready var btn_reiniciar: Button = $Reiniciar

var game_over: bool = false


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

	dado_label.text = "Tira el dado"
	
	# --- Botones ---
	btn_salir.pressed.connect(_on_salir)
	btn_tirar_3.pressed.connect(_on_tirar_3)
	btn_reiniciar.pressed.connect(_on_reiniciar)

	print("Main: _ready completo")

func _on_salir() -> void:
	get_tree().quit()


func _on_tirar_3() -> void:
	if game_over:
		return
	# Salta animación del dado y simula directamente un 3
	dado_label.text = "Tiraste un 3"
	dado.set_locked(true)
	await GameManager.on_dice_rolled(3)
	if not game_over:
		dado.set_locked(false)


func _on_reiniciar() -> void:
	# Limpia el GameManager antes de recargar
	GameManager.tokens.clear()
	GameManager.current_player = 0
	GameManager.is_player_moving = false
	GameManager.minijuego_activo = false
	get_tree().reload_current_scene()

func _on_dice_rolled(n: int) -> void:
	if game_over:
		return

	print("Dado:", n)

	dado_label.text = "Tiraste un %d" % n

	dado.set_locked(true)

	print("Main: llamando a GameManager.on_dice_rolled para mover ficha")

	await GameManager.on_dice_rolled(n)

	if not game_over:
		dado.set_locked(false)


func _on_turn_changed(player_index: int) -> void:
	print("Turno del jugador", player_index + 1)


func _on_ficha_reached_end() -> void:
	print("¡Llegaste a la meta!")

	game_over = true

	dado_label.text = "¡Meta!"

	dado.set_locked(true)
