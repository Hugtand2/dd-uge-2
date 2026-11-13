extends Node2D

# Automatisk test af regelbogen med TestBot.
# Kør scenen: den trækker regelbogen, åbner A-skat-siden, trækker siden,
# går tilbage til bogen, tager screenshots (i !DEBUG/Screenshots/) og lukker selv.
# Sæt AUTO_QUIT til false, hvis vinduet skal blive åbent bagefter,
# så du selv kan prøve regelbogen.

const AUTO_QUIT := true
const RULEBOOK := preload("res://Scenes&Scripts/InteractiveScenes/rulebook.tscn")
const PAGE_PATH := "res://Resources/Rulebook/Pages/a_skat.txt"

var bot: TestBot

func _ready() -> void:
	bot = TestBot.new()
	add_child(bot)
	_run.call_deferred()

func _run() -> void:
	var form := A_Indkomst.new()
	form.position = Vector2(760, 40)
	add_child(form)
	var book := RULEBOOK.instantiate() as Board
	book.position = Vector2(40, 40)
	add_child(book)

	await bot.wait_frames(3)
	await bot.screenshot("rulebook_01_start")

	bot.check(book.visible and book.is_in_group("boards"), "Regelbogen er synlig og er et board")
	var buttons := book.find_children("*", "Button", true, false)
	bot.check_equal(buttons.size(), 2, "Regelbogen har en knap for hver side (A-skat og Aktieskat)")
	var page_button := buttons[0] as Button
	bot.check_equal(page_button.text, "A-skat", "Knappen har sidens titel")
	bot.check_equal((buttons[1] as Button).text, "Aktieskat", "Den anden knap er Aktieskat")

	# 1. Regelbogen kan trækkes (grib den på højre side, hvor der ikke er knapper)
	var grab := book.global_position + Vector2(450, 200)
	await bot.drag(grab, grab + Vector2(30, 60))
	bot.check_equal(book.global_position, Vector2(70, 100), "Regelbogen fulgte musen")

	# 2. Klik på knappen -> bogen skjules, og siden vises samme sted
	await bot.click(page_button.get_global_rect().get_center())
	var page := _find_page()
	bot.check(page != null, "Siden blev lavet")
	if page == null:
		bot.finish(AUTO_QUIT)
		return
	bot.check(page.visible and page.is_in_group("boards"), "Siden er synlig og er et board")
	bot.check(not book.visible and not book.is_in_group("boards"), "Regelbogen er skjult og slået fra")
	bot.check_equal(page.global_position, book.global_position, "Siden ligger, hvor bogen lå")
	bot.check_equal(page.get_index(), book.get_index() + 1, "Siden ligger i laget lige over bogen")
	_check_page_text(page)
	await bot.screenshot("rulebook_02_side")

	# 3. Siden kan trækkes (også ved at tage fat i teksten), og den skjulte bog følger ikke med
	grab = page.global_position + Vector2(150, 120)
	await bot.drag(grab, grab + Vector2(40, -30))
	bot.check_equal(page.global_position, Vector2(110, 70), "Siden fulgte musen")
	bot.check_equal(book.global_position, Vector2(70, 100), "Den skjulte bog blev liggende")

	# 4. "Tilbage" -> siden skjules, og bogen vises, hvor siden blev lagt
	await bot.click(page.exit_button.get_global_rect().get_center())
	bot.check(book.visible and book.is_in_group("boards"), "Regelbogen er tilbage")
	bot.check(not page.visible and not page.is_in_group("boards"), "Siden er skjult og slået fra")
	bot.check_equal(book.global_position, Vector2(110, 70), "Bogen ligger, hvor siden blev lagt")
	await bot.screenshot("rulebook_03_tilbage")

	# 5. Åbn siden igen -> det er den samme side, ikke en ny
	await bot.click(page_button.get_global_rect().get_center())
	bot.check(page.visible and not book.visible, "Siden åbnede igen")
	bot.check_equal(_count_pages(), 1, "Siden blev genbrugt")

	# 6. Læg siden oven på blanketten -> de clippes, og bogen overtager clippet ved "Tilbage"
	grab = page.global_position + Vector2(300, 200)
	await bot.drag(grab, grab + Vector2(420, 0))
	bot.check_equal(page.global_position, Vector2(530, 70), "Siden landede på blanketten")
	bot.check(form in page.clipped, "Siden og blanketten er clippet sammen")
	await bot.click(page.exit_button.get_global_rect().get_center())
	bot.check(form in book.clipped and book in form.clipped, "Bogen overtog sidens clip")
	bot.check(page.clipped.is_empty(), "Den skjulte side har ingen clips")

	# 7. Knappen virker også, når bogen ligger oven på en blanket
	#    (klik på den del af knappen, der dækker blanketten)
	var button_rect := page_button.get_global_rect()
	var over_form := Vector2(button_rect.end.x - 10, button_rect.get_center().y)
	bot.check(form.get_global_rect().has_point(over_form), "Testen klikker et sted, hvor blanketten ligger under knappen")
	await bot.click(over_form)
	bot.check(page.visible and not book.visible, "Knappen virker oven på en blanket")
	bot.check(not form.dragging, "Blanketten under knappen tog ikke klikket")
	bot.check_equal(form.global_position, Vector2(760, 40), "Blanketten blev liggende")
	await bot.screenshot("rulebook_04_paa_blanket")

	# 8. Træk blanketten (i den stribe siden ikke dækker) -> siden følger med
	grab = form.global_position + Vector2(form.size.x / 2, 10)
	await bot.drag(grab, grab + Vector2(-100, 50))
	bot.check_equal(form.global_position, Vector2(660, 90), "Blanketten fulgte musen")
	bot.check_equal(page.global_position, Vector2(430, 120), "Siden fulgte med blanketten")

	await bot.screenshot("rulebook_05_slut")
	bot.finish(AUTO_QUIT)

# Teksten på siden skal være den samme som i txt-filen
func _check_page_text(page: RulebookPage) -> void:
	var file := FileAccess.open(PAGE_PATH, FileAccess.READ)
	var data := CustomerData.new(file.get_as_text().split("\n"))
	var shown := PackedStringArray()
	for label in page.find_children("*", "Label", true, false):
		shown.append((label as Label).text)

	bot.check(data.read_line("[TITLE]", 0) in shown, "Titlen fra txt-filen står på siden")
	var left := data.read_section("[LEFT]")
	var right := data.read_section("[RIGHT]")
	bot.check(not left.is_empty() and not right.is_empty(), "Txt-filen har tekst i [LEFT] og [RIGHT]")
	var missing := 0
	for line in left + right:
		if line not in shown:
			missing += 1
	bot.check_equal(missing, 0, "Alle linjer fra [LEFT] og [RIGHT] står på siden")

	# Teksten må ikke løbe ud over papiret
	var paper := page.get_global_rect()
	var outside := 0
	for control in page.find_children("*", "Control", true, false):
		if not paper.encloses((control as Control).get_global_rect()):
			outside += 1
	bot.check_equal(outside, 0, "Al tekst og knappen er inden for papiret")

func _find_page() -> RulebookPage:
	for child in get_children():
		if child is RulebookPage:
			return child
	return null

func _count_pages() -> int:
	var count := 0
	for child in get_children():
		if child is RulebookPage:
			count += 1
	return count
