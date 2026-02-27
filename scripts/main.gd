extends Node2D

const CARD_WIDTH  := 126
const CARD_HEIGHT := 176

# Deck origin: viewport_centre minus half card dimensions (1920x1080)
var deck_pos         := Vector2(960 - 63, 540 - 88)
var deck_rect        : Rect2
var return_btn_center: Vector2
const RETURN_BTN_RADIUS := 15.0

var all_cards  : Array = []
var deck_cards : Array = []
var sound_queue: Array = []  # Array of {delay:float, pitch:float}

var card_scene  : PackedScene
var card_sound  : AudioStream
var crt_material: ShaderMaterial
var elapsed     := 0.0

var back_path = "res://assets/card_back.webp"


#func _ready() -> void:
	#card_scene = preload("res://scenes/card.tscn")
	#card_sound = preload("res://assets/card.ogg")
#
	#deck_rect         = Rect2(deck_pos, Vector2(CARD_WIDTH, CARD_HEIGHT))
	#return_btn_center = Vector2(deck_pos.x + CARD_WIDTH / 2.0, deck_pos.y + CARD_HEIGHT + 50.0)
#
	## CRT setup
	#var overlay := $CRTLayer/CRTOverlay
	#if overlay.material is ShaderMaterial:
		#crt_material = overlay.material as ShaderMaterial
		#crt_material.set_shader_parameter("resolution", Vector2(1920.0, 1080.0))

func _ready() -> void:
	card_scene = preload("res://scenes/card.tscn")
	card_sound = preload("res://assets/card.ogg")

	deck_rect         = Rect2(deck_pos, Vector2(CARD_WIDTH, CARD_HEIGHT))
	return_btn_center = Vector2(deck_pos.x + CARD_WIDTH / 2.0, deck_pos.y + CARD_HEIGHT + 50.0)

	# CRT setup
	var overlay := $CRTLayer/CRTOverlay
	if overlay.material is ShaderMaterial:
		crt_material = overlay.material as ShaderMaterial
		crt_material.set_shader_parameter("resolution", Vector2(1920.0, 1080.0))

	# 👉 DECK SPAWN
	var deck_paths = _load_deck()
	var back_path = "res://assets/card_back.webp"   # ⭐ ADD THIS

	for path in deck_paths:
		var card = card_scene.instantiate()
		add_child(card)
		card.setup(deck_pos)

		card.set_card_texture(path, Vector2(CARD_WIDTH, CARD_HEIGHT))
		card.set_back_texture(back_path)            # ⭐ ADD THIS

		all_cards.append(card)
		deck_cards.append(card)


func _load_deck() -> Array:
	var deck := []
	var base_path := "res://assets/cards/"

	var suits = DirAccess.get_directories_at(base_path)

	for suit in suits:
		var suit_path = base_path + suit + "/"
		var files = DirAccess.get_files_at(suit_path)

		for file in files:
			if file.get_extension().to_lower() == "webp":
				deck.append(suit_path + file)

	deck.shuffle()
	return deck

func _align() -> void:
	var offset := Vector2(-0.25, 0.25) 

	for i in deck_cards.size():
		var card = deck_cards[i]
		if not card.dragging:
			card.target_pos = deck_pos + offset * i

func _process(dt: float) -> void:
	elapsed += dt

	var mouse_pos := get_viewport().get_mouse_position()

	for card in all_cards:
		if card.dragging:
			card.target_pos = mouse_pos - Vector2(CARD_WIDTH / 2.0, CARD_HEIGHT / 2.0)
		card.move(dt)

	_align()

	# Z-order: deck bottom → off-deck → dragging card always on very top
	for i in deck_cards.size():
		deck_cards[i].z_index = i
	var off_z := deck_cards.size()
	for card in all_cards:
		if not card.is_on_deck and not card.dragging:
			card.z_index = off_z
			off_z += 1
	for card in all_cards:
		if card.dragging:
			card.z_index = off_z

	# Drain sound queue
	var i := 0
	while i < sound_queue.size():
		sound_queue[i]["delay"] -= dt
		if sound_queue[i]["delay"] <= 0.0:
			_play_sound(sound_queue[i]["pitch"])
			sound_queue.remove_at(i)
		else:
			i += 1

	queue_redraw()

	if crt_material:
		crt_material.set_shader_parameter("millis", elapsed)


# Draw background fill then the return button.
# Both run before children (cards) are composited, so cards appear on top.
# The CRTLayer (layer 10) then captures everything via hint_screen_texture.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0)), Color(0.937, 0.945, 0.96, 1.0))
	draw_circle(return_btn_center, RETURN_BTN_RADIUS, Color(0.015, 0.647, 0.898))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release()

func _on_press(pos: Vector2) -> void:
	var sorted := all_cards.duplicate()
	sorted.sort_custom(func(a, b): return a.z_index > b.z_index)

	# --- CARD CLICK ---
	for card in sorted:
		if Rect2(card.position, Vector2(CARD_WIDTH, CARD_HEIGHT)).has_point(pos):
			card.handle_click()
			card.dragging = true
			return

	# --- RETURN BUTTON ---
	if pos.distance_to(return_btn_center) <= RETURN_BTN_RADIUS:
		var count := 1
		for card in all_cards:
			if not card.is_on_deck:
				card.is_on_deck = true
				deck_cards.append(card)

				card.force_face_up()   # ⭐ THIS is where it belongs

				sound_queue.append({
					"delay": count * 0.05,
					"pitch": 1.0 + count * 0.2
				})
				count += 1

	# Return button — recall all off-deck cards with staggered ascending chime
	if pos.distance_to(return_btn_center) <= RETURN_BTN_RADIUS:
		var count := 1
		for card in all_cards:
			if not card.is_on_deck:
				card.is_on_deck = true
				deck_cards.append(card)
				sound_queue.append({"delay": count * 0.05, "pitch": 1.0 + count * 0.2})
				count += 1

# On release: decide deck membership based on where the card landed.
func _on_release() -> void:
	for card in all_cards:
		if card.dragging:
			card.dragging = false
			_play_sound(1.0)

			var center: Vector2 = card.position + Vector2(CARD_WIDTH / 2.0, CARD_HEIGHT / 2.0)
			if deck_rect.has_point(center):
				# Dropped onto deck → join (or stay in) the deck
				card.is_on_deck = true
				if not deck_cards.has(card):
					deck_cards.append(card)

				card.force_face_up()   # ⭐ ADD THIS LINE HERE

			else:
				# Dropped off deck → leave (or stay off) the deck
				card.is_on_deck = false
				deck_cards.erase(card)
			break


func _play_sound(pitch: float) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = card_sound
	player.pitch_scale = pitch
	player.play()
	player.finished.connect(player.queue_free)
