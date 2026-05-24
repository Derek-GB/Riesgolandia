## MapPuzzle.gd
## Minijuego: Rompecabezas de Mapa
## Godot 4.x

extends Node2D

signal puzzle_completed(moves: int)

# =========================================================
# CONFIGURACIÓN
# =========================================================
@export var map_texture: Texture2D
@export var cols: int = 4
@export var rows: int = 3
@export var piece_gap: int = 3
@export var show_numbers: bool = false

# =========================================================
# RESOLUCIÓN
# =========================================================
const SCREEN_SIZE = Vector2(1152, 648)
const MODAL_SIZE = Vector2(820, 500)

# =========================================================
# VARIABLES
# =========================================================
var piece_size: Vector2
var pieces: Array = []

var selected_index: int = -1
var moves: int = 0
var game_active: bool = false

# =========================================================
# UI
# =========================================================
var overlay: ColorRect
var modal: Panel
var board_container: Node2D

var moves_label: Label
var status_label: Label
var restart_button: Button
var close_button: Button
var title_label: Label
var instruction_label: Label
var guide_preview: TextureRect

# =========================================================
# COLORES
# =========================================================
const COLOR_PANEL = Color("#2A1F12")
const COLOR_GOLD = Color("#D4AF37")
const COLOR_GOLD_DIM = Color("#8A6E2A")
const COLOR_SELECTED = Color(1.0, 0.878, 0.251, 0.35)
const COLOR_CORRECT = Color(0.251, 1.0, 0.502, 0.2)
const COLOR_OVERLAY = Color(0, 0, 0, 0.7)

# =========================================================
# READY
# =========================================================
func _ready() -> void:

	_build_ui()

	if map_texture:
		start_game()
	else:
		status_label.text = "Asigna una textura"


# =========================================================
# START GAME
# =========================================================
func start_game() -> void:

	_clear_pieces()

	moves = 0
	selected_index = -1
	game_active = true

	overlay.visible = true

	if map_texture == null:
		push_error("No se asignó map_texture")
		return

	guide_preview.texture = map_texture

	var available_width = 700.0
	var available_height = 280.0

	piece_size = Vector2(
		available_width / cols,
		available_height / rows
	)

	_create_pieces()

	_shuffle_pieces()

	_update_ui()

	_animate_modal()


# =========================================================
# CREAR PIEZAS
# =========================================================
func _create_pieces() -> void:

	var image: Image = map_texture.get_image()

	var original_piece_size = Vector2(
		map_texture.get_width() / cols,
		map_texture.get_height() / rows
	)

	for row in rows:

		for col in cols:

			var index: int = row * cols + col

			var region := Rect2i(
				col * int(original_piece_size.x),
				row * int(original_piece_size.y),
				int(original_piece_size.x),
				int(original_piece_size.y)
			)

			var piece_image := image.get_region(region)

			var piece_tex := ImageTexture.create_from_image(piece_image)

			var sprite := Sprite2D.new()

			sprite.texture = piece_tex
			sprite.centered = false

			sprite.scale = Vector2(
				piece_size.x / original_piece_size.x,
				piece_size.y / original_piece_size.y
			)

			board_container.add_child(sprite)

			var highlight := ColorRect.new()

			highlight.size = piece_size - Vector2(piece_gap * 2, piece_gap * 2)
			highlight.color = Color.TRANSPARENT
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

			sprite.add_child(highlight)

			highlight.position = Vector2(piece_gap, piece_gap)

			if show_numbers:

				var lbl := Label.new()

				lbl.text = str(index)

				lbl.add_theme_color_override(
					"font_color",
					COLOR_GOLD
				)

				lbl.add_theme_font_size_override(
					"font_size",
					18
				)

				sprite.add_child(lbl)

				lbl.position = Vector2(10, 10)

			pieces.append({
				"sprite": sprite,
				"highlight": highlight,
				"correct_pos": index,
				"current_pos": index
			})


# =========================================================
# SHUFFLE
# =========================================================
func _shuffle_pieces() -> void:

	var positions: Array = range(cols * rows)

	positions.shuffle()

	for i in pieces.size():

		pieces[i]["current_pos"] = positions[i]

	_apply_positions()


# =========================================================
# POSICIONES
# =========================================================
func _apply_positions() -> void:

	var start_x = 40
	var start_y = 180

	for piece in pieces:

		var pos_index: int = piece["current_pos"]

		var col: int = pos_index % cols
		var row: int = pos_index / cols

		var target := Vector2(
			start_x + col * (piece_size.x + piece_gap),
			start_y + row * (piece_size.y + piece_gap)
		)

		piece["sprite"].position = target

	_refresh_highlights()


# =========================================================
# INPUT
# =========================================================
func _input(event: InputEvent) -> void:

	if not game_active:
		return

	if event is InputEventMouseButton:

		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

			var clicked_index = _get_piece_at(event.position)

			if clicked_index == -1:
				return

			if selected_index == -1:

				selected_index = clicked_index

			elif selected_index == clicked_index:

				selected_index = -1

			else:

				_swap_pieces(selected_index, clicked_index)

				selected_index = -1

				moves += 1

				_update_ui()

				_check_win()

			_refresh_highlights()


# =========================================================
# DETECTAR PIEZA
# =========================================================
func _get_piece_at(pos: Vector2) -> int:

	for i in pieces.size():

		var p = pieces[i]

		var p_pos = p["sprite"].global_position

		var rect = Rect2(
			p_pos,
			piece_size
		)

		if rect.has_point(pos):
			return i

	return -1


# =========================================================
# SWAP
# =========================================================
func _swap_pieces(a: int, b: int) -> void:

	var temp_pos = pieces[a]["current_pos"]

	pieces[a]["current_pos"] = pieces[b]["current_pos"]

	pieces[b]["current_pos"] = temp_pos

	_apply_positions()


# =========================================================
# HIGHLIGHTS
# =========================================================
func _refresh_highlights() -> void:

	for i in pieces.size():

		var p = pieces[i]

		var highlight = p["highlight"]

		var is_sel = (i == selected_index)

		var is_ok = (p["current_pos"] == p["correct_pos"])

		if is_sel:

			highlight.color = COLOR_SELECTED

		elif is_ok:

			highlight.color = COLOR_CORRECT

		else:

			highlight.color = Color.TRANSPARENT


# =========================================================
# WIN
# =========================================================
func _check_win() -> void:

	for piece in pieces:

		if piece["current_pos"] != piece["correct_pos"]:
			return

	game_active = false

	_show_win_overlay()

	emit_signal("puzzle_completed", moves)


# =========================================================
# WIN UI
# =========================================================
func _show_win_overlay() -> void:

	game_active = false

	# ============================================
	# PANEL VICTORIA
	# ============================================
	var win_panel := Panel.new()

	win_panel.size = Vector2(520, 150)

	win_panel.position = Vector2(
		(MODAL_SIZE.x - win_panel.size.x) / 2,
		(MODAL_SIZE.y - win_panel.size.y) / 2 + 70
	)

	var style := StyleBoxFlat.new()

	style.bg_color = Color("#1E160C")

	style.border_color = COLOR_GOLD

	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3

	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16

	win_panel.add_theme_stylebox_override("panel", style)

	modal.add_child(win_panel)

	win_panel.move_to_front()

	# ============================================
	# TITULO
	# ============================================
	var title := Label.new()

	title.text = "¡MAPA CONSEGUIDO!"

	title.position = Vector2(90, 18)

	title.size = Vector2(340, 40)

	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title.add_theme_font_size_override(
		"font_size",
		28
	)

	title.add_theme_color_override(
		"font_color",
		COLOR_GOLD
	)

	win_panel.add_child(title)

	# ============================================
	# MENSAJE
	# ============================================
	var description := Label.new()

	description.text = "¡Excelente trabajo!\nAhora conoces mejor las zonas de riesgo de tu escuela."

	description.position = Vector2(35, 60)

	description.size = Vector2(450, 55)

	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	description.add_theme_font_size_override(
		"font_size",
		18
	)

	description.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	win_panel.add_child(description)

	# ============================================
	# MOVIMIENTOS
	# ============================================
	var moves_label_finish := Label.new()

	moves_label_finish.text = "Completado en %d movimientos" % moves

	moves_label_finish.position = Vector2(120, 118)

	moves_label_finish.size = Vector2(280, 30)

	moves_label_finish.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	moves_label_finish.add_theme_font_size_override(
		"font_size",
		16
	)

	moves_label_finish.add_theme_color_override(
		"font_color",
		COLOR_GOLD
	)

	win_panel.add_child(moves_label_finish)

	# ============================================
	# ANIMACIÓN
	# ============================================
	win_panel.scale = Vector2(0.7, 0.7)

	var tween := create_tween()

	tween.tween_property(
		win_panel,
		"scale",
		Vector2.ONE,
		0.2
	)

	# ============================================
	# STATUS
	# ============================================
	status_label.text = "Mapa restaurado correctamente"

	status_label.add_theme_color_override(
		"font_color",
		COLOR_GOLD
	)


# =========================================================
# UI
# =========================================================
func _build_ui() -> void:

	# =====================================================
	# OVERLAY
	# =====================================================
	overlay = ColorRect.new()

	overlay.color = COLOR_OVERLAY
	overlay.size = SCREEN_SIZE

	add_child(overlay)

	# =====================================================
	# MODAL
	# =====================================================
	modal = Panel.new()

	modal.size = MODAL_SIZE
	modal.position = (SCREEN_SIZE - MODAL_SIZE) / 2

	add_child(modal)

	# =====================================================
	# ESTILO
	# =====================================================
	var style := StyleBoxFlat.new()

	style.bg_color = COLOR_PANEL

	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18

	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3

	style.border_color = COLOR_GOLD

	modal.add_theme_stylebox_override(
		"panel",
		style
	)

	# =====================================================
	# CONTENEDOR TABLERO
	# =====================================================
	board_container = Node2D.new()

	modal.add_child(board_container)

	# =====================================================
	# TITULO
	# =====================================================
	title_label = Label.new()

	title_label.text = "ROMPECABEZAS DEL MAPA"

	title_label.position = Vector2(220, 15)

	title_label.add_theme_font_size_override(
		"font_size",
		24
	)

	title_label.add_theme_color_override(
		"font_color",
		COLOR_GOLD
	)

	modal.add_child(title_label)

	# =====================================================
	# TEXTO EDUCATIVO
	# =====================================================
	instruction_label = Label.new()

	instruction_label.text = "Participaste en la elaboración del mapa de riesgo escolar."

	instruction_label.position = Vector2(30, 55)

	instruction_label.size = Vector2(400, 70)

	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	instruction_label.add_theme_font_size_override(
		"font_size",
		18
	)

	instruction_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	modal.add_child(instruction_label)

	# =====================================================
	# BORDE PREVIEW
	# =====================================================
	var preview_border := Panel.new()

	preview_border.position = Vector2(630, 50)

	preview_border.size = Vector2(160, 110)

	var preview_style := StyleBoxFlat.new()

	preview_style.bg_color = Color(0, 0, 0, 0.2)

	preview_style.border_width_left = 2
	preview_style.border_width_top = 2
	preview_style.border_width_right = 2
	preview_style.border_width_bottom = 2

	preview_style.border_color = COLOR_GOLD

	preview_style.corner_radius_top_left = 8
	preview_style.corner_radius_top_right = 8
	preview_style.corner_radius_bottom_left = 8
	preview_style.corner_radius_bottom_right = 8

	preview_border.add_theme_stylebox_override(
		"panel",
		preview_style
	)

	modal.add_child(preview_border)

	# =====================================================
	# IMAGEN GUÍA
	# =====================================================
	guide_preview = TextureRect.new()

	guide_preview.position = Vector2(635, 55)

	guide_preview.size = Vector2(150, 100)

	guide_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	guide_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	modal.add_child(guide_preview)

	guide_preview.move_to_front()

	# =====================================================
	# MOVIMIENTOS
	# =====================================================
	moves_label = Label.new()

	moves_label.position = Vector2(30, 135)

	moves_label.add_theme_font_size_override(
		"font_size",
		18
	)

	moves_label.add_theme_color_override(
		"font_color",
		COLOR_GOLD
	)

	modal.add_child(moves_label)

	# =====================================================
	# STATUS
	# =====================================================
	status_label = Label.new()

	status_label.position = Vector2(250, 135)

	status_label.text = "Intercambia piezas"

	status_label.add_theme_font_size_override(
		"font_size",
		16
	)

	status_label.add_theme_color_override(
		"font_color",
		COLOR_GOLD_DIM
	)

	modal.add_child(status_label)

	# =====================================================
	# RESTART
	# =====================================================
	restart_button = Button.new()

	restart_button.text = "Reiniciar"

	restart_button.position = Vector2(520, 125)

	restart_button.size = Vector2(120, 40)

	restart_button.pressed.connect(_on_restart_pressed)

	modal.add_child(restart_button)

	# =====================================================
	# CLOSE
	# =====================================================
	close_button = Button.new()

	close_button.text = "X"

	close_button.position = Vector2(760, 10)

	close_button.size = Vector2(40, 40)

	close_button.pressed.connect(queue_free)

	modal.add_child(close_button)


# =========================================================
# ANIMACIÓN
# =========================================================
func _animate_modal() -> void:

	modal.scale = Vector2(0.8, 0.8)

	var tween = create_tween()

	tween.tween_property(
		modal,
		"scale",
		Vector2.ONE,
		0.2
	)


# =========================================================
# UPDATE UI
# =========================================================
func _update_ui() -> void:

	if moves_label:

		moves_label.text = "Movimientos: %d" % moves


# =========================================================
# CLEAR
# =========================================================
func _clear_pieces() -> void:

	for piece in pieces:

		piece["sprite"].queue_free()

	pieces.clear()


# =========================================================
# RESTART
# =========================================================
func _on_restart_pressed() -> void:

	if map_texture:

		start_game()
