extends Node2D

# =============================================================================
#  GAME — Escena Principal del Nivel (Sector C-4)
#  Zombie Roguelike · Godot 4
# =============================================================================
#
#  Responsabilidades:
#    · Reproducir el briefing narrativo de inicio (transmisión por radio).
#    · Inicializar el HUD y conectar señales del jugador.
#    · Desplegar la horda de zombis tras el diálogo o salto del mismo.
#    · Detectar victoria (horda exterminada) y derrota (salud 0).
#    · Garantizar estabilidad y evitar carreras asíncronas en transiciones.
# =============================================================================

const ZOMBIE_SCENE = preload("res://scenes/enemies/Zombie.tscn")
const NarrativeData = preload("res://scenes/narrative/NarrativeData.gd")

# ---------------------------------------------------------------------------
#  Configuración del nivel (Inspector)
# ---------------------------------------------------------------------------

## Número total de zombis que spawn tras el briefing.
@export var total_zombies: int = 10

## Distancia mínima de spawn respecto al jugador (px).
@export var spawn_radius_min: float = 350.0

## Distancia máxima de spawn respecto al jugador (px).
@export var spawn_radius_max: float = 600.0

## Segundos de espera tras la muerte del jugador antes del fundido a Game Over.
@export var game_over_delay: float = 1.2

## Segundos de espera tras la victoria antes del fundido a Victoria.
@export var victory_delay: float = 1.6

# ---------------------------------------------------------------------------
#  Referencias a nodos de la escena
# ---------------------------------------------------------------------------
@onready var _player = $Player
@onready var _hud = $HUD
@onready var _pause_menu = $PauseMenu
@onready var _dialogue_box = $DialogueBox

# ---------------------------------------------------------------------------
#  Estado interno
# ---------------------------------------------------------------------------
var _zombies_remaining: int = 0
var _zombies_killed: int = 0
var _game_ended: bool = false
var _intro_active: bool = true


# ===========================================================================
#  CICLO DE VIDA
# ===========================================================================

func _ready() -> void:
	AudioManager.play_game_music()

	# Conectar señales del jugador
	_player.died.connect(_on_player_died)

	# Inicializar HUD
	_hud.connect_to_player(_player)
	_hud.update_kills(0, total_zombies)

	# Iniciar transmisión narrativa introductoria
	_zombies_remaining = total_zombies
	if _dialogue_box:
		_dialogue_box.dialogue_completed.connect(_on_intro_completed)
		_dialogue_box.start_dialogues(NarrativeData.INTRO_DIALOGUES)
	else:
		_start_combat()


func _on_intro_completed() -> void:
	_intro_active = false
	_start_combat()


func _start_combat() -> void:
	# Desplegar la horda de zombis en el sector
	_spawn_zombies(total_zombies)


# ===========================================================================
#  SPAWN DE ZOMBIS
# ===========================================================================

func _spawn_zombies(count: int) -> void:
	for i in count:
		var angle := randf() * TAU
		var distance := randf_range(spawn_radius_min, spawn_radius_max)
		var pos: Vector2 = _player.global_position + Vector2(cos(angle), sin(angle)) * distance

		var zombie = ZOMBIE_SCENE.instantiate()
		zombie.global_position = pos
		zombie.set_player(_player)
		zombie.died.connect(_on_zombie_died)
		add_child(zombie)


# ===========================================================================
#  CONDICIONES DE FIN DE PARTIDA Y ESTABILIDAD
# ===========================================================================

func _on_zombie_died() -> void:
	if _game_ended:
		return
	_zombies_killed += 1
	_zombies_remaining -= 1
	_hud.update_kills(_zombies_killed, total_zombies)

	if _zombies_remaining <= 0:
		_end_game(true)


func _on_player_died() -> void:
	if _game_ended:
		return
	_end_game(false)


## Gestiona el fin de la partida con verificación rigurosa de ciclo de vida.
func _end_game(victory: bool) -> void:
	if _game_ended:
		return
	_game_ended = true

	var delay := victory_delay if victory else game_over_delay
	await get_tree().create_timer(delay).timeout

	# CONTROL DE ESTABILIDAD:
	# Si el jugador pausó y volvió al menú principal durante el temporizador,
	# el nodo ya no estará en el árbol o la escena habrá cambiado.
	# Esta comprobación previene cambios de escena no deseados o referencias nulas.
	if not is_inside_tree() or SceneManager.get_current_scene() != "game":
		return

	if victory:
		SceneManager.go_to_victory()
	else:
		SceneManager.go_to_game_over()
