extends CanvasLayer

const CARD_W = 350.0
const CARD_H = 500.0

signal action_completed

var cards = [
	{
		"text": "Se avecina un evento y el plan de seguridad escolar no contempló el uso de la escuela como albergue.",
		"action": "Pierdes 1 turno.",
		"type": "skip_turn"
	},
	{
		"text": "Tu escuela aún no ha construido rampas de acceso, aumentando la vulnerabilidad de las personas con discapacidad y mayores.",
		"action": "Retrocede 1 casilla.",
		"type": "go_back"
	},
	{
		"text": "La alcaldía ha decidido autorizar la reconstrucción de la escuela en una zona de inundación.",
		"action": "Retrocede 1 casilla y alerta que la escuela estará en un lugar inseguro.",
		"type": "go_back"
	}
]

var selected_card = {}
var card_container: Control
var front_side: Control
var back_panel: Control

func _ready():
	randomize()
	_pick_card()
	_build_ui()
	_animate_card()

# =========================================================
# UNA SOLA CARTA AL AZAR
# =========================================================
func _pick_card():
	var index = randi() % cards.size()
	selected_card = cards[index]
	print("Carta seleccionada:", selected_card["action"])

# =========================================================
# UI
# =========================================================
func _build_ui():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	card_container = Control.new()
	card_container.set_anchors_preset(Control.PRESET_CENTER)
	card_container.size = Vector2(CARD_W, CARD_H)
	card_container.position = Vector2(-CARD_W / 2.0, -CARD_H / 2.0)
	card_container.pivot_offset = Vector2(CARD_W / 2.0, CARD_H / 2.0)
	add_child(card_container)

	# =========================================================
	# FRENTE — IMAGEN card_action.png
	# =========================================================
	front_side = Panel.new()
	front_side.size = Vector2(CARD_W, CARD_H)
	front_side.position = Vector2(0, 0)
	card_container.add_child(front_side)

	var front_style = StyleBoxFlat.new()
	front_style.bg_color = Color("#D32F2F")
	front_style.corner_radius_top_left = 20
	front_style.corner_radius_top_right = 20
	front_style.corner_radius_bottom_left = 20
	front_style.corner_radius_bottom_right = 20
	front_style.border_width_left = 4
	front_style.border_width_top = 4
	front_style.border_width_right = 4
	front_style.border_width_bottom = 4
	front_style.border_color = Color("#FFD700")
	front_side.add_theme_stylebox_override("panel", front_style)

	var img = TextureRect.new()
	img.texture = load("res://images/card_action.png")
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size = Vector2(CARD_W, CARD_H)
	img.position = Vector2(0, 0)
	front_side.add_child(img)

	var front_info = Label.new()
	front_info.text = "Presiona para ver tu acción"
	front_info.position = Vector2(40, 460)
	front_info.add_theme_font_size_override("font_size", 18)
	front_info.add_theme_color_override("font_color", Color.YELLOW)
	front_side.add_child(front_info)

	var click_btn = Button.new()
	click_btn.flat = true
	click_btn.size = Vector2(CARD_W, CARD_H)
	click_btn.position = Vector2(0, 0)
	click_btn.pressed.connect(_flip_card)
	front_side.add_child(click_btn)

	# =========================================================
	# REVERSO — ACCIÓN
	# =========================================================
	back_panel = Panel.new()
	back_panel.visible = false
	back_panel.size = Vector2(CARD_W, CARD_H)
	back_panel.position = Vector2(0, 0)
	card_container.add_child(back_panel)

	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color("#F4E7C5")
	back_style.corner_radius_top_left = 20
	back_style.corner_radius_top_right = 20
	back_style.corner_radius_bottom_left = 20
	back_style.corner_radius_bottom_right = 20
	back_style.border_width_left = 4
	back_style.border_width_top = 4
	back_style.border_width_right = 4
	back_style.border_width_bottom = 4
	back_style.border_color = Color("#7A4E1D")
	back_panel.add_theme_stylebox_override("panel", back_style)

	_build_card_content()

# =========================================================
# CONTENIDO DEL REVERSO
# =========================================================
func _build_card_content():
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 30)
	vbox.size = Vector2(310, 440)
	vbox.add_theme_constant_override("separation", 20)
	back_panel.add_child(vbox)

	var text_label = Label.new()
	text_label.text = selected_card["text"]
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(310, 200)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.add_theme_color_override("font_color", Color("#3B1F00"))
	vbox.add_child(text_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var action_label = Label.new()
	action_label.text = selected_card["action"]
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.add_theme_font_size_override("font_size", 22)
	action_label.add_theme_color_override("font_color", Color("#8B0000"))
	vbox.add_child(action_label)

	var btn = Button.new()
	btn.text = "Aceptar"
	btn.custom_minimum_size = Vector2(310, 55)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(_on_accepted)
	vbox.add_child(btn)

# =========================================================
# ANIMACIÓN ENTRADA
# =========================================================
func _animate_card():
	card_container.scale = Vector2(0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(card_container, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

# =========================================================
# GIRAR CARTA
# =========================================================
func _flip_card():
	var tween1 = create_tween()
	tween1.tween_property(card_container, "scale:x", 0.0, 0.18)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	await tween1.finished

	front_side.visible = false
	back_panel.visible = true

	var tween2 = create_tween()
	tween2.tween_property(card_container, "scale:x", 1.0, 0.18)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	await tween2.finished

# =========================================================
# ACEPTAR ACCIÓN
# =========================================================
func _on_accepted():
	action_completed.emit(selected_card["type"])
	queue_free()
