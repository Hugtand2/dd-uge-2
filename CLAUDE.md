# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Godot 4.7 (Forward Plus, GDScript) 2D game made as a school DDU project ("Undulaternes DDU projekt 2"). The game appears to be about processing tax forms: customers come in with dialogue, and paper forms (`Board`s) are dragged around and clipped together on a desk. Some code comments are in Danish.

## Running

There is no build step, linter or test suite. Open the project in the Godot 4.7 editor, or from the CLI (if `godot` is on PATH):

- Run the main scene: `godot --path .`
- Run a single scene (the way features are tested here): `godot --path . "res://!DEBUG/DebugScenes/test_boards/test_boards.tscn"`
- Headless parse/script check: `godot --headless --path . --quit`

Features are tested by hand in scenes under `!DEBUG/DebugScenes/` (e.g. `test_boards`, `test_dialogue`), each a small scene that builds objects in code.

## Architecture

- **Autoloads** (`project.godot`): `MusicPlayer` (`Setup/AudioSetup/audio_stream_player.gd`, plays looping tracks via `play_custom_track(path)`, skips the call if that track is already playing) and `DialogueBox` (`Scenes/UIScenes/dialogue_box/`, a `CanvasLayer` with `show_lines(speaker, lines)` that advances on the `Confirm` action: Space, Enter or left click). Both are called globally by name.
- **Classes are built in code, not scenes.** `Classes/` holds `class_name` scripts whose `_init` takes arguments (e.g. `Board.new(sprite_path)`, `Customer.new("George")`), so they are created with `.new(...)` and `add_child`, not by instancing `.tscn` files.
- **Board** (`Classes/ObjectClasses/Board.gd`): a draggable paper sprite. Boards join the `"boards"` group. Dropping a board onto another *clips* them together (`clipped` is a two-way adjacency list), and `get_group()` returns the connected set that moves as one. On mouse down, `lift()` recomputes the clips: the board takes along every board above it in draw order that overlaps it, transitively. Draw order is the node's child index (`bring_to_front` uses `move_child`). Hit-testing uses `size`, taken from the texture, with `centered = false`.
- **TaxForm** (`Classes/ObjectClasses/TaxForm.gd`): an `@abstract` subclass of `Board` (needs Godot 4.5+) with abstract `get_form_title()` and `validate() -> float` (the difference between the correct tax and the entered tax). Concrete forms such as `PersonIncomeTax` extend it.
- **Customer** (`Classes/Customer/`): `Customer.new(name)` loads by convention from `res://Resources/Customers/<Name>/<name>_data.txt` and `<name>.jpg` (folder name capitalised, file names lowercase). The data file is a sectioned text file (e.g. a `[DIALOGUE]` header followed by lines), parsed by `CustomerData`, which is still being written.
