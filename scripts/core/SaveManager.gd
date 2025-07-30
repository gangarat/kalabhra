extends Node

## Save Manager
## Handles persistent data storage for player progress and educational assessment data
## Browser-compatible using localStorage and IndexedDB through Godot's user:// system

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_failed(slot: int, error: String)
signal auto_save_triggered()

# Save data structure
var current_save_data: Dictionary = {}
var save_slots: Array[Dictionary] = []
var max_save_slots: int = 5

# Auto-save settings
var auto_save_enabled: bool = true
var auto_save_interval: float = 300.0  # 5 minutes
var auto_save_timer: Timer

# File paths
var save_directory: String = "user://saves/"
var save_file_prefix: String = "kalabhra_save_"
var save_file_extension: String = ".json"
var progress_file: String = "user://progress.json"
var assessment_file: String = "user://assessments.json"

# Encryption (optional for sensitive educational data)
var use_encryption: bool = false
var encryption_key: String = "kalabhra_education_key"

func _ready():
	_initialize_save_system()
	_setup_auto_save()
	_load_save_slots()

## Save current game state to specified slot
func save_game(slot: int = 0, custom_name: String = "") -> bool:
	if slot < 0 or slot >= max_save_slots:
		save_failed.emit(slot, "Invalid save slot")
		return false
	
	var save_data = _collect_save_data()
	save_data["save_name"] = custom_name if not custom_name.is_empty() else _generate_save_name()
	save_data["timestamp"] = Time.get_unix_time_from_system()
	save_data["version"] = ProjectSettings.get_setting("application/config/version", "1.0")
	
	var success = _write_save_file(slot, save_data)
	
	if success:
		save_slots[slot] = _create_save_slot_info(save_data)
		current_save_data = save_data
		save_completed.emit(slot)
	else:
		save_failed.emit(slot, "Failed to write save file")
	
	return success

## Load game state from specified slot
func load_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= max_save_slots:
		load_failed.emit(slot, "Invalid save slot")
		return false
	
	var save_data = _read_save_file(slot)
	
	if save_data.is_empty():
		load_failed.emit(slot, "Save file not found or corrupted")
		return false
	
	var success = _apply_save_data(save_data)
	
	if success:
		current_save_data = save_data
		load_completed.emit(slot)
	else:
		load_failed.emit(slot, "Failed to apply save data")
	
	return success

## Quick save to slot 0
func quick_save() -> bool:
	return save_game(0, "Quick Save")

## Quick load from slot 0
func quick_load() -> bool:
	return load_game(0)

## Auto-save current progress
func auto_save() -> void:
	if auto_save_enabled:
		auto_save_triggered.emit()
		save_game(0, "Auto Save")

## Save educational progress data
func save_progress_data(progress_data: Dictionary) -> bool:
	var file = FileAccess.open(progress_file, FileAccess.WRITE)
	if not file:
		return false
	
	var json_string = JSON.stringify(progress_data, "\t")
	if use_encryption:
		json_string = _encrypt_data(json_string)
	
	file.store_string(json_string)
	file.close()
	return true

## Load educational progress data
func load_progress_data() -> Dictionary:
	var file = FileAccess.open(progress_file, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	if use_encryption:
		json_string = _decrypt_data(json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	return json.data

## Save assessment data
func save_assessment_data(assessment_data: Dictionary) -> bool:
	var existing_data = load_assessment_data()
	existing_data.merge(assessment_data)
	
	var file = FileAccess.open(assessment_file, FileAccess.WRITE)
	if not file:
		return false
	
	var json_string = JSON.stringify(existing_data, "\t")
	if use_encryption:
		json_string = _encrypt_data(json_string)
	
	file.store_string(json_string)
	file.close()
	return true

## Load assessment data
func load_assessment_data() -> Dictionary:
	var file = FileAccess.open(assessment_file, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	if use_encryption:
		json_string = _decrypt_data(json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	return json.data

## Get save slot information
func get_save_slot_info(slot: int) -> Dictionary:
	if slot < 0 or slot >= max_save_slots:
		return {}
	
	return save_slots[slot]

## Get all save slots information
func get_all_save_slots() -> Array[Dictionary]:
	return save_slots

## Check if save slot exists
func has_save_data(slot: int) -> bool:
	if slot < 0 or slot >= max_save_slots:
		return false
	
	return not save_slots[slot].is_empty()

## Delete save slot
func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= max_save_slots:
		return false
	
	var file_path = _get_save_file_path(slot)
	
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
	
	save_slots[slot] = {}
	return true

## Set auto-save enabled/disabled
func set_auto_save_enabled(enabled: bool) -> void:
	auto_save_enabled = enabled
	if auto_save_timer:
		auto_save_timer.paused = not enabled

## Set auto-save interval
func set_auto_save_interval(interval: float) -> void:
	auto_save_interval = interval
	if auto_save_timer:
		auto_save_timer.wait_time = interval

# Private methods

func _initialize_save_system() -> void:
	# Create save directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(save_directory):
		DirAccess.open("user://").make_dir_recursive(save_directory)
	
	# Initialize save slots
	save_slots.resize(max_save_slots)
	for i in range(max_save_slots):
		save_slots[i] = {}

func _setup_auto_save() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = auto_save_interval
	auto_save_timer.timeout.connect(auto_save)
	auto_save_timer.autostart = true
	add_child(auto_save_timer)

func _load_save_slots() -> void:
	for i in range(max_save_slots):
		var file_path = _get_save_file_path(i)
		if FileAccess.file_exists(file_path):
			var save_data = _read_save_file(i)
			if not save_data.is_empty():
				save_slots[i] = _create_save_slot_info(save_data)

func _collect_save_data() -> Dictionary:
	var save_data = {}
	
	# Game state
	save_data["scene"] = SceneManager.current_scene_path if SceneManager else ""
	save_data["player_data"] = _get_player_data()
	save_data["game_state"] = _get_game_state()
	save_data["inventory"] = _get_inventory_data()
	save_data["progress"] = load_progress_data()
	save_data["settings"] = _get_settings_data()
	
	return save_data

func _get_player_data() -> Dictionary:
	var player_data = {}
	
	# Find player in current scene
	var player = _find_player()
	if player and player.has_method("get_save_data"):
		player_data = player.get_save_data()
	
	return player_data

func _get_game_state() -> Dictionary:
	var game_state = {}
	
	if GameManager and GameManager.has_method("get_save_data"):
		game_state = GameManager.get_save_data()
	
	return game_state

func _get_inventory_data() -> Dictionary:
	# Implement inventory system integration
	return {}

func _get_settings_data() -> Dictionary:
	if ConfigManager:
		return {
			"game": ConfigManager.get_category_settings("game"),
			"user": ConfigManager.get_category_settings("user")
		}
	return {}

func _apply_save_data(save_data: Dictionary) -> bool:
	# Apply player data
	if save_data.has("player_data"):
		var player = _find_player()
		if player and player.has_method("load_save_data"):
			player.load_save_data(save_data["player_data"])
	
	# Apply game state
	if save_data.has("game_state") and GameManager and GameManager.has_method("load_save_data"):
		GameManager.load_save_data(save_data["game_state"])
	
	# Apply settings
	if save_data.has("settings") and ConfigManager:
		if save_data["settings"].has("game"):
			ConfigManager.set_category_settings("game", save_data["settings"]["game"])
		if save_data["settings"].has("user"):
			ConfigManager.set_category_settings("user", save_data["settings"]["user"])
	
	# Load scene if different
	if save_data.has("scene") and SceneManager:
		var target_scene = save_data["scene"]
		if not target_scene.is_empty() and target_scene != SceneManager.current_scene_path:
			SceneManager.change_scene(target_scene)
	
	return true

func _write_save_file(slot: int, save_data: Dictionary) -> bool:
	var file_path = _get_save_file_path(slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	if use_encryption:
		json_string = _encrypt_data(json_string)
	
	file.store_string(json_string)
	file.close()
	return true

func _read_save_file(slot: int) -> Dictionary:
	var file_path = _get_save_file_path(slot)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	if use_encryption:
		json_string = _decrypt_data(json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	return json.data

func _get_save_file_path(slot: int) -> String:
	return save_directory + save_file_prefix + str(slot) + save_file_extension

func _create_save_slot_info(save_data: Dictionary) -> Dictionary:
	return {
		"name": save_data.get("save_name", ""),
		"timestamp": save_data.get("timestamp", 0),
		"scene": save_data.get("scene", ""),
		"version": save_data.get("version", ""),
		"playtime": save_data.get("playtime", 0)
	}

func _generate_save_name() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "Save %02d/%02d/%04d %02d:%02d" % [
		datetime.month, datetime.day, datetime.year,
		datetime.hour, datetime.minute
	]

func _find_player() -> Node:
	var current_scene = get_tree().current_scene
	if current_scene:
		return current_scene.find_child("Player", true, false)
	return null

func _encrypt_data(data: String) -> String:
	# Simple encryption - in production, use proper encryption
	return data.to_utf8_buffer().compress().get_string_from_utf8()

func _decrypt_data(data: String) -> String:
	# Simple decryption - in production, use proper decryption
	return data.to_utf8_buffer().decompress_dynamic(-1).get_string_from_utf8()
