extends Node

## GameManager - Core System Coordinator
##
## The GameManager is the central hub that coordinates all game systems and maintains
## global state for Light of the Kalabhra. It provides a unified interface for
## system communication and ensures proper initialization order.
##
## Key Responsibilities:
## - System lifecycle management (initialization, shutdown)
## - Global state management and persistence
## - Inter-system communication coordination
## - Error handling and recovery
## - Performance monitoring and optimization
## - Educational session management
##
## Usage Example:
## ```gdscript
## # Start a new educational session
## GameManager.start_new_session("ancient_architecture")
##
## # Check if systems are ready
## if GameManager.are_systems_ready():
##     GameManager.transition_to_state(GameManager.GameState.PLAYING)
##
## # Get system reference safely
## var education_mgr = GameManager.get_system("EducationManager")
## if education_mgr:
##     education_mgr.start_lesson("introduction")
## ```

# System state signals
signal systems_initialized()
signal system_error(system_name: String, error_message: String)
signal system_warning(system_name: String, warning_message: String)

# Game state signals
signal game_state_changed(new_state: GameState, previous_state: GameState)
signal session_started(session_id: String)
signal session_ended(session_id: String, duration: float)

# Educational signals
signal lesson_started(lesson_id: String)
signal lesson_completed(lesson_id: String, performance_data: Dictionary)
signal assessment_started(assessment_id: String)
signal assessment_completed(assessment_id: String, results: Dictionary)

# Performance signals
signal performance_warning(metric: String, value: float, threshold: float)
signal memory_pressure_detected(usage_mb: float)

## Game states with clear transitions
enum GameState {
	INITIALIZING,    ## Systems are being initialized
	MAIN_MENU,      ## Main menu is active
	LOADING,        ## Loading content or transitioning
	PLAYING,        ## Active gameplay
	PAUSED,         ## Game is paused
	ASSESSMENT,     ## Educational assessment in progress
	CUTSCENE,       ## Cutscene or narrative sequence
	SETTINGS,       ## Settings menu is open
	ERROR           ## Error state requiring user action
}

## System initialization states
enum SystemState {
	NOT_INITIALIZED,
	INITIALIZING,
	READY,
	ERROR,
	SHUTTING_DOWN
}

# Core system references
var _systems: Dictionary = {}
var _system_states: Dictionary = {}
var _initialization_order: Array[String] = [
	"ConfigManager",
	"AssetManager",
	"AudioManager",
	"UIManager",
	"SceneManager",
	"EducationManager"
]

# Game state management
var current_state: GameState = GameState.INITIALIZING
var previous_state: GameState = GameState.INITIALIZING
var state_history: Array[GameState] = []
var state_transition_time: float = 0.0

# Session management
var current_session_id: String = ""
var session_start_time: float = 0.0
var session_data: Dictionary = {}
var auto_save_enabled: bool = true
var auto_save_interval: float = 300.0  # 5 minutes

# Performance monitoring
var _performance_monitor: PerformanceMonitor
var _error_handler: ErrorHandler
var _auto_save_timer: Timer

# System health tracking
var _system_health: Dictionary = {}
var _last_health_check: float = 0.0
var _health_check_interval: float = 5.0

# Error recovery
var _error_recovery_attempts: Dictionary = {}
var _max_recovery_attempts: int = 3

## Performance monitoring class
class PerformanceMonitor:
	var metrics: Dictionary = {}
	var thresholds: Dictionary = {
		"fps": 30.0,
		"memory_mb": 512.0,
		"load_time_ms": 5000.0
	}

	func update_metric(name: String, value: float) -> void:
		metrics[name] = value
		if thresholds.has(name) and value > thresholds[name]:
			GameManager.performance_warning.emit(name, value, thresholds[name])

	func get_metric(name: String) -> float:
		return metrics.get(name, 0.0)

	func get_all_metrics() -> Dictionary:
		return metrics.duplicate()

## Error handling class
class ErrorHandler:
	var error_log: Array[Dictionary] = []
	var max_log_size: int = 100

	func log_error(system: String, message: String, severity: String = "ERROR") -> void:
		var error_entry = {
			"timestamp": Time.get_unix_time_from_system(),
			"system": system,
			"message": message,
			"severity": severity
		}

		error_log.append(error_entry)
		if error_log.size() > max_log_size:
			error_log.pop_front()

		match severity:
			"ERROR":
				GameManager.system_error.emit(system, message)
				push_error("[%s] %s" % [system, message])
			"WARNING":
				GameManager.system_warning.emit(system, message)
				push_warning("[%s] %s" % [system, message])
			"INFO":
				print("[%s] %s" % [system, message])

	func get_recent_errors(count: int = 10) -> Array[Dictionary]:
		var recent = error_log.slice(-count) if error_log.size() > count else error_log
		return recent

	func clear_errors() -> void:
		error_log.clear()

func _ready():
	_initialize_core_components()
	await _initialize_systems()
	_setup_auto_save()
	_start_health_monitoring()

func _notification(what):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			await _shutdown_gracefully()
			get_tree().quit()
		NOTIFICATION_APPLICATION_PAUSED:
			_handle_application_pause(true)
		NOTIFICATION_APPLICATION_RESUMED:
			_handle_application_pause(false)

func _process(delta):
	_update_performance_metrics(delta)
	_check_system_health()

#region Public API

## Initialize a new educational session
## @param session_type: Type of educational session (e.g., "lesson", "assessment", "exploration")
## @param session_config: Configuration data for the session
## @return: Session ID if successful, empty string if failed
func start_new_session(session_type: String, session_config: Dictionary = {}) -> String:
	if current_state != GameState.MAIN_MENU and current_state != GameState.PLAYING:
		_error_handler.log_error("GameManager", "Cannot start session in state: " + str(current_state))
		return ""

	current_session_id = _generate_session_id()
	session_start_time = Time.get_unix_time_from_system()
	session_data = {
		"id": current_session_id,
		"type": session_type,
		"config": session_config,
		"start_time": session_start_time,
		"events": []
	}

	session_started.emit(current_session_id)
	_error_handler.log_error("GameManager", "Started session: " + current_session_id, "INFO")

	return current_session_id

## End the current educational session
## @param save_data: Whether to save session data
## @return: Session duration in seconds
func end_current_session(save_data: bool = true) -> float:
	if current_session_id.is_empty():
		return 0.0

	var duration = Time.get_unix_time_from_system() - session_start_time
	session_data["end_time"] = Time.get_unix_time_from_system()
	session_data["duration"] = duration

	if save_data:
		_save_session_data()

	session_ended.emit(current_session_id, duration)
	_error_handler.log_error("GameManager", "Ended session: " + current_session_id + " (Duration: %.1fs)" % duration, "INFO")

	current_session_id = ""
	session_data.clear()

	return duration

## Transition to a new game state with validation
## @param new_state: Target game state
## @param force: Whether to force the transition even if invalid
## @return: True if transition was successful
func transition_to_state(new_state: GameState, force: bool = false) -> bool:
	if not force and not _is_valid_state_transition(current_state, new_state):
		_error_handler.log_error("GameManager", "Invalid state transition: %s -> %s" % [current_state, new_state])
		return false

	previous_state = current_state
	state_history.append(current_state)

	# Limit state history size
	if state_history.size() > 10:
		state_history.pop_front()

	current_state = new_state
	state_transition_time = Time.get_unix_time_from_system()

	_handle_state_transition(previous_state, new_state)
	game_state_changed.emit(new_state, previous_state)

	return true

## Get a reference to a system safely
## @param system_name: Name of the system to retrieve
## @return: System reference or null if not found/ready
func get_system(system_name: String) -> Node:
	if not _systems.has(system_name):
		_error_handler.log_error("GameManager", "System not found: " + system_name)
		return null

	if _system_states.get(system_name) != SystemState.READY:
		_error_handler.log_error("GameManager", "System not ready: " + system_name)
		return null

	return _systems[system_name]

## Check if all critical systems are ready
## @return: True if all systems are initialized and ready
func are_systems_ready() -> bool:
	for system_name in _initialization_order:
		if _system_states.get(system_name) != SystemState.READY:
			return false
	return true

## Get current system health status
## @return: Dictionary with system health information
func get_system_health() -> Dictionary:
	return _system_health.duplicate()

## Get performance metrics
## @return: Dictionary with current performance data
func get_performance_metrics() -> Dictionary:
	return _performance_monitor.get_all_metrics()

## Force a system health check
func force_health_check() -> void:
	_check_system_health()

#endregion

#region Private Implementation

## Initialize core components
func _initialize_core_components() -> void:
	_performance_monitor = PerformanceMonitor.new()
	_error_handler = ErrorHandler.new()

	# Set process mode for pause handling
	process_mode = Node.PROCESS_MODE_ALWAYS

	_error_handler.log_error("GameManager", "Core components initialized", "INFO")

## Initialize all game systems in proper order
func _initialize_systems() -> void:
	_error_handler.log_error("GameManager", "Starting system initialization", "INFO")

	for system_name in _initialization_order:
		await _initialize_system(system_name)

		# Check if initialization was successful
		if _system_states.get(system_name) != SystemState.READY:
			_error_handler.log_error("GameManager", "Failed to initialize system: " + system_name)
			transition_to_state(GameState.ERROR, true)
			return

	_error_handler.log_error("GameManager", "All systems initialized successfully", "INFO")
	systems_initialized.emit()
	transition_to_state(GameState.MAIN_MENU)

## Initialize a specific system
func _initialize_system(system_name: String) -> void:
	_system_states[system_name] = SystemState.INITIALIZING
	_error_handler.log_error("GameManager", "Initializing system: " + system_name, "INFO")

	var system_node = get_node_or_null("/root/" + system_name)
	if not system_node:
		_error_handler.log_error("GameManager", "System node not found: " + system_name)
		_system_states[system_name] = SystemState.ERROR
		return

	_systems[system_name] = system_node

	# Call system-specific initialization if available
	if system_node.has_method("initialize_system"):
		var result = await system_node.initialize_system()
		if result:
			_system_states[system_name] = SystemState.READY
			_system_health[system_name] = {"status": "healthy", "last_check": Time.get_unix_time_from_system()}
		else:
			_system_states[system_name] = SystemState.ERROR
	else:
		# Assume ready if no initialization method
		_system_states[system_name] = SystemState.READY
		_system_health[system_name] = {"status": "healthy", "last_check": Time.get_unix_time_from_system()}

## Setup auto-save functionality
func _setup_auto_save() -> void:
	if auto_save_enabled:
		_auto_save_timer = Timer.new()
		_auto_save_timer.wait_time = auto_save_interval
		_auto_save_timer.timeout.connect(_perform_auto_save)
		_auto_save_timer.autostart = true
		add_child(_auto_save_timer)

## Start health monitoring
func _start_health_monitoring() -> void:
	_last_health_check = Time.get_unix_time_from_system()

## Update performance metrics
func _update_performance_metrics(delta: float) -> void:
	_performance_monitor.update_metric("fps", Engine.get_frames_per_second())
	_performance_monitor.update_metric("delta_time_ms", delta * 1000.0)

	# Memory usage (approximate)
	var memory_usage = OS.get_static_memory_usage_by_type()
	var total_memory = 0
	for usage in memory_usage.values():
		total_memory += usage
	_performance_monitor.update_metric("memory_mb", total_memory / (1024.0 * 1024.0))

## Check system health periodically
func _check_system_health() -> void:
	var current_time = Time.get_unix_time_from_system()
	if current_time - _last_health_check < _health_check_interval:
		return

	_last_health_check = current_time

	for system_name in _systems.keys():
		var system = _systems[system_name]
		if not is_instance_valid(system):
			_system_health[system_name] = {"status": "error", "message": "System instance invalid"}
			_error_handler.log_error("GameManager", "System health check failed: " + system_name + " (invalid instance)")
			continue

		# Check if system has health check method
		if system.has_method("get_health_status"):
			var health_status = system.get_health_status()
			_system_health[system_name] = health_status

			if health_status.get("status") != "healthy":
				_error_handler.log_error("GameManager", "System health issue: " + system_name + " - " + str(health_status.get("message", "Unknown issue")), "WARNING")
		else:
			_system_health[system_name] = {"status": "healthy", "last_check": current_time}

## Handle state transitions
func _handle_state_transition(from_state: GameState, to_state: GameState) -> void:
	_error_handler.log_error("GameManager", "State transition: %s -> %s" % [from_state, to_state], "INFO")

	# Handle exit from previous state
	match from_state:
		GameState.PLAYING:
			if auto_save_enabled:
				_perform_auto_save()
		GameState.PAUSED:
			get_tree().paused = false

	# Handle entry to new state
	match to_state:
		GameState.MAIN_MENU:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameState.PLAYING:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameState.PAUSED:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameState.ERROR:
			_handle_error_state()

## Validate state transitions
func _is_valid_state_transition(from_state: GameState, to_state: GameState) -> bool:
	# Define valid transitions
	var valid_transitions = {
		GameState.INITIALIZING: [GameState.MAIN_MENU, GameState.ERROR],
		GameState.MAIN_MENU: [GameState.LOADING, GameState.SETTINGS, GameState.ERROR],
		GameState.LOADING: [GameState.PLAYING, GameState.MAIN_MENU, GameState.ERROR],
		GameState.PLAYING: [GameState.PAUSED, GameState.ASSESSMENT, GameState.CUTSCENE, GameState.LOADING, GameState.MAIN_MENU, GameState.ERROR],
		GameState.PAUSED: [GameState.PLAYING, GameState.SETTINGS, GameState.MAIN_MENU, GameState.ERROR],
		GameState.ASSESSMENT: [GameState.PLAYING, GameState.MAIN_MENU, GameState.ERROR],
		GameState.CUTSCENE: [GameState.PLAYING, GameState.MAIN_MENU, GameState.ERROR],
		GameState.SETTINGS: [GameState.MAIN_MENU, GameState.PAUSED, GameState.ERROR],
		GameState.ERROR: [GameState.MAIN_MENU, GameState.INITIALIZING]
	}

	return valid_transitions.get(from_state, []).has(to_state)

## Handle application pause/resume
func _handle_application_pause(paused: bool) -> void:
	if paused:
		if current_state == GameState.PLAYING:
			transition_to_state(GameState.PAUSED)
		_perform_auto_save()
	else:
		# Resume from pause if we were playing
		if current_state == GameState.PAUSED and previous_state == GameState.PLAYING:
			transition_to_state(GameState.PLAYING)

## Handle error state
func _handle_error_state() -> void:
	_error_handler.log_error("GameManager", "Entered error state", "ERROR")

	# Try to recover systems
	for system_name in _systems.keys():
		if _system_states.get(system_name) == SystemState.ERROR:
			_attempt_system_recovery(system_name)

## Attempt to recover a failed system
func _attempt_system_recovery(system_name: String) -> void:
	var attempts = _error_recovery_attempts.get(system_name, 0)
	if attempts >= _max_recovery_attempts:
		_error_handler.log_error("GameManager", "Max recovery attempts reached for: " + system_name)
		return

	_error_recovery_attempts[system_name] = attempts + 1
	_error_handler.log_error("GameManager", "Attempting recovery for: " + system_name + " (attempt %d)" % (attempts + 1), "INFO")

	# Reinitialize the system
	await _initialize_system(system_name)

## Perform auto-save
func _perform_auto_save() -> void:
	if not current_session_id.is_empty():
		var save_manager = get_system("SaveManager")
		if save_manager and save_manager.has_method("auto_save"):
			save_manager.auto_save()

## Save current session data
func _save_session_data() -> void:
	if current_session_id.is_empty():
		return

	var save_manager = get_system("SaveManager")
	if save_manager and save_manager.has_method("save_session_data"):
		save_manager.save_session_data(session_data)

## Generate unique session ID
func _generate_session_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "session_%d_%04d" % [timestamp, random_suffix]

## Graceful shutdown
func _shutdown_gracefully() -> void:
	_error_handler.log_error("GameManager", "Starting graceful shutdown", "INFO")

	# End current session
	if not current_session_id.is_empty():
		end_current_session(true)

	# Shutdown systems in reverse order
	var shutdown_order = _initialization_order.duplicate()
	shutdown_order.reverse()

	for system_name in shutdown_order:
		if _systems.has(system_name):
			var system = _systems[system_name]
			if system and system.has_method("shutdown_system"):
				_system_states[system_name] = SystemState.SHUTTING_DOWN
				await system.shutdown_system()
			_system_states[system_name] = SystemState.NOT_INITIALIZED

	_error_handler.log_error("GameManager", "Graceful shutdown completed", "INFO")

#endregion

#region Legacy API Support (for backward compatibility)

## Legacy method - use start_new_session instead
func start_new_game() -> void:
	start_new_session("new_game")
	var scene_manager = get_system("SceneManager")
	if scene_manager:
		scene_manager.change_scene_by_key("main_hall")

## Legacy method - use start_new_session instead
func continue_game() -> void:
	var save_manager = get_system("SaveManager")
	if save_manager and save_manager.has_method("has_save_data") and save_manager.has_save_data(0):
		start_new_session("continue_game")
		save_manager.quick_load()
	else:
		_error_handler.log_error("GameManager", "No save data found for continue game")

## Legacy method - use transition_to_state instead
func pause_game() -> void:
	transition_to_state(GameState.PAUSED)

## Legacy method - use transition_to_state instead
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		transition_to_state(previous_state)

## Legacy method - use transition_to_state instead
func set_game_state(new_state: GameState) -> void:
	transition_to_state(new_state)

#endregion




