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
	card_size = size

	var tex = load(path)
	if tex:
		var sprite := $Sprite2D
		sprite.texture = tex

		var tex_size: Vector2 = tex.get_size()
		sprite.scale = Vector2(
			card_size.x / tex_size.x,
			card_size.y / tex_size.y
		)

func move(dt: float) -> void:
	if position != target_pos or velocity != Vector2.ZERO:
		velocity.x = MOMENTUM * velocity.x + (1.0 - MOMENTUM) * (target_pos.x - position.x) * 30.0 * dt
		velocity.y = MOMENTUM * velocity.y + (1.0 - MOMENTUM) * (target_pos.y - position.y) * 30.0 * dt
		position += velocity

		var speed := velocity.length()
		if speed > MAX_VELOCITY:
			velocity = velocity * (MAX_VELOCITY / speed)
