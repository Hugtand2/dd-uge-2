extends Node2D

# Automatisk test af regelbogen med TestBot.
# Kør scenen: den åbner A-skat-siden, flytter siden, går tilbage til bogen,
# tager screenshots (i !DEBUG/Screenshots/) og lukker selv.
# Sæt AUTO_QUIT til false, hvis vinduet skal blive åbent bagefter,
# så du selv kan prøve regelbogen.
#
# Testen bruger ikke falsk mus: Board læser den rigtige cursor, så TestBot kan
# ikke trække boards. I stedet trykkes knapperne via deres `pressed`-signal,
# og boards flyttes ved at sætte global_position.

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

	bot.check(book.visible and book.is_in_group("boards"), "Regelbogen er synlig og er et board")
	var buttons := book.find_children("*", "Button", true, false)
	bot.check_equal(buttons.size(), 2, "Regelbogen har en knap for hver side (A-skat og Aktieskat)")
	var page_button := buttons[0] as Button
	bot.check_equal(page_button.text, "A-skat", "Knappen har sidens titel")
	bot.check_equal((buttons[1] as Button).text, "Aktieskat", "Den anden knap er Aktieskat")

	# 1. Boards starter med skjult indhold. Det vises, når boardet har været
	#    et ikon (over skrivebordet) og bliver trukket ud igen.
	bot.check(not page_button.is_visible_in_tree(), "Knapperne er skjult fra start")
	book.set_icon_mode(true)
	bot.check(book.is_icon and not page_button.is_visible_in_tree(), "Som ikon er knapperne skjult")
	book.set_icon_mode(false)
	bot.check(page_button.is_visible_in_tree(), "Knapperne vises, når bogen ikke længere er et ikon")
	bot.check_equal(book.global_position, Vector2(40, 40), "Bogen ligger samme sted efter ikon og tilbage")
	book.global_position = Vector2(70, 100)
	await bot.wait_frames(2)
	await bot.screenshot("rulebook_01_start")

	# 2. Tryk på knappen -> bogen skjules, og siden vises samme sted
	page_button.pressed.emit()
	var page := _find_page()
	bot.check(page != null, "Siden blev lavet")
	if page == null:
		bot.finish(AUTO_QUIT)
		return
	await bot.wait_frames(2)
	bot.check(page.visible and page.is_in_group("boards"), "Siden er synlig og er et board")
	bot.check(not book.visible and not book.is_in_group("boards"), "Regelbogen er skjult og slået fra")
	bot.check_equal(page.global_position, book.global_position, "Siden ligger, hvor bogen lå")
	bot.check_equal(page.get_index(), book.get_index() + 1, "Siden ligger i laget lige over bogen")
	bot.check_equal(_hidden_controls(page), 0, "Sidens tekst og knap er synlige, når den åbnes")
	_check_page_text(page)
	await bot.screenshot("rulebook_02_side")

	# 3. Som ikon (over skrivebordet) vises kun ikonet: al tekst og "Tilbage" skjules
	var page_position := page.global_position
	page.set_icon_mode(true)
	bot.check_equal(_visible_controls(page), 0, "Som ikon er al tekst og knappen på siden skjult")
	bot.check(page.icon_sprite.visible and not page.sprite.visible, "Som ikon vises kun ikonet")
	page.set_icon_mode(false)
	bot.check_equal(_hidden_controls(page), 0, "Teksten og knappen er tilbage, når siden ikke er et ikon")
	bot.check_equal(page.global_position, page_position, "Siden ligger samme sted efter ikon og tilbage")

	# 4. Siden flyttes, og den skjulte bog følger ikke med
	page.global_position = Vector2(110, 70)
	bot.check_equal(book.global_position, Vector2(70, 100), "Den skjulte bog blev liggende")

	# 5. "Tilbage" -> siden skjules, og bogen vises, hvor siden blev lagt
	page.exit_button.pressed.emit()
	await bot.wait_frames(2)
	bot.check(book.visible and book.is_in_group("boards"), "Regelbogen er tilbage")
	bot.check(not page.visible and not page.is_in_group("boards"), "Siden er skjult og slået fra")
	bot.check_equal(book.global_position, Vector2(110, 70), "Bogen ligger, hvor siden blev lagt")
	bot.check(page_button.is_visible_in_tree(), "Bogens knapper er synlige igen")
	await bot.screenshot("rulebook_03_tilbage")

	# 6. Åbn siden igen -> det er den samme side, ikke en ny
	page_button.pressed.emit()
	bot.check(page.visible and not book.visible, "Siden åbnede igen")
	bot.check_equal(_count_pages(), 1, "Siden blev genbrugt")

	# 7. Læg siden oven på blanketten -> de clippes, og bogen overtager clippet ved "Tilbage"
	page.global_position = Vector2(530, 70)
	bot.check(page.get_board_under() == form, "Siden ligger oven på blanketten")
	page.clip(form)
	page.exit_button.pressed.emit()
	bot.check(form in book.clipped and book in form.clipped, "Bogen overtog sidens clip")
	bot.check(page.clipped.is_empty(), "Den skjulte side har ingen clips")
	bot.check_equal(book.global_position, Vector2(530, 70), "Bogen ligger på blanketten")

	# 8. Åbn siden igen -> siden overtager clippet, og bogen er ude af gruppen
	page_button.pressed.emit()
	await bot.wait_frames(2)
	bot.check(page.visible and not book.visible, "Knappen virker oven på en blanket")
	bot.check(page in form.get_group(), "Siden flytter sig sammen med blanketten")
	bot.check(book not in form.get_group(), "Den skjulte bog flytter sig ikke med blanketten")
	bot.check_equal(form.global_position, Vector2(760, 40), "Blanketten blev liggende")
	await bot.screenshot("rulebook_04_paa_blanket")

	# 9. En skjult bog må ikke tage klik fra siden: den er ikke længere et board
	var point := page.global_position + Vector2(300, 200)
	bot.check(page._is_topmost_at(point), "Siden er øverst, selvom bogen ligger samme sted")

	await bot.screenshot("rulebook_05_slut")
	bot.finish(AUTO_QUIT)

# Antal Controls på boardet, der kan ses lige nu
func _visible_controls(board: Board) -> int:
	var count := 0
	for control in board.find_children("*", "Control", true, false):
		if (control as Control).is_visible_in_tree():
			count += 1
	return count

# Antal Controls på boardet, der er skjult lige nu
func _hidden_controls(board: Board) -> int:
	return board.find_children("*", "Control", true, false).size() - _visible_controls(board)

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
