class_name NarrativeData
extends RefCounted

# =============================================================================
#  NARRATIVE DATA — Guion, Diálogos y Registro de Historia
#  Zombie Roguelike · Godot 4
# =============================================================================
#
#  Contexto:
#    Complejo Subterráneo C-4 — Laboratorios Aethelgard.
#    Tras el fallo del protocolo de contención biológica, la horda de sujetos
#    infectados bloqueó las salidas de emergencia.
#    El agente de reconocimiento "Sable-7" (Alex Cole) debe purgar el sector
#    para habilitar el restablecimiento de energía y coordinar la extracción.
# =============================================================================

## Estructura de una línea de diálogo:
##   "speaker": Nombre del emisor
##   "callsign": Identificador de canal / rango
##   "color": Color del nombre/emisor en la interfaz
##   "text": Texto del diálogo
##   "sound_pitch": Pitch del pitido de radio

const INTRO_DIALOGUES: Array[Dictionary] = [
	{
		"speaker": "OPERADOR RAMOS",
		"callsign": "[CANAL TÁCTICO // 4.8 MHz]",
		"color": Color(0.95, 0.75, 0.2, 1.0),
		"text": "—¡Sable-7, responde! ¿Sigues consciente?... Las lecturas de biopeligro en tu nivel están fuera de escala. El muro de contención del Sector C-4 colapsó por completo.",
		"sound_pitch": 1.05
	},
	{
		"speaker": "SABLE-7 (ALEX COLE)",
		"callsign": "[UNIDAD DE RECONOCIMIENTO]",
		"color": Color(0.3, 0.7, 1.0, 1.0),
		"text": "—Ramos... sigo de pie, pero este lugar es un matadero. Las luces parpadean y el hedor a putrefacción llena los pasillos. Los sujetos de prueba rompieron las esclusas... y mutaron.",
		"sound_pitch": 0.95
	},
	{
		"speaker": "OPERADOR RAMOS",
		"callsign": "[BASE BASTIÓN]",
		"color": Color(0.95, 0.75, 0.2, 1.0),
		"text": "—El helicóptero de extracción está en camino a la azotea, pero los sistemas de seguridad tienen bloqueado el ascensor de carga por presencia biológica hostil. ¡No hay paso mientras sigan vivos!",
		"sound_pitch": 1.1
	},
	{
		"speaker": "OPERADOR RAMOS",
		"callsign": "[BASE BASTIÓN]",
		"color": Color(0.95, 0.75, 0.2, 1.0),
		"text": "—Tu orden de supervivencia es directa: elimina a todos los especímenes del sector para purgar el bloqueo del ascensor. Mantén distancia con tu Dash táctico y haz que cada bala cuente.",
		"sound_pitch": 1.05
	},
	{
		"speaker": "SABLE-7 (ALEX COLE)",
		"callsign": "[UNIDAD DE RECONOCIMIENTO]",
		"color": Color(0.3, 0.7, 1.0, 1.0),
		"text": "—Cargador lleno y chaleco asegurado. Si no logro limpiar la zona en diez minutos... sellen las compuertas desde arriba y no miren atrás. Aquí vienen...",
		"sound_pitch": 0.92
	}
]

const GAME_OVER_LOG: Dictionary = {
	"title": "REGISTRO FINAL DE CAJA NEGRA // ARCHIVO DESCLASIFICADO",
	"transmission": "[SISTEMA DE MONITOREO BIOMÉTRICO]: Signos vitales de Sable-7: CERO.",
	"text": "\"...El chaleco no resistió el asalto continuo. Eran demasiados... Los mordiscos me destrozaron el hombro y ya no puedo sostener el arma. La sangre caliente me nubla la vista y las sombras avanzan devorando la poca luz que quedaba.\n\nRamos... si encuentras este registro entre los escombros... no envíes más hombres. El virus no muere con plomo... Quemen... quemen todo el complejo...\"",
	"command_note": "[BASE BASTIÓN]: Enlace neural perdido. Sector C-4 declarado Zona Roja Irrecuperable. Protocolo de cuarentena e incineración orbital activado."
}

const VICTORY_LOG: Dictionary = {
	"title": "TRANSMISIÓN DE EXTRACCIÓN // ZONA CERO DESPEJADA",
	"transmission": "[CONFIRMACIÓN RADAR TÁCTICO]: Cero firmas térmicas hostiles en el sector.",
	"text": "—¡Sable-7, tus sensores térmicos muestran el sector totalmente limpio! ¡Increíble que lo hayas logrado solo!\n\nEl ascensor de carga se energizó y el Black Hawk de rescate ya está en posición sobre la azotea desplegando cable de sujeción.\n\n—Subiendo a la azotea, Ramos. La horda fue purgada, pero aseguré el disco con las muestras genéticas... Este brote no fue un fallo técnico. Alguien liberó la cepa intencionalmente.\n\n—Asegura la carga y sube de inmediato, soldado. Buen trabajo. Dejemos que los bombardeos aéreos borren esta pesadilla del mapa.",
	"command_note": "[ESTADO]: Misión Cumplida. Sable-7 evacuado con éxito. Sujeto en cuarentena preventiva."
}
