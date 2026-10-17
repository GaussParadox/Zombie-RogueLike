extends CanvasLayer

# =============================================================================
#  DIALOGUE BOX — Interfaz de Diálogos y Transmisiones Narrativas
#  Zombie Roguelike · Godot 4
# =============================================================================

signal dialogue_started
signal line_finished
signal dialogue_completed

@onready var _panel: PanelContainer = $Control/MarginContainer/PanelContainer
@onready var _speaker_label: Label = $Control/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HeaderRow/SpeakerLabel
@onready var _callsign_label: Label = $Control/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HeaderRow/CallsignLabel
@onready var _dialogue_label: RichTextLabel = $Control/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/DialogueLabel
@onready var _next_button: Button = $Control/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/FooterRow/NextButton
@onready var _skip_button: Button = $Control/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/FooterRow/SkipButton

var _dialogues: Array[Dictionary] = []
var _current_index: int = 0
var _is_typing: bool = false
var _typewriter_tween: Tween
var _full_text: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_next_button.pressed.connect(_on_next_pressed)
	_skip_button.pressed.connect(_on_skip_pressed)
	hide()

func start_dialogues(dialogue_list: Array[Dictionary]) -> void:
	if dialogue_list.is_empty():
		dialogue_completed.emit()
		return

	_dialogues = dialogue_list
	_current_index = 0
	show()
	_display_current_line()
	dialogue_started.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_on_next_pressed()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_focus_next"):
		get_viewport().set_input_as_handled()
		_on_skip_pressed()

func _display_current_line() -> void:
	if _current_index >= _dialogues.size():
		_finish_dialogue()
		return

	var current: Dictionary = _dialogues[_current_index]
	_speaker_label.text = current.get("speaker", "TRANSMISIÓN")
	_callsign_label.text = current.get("callsign", "")
	var color: Color = current.get("color", Color(1, 1, 1, 1))
	_speaker_label.modulate = color

	_full_text = current.get("text", "")
	_dialogue_label.text = _full_text
	_dialogue_label.visible_characters = 0

	var sound_pitch: float = current.get("sound_pitch", 1.0)
	AudioManager.play_radio_blip(sound_pitch, -4.0)

	_is_typing = true
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	var char_count: int = _full_text.length()
	var duration: float = maxf(char_count * 0.02, 0.6) # ~50 caracteres por segundo

	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(_dialogue_label, "visible_characters", char_count, duration)
	_typewriter_tween.finished.connect(_on_typing_finished)

	_next_button.text = "Continuar [Espacio]"
	_next_button.grab_focus()

func _on_typing_finished() -> void:
	_is_typing = false
	_dialogue_label.visible_characters = -1
	line_finished.emit()

func _on_next_pressed() -> void:
	if _is_typing:
		# Si está escribiendo, autocompletar el texto de inmediato
		if _typewriter_tween and _typewriter_tween.is_valid():
			_typewriter_tween.kill()
		_dialogue_label.visible_characters = -1
		_is_typing = false
		line_finished.emit()
	else:
		_current_index += 1
		if _current_index < _dialogues.size():
			_display_current_line()
		else:
			_finish_dialogue()

func _on_skip_pressed() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	_finish_dialogue()

func _finish_dialogue() -> void:
	hide()
	dialogue_completed.emit()
