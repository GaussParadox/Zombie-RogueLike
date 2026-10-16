extends Node2D

# Game - Escena principal del juego (placeholder).
# Instancia el PauseMenu dinámicamente y lo añade como hijo.

var _pause_menu: Node = null

const PAUSE_MENU_SCENE = preload("res://scenes/menus/PauseMenu.tscn")

func _ready() -> void:
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(_pause_menu)
	# Señal de victoria/game over de prueba (quitar cuando haya lógica real)
	# Para probar: presiona Enter para ir a GameOver, Backspace para Victory

func _unhandled_input(event: InputEvent) -> void:
	# Teclas de prueba para pantallas de fin — ELIMINAR en producción
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			SceneManager.go_to_game_over()
		elif event.keycode == KEY_F2:
			SceneManager.go_to_victory()
