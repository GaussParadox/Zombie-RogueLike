extends CharacterBody2D

# =============================================================================
#  PLAYER CONTROLLER — Vista Cenital (Top-Down)
#  Zombie Roguelike · Godot 4
#  Combina: Movimiento + Dash + Slide + Salud/Escudo + Disparo
# =============================================================================

# ---------------------------------------------------------------------------
#  Señales
# ---------------------------------------------------------------------------
## Emitida cada vez que la salud cambia (current, maximum).
signal health_changed(current: float, maximum: float)
## Emitida cada vez que el escudo cambia (current, maximum).
signal shield_changed(current: float, maximum: float)
## Emitida al disparar o recargar (balas actuales, máximo, nombre del arma).
signal ammo_changed(current_ammo: int, max_ammo: int, weapon_name: String)
## Emitida al iniciar la recarga (tiempo total en segundos).
signal reloading_started(reload_time: float)
## Emitida al terminar la recarga.
signal reloading_finished()
## Emitida cuando la salud llega a 0.
signal died()
## Emitida al cambiar de estado (IDLE, WALK, DASH, SLIDE).
signal state_changed(new_state: String)
## Emitida cuando el dash sale de cooldown.
signal dash_ready()
## Emitida cuando el slide sale de cooldown.
signal slide_ready()

# ---------------------------------------------------------------------------
#  Estados del jugador
# ---------------------------------------------------------------------------
enum State { IDLE, WALK, DASH, SLIDE }

# ---------------------------------------------------------------------------
#  Salud y Escudo
# ---------------------------------------------------------------------------
@export_group("Salud / Escudo")
## Puntos de vida máximos del jugador.
@export var max_health: float = 100.0
## Puntos de escudo máximos. El escudo absorbe daño antes que la salud.
@export var max_shield: float = 50.0

# ---------------------------------------------------------------------------
#  Movimiento base
# ---------------------------------------------------------------------------
@export_group("Movimiento")
## Velocidad máxima al caminar (px/s).
@export var walk_speed: float = 200.0
## Aceleración al moverse (px/s²). Valor alto = control inmediato.
@export var acceleration: float = 1800.0
## Desaceleración al soltar el movimiento (px/s²). Simula fricción del suelo.
@export var friction: float = 2200.0

# ---------------------------------------------------------------------------
#  Dash (impulso rápido)
# ---------------------------------------------------------------------------
@export_group("Dash")
## Velocidad del impulso de dash (px/s).
@export var dash_speed: float = 600.0
## Duración del dash (segundos). Rango típico: 0.12–0.20 s.
@export var dash_duration: float = 0.15
## Cooldown del dash desde que termina hasta que vuelve a estar listo (segundos).
@export var dash_cooldown: float = 0.8
## Si es true, el jugador es inmune al daño mientras dashea.
@export var dash_invincible: bool = true

# ---------------------------------------------------------------------------
#  Slide (deslizamiento táctico)
# ---------------------------------------------------------------------------
@export_group("Slide")
## Velocidad inicial del deslizamiento (px/s).
@export var slide_speed: float = 450.0
## Duración del deslizamiento (segundos).
@export var slide_duration: float = 0.25
## Cooldown del slide (segundos).
@export var slide_cooldown: float = 1.2
## Tasa de desaceleración durante el slide (0 = sin freno, 1 = freno total instantáneo).
@export_range(0.0, 1.0) var slide_deceleration: float = 0.08

# ---------------------------------------------------------------------------
#  Arma y munición
# ---------------------------------------------------------------------------
@export_group("Arma")
## Nombre del arma mostrado en el HUD.
@export var weapon_name: String = "Pistola"
## Daño por proyectil.
@export var bullet_damage: float = 25.0
## Velocidad del proyectil (px/s).
@export var bullet_speed: float = 650.0
## Cadencia de fuego: segundos entre disparos.
@export var fire_rate: float = 0.25
## Capacidad del cargador.
@export var max_ammo: int = 12
## Tiempo de recarga del cargador (segundos).
@export var reload_time: float = 1.5

# ---------------------------------------------------------------------------
#  Nodos (asignados en _ready via @onready)
# ---------------------------------------------------------------------------
@onready var _sprite: Node2D             = $Sprite2D
@onready var _dash_timer: Timer          = $DashTimer
@onready var _dash_cd_timer: Timer       = $DashCooldownTimer
@onready var _slide_timer: Timer         = $SlideTimer
@onready var _slide_cd_timer: Timer      = $SlideCooldownTimer
@onready var _fire_rate_timer: Timer     = $FireRateTimer
@onready var _reload_timer: Timer        = $ReloadTimer

# ---------------------------------------------------------------------------
#  Estado interno (no modificar desde fuera; usar API pública)
# ---------------------------------------------------------------------------
var _state: State            = State.IDLE
var _dash_dir: Vector2       = Vector2.ZERO
var _slide_dir: Vector2      = Vector2.ZERO
var _can_dash: bool          = true
var _can_slide: bool         = true
var _can_fire: bool          = true
var _is_reloading: bool      = false

## Salud actual del jugador (lectura pública).
var current_health: float
## Escudo actual del jugador (lectura pública).
var current_shield: float
## Balas actuales en el cargador (lectura pública).
var current_ammo: int

const BULLET_SCENE = preload("res://scenes/weapons/Bullet.tscn")


# ===========================================================================
#  CICLO DE VIDA
# ===========================================================================

func _ready() -> void:
	current_health = max_health
	current_shield = max_shield
	current_ammo   = max_ammo
	_connect_timers()


func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE, State.WALK:
			_process_walk(delta)
			_check_special_moves()
		State.DASH:
			pass  # velocidad constante; no se modifica en este frame
		State.SLIDE:
			velocity = velocity.lerp(Vector2.ZERO, slide_deceleration)

	move_and_slide()
	_update_sprite_direction()
	_handle_shoot()


# ===========================================================================
#  MOVIMIENTO — WALK
# ===========================================================================

func _process_walk(delta: float) -> void:
	var dir := _get_input_dir()
	if dir != Vector2.ZERO:
		velocity = velocity.move_toward(dir * walk_speed, acceleration * delta)
		_set_state(State.WALK)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if velocity.is_zero_approx():
			_set_state(State.IDLE)

## Retorna la dirección de entrada normalizada (WASD + Flechas).
func _get_input_dir() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()


# ===========================================================================
#  MOVIMIENTO ESPECIAL — DASH
# ===========================================================================

func _start_dash() -> void:
	if not _can_dash:
		return
	_dash_dir = _get_input_dir()
	if _dash_dir == Vector2.ZERO:
		# Sin input: impulso en la dirección actual del sprite
		_dash_dir = Vector2.RIGHT.rotated(_sprite.rotation)
	_can_dash = false
	_set_state(State.DASH)
	velocity = _dash_dir * dash_speed
	_dash_timer.start(dash_duration)


func _on_dash_timer_timeout() -> void:
	_set_state(State.IDLE)
	velocity *= 0.3
	_dash_cd_timer.start(dash_cooldown)


func _on_dash_cd_timeout() -> void:
	_can_dash = true
	dash_ready.emit()


# ===========================================================================
#  MOVIMIENTO ESPECIAL — SLIDE (deslizamiento táctico)
# ===========================================================================

func _start_slide() -> void:
	if not _can_slide:
		return
	_slide_dir = _get_input_dir()
	if _slide_dir == Vector2.ZERO:
		# Sin input: slide hacia el cursor
		_slide_dir = (get_global_mouse_position() - global_position).normalized()
	_can_slide = false
	_set_state(State.SLIDE)
	velocity = _slide_dir * slide_speed
	_slide_timer.start(slide_duration)


func _on_slide_timer_timeout() -> void:
	_set_state(State.IDLE)
	velocity *= 0.2
	_slide_cd_timer.start(slide_cooldown)


func _on_slide_cd_timeout() -> void:
	_can_slide = true
	slide_ready.emit()


func _check_special_moves() -> void:
	if Input.is_action_just_pressed("dash"):
		_start_dash()
	elif Input.is_action_just_pressed("slide"):
		_start_slide()


# ===========================================================================
#  ORIENTACIÓN DEL SPRITE (mira siempre hacia el cursor)
# ===========================================================================

func _update_sprite_direction() -> void:
	if _sprite == null:
		return
	_sprite.rotation = (get_global_mouse_position() - global_position).angle()


# ===========================================================================
#  DISPARO
# ===========================================================================

func _handle_shoot() -> void:
	if not Input.is_action_pressed("shoot"):
		return
	if _is_reloading or not _can_fire:
		return
	if current_ammo > 0:
		_fire()
	else:
		_start_reload()


func _fire() -> void:
	current_ammo   -= 1
	_can_fire       = false
	ammo_changed.emit(current_ammo, max_ammo, weapon_name)

	var bullet       = BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.direction = (get_global_mouse_position() - global_position).normalized()
	bullet.damage    = bullet_damage
	bullet.speed     = bullet_speed
	# Se agrega al padre (Game) para que el proyectil no se mueva con el jugador
	get_parent().add_child(bullet)

	_fire_rate_timer.start(fire_rate)

	if current_ammo <= 0:
		_start_reload()


func _start_reload() -> void:
	if _is_reloading or current_ammo == max_ammo:
		return
	_is_reloading = true
	reloading_started.emit(reload_time)
	_reload_timer.start(reload_time)


func _on_fire_rate_timer_timeout() -> void:
	_can_fire = true


func _on_reload_timer_timeout() -> void:
	_is_reloading  = false
	current_ammo   = max_ammo
	ammo_changed.emit(current_ammo, max_ammo, weapon_name)
	reloading_finished.emit()


# ===========================================================================
#  SALUD Y ESCUDO
# ===========================================================================

## Aplica daño al jugador. El escudo absorbe primero; el resto va a la salud.
func take_damage(amount: float) -> void:
	# Inmunidad durante el dash
	if dash_invincible and _state == State.DASH:
		return

	# El escudo absorbe la primera capa de daño
	if current_shield > 0.0:
		var absorbed := minf(current_shield, amount)
		current_shield -= absorbed
		amount          -= absorbed
		shield_changed.emit(current_shield, max_shield)

	# El daño restante va a la salud
	if amount > 0.0:
		current_health  = maxf(current_health - amount, 0.0)
		health_changed.emit(current_health, max_health)
		if current_health <= 0.0:
			died.emit()


# ===========================================================================
#  MÁQUINA DE ESTADOS
# ===========================================================================

func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	state_changed.emit(State.keys()[new_state])


# ===========================================================================
#  CONEXIÓN DE TIMERS
# ===========================================================================

func _connect_timers() -> void:
	_dash_timer.timeout.connect(_on_dash_timer_timeout)
	_dash_cd_timer.timeout.connect(_on_dash_cd_timeout)
	_slide_timer.timeout.connect(_on_slide_timer_timeout)
	_slide_cd_timer.timeout.connect(_on_slide_cd_timeout)
	_fire_rate_timer.timeout.connect(_on_fire_rate_timer_timeout)
	_reload_timer.timeout.connect(_on_reload_timer_timeout)


# ===========================================================================
#  API PÚBLICA
# ===========================================================================

## Retorna true si el dash está disponible.
func can_dash() -> bool:          return _can_dash
## Retorna true si el slide está disponible.
func can_slide() -> bool:         return _can_slide
## Retorna true si el jugador está dasheando ahora.
func is_dashing() -> bool:        return _state == State.DASH
## Retorna true si el jugador está en slide ahora.
func is_sliding() -> bool:        return _state == State.SLIDE
## Retorna el nombre del estado actual como String.
func get_state_name() -> String:  return State.keys()[_state]
