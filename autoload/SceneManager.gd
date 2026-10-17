extends Node

# =============================================================================
#  SCENE MANAGER — Gestor Global de Escenas, Transiciones y Estabilidad
#  Zombie Roguelike · Godot 4
# =============================================================================
#
#  Garantías de Estabilidad:
#    · Despausa automática del SceneTree (evita bloqueos tras pausar el juego).
#    · Bloqueo de reentrancia (_is_transitioning): previene carreras si el
#      usuario hace doble clic rápido en botones de navegación.
#    · Fade overlay con Tween dinámico en un CanvasLayer superior (capa 100).
#    · Filtrado de inputs durante el fade (mouse_filter = STOP).
#    · Señales de ciclo de vida completas para sincronizar audio y UI.
# =============================================================================

signal scene_changed(scene_name: String)
signal transition_started(from_scene: String, to_scene: String)
signal transition_finished(to_scene: String)

const SCENES: Dictionary = {
	"main_menu": "res://scenes/menus/MainMenu.tscn",
	"credits": "res://scenes/menus/Credits.tscn",
	"game_over": "res://scenes/menus/GameOver.tscn",
	"victory": "res://scenes/menus/Victory.tscn",
	"game": "res://scenes/game/Game.tscn",
}

var _current_scene_name: String = "main_menu"
var _is_transitioning: bool = false

# Nodos de transición visual
var _transition_layer: CanvasLayer
var _fade_rect: ColorRect
var _tween: Tween


func _ready() -> void:
	# El SceneManager debe procesar SIEMPRE, incluso si el juego está en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_transition_ui()


func _setup_transition_ui() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.name = "SceneTransitionLayer"
	_transition_layer.layer = 100 # Máxima prioridad visual
	add_child(_transition_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeOverlay"
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_layer.add_child(_fade_rect)


## Cambia a la escena identificada por `scene_key` con transición opcional de fundido a negro.
func go_to(scene_key: String, with_fade: bool = true, fade_duration: float = 0.25) -> void:
	if not SCENES.has(scene_key):
		push_error("SceneManager: Clave de escena desconocida '%s'" % scene_key)
		return

	# Prevenir doble ejecución concurrente
	if _is_transitioning:
		return
	_is_transitioning = true

	# REGLA DE ESTABILIDAD: Asegurar que el árbol no quede pausado al cambiar de escena
	get_tree().paused = false

	# REGLA DE ESTABILIDAD 2: Esperar al final del ciclo de frame actual para evitar colisiones
	# con nodos que estén siendo agregados/removidos en el SceneTree.
	await get_tree().process_frame

	var from_scene := _current_scene_name
	var target_path: String = SCENES[scene_key]
	transition_started.emit(from_scene, scene_key)

	if with_fade:
		# Bloquear interacciones del usuario durante el fundido
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

		if _tween and _tween.is_valid():
			_tween.kill()

		# 1. Fundido a negro (Fade Out)
		_tween = create_tween()
		_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_property(_fade_rect, "color:a", 1.0, fade_duration)
		await _tween.finished

		# 2. Reemplazo atómico de la escena en el árbol
		var err := get_tree().change_scene_to_file(target_path)
		if err != OK:
			push_error("SceneManager: Error al cambiar a la escena %s (Código: %d)" % [target_path, err])
			_is_transitioning = false
			_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fade_rect.color.a = 0.0
			return

		_current_scene_name = scene_key
		scene_changed.emit(scene_key)

		# Esperar al frame siguiente para que la nueva escena inicialice su _ready()
		await get_tree().process_frame

		# 3. Fundido desde negro (Fade In)
		_tween = create_tween()
		_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_property(_fade_rect, "color:a", 0.0, fade_duration)
		await _tween.finished

		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		var err := get_tree().change_scene_to_file(target_path)
		if err != OK:
			push_error("SceneManager: Error al cambiar a la escena %s (Código: %d)" % [target_path, err])
			_is_transitioning = false
			return
		_current_scene_name = scene_key
		scene_changed.emit(scene_key)

	_is_transitioning = false
	transition_finished.emit(scene_key)


# Métodos de navegación directa
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

func is_transitioning() -> bool:
	return _is_transitioning
