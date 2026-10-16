extends CharacterBody2D

# =============================================================================
#  PLAYER CONTROLLER — Vista Cenital (Top-Down)
#  Zombie Roguelike · Godot 4
# =============================================================================
#
#  Movimientos implementados:
#    · Walk       — movimiento en 8 direcciones con aceleración/fricción
#    · Dash       — impulso rápido en la dirección de movimiento (cooldown)
#    · Slide      — deslizamiento táctico hacia el cursor (cooldown)
#
#  Señales emitidas:
#    · state_changed(new_state)   — cuando el estado cambia
#    · dash_ready()               — cuando el dash sale de cooldown
#    · slide_ready()              — cuando el slide sale de cooldown
# =============================================================================

# ---------------------------------------------------------------------------
#  Señales
# ---------------------------------------------------------------------------
signal state_changed(new_state: String)
signal dash_ready()
signal slide_ready()

# ---------------------------------------------------------------------------
#  Estados del jugador
# ---------------------------------------------------------------------------
enum State {
	IDLE,    # En reposo
	WALK,    # Caminando
	DASH,    # Durante el impulso
	SLIDE,   # Durante el deslizamiento
}

# ---------------------------------------------------------------------------
#  Velocidad y movimiento base
# ---------------------------------------------------------------------------

## Velocidad máxima de caminar (píxeles/segundo).
@export_group("Walk")
@export var walk_speed: float = 200.0

## Cuánto tarda en llegar a la velocidad máxima (píxeles/segundo²).
## Valor alto = respuesta inmediata. Valor bajo = arranque gradual.
@export var acceleration: float = 1800.0

## Desaceleración al soltar el movimiento (píxeles/segundo²).
## Simula fricción del suelo.
@export var friction: float = 2200.0

# ---------------------------------------------------------------------------
#  Dash
# ---------------------------------------------------------------------------

## Velocidad del impulso de dash (píxeles/segundo).
@export_group("Dash")
@export var dash_speed: float = 600.0

## Duración del dash en segundos.
## Valores típicos: 0.12–0.20 s para sensación arcade.
@export var dash_duration: float = 0.15

## Tiempo de recarga del dash (segundos) desde que termina hasta que vuelve a estar listo.
@export var dash_cooldown: float = 0.8

## Si es true, el jugador es invulnerable durante el dash.
@export var dash_invincible: bool = true

# ---------------------------------------------------------------------------
#  Slide (deslizamiento táctico)
# ---------------------------------------------------------------------------

## Velocidad inicial del deslizamiento (píxeles/segundo).
@export_group("Slide")
@export var slide_speed: float = 450.0

## Duración del deslizamiento en segundos.
@export var slide_duration: float = 0.25

## Tiempo de recarga del slide (segundos).
@export var slide_cooldown: float = 1.2

## Factor de desaceleración del slide (0–1 por frame).
## 0.0 = sin frenado; 1.0 = para instantáneamente.
@export_range(0.0, 1.0) var slide_deceleration: float = 0.08

# ---------------------------------------------------------------------------
#  Nodos internos (se asignan en _ready)
# ---------------------------------------------------------------------------
@onready var _sprite: Node2D = $Sprite2D          # Nodo visual del jugador
@onready var _anim: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var _dash_timer: Timer = $DashTimer
@onready var _dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var _slide_timer: Timer = $SlideTimer
@onready var _slide_cooldown_timer: Timer = $SlideCooldownTimer

# ---------------------------------------------------------------------------
#  Estado interno
# ---------------------------------------------------------------------------
var _state: State = State.IDLE         # Estado actual
var _dash_direction: Vector2 = Vector2.ZERO   # Dirección al iniciar el dash
var _slide_direction: Vector2 = Vector2.ZERO  # Dirección al iniciar el slide
var _can_dash: bool = true             # true = dash disponible
var _can_slide: bool = true            # true = slide disponible


# ===========================================================================
#  CICLO DE VIDA
# ===========================================================================

func _ready() -> void:
	_configure_timers()


func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE, State.WALK:
			_process_walk(delta)
			_check_special_moves()
		State.DASH:
			_process_dash()
		State.SLIDE:
			_process_slide()

	move_and_slide()
	_update_sprite_direction()


# ===========================================================================
#  MOVIMIENTO — WALK
# ===========================================================================

func _process_walk(delta: float) -> void:
	var dir := _get_input_direction()

	if dir != Vector2.ZERO:
		# Aceleración hacia la dirección de entrada
		velocity = velocity.move_toward(dir * walk_speed, acceleration * delta)
		_set_state(State.WALK)
	else:
		# Fricción: desacelerar hasta detenerse
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if velocity.is_zero_approx():
			_set_state(State.IDLE)


## Retorna la dirección de entrada normalizada (soporte WASD + flechas).
func _get_input_direction() -> Vector2:
	return Input.get_vector(
		"move_left", "move_right",
		"move_up",   "move_down"
	).normalized()


# ===========================================================================
#  MOVIMIENTO ESPECIAL — DASH
# ===========================================================================

## Inicia el dash si está disponible. Dirección = input actual o última dirección.
func _start_dash() -> void:
	if not _can_dash:
		return

	_dash_direction = _get_input_direction()
	if _dash_direction == Vector2.ZERO:
		# Sin input: impulsa en la dirección donde mira el sprite
		_dash_direction = Vector2.RIGHT.rotated(_sprite.rotation)

	_can_dash = false
	_set_state(State.DASH)
	velocity = _dash_direction * dash_speed

	_dash_timer.start(dash_duration)
	# TODO: activar efecto visual / invulnerabilidad aquí


func _process_dash() -> void:
	# La velocidad se mantiene constante; move_and_slide la aplica.
	# El timer _dash_timer llama a _on_dash_timer_timeout al terminar.
	pass


func _on_dash_timer_timeout() -> void:
	_set_state(State.IDLE)
	# Reducir velocidad al terminar para que no se sienta abrupto
	velocity *= 0.3
	_dash_cooldown_timer.start(dash_cooldown)


func _on_dash_cooldown_timer_timeout() -> void:
	_can_dash = true
	dash_ready.emit()


# ===========================================================================
#  MOVIMIENTO ESPECIAL — SLIDE (Deslizamiento Táctico)
# ===========================================================================

## Inicia el slide si está disponible. Dirección = hacia el cursor del ratón.
func _start_slide() -> void:
	if not _can_slide:
		return

	# El slide va hacia la dirección de movimiento actual, o al cursor si está quieto.
	var dir := _get_input_direction()
	if dir == Vector2.ZERO:
		var mouse_pos := get_global_mouse_position()
		dir = (mouse_pos - global_position).normalized()

	_slide_direction = dir
	_can_slide = false
	_set_state(State.SLIDE)
	velocity = _slide_direction * slide_speed

	_slide_timer.start(slide_duration)
	# TODO: activar efecto visual / reducir hitbox aquí


func _process_slide() -> void:
	# Desacelera progresivamente durante el slide
	velocity = velocity.lerp(Vector2.ZERO, slide_deceleration)


func _on_slide_timer_timeout() -> void:
	_set_state(State.IDLE)
	velocity *= 0.2
	_slide_cooldown_timer.start(slide_cooldown)


func _on_slide_cooldown_timer_timeout() -> void:
	_can_slide = true
	slide_ready.emit()


# ===========================================================================
#  VERIFICACIÓN DE ACCIONES ESPECIALES
# ===========================================================================

func _check_special_moves() -> void:
	if Input.is_action_just_pressed("dash"):
		_start_dash()
	elif Input.is_action_just_pressed("slide"):
		_start_slide()


# ===========================================================================
#  ORIENTACIÓN DEL SPRITE (mira hacia el cursor)
# ===========================================================================

func _update_sprite_direction() -> void:
	if _sprite == null:
		return
	var mouse_pos := get_global_mouse_position()
	var angle := (mouse_pos - global_position).angle()
	_sprite.rotation = angle


# ===========================================================================
#  MÁQUINA DE ESTADOS INTERNA
# ===========================================================================

func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	state_changed.emit(State.keys()[new_state])
	# TODO: conectar animaciones según el estado aquí


# ===========================================================================
#  CONFIGURACIÓN DE TIMERS
# ===========================================================================

func _configure_timers() -> void:
	_dash_timer.one_shot = true
	_dash_timer.timeout.connect(_on_dash_timer_timeout)

	_dash_cooldown_timer.one_shot = true
	_dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timer_timeout)

	_slide_timer.one_shot = true
	_slide_timer.timeout.connect(_on_slide_timer_timeout)

	_slide_cooldown_timer.one_shot = true
	_slide_cooldown_timer.timeout.connect(_on_slide_cooldown_timer_timeout)


# ===========================================================================
#  API PÚBLICA — para otros sistemas (HUD, combate, etc.)
# ===========================================================================

## Retorna true si el jugador puede ejecutar un dash.
func can_dash() -> bool:
	return _can_dash

## Retorna true si el jugador puede ejecutar un slide.
func can_slide() -> bool:
	return _can_slide

## Retorna el estado actual como String legible.
func get_state_name() -> String:
	return State.keys()[_state]

## Retorna true si el jugador está actualmente en dash (útil para invulnerabilidad).
func is_dashing() -> bool:
	return _state == State.DASH

## Retorna true si el jugador está actualmente en slide.
func is_sliding() -> bool:
	return _state == State.SLIDE
