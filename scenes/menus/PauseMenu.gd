extends CanvasLayer

# PauseMenu - Escena reutilizable de pausa.
# Instanciala como hijo de tu escena de juego (Game.tscn) o añádela
# dinámicamente. Llama a show_pause() / hide_pause() desde el juego.

signal resumed
signal went_to_main_menu

func _ready() -> void:
	$Panel/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	# Empieza oculto
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if SceneManager.is_transitioning():
		return
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume_pressed()
		else:
			show_pause()

func show_pause() -> void:
	get_tree().paused = true
	show()
	$Panel/VBoxContainer/ResumeButton.grab_focus()

func hide_pause() -> void:
	get_tree().paused = false
	hide()

func _on_resume_pressed() -> void:
	hide_pause()
	resumed.emit()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	went_to_main_menu.emit()
	SceneManager.go_to_main_menu()
