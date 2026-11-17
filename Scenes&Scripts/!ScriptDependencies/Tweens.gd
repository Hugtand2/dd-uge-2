extends Node

func wobble(node: Control) -> void:
	# Stop gamle tweens, og gendan udgangspunktet
	_kill(node, "_rot_tween")
	_kill(node, "_size_tween")

	if not node.has_meta("_base_scale"):
		node.set_meta("_base_scale", node.scale)   # gemmes kun første gang
	var base: Vector2 = node.get_meta("_base_scale")

	node.scale = base
	node.rotation_degrees = 0.0
	node.pivot_offset = node.size / 2.0

	var rot := rotation_wobble(node)
	var siz := size_wobble(node, base)
	node.set_meta("_rot_tween", rot)
	node.set_meta("_size_tween", siz)

	await rot.finished
	await siz.finished

func _kill(node: Control, key: String) -> void:
	if node.has_meta(key):
		var t: Tween = node.get_meta(key)
		if t and t.is_valid():
			t.kill()

func rotation_wobble(node: CanvasItem) -> Tween:
	node.pivot_offset = node.size / 2.0
	var tween = create_tween()
	# Tilt right quickly
	tween.tween_property(node, "rotation_degrees", 15.0, 0.06).set_ease(Tween.EASE_OUT)
	# Swing past center to the left
	tween.tween_property(node, "rotation_degrees", -12.0, 0.08).set_ease(Tween.EASE_IN_OUT)
	# Spring back to upright using elastic physics
	tween.tween_property(node, "rotation_degrees", 0.0, 0.45)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)
	return tween

func size_wobble(node: CanvasItem, base_scale := Vector2.ONE) -> Tween:
	node.pivot_offset = node.size / 2.0
	var tween := create_tween()
	# Pop hurtigt større
	tween.tween_property(node, "scale", base_scale * 1.25, 0.08).set_ease(Tween.EASE_OUT)
	# Lidt under normal størrelse
	tween.tween_property(node, "scale", base_scale * 0.9, 0.08).set_ease(Tween.EASE_IN_OUT)
	# Fjeder tilbage til normal med elastik
	tween.tween_property(node, "scale", base_scale, 0.45) \
		.set_trans(Tween.TRANS_ELASTIC) \
		.set_ease(Tween.EASE_OUT)
	return tween
