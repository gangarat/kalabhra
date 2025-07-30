extends Node

## AudioManager - Advanced Audio System with Spatial Audio and Accessibility
##
## The AudioManager provides comprehensive audio management including spatial audio,
## advanced music systems, accessibility features, and educational audio support.
##
## Key Features:
## - 3D spatial audio with distance attenuation and occlusion
## - Advanced music management with seamless transitions
## - Accessibility features (audio descriptions, sound visualization)
## - Educational audio support (narration, interactive sounds)
## - Dynamic audio mixing and effects processing
## - Browser-optimized streaming and compression
##
## Usage Example:
## ```gdscript
## # Play spatial audio
## AudioManager.play_spatial_sfx("footstep", player_position, {
##     "max_distance": 50.0,
##     "attenuation": 2.0
## })
##
## # Start adaptive music
## AudioManager.start_adaptive_music("exploration", {
##     "intensity": 0.7,
##     "educational_context": "ancient_architecture"
## })
##
## # Enable accessibility features
## AudioManager.enable_audio_descriptions(true)
## AudioManager.set_sound_visualization(true)
## ```

# Audio system signals
signal audio_system_ready()
signal audio_device_changed(device_name: String)
signal spatial_audio_enabled(enabled: bool)

# Playback signals
signal audio_started(audio_id: String, audio_type: String)
signal audio_finished(audio_id: String, audio_type: String)
signal audio_paused(audio_id: String)
signal audio_resumed(audio_id: String)

# Music system signals
signal music_track_changed(track_name: String, previous_track: String)
signal music_intensity_changed(intensity: float)
signal adaptive_music_triggered(trigger: String, context: Dictionary)

# Spatial audio signals
signal spatial_listener_moved(position: Vector3, orientation: Vector3)
signal spatial_source_added(source_id: String, position: Vector3)
signal spatial_source_removed(source_id: String)

# Accessibility signals
signal audio_description_started(description_id: String)
signal sound_visualization_updated(frequency_data: PackedFloat32Array)
signal audio_subtitle_displayed(text: String, duration: float)

## Audio player types
enum AudioPlayerType {
	MUSIC,
	SFX_2D,
	SFX_3D,
	VOICE,
	AMBIENT,
	UI,
	EDUCATIONAL
}

## Spatial audio modes
enum SpatialMode {
	DISABLED,
	SIMPLE,
	ADVANCED,
	HRTF
}

# Core audio players
var music_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer

# Spatial audio system
var is_spatial_audio_enabled: bool = true
var spatial_mode: SpatialMode = SpatialMode.ADVANCED
var audio_listener: AudioListener3D
var spatial_sources: Dictionary = {}
var max_spatial_sources: int = 32

# Audio player pools
var sfx_2d_pool: Array[AudioStreamPlayer] = []
var sfx_3d_pool: Array[AudioStreamPlayer3D] = []
var educational_pool: Array[AudioStreamPlayer] = []
var max_pool_size: int = 16

# Volume and mixing
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var voice_volume: float = 1.0
var ambient_volume: float = 0.6
var ui_volume: float = 1.0
var educational_volume: float = 1.0

# Advanced music system
var current_music_track: String = ""
var music_layers: Dictionary = {}
var adaptive_music_enabled: bool = true
var music_intensity: float = 0.5
var music_transition_time: float = 2.0

# Audio resources and caching
var audio_cache: Dictionary = {}
var streaming_sources: Dictionary = {}
var preloaded_audio: Dictionary = {}

# Audio libraries
var sfx_library: Dictionary = {}
var voice_clips: Dictionary = {}
var ambient_sounds: Dictionary = {}
var music_tracks: Dictionary = {}

# Audio player management
var max_sfx_players: int = 8
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_index: int = 0

# Music system variables
var music_fade_duration: float = 2.0

# Additional signals
signal music_changed(track_name: String)

# Accessibility features
var audio_descriptions_enabled: bool = false
var sound_visualization_enabled: bool = false
var audio_subtitles_enabled: bool = false
var frequency_analyzer: AudioEffectSpectrumAnalyzer

# Educational audio features
var narration_queue: Array[Dictionary] = []
var interactive_audio_zones: Dictionary = {}
var educational_context: String = ""

# Performance and optimization
var audio_quality_level: int = 2  # 0=low, 1=medium, 2=high, 3=ultra
var max_concurrent_sounds: int = 64
var audio_occlusion_enabled: bool = true
var reverb_zones: Dictionary = {}

func _ready():
	_initialize_audio_system()

#region System Management

## Initialize the audio system
func initialize_system() -> bool:
	_setup_audio_players()
	_setup_audio_buses()
	_setup_spatial_audio()
	_setup_accessibility_features()
	_load_audio_resources()
	_connect_signals()

	print("[AudioManager] Audio system initialized successfully")
	audio_system_ready.emit()
	return true

## Get system health status
func get_health_status() -> Dictionary:
	var health = {
		"status": "healthy",
		"active_sources": _count_active_sources(),
		"cached_audio": audio_cache.size(),
		"spatial_sources": spatial_sources.size(),
		"memory_usage_mb": _estimate_audio_memory_usage(),
		"last_check": Time.get_unix_time_from_system()
	}

	# Check for potential issues
	if health["active_sources"] > max_concurrent_sounds * 0.8:
		health["status"] = "warning"
		health["message"] = "High number of concurrent audio sources"

	return health

## Shutdown the audio system
func shutdown_system() -> void:
	_stop_all_audio()
	_clear_audio_cache()
	_save_audio_settings()
	print("[AudioManager] Audio system shutdown completed")

#endregion

#region Spatial Audio System

## Enable or disable spatial audio
## @param enabled: Whether to enable spatial audio
## @param mode: Spatial audio processing mode
func set_spatial_audio_enabled(enabled: bool, mode: SpatialMode = SpatialMode.ADVANCED) -> void:
	is_spatial_audio_enabled = enabled
	spatial_mode = mode

	if enabled:
		_setup_spatial_audio()
	else:
		_disable_spatial_audio()

	spatial_audio_enabled.emit(enabled)

## Play spatial sound effect
## @param sfx_name: Name of the sound effect
## @param position: 3D position for the sound
## @param config: Additional configuration options
## @return: Audio source ID for tracking
func play_spatial_sfx(sfx_name: String, position: Vector3, config: Dictionary = {}) -> String:
	if not is_spatial_audio_enabled:
		# Fallback to 2D audio
		play_sfx(sfx_name, config.get("volume_db", 0.0))
		return ""

	var audio_resource = _get_audio_resource(sfx_name, "sfx")
	if not audio_resource:
		push_error("[AudioManager] Spatial SFX not found: " + sfx_name)
		return ""

	var source_id = _generate_audio_id()
	var player = _get_spatial_player()

	if not player:
		push_warning("[AudioManager] No available spatial audio players")
		return ""

	# Configure spatial properties
	player.global_position = position
	player.max_distance = config.get("max_distance", 50.0)
	player.unit_size = config.get("unit_size", 1.0)
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.attenuation_filter_cutoff_hz = config.get("filter_cutoff", 5000.0)

	# Apply audio effects
	if config.has("reverb_zone"):
		_apply_reverb_zone(player, config["reverb_zone"])

	if audio_occlusion_enabled:
		_setup_occlusion_detection(player, source_id)

	# Play the audio
	player.stream = audio_resource
	player.volume_db = linear_to_db(sfx_volume) + config.get("volume_db", 0.0)
	player.pitch_scale = config.get("pitch", 1.0)
	player.play()

	# Track the source
	spatial_sources[source_id] = {
		"player": player,
		"position": position,
		"sfx_name": sfx_name,
		"start_time": Time.get_unix_time_from_system()
	}

	spatial_source_added.emit(source_id, position)
	audio_started.emit(source_id, "spatial_sfx")

	# Setup cleanup when finished
	player.finished.connect(_on_spatial_audio_finished.bind(source_id), CONNECT_ONE_SHOT)

	return source_id

## Update spatial listener position and orientation
## @param position: Listener position in 3D space
## @param forward: Forward direction vector
## @param up: Up direction vector
func update_spatial_listener(position: Vector3, forward: Vector3 = Vector3.FORWARD, up: Vector3 = Vector3.UP) -> void:
	if not is_spatial_audio_enabled or not audio_listener:
		return

	audio_listener.global_position = position
	audio_listener.look_at(position + forward, up)

	spatial_listener_moved.emit(position, forward)

## Create an interactive audio zone
## @param zone_id: Unique identifier for the zone
## @param position: Center position of the zone
## @param radius: Radius of the zone
## @param audio_config: Audio configuration for the zone
func create_audio_zone(zone_id: String, position: Vector3, radius: float, audio_config: Dictionary) -> void:
	interactive_audio_zones[zone_id] = {
		"position": position,
		"radius": radius,
		"config": audio_config,
		"active": false
	}

## Remove an interactive audio zone
## @param zone_id: Zone to remove
func remove_audio_zone(zone_id: String) -> void:
	if interactive_audio_zones.has(zone_id):
		var zone = interactive_audio_zones[zone_id]
		if zone["active"]:
			_deactivate_audio_zone(zone_id)
		interactive_audio_zones.erase(zone_id)

#endregion

#region Advanced Music System

## Start adaptive music that responds to game context
## @param track_name: Base music track name
## @param config: Configuration for adaptive behavior
func start_adaptive_music(track_name: String, config: Dictionary = {}) -> void:
	if not adaptive_music_enabled:
		play_music(track_name)
		return

	var music_data = _get_music_data(track_name)
	if music_data.is_empty():
		push_error("[AudioManager] Adaptive music track not found: " + track_name)
		return

	# Setup music layers
	_setup_music_layers(music_data, config)

	# Set initial intensity
	music_intensity = config.get("intensity", 0.5)
	educational_context = config.get("educational_context", "")

	# Start base layer
	_start_music_layer("base", music_data["base_track"])

	current_music_track = track_name
	music_track_changed.emit(track_name, "")

## Adjust music intensity dynamically
## @param intensity: Intensity level (0.0 to 1.0)
## @param transition_time: Time to transition to new intensity
func set_music_intensity(intensity: float, transition_time: float = 2.0) -> void:
	if not adaptive_music_enabled:
		return

	intensity = clamp(intensity, 0.0, 1.0)
	var old_intensity = music_intensity
	music_intensity = intensity

	_adjust_music_layers(intensity, transition_time)
	music_intensity_changed.emit(intensity)

## Trigger adaptive music event
## @param trigger: Event trigger name
## @param context: Additional context data
func trigger_adaptive_music(trigger: String, context: Dictionary = {}) -> void:
	if not adaptive_music_enabled or current_music_track.is_empty():
		return

	var music_data = _get_music_data(current_music_track)
	if music_data.has("triggers") and music_data["triggers"].has(trigger):
		var trigger_config = music_data["triggers"][trigger]
		_execute_music_trigger(trigger_config, context)
		adaptive_music_triggered.emit(trigger, context)

## Play background music with advanced options
## @param track_name: Music track name
## @param config: Playback configuration
func play_music(track_name: String, config: Dictionary = {}) -> void:
	if track_name == current_music_track and not config.get("force_restart", false):
		return

	var music_resource = _get_audio_resource(track_name, "music")
	if not music_resource:
		push_warning("[AudioManager] Music track not found: " + track_name)
		return

	var fade_in = config.get("fade_in", true)
	var loop = config.get("loop", true)
	var crossfade = config.get("crossfade", true)

	if crossfade and music_player.playing:
		_crossfade_music(music_resource, track_name, fade_in, loop)
	else:
		_play_music_direct(music_resource, track_name, fade_in, loop)

## Stop current music
## @param fade_out: Whether to fade out the music
## @param stop_adaptive: Whether to stop adaptive music system
func stop_music(fade_out: bool = true, stop_adaptive: bool = true) -> void:
	if stop_adaptive:
		_stop_adaptive_music()

	if fade_out:
		_fade_out_music()
	else:
		music_player.stop()
		current_music_track = ""

#endregion

#region Accessibility Features

## Enable or disable audio descriptions
## @param enabled: Whether to enable audio descriptions
func enable_audio_descriptions(enabled: bool) -> void:
	audio_descriptions_enabled = enabled

	if enabled:
		_setup_audio_descriptions()
	else:
		_disable_audio_descriptions()

## Enable or disable sound visualization
## @param enabled: Whether to enable sound visualization
func set_sound_visualization(enabled: bool) -> void:
	sound_visualization_enabled = enabled

	if enabled:
		_setup_sound_visualization()
	else:
		_disable_sound_visualization()

## Enable or disable audio subtitles
## @param enabled: Whether to enable audio subtitles
func enable_audio_subtitles(enabled: bool) -> void:
	audio_subtitles_enabled = enabled

## Play audio description
## @param description_id: ID of the description to play
## @param text: Text content of the description
## @param priority: Playback priority
func play_audio_description(description_id: String, text: String, priority: int = 1) -> void:
	if not audio_descriptions_enabled:
		return

	# Generate or load audio description
	var audio_resource = _get_or_generate_audio_description(description_id, text)
	if not audio_resource:
		return

	# Play with appropriate priority
	var player = _get_educational_player()
	if player:
		player.stream = audio_resource
		player.volume_db = linear_to_db(educational_volume)
		player.play()

		audio_description_started.emit(description_id)

		# Show subtitle if enabled
		if audio_subtitles_enabled:
			_show_audio_subtitle(text, audio_resource.get_length())

## Update sound visualization data
func _update_sound_visualization() -> void:
	if not sound_visualization_enabled or not frequency_analyzer:
		return

	var spectrum = frequency_analyzer.get_magnitude_for_frequency_range(20, 20000)
	var frequency_data = PackedFloat32Array()

	# Sample frequency bands for visualization
	for i in range(64):  # 64 frequency bands
		var freq = 20.0 * pow(1000.0, float(i) / 63.0)  # Logarithmic scale
		var magnitude = frequency_analyzer.get_magnitude_for_frequency_range(freq, freq * 1.1).length()
		frequency_data.append(magnitude)

	sound_visualization_updated.emit(frequency_data)

#endregion

## Play sound effect
func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var sfx_resource = sfx_library.get(sfx_name)
	if not sfx_resource:
		push_warning("SFX not found: " + sfx_name)
		return
	
	var player = _get_available_sfx_player()
	player.stream = sfx_resource
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

## Play voice clip
func play_voice(clip_name: String, interrupt_current: bool = true) -> void:
	var voice_resource = voice_clips.get(clip_name)
	if not voice_resource:
		push_warning("Voice clip not found: " + clip_name)
		return
	
	if voice_player.playing and not interrupt_current:
		return
	
	voice_player.stream = voice_resource
	voice_player.play()

## Play ambient sound
func play_ambient(ambient_name: String, fade_in: bool = true, loop: bool = true) -> void:
	var ambient_resource = ambient_sounds.get(ambient_name)
	if not ambient_resource:
		push_warning("Ambient sound not found: " + ambient_name)
		return
	
	ambient_player.stream = ambient_resource
	
	if loop and ambient_resource is AudioStreamOggVorbis:
		ambient_resource.loop = true
	elif loop and ambient_resource is AudioStreamWAV:
		ambient_resource.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	if fade_in:
		ambient_player.volume_db = -80.0
		ambient_player.play()
		_fade_in_audio(ambient_player, ambient_volume)
	else:
		ambient_player.volume_db = linear_to_db(ambient_volume)
		ambient_player.play()

## Stop ambient sound
func stop_ambient(fade_out: bool = true) -> void:
	if fade_out:
		_fade_out_audio(ambient_player)
	else:
		ambient_player.stop()

## Set master volume
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

## Set music volume
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))

## Set SFX volume
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))

## Set voice volume
func set_voice_volume(volume: float) -> void:
	voice_volume = clamp(volume, 0.0, 1.0)
	var voice_bus = AudioServer.get_bus_index("Voice")
	if voice_bus != -1:
		AudioServer.set_bus_volume_db(voice_bus, linear_to_db(voice_volume))

## Preload audio resource
func preload_audio(resource_path: String, category: String) -> void:
	# Load synchronously since ResourceManager is disabled
	var resource = load(resource_path)
	if resource:
		_on_audio_resource_loaded(resource_path, category, resource)

## Check if music is playing
func is_music_playing() -> bool:
	return music_player.playing

## Get current music track
func get_current_music_track() -> String:
	return current_music_track

# Private methods

func _setup_audio_players() -> void:
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# SFX players pool
	for i in range(max_sfx_players):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		sfx_players.append(sfx_player)
		add_child(sfx_player)
	
	# Voice player
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "Voice"
	add_child(voice_player)
	
	# Ambient player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Ambient"
	add_child(ambient_player)

func _setup_audio_buses() -> void:
	# Create audio buses if they don't exist
	var buses_to_create = ["Music", "SFX", "Voice", "Ambient", "Educational"]
	for bus_name in buses_to_create:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var bus_index = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(bus_index, bus_name)
			AudioServer.set_bus_send(bus_index, "Master")

func _load_audio_resources() -> void:
	# Load audio resource definitions
	var audio_config_path = "res://resources/data/audio_config.json"
	var file = FileAccess.open(audio_config_path, FileAccess.READ)
	
	if not file:
		push_warning("Audio config file not found: " + audio_config_path)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse audio config")
		return
	
	var audio_config = json.data
	
	# Load music tracks
	if audio_config.has("music"):
		for track_name in audio_config["music"].keys():
			var track_path = audio_config["music"][track_name]
			music_tracks[track_name] = load(track_path)
	
	# Load SFX
	if audio_config.has("sfx"):
		for sfx_name in audio_config["sfx"].keys():
			var sfx_path = audio_config["sfx"][sfx_name]
			sfx_library[sfx_name] = load(sfx_path)
	
	# Load voice clips
	if audio_config.has("voice"):
		for clip_name in audio_config["voice"].keys():
			var clip_path = audio_config["voice"][clip_name]
			voice_clips[clip_name] = load(clip_path)
	
	# Load ambient sounds
	if audio_config.has("ambient"):
		for ambient_name in audio_config["ambient"].keys():
			var ambient_path = audio_config["ambient"][ambient_name]
			ambient_sounds[ambient_name] = load(ambient_path)

func _connect_config_signals() -> void:
	if ConfigManager:
		ConfigManager.setting_changed.connect(_on_setting_changed)

func _get_available_sfx_player() -> AudioStreamPlayer:
	# Round-robin selection of SFX players
	var player = sfx_players[sfx_player_index]
	sfx_player_index = (sfx_player_index + 1) % max_sfx_players
	return player

func _play_music_direct(music_resource: AudioStream, track_name: String, fade_in: bool, loop: bool) -> void:
	music_player.stream = music_resource
	
	# Set loop mode
	if loop and music_resource is AudioStreamOggVorbis:
		music_resource.loop = true
	elif loop and music_resource is AudioStreamWAV:
		music_resource.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	if fade_in:
		music_player.volume_db = -80.0
		music_player.play()
		_fade_in_audio(music_player, music_volume)
	else:
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play()
	
	current_music_track = track_name
	music_changed.emit(track_name)

func _crossfade_music(new_music_resource: AudioStream, track_name: String, fade_in: bool, loop: bool) -> void:
	# Create temporary player for crossfade
	var temp_player = AudioStreamPlayer.new()
	temp_player.bus = "Music"
	add_child(temp_player)
	
	temp_player.stream = new_music_resource
	
	# Set loop mode
	if loop and new_music_resource is AudioStreamOggVorbis:
		new_music_resource.loop = true
	elif loop and new_music_resource is AudioStreamWAV:
		new_music_resource.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	temp_player.volume_db = -80.0
	temp_player.play()
	
	# Crossfade
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out current music
	tween.tween_method(_set_player_volume, music_player.volume_db, -80.0, music_fade_duration).bind(music_player)
	
	# Fade in new music
	tween.tween_method(_set_player_volume, -80.0, linear_to_db(music_volume), music_fade_duration).bind(temp_player)
	
	await tween.finished
	
	# Switch players
	music_player.stop()
	music_player.queue_free()
	music_player = temp_player
	
	current_music_track = track_name
	music_changed.emit(track_name)

func _fade_in_audio(player: AudioStreamPlayer, target_volume: float) -> void:
	var tween = create_tween()
	tween.tween_method(_set_player_volume, -80.0, linear_to_db(target_volume), music_fade_duration).bind(player)

func _fade_out_audio(player: AudioStreamPlayer) -> void:
	var tween = create_tween()
	tween.tween_method(_set_player_volume, player.volume_db, -80.0, music_fade_duration).bind(player)
	await tween.finished
	player.stop()

func _fade_out_music() -> void:
	var tween = create_tween()
	tween.tween_method(_set_player_volume, music_player.volume_db, -80.0, music_fade_duration).bind(music_player)
	await tween.finished
	music_player.stop()
	current_music_track = ""

func _set_player_volume(volume_db: float, player: AudioStreamPlayer) -> void:
	player.volume_db = volume_db

func _on_audio_resource_loaded(resource_path: String, category: String, resource: Resource) -> void:
	if not resource:
		return
	
	var resource_name = resource_path.get_file().get_basename()
	
	match category:
		"music":
			music_tracks[resource_name] = resource
		"sfx":
			sfx_library[resource_name] = resource
		"voice":
			voice_clips[resource_name] = resource
		"ambient":
			ambient_sounds[resource_name] = resource

func _on_setting_changed(category: String, key: String, value) -> void:
	if category == "game":
		match key:
			"master_volume":
				set_master_volume(value)
			"music_volume":
				set_music_volume(value)
			"sfx_volume":
				set_sfx_volume(value)
			"voice_volume":
				set_voice_volume(value)

# Missing function implementations

func _initialize_audio_system() -> void:
	initialize_system()

func _count_active_sources() -> int:
	var count = 0
	for player in sfx_players:
		if player.playing:
			count += 1
	if music_player and music_player.playing:
		count += 1
	if voice_player and voice_player.playing:
		count += 1
	if ambient_player and ambient_player.playing:
		count += 1
	return count

func _estimate_audio_memory_usage() -> float:
	var total_size = 0.0
	for audio_stream in audio_cache.values():
		if audio_stream is AudioStream:
			# Rough estimate based on typical audio stream sizes
			total_size += 1.0  # MB per stream (rough estimate)
	return total_size

func _stop_all_audio() -> void:
	if music_player:
		music_player.stop()
	if voice_player:
		voice_player.stop()
	if ambient_player:
		ambient_player.stop()
	for player in sfx_players:
		player.stop()

func _clear_audio_cache() -> void:
	audio_cache.clear()
	streaming_sources.clear()
	preloaded_audio.clear()

func _save_audio_settings() -> void:
	if ConfigManager:
		ConfigManager.set_setting("game", "master_volume", master_volume)
		ConfigManager.set_setting("game", "music_volume", music_volume)
		ConfigManager.set_setting("game", "sfx_volume", sfx_volume)
		ConfigManager.set_setting("game", "voice_volume", voice_volume)

func _disable_spatial_audio() -> void:
	is_spatial_audio_enabled = false
	# Clean up spatial audio components
	for source in spatial_sources.values():
		if source is AudioStreamPlayer3D:
			source.queue_free()
	spatial_sources.clear()

func _connect_signals() -> void:
	_connect_config_signals()
	# Connect other internal signals as needed

# Additional missing functions for AudioManager

func _setup_spatial_audio() -> void:
	if not is_spatial_audio_enabled:
		return

	# Create audio listener if needed
	if not audio_listener:
		audio_listener = AudioListener3D.new()
		add_child(audio_listener)

	print("[AudioManager] Spatial audio system initialized")

func _setup_accessibility_features() -> void:
	if audio_descriptions_enabled:
		_setup_audio_descriptions()
	if sound_visualization_enabled:
		_setup_sound_visualization()

func _get_audio_resource(audio_name: String, category: String) -> AudioStream:
	match category:
		"music":
			return music_tracks.get(audio_name)
		"sfx":
			return sfx_library.get(audio_name)
		"voice":
			return voice_clips.get(audio_name)
		"ambient":
			return ambient_sounds.get(audio_name)
		_:
			return null

func _generate_audio_id() -> String:
	return "audio_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func _get_spatial_player() -> AudioStreamPlayer3D:
	# Find available 3D player from pool
	for player in sfx_3d_pool:
		if not player.playing:
			return player

	# Create new player if pool not full
	if sfx_3d_pool.size() < max_pool_size:
		var player = AudioStreamPlayer3D.new()
		player.bus = "SFX"
		sfx_3d_pool.append(player)
		add_child(player)
		return player

	# Return first player (will interrupt)
	return sfx_3d_pool[0]

func _apply_reverb_zone(player: AudioStreamPlayer3D, zone_data: Dictionary) -> void:
	# Apply reverb effects based on zone data
	pass

func _setup_occlusion_detection(player: AudioStreamPlayer3D, source_id: String) -> void:
	# Setup audio occlusion detection
	pass

func _on_spatial_audio_finished(audio_id: String) -> void:
	audio_finished.emit(audio_id, "spatial")

func _deactivate_audio_zone(zone_id: String) -> void:
	if interactive_audio_zones.has(zone_id):
		interactive_audio_zones.erase(zone_id)

func _get_music_data(track_name: String) -> Dictionary:
	return {
		"name": track_name,
		"resource": music_tracks.get(track_name),
		"layers": music_layers.get(track_name, {}),
		"intensity": music_intensity
	}

func _setup_music_layers(track_name: String, layers: Dictionary) -> void:
	music_layers[track_name] = layers

func _start_music_layer(layer_name: String, track_name: String) -> void:
	if music_layers.has(track_name) and music_layers[track_name].has(layer_name):
		# Start specific music layer
		pass

func _adjust_music_layers(intensity: float, transition_time: float = 2.0) -> void:
	# Adjust music layers based on intensity
	music_intensity = intensity

func _execute_music_trigger(trigger: String, context: Dictionary) -> void:
	adaptive_music_triggered.emit(trigger, context)

func _stop_adaptive_music() -> void:
	# Stop adaptive music system
	pass

func _setup_audio_descriptions() -> void:
	# Setup audio description system
	pass

func _disable_audio_descriptions() -> void:
	audio_descriptions_enabled = false

func _setup_sound_visualization() -> void:
	# Setup sound visualization system
	if not frequency_analyzer:
		frequency_analyzer = AudioEffectSpectrumAnalyzer.new()

func _disable_sound_visualization() -> void:
	sound_visualization_enabled = false

func _get_or_generate_audio_description(description_id: String, text: String) -> AudioStream:
	# Generate or return audio description resource
	# For now, return null as this would need TTS implementation
	return null

func _get_educational_player() -> AudioStreamPlayer:
	# Find available educational player from pool
	for player in educational_pool:
		if not player.playing:
			return player

	# Create new player if pool not full
	if educational_pool.size() < max_pool_size:
		var player = AudioStreamPlayer.new()
		player.bus = "Educational"
		educational_pool.append(player)
		add_child(player)
		return player

	# Return first player (will interrupt)
	return educational_pool[0]

func _show_audio_subtitle(text: String, duration: float) -> void:
	audio_subtitle_displayed.emit(text, duration)
