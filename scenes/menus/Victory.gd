extends Control

# =============================================================================
#  VICTORY — Pantalla de Victoria y Reporte de Extracción
#  Zombie Roguelike · Godot 4
# =============================================================================

const NarrativeData = preload("res://scenes/narrative/NarrativeData.gd")

@onready var _narrative_text: RichTextLabel = $MarginContainer/VBoxContainer/NarrativePanel/NarrativeMargin/ScrollContainer/NarrativeText
@onready var _restart_button: Button = $MarginContainer/VBoxContainer/ButtonRow/RestartButton
@onready var _main_menu_button: Button = $MarginContainer/VBoxContainer/ButtonRow/MainMenuButton


func _ready() -> void:
	AudioManager.play_menu_music()
	_restart_button.pressed.connect(_on_restart_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_restart_button.grab_focus()
	_load_narrative_report()


func _load_narrative_report() -> void:
	var log_data := NarrativeData.VICTORY_LOG
	var formatted := "[color=#55ff88][b]%s[/b][/color]\n" % log_data.get("title", "")
	formatted += "[color=#aaaaaa][i]%s[/i][/color]\n\n" % log_data.get("transmission", "")
	formatted += "[color=#e0e0e0]%s[/color]\n\n" % log_data.get("text", "")
	formatted += "[color=#88ffaa][b]%s[/b][/color]" % log_data.get("command_note", "")
	_narrative_text.text = formatted


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_main_menu_pressed()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_on_restart_pressed()


func _on_restart_pressed() -> void:
	SceneManager.go_to_game()


func _on_main_menu_pressed() -> void:
	SceneManager.go_to_main_menu()
