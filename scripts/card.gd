extends Node2D

const MOMENTUM := 0.75
const MAX_VELOCITY := 10.0

var velocity := Vector2.ZERO
var target_pos := Vector2.ZERO
var dragging := false
var is_on_deck := true


func setup(pos: Vector2) -> void:
	position = pos
	target_pos = pos

var card_size := Vector2.ZERO

func set_card_texture(path: String, size: Vector2) -> void:
	var tex = load(path)
	if not tex:
		return

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
