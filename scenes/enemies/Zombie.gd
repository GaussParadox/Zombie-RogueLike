extends CharacterBody2D

# =============================================================================
#  ZOMBIE — Enemigo con IA de persecución continua
#  Zombie Roguelike · Godot 4
# =============================================================================

## Emitida cuando el zombi muere (usado por Game.gd para contabilizar bajas).
signal died()

# ---------------------------------------------------------------------------
#  Estadísticas exportadas (ajustables por inspector o desde Game.gd)
# ---------------------------------------------------------------------------

## Velocidad de desplazamiento hacia el jugador (px/s).
@export_group("Estadísticas")
@export var speed: float = 80.0

## Puntos de vida del zombi.
@export var max_health: float = 50.0

## Daño aplicado al jugador por cada golpe de contacto.
@export var damage_per_hit: float = 8.0

## Segundos entre cada golpe cuando el zombi toca al jugador.
@export var damage_interval: float = 0.5

# ---------------------------------------------------------------------------
#  Nodos internos
# ---------------------------------------------------------------------------
@onready var _sprite: Sprite2D    = $Sprite2D
@onready var _hitbox: Area2D      = $HitboxArea
@onready var _dmg_timer: Timer    = $DamageTimer

# ---------------------------------------------------------------------------
#  Estado interno
# ---------------------------------------------------------------------------
## Salud actual (lectura pública para sistemas externos como barras de vida).
var current_health: float

var _player: CharacterBody2D = null
var _touching_player: bool   = false


# ===========================================================================
#  CICLO DE VIDA
# ===========================================================================

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")

	# Configurar timer de daño
	_dmg_timer.wait_time   = damage_interval
	_dmg_timer.one_shot    = false
	_dmg_timer.autostart   = false
	_dmg_timer.timeout.connect(_on_damage_timer_timeout)

	# Conectar hitbox
	_hitbox.body_entered.connect(_on_hitbox_body_entered)
	_hitbox.body_exited.connect(_on_hitbox_body_exited)


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	# --- IA de persecución: moverse directo al jugador ---
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * speed

	# Rotar sprite para mirar al jugador
	_sprite.rotation = dir.angle()

	move_and_slide()


# ===========================================================================
#  API PÚBLICA
# ===========================================================================

## Asigna la referencia al jugador. Llamada desde Game.gd al instanciar.
func set_player(player: CharacterBody2D) -> void:
	_player = player


## Aplica daño al zombi. Si la salud llega a 0, emite died() y se destruye.
func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0.0:
		_die()


# ===========================================================================
#  DAÑO POR CONTACTO
# ===========================================================================

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == _player:
		_touching_player = true
		_dmg_timer.start()
		# Golpe inmediato al entrar en contacto
		if _player.has_method("take_damage"):
			_player.take_damage(damage_per_hit)


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == _player:
		_touching_player = false
		_dmg_timer.stop()


func _on_damage_timer_timeout() -> void:
	if _touching_player and is_instance_valid(_player):
		if _player.has_method("take_damage"):
			_player.take_damage(damage_per_hit)


# ===========================================================================
#  MUERTE
# ===========================================================================

func _die() -> void:
	# TODO: reproducir animación de muerte / partículas antes del queue_free
	died.emit()
	queue_free()
