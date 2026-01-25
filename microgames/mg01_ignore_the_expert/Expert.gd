extends Node

const IGNORE_X_SIZE := 96
const IGNORE_X_THICKNESS := 6
const IGNORE_X_COLOR := Color(0.86, 0.0, 0.0, 1.0)

var ignore_overlay: CanvasItem = null
var ignore_x: Node = null
var _overlay_tween: Tween = null
var _overlay_base_scale := Vector2.ONE


func _ready() -> void:
	ignore_overlay = get_node_or_null("IgnoreOverlay") as CanvasItem
	if ignore_overlay:
		ignore_overlay.visible = false
		ignore_x = ignore_overlay.get_node_or_null("X")
		if ignore_x:
			var tex := _build_ignore_x_texture()
			_assign_texture(ignore_x, tex)
			if ignore_x is CanvasItem:
				_overlay_base_scale = (ignore_x as CanvasItem).scale
		elif ignore_overlay:
			_overlay_base_scale = ignore_overlay.scale


func show_ignore_overlay(animated := true) -> void:
	if not ignore_overlay:
		return
	ignore_overlay.visible = true
	var target: CanvasItem = ignore_overlay
	if ignore_x and ignore_x is CanvasItem:
		target = ignore_x
	if _overlay_tween:
		_overlay_tween.kill()
		_overlay_tween = null
	target.scale = _overlay_base_scale * 0.8
	if animated:
		_overlay_tween = create_tween()
		_overlay_tween.tween_property(target, "scale", _overlay_base_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		target.scale = _overlay_base_scale


func hide_ignore_overlay() -> void:
	if _overlay_tween:
		_overlay_tween.kill()
		_overlay_tween = null
	if ignore_overlay:
		ignore_overlay.visible = false


func _assign_texture(node: Node, texture: Texture2D) -> void:
	if not texture:
		return
	if node is Sprite2D:
		(node as Sprite2D).texture = texture
	elif node is TextureRect:
		(node as TextureRect).texture = texture


func _build_ignore_x_texture() -> Texture2D:
	var image := Image.create(IGNORE_X_SIZE, IGNORE_X_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var last := IGNORE_X_SIZE - 1
	for y in range(IGNORE_X_SIZE):
		for x in range(IGNORE_X_SIZE):
			if absf(float(x - y)) <= IGNORE_X_THICKNESS or absf(float((last - x) - y)) <= IGNORE_X_THICKNESS:
				image.set_pixel(x, y, IGNORE_X_COLOR)
	var png_buffer := image.save_png_to_buffer()
	var png_image := Image.new()
	if png_image.load_png_from_buffer(png_buffer) == OK:
		return ImageTexture.create_from_image(png_image)
	return ImageTexture.create_from_image(image)
