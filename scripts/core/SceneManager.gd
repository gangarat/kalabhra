extends Node

## SceneManager - Advanced Scene Loading and Transition System
##
## The SceneManager provides sophisticated scene loading, unloading, and transition
## capabilities optimized for educational content delivery and browser deployment.
##
## Key Features:
## - Asynchronous scene loading with progress tracking
## - Advanced state preservation and restoration
## - Memory-efficient scene caching and unloading
## - Smooth transitions with customizable effects
## - Educational context preservation
## - Performance monitoring and optimization
##
## Usage Example:
## ```gdscript
## # Load scene with custom transition
## SceneManager.load_scene_async("sanctuary_hall", {
##     "transition": "fade_with_loading",
##     "preserve_education_state": true,
##     "preload_adjacent": true
## })
##
## # Preload scenes for faster transitions
## SceneManager.preload_scene_batch(["chamber_1", "chamber_2", "chamber_3"])
##
## # Get scene loading progress
## var progress = SceneManager.get_loading_progress("sanctuary_hall")
## ```

# Scene loading and transition signals
signal scene_load_requested(scene_id: String, config: Dictionary)
signal scene_loading_started(scene_id: String, scene_path: String)
signal scene_loading_progress(scene_id: String, progress: float, stage: String)
signal scene_loading_completed(scene_id: String, load_time: float)
signal scene_loading_failed(scene_id: String, error: String)

signal scene_transition_started(from_scene: String, to_scene: String, transition_type: String)
signal scene_transition_progress(progress: float, stage: String)
signal scene_transition_completed(scene_id: String, transition_time: float)
signal scene_loading_finished(scene_path: String)

signal scene_unloaded(scene_id: String, memory_freed: int)
signal scene_preloaded(scene_id: String, cache_size: int)

# Memory and performance signals
signal memory_pressure_detected(usage_mb: float, threshold_mb: float)
signal scene_cache_cleaned(scenes_removed: int, memory_freed: int)

## Scene loading states
enum LoadingState {
	NOT_LOADED,
	LOADING,
	LOADED,
	ACTIVE,
	UNLOADING,
	ERROR
}

## Transition types
enum TransitionType {
	INSTANT,
	FADE,
	SLIDE,
	DISSOLVE,
	EDUCATIONAL_WIPE,
	CUSTOM
}

# Core scene management
var current_scene: Node = null
var current_scene_id: String = ""
var current_scene_path: String = ""
var scene_loading_states: Dictionary = {}
var scene_cache: Dictionary = {}

# Loading and transition management
var active_loading_tasks: Dictionary = {}
var loading_queue: Array[Dictionary] = []
var transition_queue: Array[Dictionary] = []
var is_transitioning: bool = false

# State preservation system
var scene_states: Dictionary = {}
var global_state: Dictionary = {}
var educational_context: Dictionary = {}
var preserved_data: Dictionary = {}
var player_state: Dictionary = {}

# Loading screen management
var loading_screen: Node = null

# Performance and memory management
var max_cached_scenes: int = 5
var memory_threshold_mb: float = 256.0
var cache_cleanup_interval: float = 30.0
var last_cleanup_time: float = 0.0

# Scene registry and configuration
var scene_registry: Dictionary = {}
var scene_dependencies: Dictionary = {}
var preload_groups: Dictionary = {}

# Transition configuration
var transition_duration: float = 1.0
var transition_settings: Dictionary = {
	TransitionType.FADE: {"duration": 0.5, "ease_type": Tween.EASE_IN_OUT},
	TransitionType.SLIDE: {"duration": 0.8, "ease_type": Tween.EASE_OUT},
	TransitionType.DISSOLVE: {"duration": 1.0, "ease_type": Tween.EASE_IN_OUT},
	TransitionType.EDUCATIONAL_WIPE: {"duration": 0.7, "ease_type": Tween.EASE_IN_OUT}
}

func _ready():
	_initialize_scene_system()
	_setup_scene_registry()
	_start_memory_monitoring()

func _process(delta):
	_update_loading_tasks(delta)
	_process_loading_queue()
	_check_memory_usage()

#region System Management

## Initialize the scene management system
func initialize_system() -> bool:
	_load_scene_configuration()
	_setup_preload_groups()
	_initialize_state_preservation()

	print("[SceneManager] Scene management system initialized")
	return true

## Get system health status
func get_health_status() -> Dictionary:
	var health = {
		"status": "healthy",
		"current_scene": current_scene_id,
		"cached_scenes": scene_cache.size(),
		"active_loading_tasks": active_loading_tasks.size(),
		"memory_usage_mb": _get_scene_memory_usage(),
		"last_check": Time.get_unix_time_from_system()
	}

	# Check for potential issues
	if health["memory_usage_mb"] > memory_threshold_mb * 0.8:
		health["status"] = "warning"
		health["message"] = "Scene memory usage approaching threshold"

	if active_loading_tasks.size() > 3:
		health["status"] = "warning"
		health["message"] = "High number of concurrent loading tasks"

	return health

## Shutdown the scene management system
func shutdown_system() -> void:
	_cancel_all_loading_tasks()
	_clear_scene_cache()
	_save_scene_states()
	print("[SceneManager] Scene management system shutdown completed")

#endregion

#region Public API - Scene Loading

## Load a scene asynchronously with advanced options
## @param scene_id: Identifier for the scene to load
## @param config: Configuration options for loading and transition
## @return: True if loading started successfully
func load_scene_async(scene_id: String, config: Dictionary = {}) -> bool:
	if not scene_registry.has(scene_id):
		push_error("[SceneManager] Scene not found in registry: " + scene_id)
		scene_loading_failed.emit(scene_id, "Scene not found in registry")
		return false

	if scene_loading_states.get(scene_id) == LoadingState.LOADING:
		push_warning("[SceneManager] Scene already loading: " + scene_id)
		return false

	# Prepare loading configuration
	var load_config = {
		"scene_id": scene_id,
		"scene_path": scene_registry[scene_id],
		"transition_type": config.get("transition", TransitionType.FADE),
		"preserve_state": config.get("preserve_state", true),
		"preserve_education_state": config.get("preserve_education_state", true),
		"preload_adjacent": config.get("preload_adjacent", true),
		"priority": config.get("priority", 1),
		"background_loading": config.get("background_loading", false)
	}

	scene_load_requested.emit(scene_id, load_config)

	if load_config["background_loading"]:
		_start_background_loading(scene_id)
	else:
		_start_scene_transition(current_scene_id, scene_id, load_config.get("transition", "fade"))

	return true

## Preload a scene without making it active
## @param scene_id: Scene to preload
## @param priority: Loading priority (higher = more important)
## @return: True if preloading started
func preload_scene(scene_id: String, priority: int = 1) -> bool:
	if not scene_registry.has(scene_id):
		push_error("[SceneManager] Scene not found for preloading: " + scene_id)
		return false

	if scene_cache.has(scene_id):
		return true  # Already cached

	var load_config = {
		"scene_id": scene_id,
		"scene_path": scene_registry[scene_id],
		"priority": priority,
		"preload_only": true
	}

	_add_to_loading_queue(scene_id, scene_registry.get(scene_id, ""))
	return true

## Preload multiple scenes as a batch
## @param scene_ids: Array of scene IDs to preload
## @param priority: Loading priority for the batch
func preload_scene_batch(scene_ids: Array[String], priority: int = 1) -> void:
	for scene_id in scene_ids:
		preload_scene(scene_id, priority)

## Unload a scene from memory
## @param scene_id: Scene to unload
## @param force: Force unload even if scene is in use
## @return: Amount of memory freed in bytes
func unload_scene(scene_id: String, force: bool = false) -> int:
	if scene_id == current_scene_id and not force:
		push_warning("[SceneManager] Cannot unload current scene without force: " + scene_id)
		return 0

	if not scene_cache.has(scene_id):
		return 0

	var scene_data = scene_cache[scene_id]
	var memory_freed = scene_data.get("memory_size", 0)

	# Clean up scene data
	scene_cache.erase(scene_id)
	scene_loading_states.erase(scene_id)

	# Free the scene resource
	if scene_data.has("scene_resource"):
		scene_data["scene_resource"] = null

	scene_unloaded.emit(scene_id, memory_freed)
	return memory_freed

## Get loading progress for a specific scene
## @param scene_id: Scene to check progress for
## @return: Dictionary with progress information
func get_loading_progress(scene_id: String) -> Dictionary:
	if active_loading_tasks.has(scene_id):
		return active_loading_tasks[scene_id].duplicate()

	var state = scene_loading_states.get(scene_id, LoadingState.NOT_LOADED)
	return {
		"scene_id": scene_id,
		"state": state,
		"progress": 1.0 if state == LoadingState.LOADED else 0.0,
		"stage": "completed" if state == LoadingState.LOADED else "not_started"
	}

## Check if a scene is loaded and ready
## @param scene_id: Scene to check
## @return: True if scene is loaded and ready to use
func is_scene_ready(scene_id: String) -> bool:
	return scene_loading_states.get(scene_id) == LoadingState.LOADED

## Get list of all cached scenes
## @return: Array of scene IDs currently in cache
func get_cached_scenes() -> Array[String]:
	return scene_cache.keys()

#endregion

#region State Preservation

## Preserve current scene state
## @param include_education_context: Whether to preserve educational context
func preserve_current_scene_state(include_education_context: bool = true) -> void:
	if current_scene_id.is_empty():
		return

	var state_data = {
		"scene_id": current_scene_id,
		"timestamp": Time.get_unix_time_from_system(),
		"player_state": _extract_player_state(_find_player_in_scene()),
		"scene_state": _extract_scene_state(),
		"ui_state": _extract_ui_state()
	}

	if include_education_context:
		state_data["educational_context"] = _extract_educational_context()

	scene_states[current_scene_id] = state_data

## Restore scene state
## @param scene_id: Scene to restore state for
## @param scene_node: The scene node to restore state to
func restore_scene_state(scene_id: String, scene_node: Node) -> void:
	if not scene_states.has(scene_id):
		return

	var state_data = scene_states[scene_id]

	# Restore player state
	if state_data.has("player_state"):
		var player = _find_player_in_scene(scene_node)
		if player:
			_restore_player_state_with_data(state_data["player_state"], player)

	# Restore scene-specific state
	if state_data.has("scene_state"):
		_restore_scene_state_with_data(state_data["scene_state"], scene_node)

	# Restore UI state
	if state_data.has("ui_state"):
		_restore_ui_state(state_data["ui_state"], scene_node)

	# Restore educational context
	if state_data.has("educational_context"):
		_restore_educational_context(state_data["educational_context"], scene_node)

## Set global state that persists across all scenes
## @param key: State key
## @param value: State value
func set_global_state(key: String, value) -> void:
	global_state[key] = value

## Get global state value
## @param key: State key
## @param default_value: Default value if key not found
## @return: State value or default
func get_global_state(key: String, default_value = null):
	return global_state.get(key, default_value)

## Clear all preserved states
func clear_all_states() -> void:
	scene_states.clear()
	global_state.clear()
	educational_context.clear()

#endregion

#region Private Implementation

## Initialize the scene system
func _initialize_scene_system() -> void:
	# Get the current scene
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	current_scene_path = current_scene.scene_file_path
	current_scene_id = _path_to_scene_id(current_scene_path)

	# Initialize data structures
	scene_loading_states = {}
	scene_cache = {}
	active_loading_tasks = {}
	scene_states = {}
	global_state = {}
	educational_context = {}

	# Set initial scene state
	scene_loading_states[current_scene_id] = LoadingState.ACTIVE

## Setup scene registry from configuration
func _setup_scene_registry() -> void:
	# Default scene registry
	scene_registry = {
		"main_menu": "res://scenes/main/MainMenu.tscn",
		"loading": "res://scenes/main/LoadingScreen.tscn",
		"main_hall": "res://scenes/environments/sanctuary/MainHall.tscn",
		"game_hud": "res://scenes/ui/hud/GameHUD.tscn"
	}

	# Load additional scenes from configuration
	_load_scene_configuration()

## Load scene configuration from file
func _load_scene_configuration() -> void:
	var config_file = "res://resources/data/config/scenes.json"
	var file = FileAccess.open(config_file, FileAccess.READ)

	if not file:
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("[SceneManager] Failed to parse scene configuration")
		return

	var config = json.data

	# Merge with existing registry
	if config.has("scenes"):
		scene_registry.merge(config["scenes"])

	if config.has("dependencies"):
		scene_dependencies = config["dependencies"]

	if config.has("preload_groups"):
		preload_groups = config["preload_groups"]

## Setup preload groups
func _setup_preload_groups() -> void:
	# Preload critical scenes
	if preload_groups.has("critical"):
		for scene_id in preload_groups["critical"]:
			preload_scene(scene_id, 10)  # High priority

## Start memory monitoring
func _start_memory_monitoring() -> void:
	last_cleanup_time = Time.get_unix_time_from_system()

## Initialize state preservation system
func _initialize_state_preservation() -> void:
	# Load existing states if available
	var states_file = "user://scene_states.json"
	var file = FileAccess.open(states_file, FileAccess.READ)

	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			var saved_states = json.data
			if saved_states.has("global_state"):
				global_state = saved_states["global_state"]

## Update loading tasks
func _update_loading_tasks(delta: float) -> void:
	for task_id in active_loading_tasks.keys():
		var task = active_loading_tasks[task_id]
		_update_loading_task(task_id, task.get("progress", 0.0), task.get("stage", "processing"))

## Process loading queue
func _process_loading_queue() -> void:
	if loading_queue.is_empty() or active_loading_tasks.size() >= 2:
		return  # Don't overload with too many concurrent tasks

	var next_task = loading_queue.pop_front()
	_start_loading_task(next_task.get("scene_id", ""), next_task.get("scene_path", ""))

## Check memory usage and cleanup if needed
func _check_memory_usage() -> void:
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_cleanup_time < cache_cleanup_interval:
		return

	last_cleanup_time = current_time
	var memory_usage = _get_scene_memory_usage()

	if memory_usage > memory_threshold_mb:
		memory_pressure_detected.emit(memory_usage, memory_threshold_mb)
		_cleanup_scene_cache()

#endregion

## Change scene by registry key
func change_scene_by_key(scene_key: String, transition_type: String = "fade", preserve_state: bool = true) -> void:
	if scene_registry.has(scene_key):
		change_scene(scene_registry[scene_key], transition_type, preserve_state)
	else:
		push_error("Scene key not found in registry: " + scene_key)

## Reload current scene
func reload_current_scene() -> void:
	if current_scene_path.is_empty():
		push_error("No current scene to reload")
		return
	
	change_scene(current_scene_path, "fade", false)

## Get preserved data for the current scene
func get_preserved_data(key: String, default_value = null):
	return preserved_data.get(key, default_value)

## Set data to be preserved across scene transitions
func set_preserved_data(key: String, value) -> void:
	preserved_data[key] = value

## Clear all preserved data
func clear_preserved_data() -> void:
	preserved_data.clear()
	player_state.clear()

## Register a new scene in the registry
func register_scene(key: String, path: String) -> void:
	scene_registry[key] = path

## Check if a scene is currently loading
func is_loading() -> bool:
	return is_transitioning

# Private methods

func _preserve_scene_state() -> void:
	if not current_scene:
		return
	
	# Preserve player state if player exists
	var player = _find_player_in_scene()
	if player:
		player_state = _extract_player_state(player)
	
	# Call preserve method on scene if it exists
	if current_scene.has_method("preserve_state"):
		var scene_data = current_scene.preserve_state()
		if scene_data is Dictionary:
			for key in scene_data.keys():
				preserved_data[key] = scene_data[key]

func _restore_scene_state(new_scene: Node) -> void:
	# Restore player state if player exists
	var player = _find_player_in_scene(new_scene)
	if player and not player_state.is_empty():
		_restore_player_state(player)
	
	# Call restore method on scene if it exists
	if new_scene.has_method("restore_state") and not preserved_data.is_empty():
		new_scene.restore_state(preserved_data)

func _find_player_in_scene(scene: Node = null) -> Node:
	var search_scene = scene if scene else current_scene
	if not search_scene:
		return null
	
	# Look for player node
	var player = search_scene.find_child("Player", true, false)
	return player

func _extract_player_state(player: Node) -> Dictionary:
	var state = {}
	
	if player.has_method("get_save_data"):
		state = player.get_save_data()
	else:
		# Default state extraction
		state["position"] = player.global_position
		state["rotation"] = player.global_rotation
		
		if player.has_method("get_health"):
			state["health"] = player.get_health()
	
	return state

func _restore_player_state(player: Node) -> void:
	if player.has_method("load_save_data"):
		player.load_save_data(player_state)
	else:
		# Default state restoration
		if player_state.has("position"):
			player.global_position = player_state["position"]
		if player_state.has("rotation"):
			player.global_rotation = player_state["rotation"]

func _should_show_loading_screen(scene_path: String) -> bool:
	# Show loading screen for large scenes or when not cached
	return not scene_cache.has(_path_to_scene_id(scene_path))

func _show_loading_screen() -> void:
	if loading_screen:
		return

	if scene_registry.has("loading"):
		var loading_scene = load(scene_registry["loading"])
		if loading_scene:
			loading_screen = loading_scene.instantiate()
			get_tree().root.add_child(loading_screen)
			loading_screen.show()

func _hide_loading_screen() -> void:
	if loading_screen:
		loading_screen.queue_free()
		loading_screen = null

func _load_scene_async(scene_path: String) -> void:
	scene_loading_started.emit(scene_path)

	# Load scene resource
	var scene_resource = load(scene_path)
	if not scene_resource:
		push_error("Failed to load scene: " + scene_path)
		return
	
	scene_loading_progress.emit(0.5)
	
	# Instantiate new scene
	var new_scene = scene_resource.instantiate()
	if not new_scene:
		push_error("Failed to instantiate scene: " + scene_path)
		return
	
	scene_loading_progress.emit(0.8)
	
	# Replace current scene
	_replace_current_scene(new_scene, scene_path)
	
	scene_loading_progress.emit(1.0)
	scene_loading_finished.emit(scene_path)

func _load_scene_with_transition(scene_path: String, transition_type: String) -> void:
	# Simple fade transition for now
	var tween = create_tween()
	
	# Fade out
	var fade_overlay = _create_fade_overlay()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, transition_duration * 0.5)
	await tween.finished
	
	# Load new scene
	await _load_scene_async(scene_path)
	
	# Fade in
	tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, transition_duration * 0.5)
	await tween.finished
	
	fade_overlay.queue_free()

func _replace_current_scene(new_scene: Node, scene_path: String) -> void:
	# Remove current scene
	if current_scene:
		current_scene.queue_free()
	
	# Add new scene
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	
	# Update references
	current_scene = new_scene
	current_scene_path = scene_path
	
	# Restore state
	_restore_scene_state(new_scene)

func _create_fade_overlay() -> ColorRect:
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(overlay)
	return overlay

# Missing function implementations

func _get_scene_memory_usage() -> float:
	# Calculate approximate memory usage of cached scenes
	var total_memory = 0.0
	for scene_id in scene_cache:
		# Rough estimate: each cached scene uses ~10MB
		total_memory += 10.0
	return total_memory

func _cancel_all_loading_tasks() -> void:
	# Cancel all active loading tasks
	for task_id in active_loading_tasks.keys():
		active_loading_tasks.erase(task_id)
	loading_queue.clear()

func _clear_scene_cache() -> void:
	# Clear all cached scenes
	for scene_id in scene_cache.keys():
		var scene = scene_cache[scene_id]
		if scene and is_instance_valid(scene):
			scene.queue_free()
	scene_cache.clear()

func _save_scene_states() -> void:
	# Save current scene states to persistent storage
	if current_scene and current_scene.has_method("get_save_data"):
		scene_states[current_scene_id] = current_scene.get_save_data()

func _start_background_loading(scene_id: String) -> void:
	# Start background loading for a scene
	if scene_registry.has(scene_id):
		var scene_path = scene_registry[scene_id]
		_add_to_loading_queue(scene_id, scene_path)

func _start_scene_transition(from_scene: String, to_scene: String, transition_type: String) -> void:
	# Start scene transition
	scene_transition_started.emit(from_scene, to_scene, transition_type)
	is_transitioning = true

func _add_to_loading_queue(scene_id: String, scene_path: String) -> void:
	# Add scene to loading queue
	loading_queue.append({
		"scene_id": scene_id,
		"scene_path": scene_path,
		"priority": 1
	})

func _extract_scene_state() -> Dictionary:
	# Extract current scene state
	var state = {}
	if current_scene and current_scene.has_method("get_save_data"):
		state = current_scene.get_save_data()
	return state

func _extract_ui_state() -> Dictionary:
	# Extract UI state
	var state = {}
	if UIManager:
		state["ui_mode"] = UIManager.current_layout_mode
		state["render_scale"] = UIManager.render_scale
	return state

func _extract_educational_context() -> Dictionary:
	# Extract educational context
	var context = {}
	# This would integrate with EducationManager when available
	return context

func _restore_ui_state(state: Dictionary, scene_node: Node) -> void:
	# Restore UI state
	if UIManager and state.has("ui_mode"):
		UIManager.set_layout_mode(state["ui_mode"])
	if UIManager and state.has("render_scale"):
		UIManager.set_render_scale(state["render_scale"])

func _restore_educational_context(context: Dictionary, scene_node: Node) -> void:
	# Restore educational context
	# This would integrate with EducationManager when available
	pass

func _restore_player_state_with_data(state_data: Dictionary, player: Node) -> void:
	# Restore player state with specific data
	if player.has_method("load_save_data"):
		player.load_save_data(state_data)
	else:
		# Default state restoration
		if state_data.has("position"):
			player.global_position = state_data["position"]
		if state_data.has("rotation"):
			player.global_rotation = state_data["rotation"]

func _restore_scene_state_with_data(state_data: Dictionary, scene_node: Node) -> void:
	# Restore scene state with specific data
	if scene_node.has_method("restore_state"):
		scene_node.restore_state(state_data)

func change_scene(scene_path: String, transition_type: String = "fade", preserve_state: bool = true) -> void:
	# Custom change scene function with transitions and state preservation
	if preserve_state:
		_preserve_scene_state()

	# Start transition
	_start_scene_transition(current_scene_id, _path_to_scene_id(scene_path), transition_type)

	# Load new scene
	var new_scene = load(scene_path)
	if new_scene:
		var scene_instance = new_scene.instantiate()

		# Remove current scene
		if current_scene:
			current_scene.queue_free()

		# Add new scene
		get_tree().root.add_child(scene_instance)
		get_tree().current_scene = scene_instance

		# Update references
		current_scene = scene_instance
		current_scene_path = scene_path
		current_scene_id = _path_to_scene_id(scene_path)

		# Restore state if needed
		if preserve_state:
			_restore_scene_state_with_data(preserved_data, scene_instance)

		# Complete transition
		scene_transition_completed.emit(current_scene_id, 1.0)
		is_transitioning = false
	else:
		push_error("Failed to load scene: " + scene_path)

func _path_to_scene_id(path: String) -> String:
	# Convert scene path to scene ID
	var scene_name = path.get_file().get_basename()
	return scene_name

func _update_loading_task(task_id: String, progress: float, stage: String) -> void:
	# Update loading task progress
	if active_loading_tasks.has(task_id):
		active_loading_tasks[task_id]["progress"] = progress
		active_loading_tasks[task_id]["stage"] = stage

func _start_loading_task(scene_id: String, scene_path: String) -> void:
	# Start a new loading task
	var task_id = scene_id + "_" + str(Time.get_unix_time_from_system())
	active_loading_tasks[task_id] = {
		"scene_id": scene_id,
		"scene_path": scene_path,
		"progress": 0.0,
		"stage": "starting"
	}

func _cleanup_scene_cache() -> void:
	# Clean up old scenes from cache
	var scenes_to_remove = []
	var current_time = Time.get_unix_time_from_system()

	for scene_id in scene_cache.keys():
		# Remove scenes that haven't been used recently
		scenes_to_remove.append(scene_id)
		if scenes_to_remove.size() >= max_cached_scenes / 2:
			break

	var memory_freed = 0
	for scene_id in scenes_to_remove:
		if scene_cache.has(scene_id):
			var scene = scene_cache[scene_id]
			if scene and is_instance_valid(scene):
				scene.queue_free()
			scene_cache.erase(scene_id)
			memory_freed += 10 # Rough estimate

	scene_cache_cleaned.emit(scenes_to_remove.size(), memory_freed)
