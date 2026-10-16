extends Area2D

# =============================================================================
#  BULLET — Proyectil del jugador
#  Zombie Roguelike · Godot 4
# =============================================================================

## Velocidad del proyectil en píxeles/segundo.
var speed: float = 650.0

## Daño aplicado al impactar con un cuerpo que tenga el método take_damage().
var damage: float = 25.0

## Dirección de vuelo normalizada (Vector2). Se asigna al instanciar.
var direction: Vector2 = Vector2.RIGHT

## Distancia máxima recorrida antes de autodestruirse (píxeles).
@export var max_range: float = 800.0

# Distancia acumulada viajada en este frame
var _traveled: float = 0.0


func _ready() -> void:
	# Orientar el nodo en la dirección de disparo
	rotation = direction.angle()
	# Conectar señal de colisión con cuerpos físicos
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	position += step
	_traveled += step.length()

	# Autodestrucción por rango máximo
	if _traveled >= max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Aplica daño a cualquier nodo con take_damage (zombis, destructibles, etc.)
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
