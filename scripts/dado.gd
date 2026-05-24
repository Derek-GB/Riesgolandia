extends CanvasLayer

@onready var dice_mesh: Node3D = $DiceContainer/SubViewportContainer/SubViewport/MeshDado
@onready var btn = $DiceContainer/ClickArea

var is_rolling: bool = false
var is_locked: bool = false

const FACE_ROTATIONS: Dictionary = {
	1: Vector3(0,    0,   0),
	2: Vector3(0,   -90,  0),
	3: Vector3(-90,  0,   0),
	4: Vector3(90,   0,   0),
	5: Vector3(0,    90,  0),
	6: Vector3(180,  0,   0),
}

signal dice_rolled(n: int)


func _ready() -> void:
	randomize()

	btn.pressed.connect(_on_roll_pressed)

	# Posición inicial: debería verse la cara 1
	dice_mesh.rotation_degrees = FACE_ROTATIONS[1]

	_update_button_state()


func set_locked(value: bool) -> void:
	is_locked = value
	_update_button_state()


func _update_button_state() -> void:
	btn.disabled = is_rolling or is_locked


func _on_roll_pressed() -> void:
	if is_rolling or is_locked:
		return

	is_rolling = true
	_update_button_state()

	var result: int = randi() % 6 + 1

	await _animate_roll(result)

	print("Dado emitido:", result)
	dice_rolled.emit(result)

	is_rolling = false
	_update_button_state()


func _animate_roll(face: int) -> void:
	var tween := create_tween()

	tween.tween_property(
		dice_mesh,
		"rotation_degrees",
		Vector3(
			randf_range(360, 720),
			randf_range(360, 720),
			randf_range(360, 720)
		),
		0.6
	).set_ease(Tween.EASE_IN)

	tween.tween_property(
		dice_mesh,
		"rotation_degrees",
		FACE_ROTATIONS[face],
		0.4
	).set_ease(Tween.EASE_OUT)

	await tween.finished
