extends CanvasLayer

var questions = [
	{
		"question": "¿Pierde la niñez sus derechos en medio de un desastre?",
		"options": ["Sí", "No"],
		"correct": 1,
		"explanation": "La niñez nunca pierde sus derechos."
	},
	{
		"question": "¿Cuál derecho suele verse más afectado?",
		"options": ["Educación", "Alimentación", "Opinión", "Recreación"],
		"correct": 0,
		"explanation": "Las escuelas pueden dejar de funcionar."
	},
	{
		"question": "¿En qué desastre la niñez pierde derechos?",
		"options": ["Inundación", "Incendio", "Sequía", "En ninguno"],
		"correct": 3,
		"explanation": "Los derechos siempre deben respetarse."
	}
]

var selected_question = {}
var card_container: Control
var front_side: Control
var back_panel: Control

# Tamaño fijo de la carta
const CARD_W = 350.0
const CARD_H = 500.0

func _ready():
	randomize()
	_pick_question()
	_build_ui()
	_animate_card()

# =========================================================
# UNA SOLA PREGUNTA AL AZAR
# =========================================================
func _pick_question():
	var index = randi() % questions.size()
	selected_question = questions[index]

# =========================================================
# UI
# =========================================================
func _build_ui():
	# FONDO OSCURO COMPLETO
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# CARTA — centrada con anchors
	card_container = Control.new()
	card_container.set_anchors_preset(Control.PRESET_CENTER)
	card_container.size = Vector2(CARD_W, CARD_H)
	card_container.position = Vector2(-CARD_W / 2.0, -CARD_H / 2.0)
	card_container.pivot_offset = Vector2(CARD_W / 2.0, CARD_H / 2.0)
	add_child(card_container)

	# =========================================================
	# FRENTE — fondo verde + imagen centrada encima
	# =========================================================
	front_side = Panel.new()
	front_side.size = Vector2(CARD_W, CARD_H)
	front_side.position = Vector2(0, 0)
	card_container.add_child(front_side)

	var front_style = StyleBoxFlat.new()
	front_style.bg_color = Color("#4a5f7a")
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

	# Imagen centrada dentro del fondo
	var img = TextureRect.new()
	img.texture = load("res://images/card_back.png")
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size = Vector2(CARD_W, CARD_H)
	img.position = Vector2(0, 0)
	front_side.add_child(img)

	var front_info = Label.new()
	front_info.text = "Presiona para girar"
	front_info.position = Vector2(60, 460)
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
	# REVERSO — mismo tamaño, fondo crema
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

	_build_question()

# =========================================================
# PREGUNTA EN EL REVERSO
# =========================================================
func _build_question():
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(310, 460)
	back_panel.add_child(vbox)

	var question = Label.new()
	question.text = selected_question["question"]
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.custom_minimum_size = Vector2(310, 80)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.add_theme_font_size_override("font_size", 20)
	question.add_theme_color_override("font_color", Color("#3B1F00"))
	vbox.add_child(question)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	for i in range(selected_question["options"].size()):
		var btn = Button.new()
		btn.text = selected_question["options"][i]
		btn.custom_minimum_size = Vector2(310, 55)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_option_selected.bind(i))
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
# RESPUESTA
# =========================================================
func _on_option_selected(option_index):
	var popup = AcceptDialog.new()
	if option_index == selected_question["correct"]:
		popup.title = "¡Correcto! ✅"
	else:
		popup.title = "Incorrecto ❌"
	popup.dialog_text = selected_question["explanation"]
	add_child(popup)
	popup.popup_centered()

	await popup.confirmed

	queue_free()
