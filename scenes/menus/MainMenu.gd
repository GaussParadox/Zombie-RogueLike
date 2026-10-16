extends Control

func _ready() -> void:
	AudioManager.play_menu_music()
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	# Grab focus on first button for keyboard/controller navigation
	$VBoxContainer/PlayButton.grab_focus()

func _on_play_pressed() -> void:
	SceneManager.go_to_game()

func _on_credits_pressed() -> void:
	SceneManager.go_to_credits()

func _on_quit_pressed() -> void:
	SceneManager.quit_game()
