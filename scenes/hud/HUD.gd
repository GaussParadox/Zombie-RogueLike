extends CanvasLayer

# =============================================================================
#  HUD — Interfaz gráfica en pantalla
#  Zombie Roguelike · Godot 4
#
#  Muestra: Arma, Salud, Escudo, Munición, Estado de recarga, Contador de zombis.
#  Se conecta al jugador a través de señales (desacoplado del Player).
# =============================================================================

# ---------------------------------------------------------------------------
#  Referencias a nodos del árbol (deben coincidir con HUD.tscn)
# ---------------------------------------------------------------------------
@onready var _weapon_label: Label       = $MarginContainer/VBoxContainer/WeaponLabel
@onready var _health_bar: ProgressBar   = $MarginContainer/VBoxContainer/HealthRow/HealthBar
@onready var _health_label: Label       = $MarginContainer/VBoxContainer/HealthRow/HealthLabel
@onready var _shield_bar: ProgressBar   = $MarginContainer/VBoxContainer/ShieldRow/ShieldBar
@onready var _shield_label: Label       = $MarginContainer/VBoxContainer/ShieldRow/ShieldLabel
@onready var _ammo_label: Label         = $MarginContainer/VBoxContainer/AmmoLabel
@onready var _reload_label: Label       = $MarginContainer/VBoxContainer/ReloadLabel
@onready var _kills_label: Label        = $MarginContainer/VBoxContainer/KillsLabel


# ===========================================================================
#  INICIALIZACIÓN
# ===========================================================================

## Conecta el HUD a las señales del jugador e inicializa todos los valores.
## Llamar desde Game.gd después de que el jugador esté listo.
func connect_to_player(player: CharacterBody2D) -> void:
	player.health_changed.connect(_on_health_changed)
	player.shield_changed.connect(_on_shield_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.reloading_started.connect(_on_reloading_started)
	player.reloading_finished.connect(_on_reloading_finished)

	# Inicialización con los valores actuales del jugador
	_weapon_label.text = player.weapon_name
	_health_bar.max_value = player.max_health
	_shield_bar.max_value = player.max_shield
	_on_health_changed(player.current_health, player.max_health)
	_on_shield_changed(player.current_shield, player.max_shield)
	_on_ammo_changed(player.current_ammo, player.max_ammo, player.weapon_name)
	_reload_label.visible = false


# ===========================================================================
#  ACTUALIZACIÓN EXTERNA
# ===========================================================================

## Actualiza el contador de zombis eliminados en el HUD.
## Llamar desde Game.gd cada vez que muere un zombi.
func update_kills(killed: int, total: int) -> void:
	_kills_label.text = "Zombis: %d / %d" % [killed, total]


# ===========================================================================
#  MANEJADORES DE SEÑALES DEL JUGADOR
# ===========================================================================

func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value     = current
	_health_label.text    = "%d / %d" % [int(current), int(maximum)]


func _on_shield_changed(current: float, maximum: float) -> void:
	_shield_bar.max_value = maximum
	_shield_bar.value     = current
	_shield_label.text    = "%d / %d" % [int(current), int(maximum)]


func _on_ammo_changed(current_ammo: int, max_ammo: int, _weapon: String) -> void:
	_ammo_label.text = "🔫  %d / %d" % [current_ammo, max_ammo]


func _on_reloading_started(_reload_time: float) -> void:
	_reload_label.visible = true
	_ammo_label.modulate  = Color(0.5, 0.5, 0.5, 1)   # atenúa la munición


func _on_reloading_finished() -> void:
	_reload_label.visible = false
	_ammo_label.modulate  = Color(1, 1, 1, 1)          # restaura el color
