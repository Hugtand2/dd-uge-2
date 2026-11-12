class_name TestBot
extends Node

# Hjælper til automatiske tests i !DEBUG: falsk mus og tastatur, screenshots og tjek.
#
# Brug i en test-scenes script:
#   var bot := TestBot.new()
#   add_child(bot)
#   await bot.wait_frames(2)
#   await bot.drag(Vector2(100, 50), Vector2(400, 300))
#   await bot.screenshot("efter_drag")
#   bot.check(form.position.x > 300, "Blanketten flyttede sig")
#   bot.finish()   # printer resultatet og lukker spillet (exit code 1 hvis noget fejlede)
#
# Alle positioner er verdens-koordinater (det samme som node.global_position).
# Rør ikke den rigtige mus over spilvinduet, mens en test kører, ellers blandes
# dine bevægelser med testens.
# Screenshots gemmes i !DEBUG/Screenshots/ (ignoreres af git og Godot).
# De virker ikke i --headless, fordi der så ikke tegnes noget.

const SCREENSHOT_DIR := "res://!DEBUG/Screenshots/"

var passed := 0
var failed := 0

var _mouse_screen := Vector2.ZERO
var _button_mask := 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR)

# --- Ventetid ---------------------------------------------------------------

func wait_frames(n: int = 1) -> void:
	for i in n:
		await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

# --- Mus --------------------------------------------------------------------

# Verdens-koordinat -> vinduets pixel-koordinat (det, et rigtigt mus-event har)
func to_screen(world: Vector2) -> Vector2:
	var vp := get_viewport()
	return vp.get_final_transform() * (vp.get_canvas_transform() * world)

func move_mouse(world: Vector2) -> void:
	var screen := to_screen(world)
	var ev := InputEventMouseMotion.new()
	ev.position = screen
	ev.global_position = screen
	ev.relative = screen - _mouse_screen
	ev.button_mask = _button_mask
	_mouse_screen = screen
	Input.parse_input_event(ev)
	await wait_frames(1)

func press(world: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await move_mouse(world)
	_button_mask |= 1 << (button - 1)
	_send_button(button, true)
	await wait_frames(1)

func release(world: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await move_mouse(world)
	_button_mask &= ~(1 << (button - 1))
	_send_button(button, false)
	await wait_frames(1)

func click(world: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await press(world, button)
	await release(world, button)

# Tryk ned, bevæg musen i `steps` skridt, slip. Til sidst én bevægelse mere,
# fordi Board først opdager, at knappen er sluppet, ved næste mus-bevægelse.
func drag(from: Vector2, to: Vector2, steps: int = 10) -> void:
	await press(from)
	for i in range(1, steps + 1):
		await move_mouse(from.lerp(to, float(i) / steps))
	await release(to)
	await move_mouse(to + Vector2(1, 0))

func _send_button(button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	ev.position = _mouse_screen
	ev.global_position = _mouse_screen
	ev.button_mask = _button_mask
	Input.parse_input_event(ev)

# --- Tastatur ---------------------------------------------------------------

# Skriv tekst i det felt, der har fokus (klik på feltet først)
func type_text(text: String) -> void:
	for ch in text:
		var ev := InputEventKey.new()
		ev.unicode = ch.unicode_at(0)
		ev.pressed = true
		Input.parse_input_event(ev)
		var up := ev.duplicate() as InputEventKey
		up.pressed = false
		Input.parse_input_event(up)
		await wait_frames(1)

# Tryk på en enkelt tast, fx KEY_ENTER eller KEY_ESCAPE
func press_key(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = true
	Input.parse_input_event(ev)
	await wait_frames(1)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(1)

# Udløs en input-action fra projektet, fx "Test" eller "ui_accept"
func press_action(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await wait_frames(1)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(1)

# --- Screenshots ------------------------------------------------------------

# Gemmer et billede af skærmen og returnerer den fulde sti (eller "" hvis det ikke gik)
func screenshot(file_name: String) -> String:
	if DisplayServer.get_name() == "headless":
		print("[TestBot] Springer screenshot '%s' over (headless)" % file_name)
		return ""
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("[TestBot] Kunne ikke tage screenshot '%s'" % file_name)
		return ""
	var path := ProjectSettings.globalize_path(SCREENSHOT_DIR + file_name + ".png")
	var err := image.save_png(path)
	if err != OK:
		push_error("[TestBot] Kunne ikke gemme %s (fejl %d)" % [path, err])
		return ""
	print("[TestBot] Screenshot: ", path)
	return path

# --- Tjek -------------------------------------------------------------------

func check(condition: bool, description: String) -> bool:
	if condition:
		passed += 1
		print("[PASS] ", description)
	else:
		failed += 1
		print("[FAIL] ", description)
		push_error("[FAIL] " + description)
	return condition

# Tal og vektorer sammenlignes med is_equal_approx (små afrundingsfejl tæller ikke)
func check_equal(actual: Variant, expected: Variant, description: String) -> bool:
	var same: bool
	if actual is float and expected is float:
		same = is_equal_approx(actual, expected)
	elif (actual is Vector2 and expected is Vector2) or (actual is Vector3 and expected is Vector3):
		same = actual.is_equal_approx(expected)
	else:
		same = actual == expected
	return check(same, "%s (fik %s, forventede %s)" % [description, actual, expected])

func check_near(actual: float, expected: float, tolerance: float, description: String) -> bool:
	return check(absf(actual - expected) <= tolerance,
		"%s (fik %s, forventede %s ± %s)" % [description, actual, expected, tolerance])

# Print resultatet. Med quit = true lukkes spillet med exit code 0 (alt bestået) eller 1.
func finish(quit: bool = true) -> void:
	print("[TestBot] RESULTAT: %d bestået, %d fejlet" % [passed, failed])
	if quit:
		get_tree().quit(1 if failed > 0 else 0)
