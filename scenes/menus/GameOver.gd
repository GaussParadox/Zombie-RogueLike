extends Control

func _ready() -> void:
	$VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	$VBoxContainer/RestartButton.grab_focus()

func _on_restart_pressed() -> void:
	SceneManager.go_to_game()

func _on_main_menu_pressed() -> void:
	SceneManager.go_to_main_menu()
