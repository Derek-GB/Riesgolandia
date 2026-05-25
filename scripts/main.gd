extends Node3D

@export var camera_smooth_speed: float = 5.0

@onready var mapa = $Mapa
@onready var ficha = $Mapa/Ficha
@onready var camera: Camera3D = $Camera3D
@onready var dado = $UI/Dado
@onready var dado_label: Label = $UI/DadoLabel
@onready var btn_salir: Button = $UI/Salir
@onready var btn_tirar_3: Button = $UI/Tirar_3
@onready var btn_reiniciar: Button = $UI/Reiniciar

@onready var dice_sound: AudioStreamPlayer = $UI/DiceSound
@onready var move_sound: AudioStreamPlayer = $UI/MoveSound

var game_over: bool = false
var camera_offset: Vector3 = Vector3.ZERO

func _ready() -> void:
	var wp: Array[Vector3] = mapa.get_waypoints()
	print("Main: waypoints cargados =", wp.size())
	ficha.setup(wp)
	GameManager.register_token(ficha)
	print("Main: ficha registrada en GameManager")
	dado.dice_rolled.connect(_on_dice_rolled)
	print("Main: conectado dado a _on_dice_rolled")
	ficha.reached_end.connect(_on_ficha_reached_end)
	GameManager.turn_changed.connect(_on_turn_changed)
	ficha.stepped_on.connect(_on_ficha_stepped)
	dado_label.text = "Tira el dado"
	btn_salir.pressed.connect(_on_salir)
	btn_tirar_3.pressed.connect(_on_tirar_3)
	btn_reiniciar.pressed.connect(_on_reiniciar)
	camera_offset = camera.global_position - ficha.global_position
	print("Main: _ready completo")

func _process(delta: float) -> void:
	if not ficha or not camera:
		return
	var target: Vector3 = ficha.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(
		target,
		clamp(delta * camera_smooth_speed, 0.0, 1.0)
	)

func _on_ficha_stepped(_index: int) -> void:
	move_sound.play()

func _on_salir() -> void:
	get_tree().quit()

# =====================================================
# BOTÓN TIRAR 3
# =====================================================
func _on_tirar_3() -> void:
	if game_over:
		return
	dice_sound.play()
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
	dice_sound.play()
	await get_tree().create_timer(0.15).timeout
	print("Dado:", n)
	dado_label.text = "Tiraste un %d" % n
	dado.set_locked(true)
	await GameManager.on_dice_rolled(n)
	if not game_over:
		dado.set_locked(false)

# =====================================================
# CAMBIO DE TURNO
# =====================================================
func _on_turn_changed(player_index: int) -> void:
	print("Turno del jugador", player_index + 1)
	if not game_over:
		dado.set_locked(false)
		dado_label.text = "Tira el dado"

# =====================================================
# META
# =====================================================
func _on_ficha_reached_end() -> void:
	print("¡Llegaste a la meta!")
	game_over = true
	dado_label.text = "¡Meta!"
	dado.set_locked(true)
