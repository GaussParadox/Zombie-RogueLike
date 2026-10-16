extends Node

# SceneManager - Autoload singleton for scene transitions
# Handles all scene changes in the game with optional fade transitions

signal scene_changed(scene_name: String)

const SCENES = {
	"main_menu": "res://scenes/menus/MainMenu.tscn",
	"credits": "res://scenes/menus/Credits.tscn",
	"game_over": "res://scenes/menus/GameOver.tscn",
	"victory": "res://scenes/menus/Victory.tscn",
	"game": "res://scenes/game/Game.tscn",
}

var _current_scene_name: String = ""

func go_to(scene_key: String) -> void:
	if not SCENES.has(scene_key):
		push_error("SceneManager: unknown scene key '%s'" % scene_key)
		return
	_current_scene_name = scene_key
	get_tree().change_scene_to_file(SCENES[scene_key])
	scene_changed.emit(scene_key)

func go_to_main_menu() -> void:
	go_to("main_menu")

func go_to_credits() -> void:
	go_to("credits")

func go_to_game() -> void:
	go_to("game")

func go_to_game_over() -> void:
	go_to("game_over")

func go_to_victory() -> void:
	go_to("victory")

func quit_game() -> void:
	get_tree().quit()

func get_current_scene() -> String:
	return _current_scene_name
