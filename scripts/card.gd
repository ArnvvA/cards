extends Node2D

const MOMENTUM := 0.75
const MAX_VELOCITY := 10.0

var velocity := Vector2.ZERO
var target_pos := Vector2.ZERO
var dragging := false
var is_on_deck := true

#flip
var front_texture: Texture2D
var back_texture: Texture2D
var is_face_up := true
var last_flip_time := -10.0
const FLIP_COOLDOWN := 0.5

var last_click_time := 0.0
const DOUBLE_CLICK_TIME := 0.18

func set_back_texture(path: String) -> void:
	back_texture = load(path)

func flip() -> void:
	if not back_texture or not front_texture:
		return

	var card_sprite := $Sprite2D
	is_face_up = !is_face_up

	if is_face_up:
		card_sprite.texture = front_texture
	else:
		card_sprite.texture = back_texture


func handle_click() -> void:
	if dragging:
		return

	var now = Time.get_ticks_msec() / 1000.0

	# cooldown check
	if now - last_flip_time < FLIP_COOLDOWN:
		return

	if now - last_click_time <= DOUBLE_CLICK_TIME:
		flip()
		last_flip_time = now
		last_click_time = 0.0   # consume double click
	else:
		last_click_time = now


func setup(pos: Vector2) -> void:
	position = pos
	target_pos = pos

var card_size := Vector2.ZERO

func set_card_texture(path: String, size: Vector2) -> void:
	var tex = load(path)
	if not tex:
		return
	
	front_texture = tex   # ⭐ THIS IS THE IMPORTANT LINE
	var card_sprite := $Sprite2D
	var border_sprite := get_node_or_null("BorderSprite")

	card_sprite.texture = tex

	# scale card to fit clickable size
	var tex_size: Vector2 = tex.get_size()
	var scale_factor = min(size.x / tex_size.x, size.y / tex_size.y)

	card_sprite.scale = Vector2.ONE * scale_factor
	card_sprite.position = size / 2

	# make border EXACTLY match card
	if border_sprite and border_sprite.texture:
		border_sprite.scale = card_sprite.scale
		border_sprite.position = card_sprite.position
		border_sprite.z_index = 1


func move(dt: float) -> void:
	if position != target_pos or velocity != Vector2.ZERO:
		velocity.x = MOMENTUM * velocity.x + (1.0 - MOMENTUM) * (target_pos.x - position.x) * 30.0 * dt
		velocity.y = MOMENTUM * velocity.y + (1.0 - MOMENTUM) * (target_pos.y - position.y) * 30.0 * dt
		position += velocity

		var speed := velocity.length()
		if speed > MAX_VELOCITY:
			velocity = velocity * (MAX_VELOCITY / speed)

func force_face_up() -> void:
	if not is_face_up and front_texture:
		$Sprite2D.texture = front_texture
		is_face_up = true
