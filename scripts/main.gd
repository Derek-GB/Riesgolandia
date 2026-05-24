extends Node2D

@onready var mapa = $Mapa
@onready var ficha = $Mapa/Ficha
@onready var dado = $Dado
@onready var dado_label: Label = $DadoLabel

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

	print("Main: _ready completo")


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
