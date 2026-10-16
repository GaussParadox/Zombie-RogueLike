extends Node

# =============================================================================
#  AUDIO MANAGER — Sistema de Audio Global y Síntesis Procedural
#  Zombie Roguelike · Godot 4
# =============================================================================
#
#  Características:
#    · Nodos AudioStreamPlayer para música y efectos polifónicos.
#    · Síntesis procedural pura de audio en GDScript (AudioStreamWAV PCM 16-bit):
#        1. Música ambiental para menús (loop armónico relajante/misterioso)
#        2. Música ambiental tensa para el nivel (loop de terror / drone)
#        3. Disparo del arma (transitorio + ruido blanco filtrado + decaimiento)
#        4. Impacto de bala (golpe con crunch)
#        5. Gruñido de zombi (síntesis FM gutural a baja frecuencia)
#        6. Daño en el escudo/chaleco (resonancia metálica y deflexión)
#    · No requiere ningún asset externo (.mp3/.wav/.ogg).
# =============================================================================

# ---------------------------------------------------------------------------
#  Nodos internos de audio
# ---------------------------------------------------------------------------
var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 12
var _current_sfx_idx: int = 0

# ---------------------------------------------------------------------------
#  Streams de audio sintetizados
# ---------------------------------------------------------------------------
var stream_music_menu: AudioStreamWAV
var stream_music_game: AudioStreamWAV
var stream_shoot: AudioStreamWAV
var stream_bullet_hit: AudioStreamWAV
var stream_zombie_groan: AudioStreamWAV
var stream_shield_hit: AudioStreamWAV

# Pista actual reproduciéndose
var _current_track: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_nodes()
	_synthesize_all_audio()


# ===========================================================================
#  CONFIGURACIÓN DE NODOS
# ===========================================================================

func _setup_audio_nodes() -> void:
	# Reproductor de música ambiental
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	_music_player.volume_db = -6.0
	add_child(_music_player)

	# Pool de reproductores para SFX polifónicos
	for i in _sfx_pool_size:
		var sfx_p := AudioStreamPlayer.new()
		sfx_p.name = "SFXPlayer_%d" % i
		sfx_p.bus = "Master"
		add_child(sfx_p)
		_sfx_pool.append(sfx_p)


# ===========================================================================
#  CONTROL DE MÚSICA AMBIENTAL
# ===========================================================================

## Reproduce la pista ambiental para los menús.
func play_menu_music() -> void:
	if _current_track == "menu" and _music_player.playing:
		return
	_current_track = "menu"
	_music_player.stream = stream_music_menu
	_music_player.volume_db = -8.0
	_music_player.play()


## Reproduce la pista ambiental tensa para el nivel del edificio.
func play_game_music() -> void:
	if _current_track == "game" and _music_player.playing:
		return
	_current_track = "game"
	_music_player.stream = stream_music_game
	_music_player.volume_db = -6.0
	_music_player.play()


## Detiene la música actual.
func stop_music() -> void:
	_current_track = ""
	_music_player.stop()


# ===========================================================================
#  REPRODUCCIÓN DE EFECTOS DE SONIDO (SFX)
# ===========================================================================

## Reproduce un stream en el pool polifónico con variación de pitch y volumen.
func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null or _sfx_pool.is_empty():
		return
	var player := _sfx_pool[_current_sfx_idx]
	_current_sfx_idx = (_current_sfx_idx + 1) % _sfx_pool_size

	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.play()


## Efecto de disparo del arma con ligero pitch aleatorio.
func play_shoot(pitch_scale: float = 1.0, volume_db: float = -2.0) -> void:
	play_sfx(stream_shoot, pitch_scale, volume_db)


## Efecto de impacto de bala.
func play_bullet_hit(pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	play_sfx(stream_bullet_hit, pitch_scale, volume_db)


## Efecto de gruñido del zombi al acercarse.
func play_zombie_groan(pitch_scale: float = 1.0, volume_db: float = -3.0) -> void:
	play_sfx(stream_zombie_groan, pitch_scale, volume_db)


## Efecto de daño absorbido por el chaleco/escudo.
func play_shield_hit(pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	play_sfx(stream_shield_hit, pitch_scale, volume_db)


# ===========================================================================
#  SÍNTESIS PROCEDURAL (AudioStreamWAV PCM 16-bit)
# ===========================================================================

func _synthesize_all_audio() -> void:
	stream_shoot = _synth_shoot()
	stream_bullet_hit = _synth_bullet_hit()
	stream_zombie_groan = _synth_zombie_groan()
	stream_shield_hit = _synth_shield_hit()
	stream_music_menu = _synth_music_menu()
	stream_music_game = _synth_music_game()


## Convierte un arreglo de floats (-1.0 a 1.0) en un AudioStreamWAV PCM de 16 bits.
func _create_wav(samples: PackedFloat32Array, mix_rate: int = 22050, loop: bool = false) -> AudioStreamWAV:
	var count := samples.size()
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	for i in count:
		var s := clampf(samples[i], -1.0, 1.0)
		var val_s16 := int(s * 32767.0)
		bytes.encode_s16(i * 2, val_s16)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = count
	return wav


## Disparo: transitorio punzante con caída rápida de frecuencia y estallido de ruido.
func _synth_shoot() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.22
	var count := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)

	var phase := 0.0
	for i in count:
		var t := float(i) / rate
		var env := exp(-t * 22.0)
		var freq := 50.0 + 350.0 * exp(-t * 35.0)
		phase += TAU * freq / rate
		var tone := sin(phase) * 0.45
		var noise := (randf() * 2.0 - 1.0) * 0.55
		samples[i] = (tone + noise) * env
	return _create_wav(samples, rate, false)


## Impacto de bala: thud sordo con golpe de choque y crujido filtrado.
func _synth_bullet_hit() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.15
	var count := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)

	var phase := 0.0
	for i in count:
		var t := float(i) / rate
		var env := exp(-t * 28.0)
		var freq := 60.0 + 180.0 * exp(-t * 30.0)
		phase += TAU * freq / rate
		var tone := sin(phase) * 0.5
		var noise := (randf() * 2.0 - 1.0) * 0.5 * exp(-t * 40.0)
		samples[i] = (tone + noise) * env
	return _create_wav(samples, rate, false)


## Gruñido de zombi: modulación de frecuencia gutural en rango bajo (~65Hz) con LFO.
func _synth_zombie_groan() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.65
	var count := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)

	var phase := 0.0
	for i in count:
		var t := float(i) / rate
		var env := sin(PI * (t / duration)) * exp(-t * 1.5)
		var lfo := sin(TAU * 12.0 * t)
		var freq := 65.0 + 20.0 * lfo
		phase += TAU * freq / rate
		var tone := sin(phase) + 0.4 * sin(phase * 2.0) + 0.2 * (randf() * 2.0 - 1.0)
		samples[i] = tone * env * 0.5
	return _create_wav(samples, rate, false)


## Escudo/Chaleco: deflexión metálica con armónicos resonantes de alta frecuencia.
func _synth_shield_hit() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.25
	var count := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)

	for i in count:
		var t := float(i) / rate
		var env := exp(-t * 16.0)
		var ring1 := sin(TAU * 880.0 * t) * 0.35
		var ring2 := sin(TAU * 1320.0 * t) * 0.25
		var sizzle := (randf() * 2.0 - 1.0) * 0.4 * exp(-t * 30.0)
		samples[i] = (ring1 + ring2 + sizzle) * env
	return _create_wav(samples, rate, false)


## Música de Menú: loop armónico relajante y enigmático (acordes menores etéreos).
func _synth_music_menu() -> AudioStreamWAV:
	var rate := 22050
	var duration := 5.0
	var count := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)

	for i in count:
		var t := float(i) / rate
		var lfo1 := 0.7 + 0.3 * sin(TAU * 1.0 * (t / duration))
		var lfo2 := 0.7 + 0.3 * cos(TAU * 2.0 * (t / duration))
		var s1 := sin(TAU * 110.0 * t) * 0.20 * lfo1 # A2
		var s2 := sin(TAU * 131.0 * t) * 0.15 * lfo2 # C3
		var s3 := sin(TAU * 165.0 * t) * 0.15 * lfo1 # E3
		var s4 := sin(TAU * 220.0 * t) * 0.10 * lfo2 # A3
		samples[i] = s1 + s2 + s3 + s4
	return _create_wav(samples, rate, true)


## Música del Nivel: drone tenso y opresivo con disonancia de semitono y pulsaciones.
func _synth_music_game() -> AudioStreamWAV:
	var rate := 22050
	var duration := 4.0
	var count := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)

	for i in count:
		var t := float(i) / rate
		# Disonancia subgrave de segunda menor (55Hz vs 58.5Hz)
		var sub1 := sin(TAU * 55.0 * t) * 0.25
		var sub2 := sin(TAU * 58.5 * t) * 0.20
		# Pulso rítmico simulando latido/impacto distante cada 1.0s
		var beat_t := fmod(t, 1.0)
		var pulse := sin(TAU * 50.0 * beat_t) * exp(-beat_t * 8.0) * 0.35
		# Susurro disonante agudo
		var eerie := (sin(TAU * 440.0 * t) + sin(TAU * 466.0 * t)) * 0.04 * (0.5 + 0.5 * sin(TAU * 0.5 * t))
		samples[i] = sub1 + sub2 + pulse + eerie
	return _create_wav(samples, rate, true)
