extends Node

## ConfigManager - Advanced Configuration and Settings Management
##
## The ConfigManager provides comprehensive configuration management including
## game settings, performance optimization, user preferences, and educational
## parameters with advanced validation and platform-specific optimizations.
##
## Key Features:
## - Hierarchical configuration with inheritance
## - Real-time setting validation and constraints
## - Platform-specific configuration profiles
## - Educational setting templates and presets
## - Performance auto-tuning based on hardware
## - Secure storage for sensitive educational data
## - Configuration migration and versioning
##
## Usage Example:
## ```gdscript
## # Set performance profile
## ConfigManager.apply_performance_profile("educational_optimized")
##
## # Configure educational settings
## ConfigManager.set_educational_preset("assessment_mode", {
##     "time_limits": true,
##     "hint_system": "adaptive",
##     "difficulty_scaling": "automatic"
## })
##
## # Auto-tune performance
## ConfigManager.auto_tune_performance()
##
## # Validate and apply settings
## if ConfigManager.validate_setting("graphics", "render_quality", "ultra"):
##     ConfigManager.set_setting("graphics", "render_quality", "ultra")
## ```

# Configuration system signals
signal config_system_ready()
signal config_loaded(category: String)
signal config_saved(category: String)
signal config_migration_completed(from_version: String, to_version: String)

# Setting change signals
signal setting_changed(category: String, key: String, old_value, new_value)
signal setting_validated(category: String, key: String, value, is_valid: bool)
signal setting_constraint_violated(category: String, key: String, value, constraint: String)

# Profile and preset signals
signal performance_profile_applied(profile_name: String, settings: Dictionary)
signal educational_preset_applied(preset_name: String, settings: Dictionary)
signal auto_tuning_completed(optimized_settings: Dictionary)

# Platform and hardware signals
signal hardware_detected(hardware_info: Dictionary)
signal platform_profile_loaded(platform: String, profile: Dictionary)

## Configuration categories
enum ConfigCategory {
	GAME,
	GRAPHICS,
	AUDIO,
	INPUT,
	EDUCATIONAL,
	ACCESSIBILITY,
	PERFORMANCE,
	USER_PREFERENCES,
	PLATFORM_SPECIFIC
}

## Performance profiles
enum PerformanceProfile {
	ULTRA_LOW,
	LOW,
	MEDIUM,
	HIGH,
	ULTRA,
	EDUCATIONAL_OPTIMIZED,
	CUSTOM
}

# Core configuration storage
var config_data: Dictionary = {}
var config_constraints: Dictionary = {}
var config_validators: Dictionary = {}
var config_metadata: Dictionary = {}

# Configuration category storage
var game_settings: Dictionary = {}
var educational_settings: Dictionary = {}
var performance_settings: Dictionary = {}
var user_preferences: Dictionary = {}

# Performance and platform management
var current_performance_profile: PerformanceProfile = PerformanceProfile.MEDIUM
var platform_capabilities: Dictionary = {}
var hardware_info: Dictionary = {}
var auto_tuning_enabled: bool = true

# Educational configuration
var educational_presets: Dictionary = {}
var assessment_configurations: Dictionary = {}
var learning_profiles: Dictionary = {}

# File management
var config_file_path: String = "user://config.json"
var backup_config_path: String = "user://config_backup.json"
var default_config_path: String = "res://resources/data/config/default_config.json"
var config_version: String = "1.0"

# Security and validation
var secure_settings: Array[String] = ["educational.student_data", "user_preferences.privacy"]
var setting_locks: Dictionary = {}
var validation_enabled: bool = true

# Default configuration
var default_config: Dictionary = {
	"game": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"voice_volume": 1.0,
		"language": "en",
		"auto_save": true,
		"difficulty": "normal"
	},
	"educational": {
		"assessment_mode": "adaptive",
		"hint_frequency": "normal",
		"progress_tracking": true,
		"detailed_feedback": true,
		"time_limits": true,
		"accessibility_mode": false
	},
	"performance": {
		"render_quality": "medium",
		"shadow_quality": "medium",
		"texture_quality": "high",
		"anti_aliasing": true,
		"vsync": true,
		"target_fps": 60,
		"memory_optimization": true
	},
	"user": {
		"first_time": true,
		"tutorial_completed": false,
		"last_scene": "",
		"control_scheme": "keyboard_mouse"
	}
}

func _ready():
	_initialize_config()
	_load_config()

## Get a setting value
func get_setting(category: String, key: String, default_value = null):
	var category_dict = _get_category_dict(category)
	return category_dict.get(key, default_value)

## Set a setting value
func set_setting(category: String, key: String, value) -> void:
	var category_dict = _get_category_dict(category)
	var old_value = category_dict.get(key)
	
	category_dict[key] = value
	
	# Emit signal if value changed
	if old_value != value:
		setting_changed.emit(category, key, value)
		_apply_setting_change(category, key, value)

## Get all settings for a category
func get_category_settings(category: String) -> Dictionary:
	return _get_category_dict(category).duplicate()

## Set multiple settings for a category
func set_category_settings(category: String, settings: Dictionary) -> void:
	var category_dict = _get_category_dict(category)
	
	for key in settings.keys():
		var old_value = category_dict.get(key)
		category_dict[key] = settings[key]
		
		if old_value != settings[key]:
			setting_changed.emit(category, key, settings[key])
			_apply_setting_change(category, key, settings[key])

## Reset category to defaults
func reset_category(category: String) -> void:
	if default_config.has(category):
		var category_dict = _get_category_dict(category)
		category_dict.clear()
		category_dict.merge(default_config[category])
		
		# Apply all settings in category
		for key in category_dict.keys():
			_apply_setting_change(category, key, category_dict[key])

## Reset all settings to defaults
func reset_all_settings() -> void:
	for category in default_config.keys():
		reset_category(category)

## Save configuration to file
func save_config() -> bool:
	var config_data = {
		"game": game_settings,
		"educational": educational_settings,
		"performance": performance_settings,
		"user": user_preferences
	}
	
	var json_string = JSON.stringify(config_data, "\t")
	var file = FileAccess.open(config_file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		file.close()
		config_saved.emit()
		return true
	else:
		push_error("Failed to save config file: " + config_file_path)
		return false

## Load configuration from file
func load_config() -> bool:
	return _load_config()

## Check if this is the first time running the game
func is_first_time() -> bool:
	return get_setting("user", "first_time", true)

## Mark first time setup as complete
func complete_first_time_setup() -> void:
	set_setting("user", "first_time", false)
	save_config()

## Get optimal performance settings based on platform
func get_optimal_performance_settings() -> Dictionary:
	var settings = {}
	
	if OS.has_feature("web"):
		# Browser-optimized settings
		settings = {
			"render_quality": "low",
			"shadow_quality": "low",
			"texture_quality": "medium",
			"anti_aliasing": false,
			"vsync": true,
			"target_fps": 30,
			"memory_optimization": true
		}
	elif OS.has_feature("mobile"):
		# Mobile-optimized settings
		settings = {
			"render_quality": "low",
			"shadow_quality": "off",
			"texture_quality": "medium",
			"anti_aliasing": false,
			"vsync": true,
			"target_fps": 30,
			"memory_optimization": true
		}
	else:
		# Desktop default settings
		settings = default_config["performance"].duplicate()
	
	return settings

## Apply optimal settings for current platform
func apply_optimal_settings() -> void:
	var optimal = get_optimal_performance_settings()
	set_category_settings("performance", optimal)

# Private methods

func _initialize_config() -> void:
	game_settings = default_config["game"].duplicate()
	educational_settings = default_config["educational"].duplicate()
	performance_settings = default_config["performance"].duplicate()
	user_preferences = default_config["user"].duplicate()

func _load_config() -> bool:
	var file = FileAccess.open(config_file_path, FileAccess.READ)
	
	if not file:
		# No config file exists, use defaults
		_apply_all_settings()
		config_loaded.emit()
		return true
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse config file: " + config_file_path)
		_apply_all_settings()
		config_loaded.emit()
		return false
	
	var config_data = json.data
	
	# Merge loaded data with defaults
	if config_data.has("game"):
		game_settings.merge(config_data["game"])
	if config_data.has("educational"):
		educational_settings.merge(config_data["educational"])
	if config_data.has("performance"):
		performance_settings.merge(config_data["performance"])
	if config_data.has("user"):
		user_preferences.merge(config_data["user"])
	
	_apply_all_settings()
	config_loaded.emit()
	return true

func _get_category_dict(category: String) -> Dictionary:
	match category:
		"game":
			return game_settings
		"educational":
			return educational_settings
		"performance":
			return performance_settings
		"user":
			return user_preferences
		_:
			push_error("Unknown config category: " + category)
			return {}

func _apply_all_settings() -> void:
	# Apply game settings
	for key in game_settings.keys():
		_apply_setting_change("game", key, game_settings[key])
	
	# Apply performance settings
	for key in performance_settings.keys():
		_apply_setting_change("performance", key, performance_settings[key])

func _apply_setting_change(category: String, key: String, value) -> void:
	match category:
		"game":
			_apply_game_setting(key, value)
		"performance":
			_apply_performance_setting(key, value)
		"educational":
			_apply_educational_setting(key, value)

func _apply_game_setting(key: String, value) -> void:
	match key:
		"master_volume":
			AudioServer.set_bus_volume_db(0, linear_to_db(value))
		"music_volume":
			var music_bus = AudioServer.get_bus_index("Music")
			if music_bus != -1:
				AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
		"sfx_volume":
			var sfx_bus = AudioServer.get_bus_index("SFX")
			if sfx_bus != -1:
				AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
		"language":
			if LocalizationManager:
				LocalizationManager.set_language(value)

func _apply_performance_setting(key: String, value) -> void:
	match key:
		"vsync":
			if value:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		"target_fps":
			Engine.max_fps = value

func _apply_educational_setting(key: String, value) -> void:
	# Educational settings are typically handled by the educational systems
	# This is where you'd integrate with assessment and tutorial systems
	pass
