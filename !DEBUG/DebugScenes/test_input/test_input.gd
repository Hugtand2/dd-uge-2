extends Node2D

# Automatisk test af mus og tastatur med TestBot.
# Kør scenen: den trækker blanketter rundt, skriver et svar, klikker på en kunde,
# tager screenshots (i !DEBUG/Screenshots/) og lukker selv, når den er færdig.
# Sæt AUTO_QUIT til false, hvis vinduet skal blive åbent bagefter.

const AUTO_QUIT := true

var bot: TestBot

func _ready() -> void:
	bot = TestBot.new()
	add_child(bot)
	_run.call_deferred()

func _run() -> void:
	var form_a := A_Indkomst.new()      # månedlig
	form_a.position = Vector2(40, 40)
	add_child(form_a)
	var form_b := A_Indkomst.new(1)     # årlig
	form_b.position = Vector2(500, 40)
	add_child(form_b)

	await bot.wait_frames(3)
	await bot.screenshot("01_start")

	# 1. Træk blanket A (grib den i margenen øverst, ikke på en Control)
	var start := form_a.global_position
	var grab := start + Vector2(form_a.size.x / 2, 8)
	await bot.drag(grab, grab + Vector2(100, 150))
	bot.check_equal(form_a.global_position, start + Vector2(100, 150), "Blanket A fulgte musen")
	bot.check_equal(form_b.global_position, Vector2(500, 40), "Blanket B blev liggende")

	# 2. A ligger alene: klik i svarfeltet og skriv det korrekte beløb
	var answer := ("%.2f" % form_a.get_correct_total()).replace(".", ",")
	await bot.click(form_a.answer_field.get_global_rect().get_center())
	bot.check(form_a.answer_field.has_focus(), "Svarfeltet fik fokus ved klik")
	await bot.type_text(answer)
	bot.check_equal(form_a.answer_field.text, answer, "Teksten blev skrevet i svarfeltet")
	bot.check_near(form_a.validate(), 0.0, 0.01, "validate() giver 0 ved korrekt svar")
	await bot.screenshot("02_svar")

	# 3. Klik på papiret (uden for svarfeltet) -> feltet skal miste fokus
	await bot.click(form_a.global_position + Vector2(10, 10))
	bot.check(not form_a.answer_field.has_focus(), "Klik på papiret fjerner fokus fra svarfeltet")

	# 4. Slip A oven på B -> de skal clippes sammen
	grab = form_a.global_position + Vector2(form_a.size.x / 2, 8)
	var target := form_b.global_position + Vector2(40, 40)
	await bot.drag(grab, grab + (target - form_a.global_position))
	bot.check_equal(form_a.global_position, target, "Blanket A landede på B")
	bot.check(form_b in form_a.clipped and form_a in form_b.clipped, "A og B er clippet sammen")
	bot.check(form_a.get_index() > form_b.get_index(), "A ligger øverst")
	await bot.screenshot("03_clippet")

	# 5. Træk B (i et hjørne A ikke dækker) -> A skal følge med
	var a_before := form_a.global_position
	grab = form_b.global_position + Vector2(10, 10)
	await bot.drag(grab, grab + Vector2(-200, 100))
	bot.check_equal(form_b.global_position, Vector2(300, 140), "Blanket B fulgte musen")
	bot.check_equal(form_a.global_position, a_before + Vector2(-200, 100), "A fulgte med B")

	# 6. A ligger oven på B: svarfeltet skal stadig kunne klikkes
	await bot.click(form_a.answer_field.get_global_rect().get_center())
	bot.check(form_a.answer_field.has_focus(), "Svarfeltet får fokus, når blanketten ligger oven på en anden")
	await bot.click(form_a.global_position + Vector2(10, 10))

	# 7. Klik på en kunde -> dialogboksen åbner, og klik bladrer igennem replikkerne
	var george := Customer.new("George")
	george.position = Vector2(1000, 420)
	add_child(george)
	await bot.wait_frames(2)
	await bot.click(george.global_position)
	bot.check(DialogueBox.visible, "Dialogboksen åbnede ved klik på George")
	await bot.screenshot("04_dialog")
	var line_count := george.customer_data.read_section("[DIALOGUE]").size()
	for i in line_count:
		await bot.click(Vector2(1000, 100))
	bot.check(not DialogueBox.visible, "Dialogboksen lukkede efter %d klik" % line_count)

	await bot.screenshot("05_slut")
	bot.finish(AUTO_QUIT)
