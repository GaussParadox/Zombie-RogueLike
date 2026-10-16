extends Node2D

# =============================================================================
#  GAME — Escena principal del nivel
#  Zombie Roguelike · Godot 4
#
#  Responsabilidades:
#    · Conectar el HUD al jugador.
#    · Spawnear zombis al inicio de la partida.
#    · Detectar condición de victoria (todos los zombis eliminados).
#    · Detectar condición de derrota (jugador muerto).
# =============================================================================

const ZOMBIE_SCENE = preload("res://scenes/enemies/Zombie.tscn")

# ---------------------------------------------------------------------------
#  Configuración del nivel (ajustable desde el Inspector)
# ---------------------------------------------------------------------------

## Número total de zombis que spawn al inicio. Matar a todos = Victoria.
@export var total_zombies: int = 10

## Distancia mínima al jugador para spawnear zombis (px).
@export var spawn_radius_min: float = 350.0

## Distancia máxima al jugador para spawnear zombis (px).
@export var spawn_radius_max: float = 600.0

## Segundos de espera después de la derrota antes de cambiar de escena.
@export var game_over_delay: float = 1.2

## Segundos de espera después de la victoria antes de cambiar de escena.
@export var victory_delay: float = 1.8

# ---------------------------------------------------------------------------
#  Referencias a nodos instanciados en Game.tscn
# ---------------------------------------------------------------------------
@onready var _player       = $Player
@onready var _hud          = $HUD
@onready var _pause_menu   = $PauseMenu

# ---------------------------------------------------------------------------
#  Estado interno
# ---------------------------------------------------------------------------
var _zombies_remaining: int = 0
var _zombies_killed: int    = 0
var _game_ended: bool       = false   # evita doble transición


# ===========================================================================
#  INICIO
# ===========================================================================

func _ready() -> void:
	AudioManager.play_game_music()

	# Conectar señales del jugador
	_player.died.connect(_on_player_died)

	# Inicializar HUD con los valores del jugador
	_hud.connect_to_player(_player)
	_hud.update_kills(0, total_zombies)

	# Spawn inicial de zombis
	_zombies_remaining = total_zombies
	_spawn_zombies(total_zombies)


# ===========================================================================
#  SPAWN DE ZOMBIS
# ===========================================================================

## Instancia `count` zombis en posiciones aleatorias alrededor del jugador
## a una distancia entre [spawn_radius_min, spawn_radius_max].
func _spawn_zombies(count: int) -> void:
	for i in count:
		var angle    := randf() * TAU
		var distance := randf_range(spawn_radius_min, spawn_radius_max)
		var pos: Vector2 = _player.global_position + Vector2(cos(angle), sin(angle)) * distance

		var zombie = ZOMBIE_SCENE.instantiate()
		zombie.global_position = pos
		zombie.set_player(_player)
		zombie.died.connect(_on_zombie_died)
		add_child(zombie)


# ===========================================================================
#  CONDICIONES DE FIN DE PARTIDA
# ===========================================================================

func _on_zombie_died() -> void:
	if _game_ended:
		return
	_zombies_killed    += 1
	_zombies_remaining -= 1
	_hud.update_kills(_zombies_killed, total_zombies)

	if _zombies_remaining <= 0:
		_end_game(true)


func _on_player_died() -> void:
	if _game_ended:
		return
	_end_game(false)


## Gestiona el fin de la partida: espera el delay y navega a la pantalla correcta.
func _end_game(victory: bool) -> void:
	_game_ended = true
	var delay := victory_delay if victory else game_over_delay
	await get_tree().create_timer(delay).timeout
	if victory:
		SceneManager.go_to_victory()
	else:
		SceneManager.go_to_game_over()
