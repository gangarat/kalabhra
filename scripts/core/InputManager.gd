extends Node

## Input Manager
## Unified input handling for keyboard/mouse and touch interfaces
## Browser-compatible with customizable input mapping

signal input_action_pressed(action: String)
signal input_action_released(action: String)
signal input_vector_changed(action: String, vector: Vector2)
signal control_scheme_changed(scheme: String)

# Input schemes
enum ControlScheme {
	KEYBOARD_MOUSE,
	TOUCH,
	GAMEPAD,
	HYBRID
}

var current_scheme: ControlScheme = ControlScheme.KEYBOARD_MOUSE
var touch_enabled: bool = false
var gamepad_connected: bool = false

# Input state tracking
var action_states: Dictionary = {}
var input_vectors: Dictionary = {}
var touch_points: Dictionary = {}

# Touch controls
var virtual_joystick: Control = null
var touch_buttons: Dictionary = {}
var touch_sensitivity: float = 1.0
var touch_deadzone: float = 0.1

# Mouse sensitivity and settings
var mouse_sensitivity: float = 1.0
var mouse_invert_y: bool = false
var mouse_smoothing: bool = true

# Input mapping
var action_mappings: Dictionary = {
	"move_forward": ["w", "up"],
	"move_backward": ["s", "down"],
	"move_left": ["a", "left"],
	"move_right": ["d", "right"],
	"jump": ["space"],
	"interact": ["e", "mouse_left"],
	"menu": ["escape"],
	"camera_up": ["mouse_up"],
	"camera_down": ["mouse_down"],
	"camera_left": ["mouse_left_move"],
	"camera_right": ["mouse_right_move"]
}

func _ready():
	_detect_input_capabilities()
	_setup_input_handling()
	_load_input_settings()

func _input(event: InputEvent):
	_handle_input_event(event)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey or event is InputEventMouseButton:
		_handle_keyboard_mouse_input(event)
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		_handle_touch_input(event)

## Get current input vector for movement
func get_movement_vector() -> Vector2:
	var vector = Vector2.ZERO
	
	match current_scheme:
		ControlScheme.KEYBOARD_MOUSE:
			vector.x = Input.get_axis("move_left", "move_right")
			vector.y = Input.get_axis("move_forward", "move_backward")
		ControlScheme.TOUCH:
			vector = _get_touch_movement_vector()
		ControlScheme.GAMEPAD:
			vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	return vector

## Get camera input vector
func get_camera_vector() -> Vector2:
	var vector = Vector2.ZERO
	
	match current_scheme:
		ControlScheme.KEYBOARD_MOUSE:
			vector = _get_mouse_delta()
		ControlScheme.TOUCH:
			vector = _get_touch_camera_vector()
		ControlScheme.GAMEPAD:
			vector = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	
	return vector * mouse_sensitivity

## Check if action is currently pressed
func is_action_pressed(action: String) -> bool:
	return action_states.get(action, false)

## Check if action was just pressed this frame
func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)

## Check if action was just released this frame
func is_action_just_released(action: String) -> bool:
	return Input.is_action_just_released(action)

## Set control scheme
func set_control_scheme(scheme: ControlScheme) -> void:
	if current_scheme != scheme:
		current_scheme = scheme
		_update_control_scheme()
		control_scheme_changed.emit(_scheme_to_string(scheme))

## Enable/disable touch controls
func set_touch_enabled(enabled: bool) -> void:
	touch_enabled = enabled
	if touch_enabled and not virtual_joystick:
		_create_virtual_controls()
	elif not touch_enabled and virtual_joystick:
		_destroy_virtual_controls()

## Set mouse sensitivity
func set_mouse_sensitivity(sensitivity: float) -> void:
	mouse_sensitivity = clamp(sensitivity, 0.1, 5.0)

## Set touch sensitivity
func set_touch_sensitivity(sensitivity: float) -> void:
	touch_sensitivity = clamp(sensitivity, 0.1, 3.0)

## Remap an action to new inputs
func remap_action(action: String, inputs: Array[String]) -> void:
	action_mappings[action] = inputs
	_update_input_map()

## Get current control scheme as string
func get_control_scheme_string() -> String:
	return _scheme_to_string(current_scheme)

## Save input settings
func save_input_settings() -> void:
	var settings = {
		"control_scheme": _scheme_to_string(current_scheme),
		"mouse_sensitivity": mouse_sensitivity,
		"mouse_invert_y": mouse_invert_y,
		"touch_sensitivity": touch_sensitivity,
		"action_mappings": action_mappings
	}
	
	ConfigManager.set_category_settings("input", settings)

# Private methods

func _detect_input_capabilities() -> void:
	# Detect if running on touch device
	if OS.has_feature("mobile") or OS.has_feature("web"):
		touch_enabled = true
		current_scheme = ControlScheme.TOUCH
	
	# Check for gamepad
	var joypads = Input.get_connected_joypads()
	gamepad_connected = joypads.size() > 0

func _setup_input_handling() -> void:
	# Connect gamepad signals
	Input.joy_connection_changed.connect(_on_gamepad_connection_changed)
	
	# Set up initial control scheme
	_update_control_scheme()

func _load_input_settings() -> void:
	if ConfigManager:
		mouse_sensitivity = ConfigManager.get_setting("input", "mouse_sensitivity", 1.0)
		mouse_invert_y = ConfigManager.get_setting("input", "mouse_invert_y", false)
		touch_sensitivity = ConfigManager.get_setting("input", "touch_sensitivity", 1.0)
		
		var scheme_string = ConfigManager.get_setting("input", "control_scheme", "keyboard_mouse")
		current_scheme = _string_to_scheme(scheme_string)

func _handle_input_event(event: InputEvent) -> void:
	# Auto-detect control scheme based on input
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		if current_scheme != ControlScheme.KEYBOARD_MOUSE:
			set_control_scheme(ControlScheme.KEYBOARD_MOUSE)
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		if current_scheme != ControlScheme.TOUCH:
			set_control_scheme(ControlScheme.TOUCH)
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_scheme != ControlScheme.GAMEPAD:
			set_control_scheme(ControlScheme.GAMEPAD)

func _handle_keyboard_mouse_input(event: InputEvent) -> void:
	# Handle custom action mappings
	for action in action_mappings.keys():
		var inputs = action_mappings[action]
		var pressed = false
		
		for input_string in inputs:
			if _check_input_match(event, input_string):
				pressed = event.pressed if event.has_method("is_pressed") else true
				break
		
		if pressed != action_states.get(action, false):
			action_states[action] = pressed
			if pressed:
				input_action_pressed.emit(action)
			else:
				input_action_released.emit(action)

func _handle_touch_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position

func _get_touch_movement_vector() -> Vector2:
	if virtual_joystick and virtual_joystick.has_method("get_vector"):
		return virtual_joystick.get_vector()
	return Vector2.ZERO

func _get_touch_camera_vector() -> Vector2:
	# Implement touch camera controls
	# This would typically use touch drag for camera movement
	return Vector2.ZERO

func _get_mouse_delta() -> Vector2:
	var delta = Input.get_last_mouse_velocity() * 0.001
	if mouse_invert_y:
		delta.y = -delta.y
	return delta

func _create_virtual_controls() -> void:
	# Create virtual joystick and buttons for touch
	# This would be implemented with a proper virtual joystick scene
	pass

func _destroy_virtual_controls() -> void:
	if virtual_joystick:
		virtual_joystick.queue_free()
		virtual_joystick = null

func _update_control_scheme() -> void:
	match current_scheme:
		ControlScheme.TOUCH:
			if not virtual_joystick:
				_create_virtual_controls()
		_:
			if virtual_joystick:
				_destroy_virtual_controls()

func _update_input_map() -> void:
	# Update Godot's input map based on custom mappings
	for action in action_mappings.keys():
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		
		InputMap.add_action(action)
		
		for input_string in action_mappings[action]:
			var event = _string_to_input_event(input_string)
			if event:
				InputMap.action_add_event(action, event)

func _check_input_match(event: InputEvent, input_string: String) -> bool:
	# Check if event matches input string
	var target_event = _string_to_input_event(input_string)
	return target_event and event.is_match(target_event)

func _string_to_input_event(input_string: String) -> InputEvent:
	# Convert string to InputEvent
	# This is a simplified version - you'd want more comprehensive mapping
	match input_string.to_lower():
		"w":
			var event = InputEventKey.new()
			event.keycode = KEY_W
			return event
		"s":
			var event = InputEventKey.new()
			event.keycode = KEY_S
			return event
		"a":
			var event = InputEventKey.new()
			event.keycode = KEY_A
			return event
		"d":
			var event = InputEventKey.new()
			event.keycode = KEY_D
			return event
		"space":
			var event = InputEventKey.new()
			event.keycode = KEY_SPACE
			return event
		"escape":
			var event = InputEventKey.new()
			event.keycode = KEY_ESCAPE
			return event
		"mouse_left":
			var event = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			return event
	
	return null

func _scheme_to_string(scheme: ControlScheme) -> String:
	match scheme:
		ControlScheme.KEYBOARD_MOUSE:
			return "keyboard_mouse"
		ControlScheme.TOUCH:
			return "touch"
		ControlScheme.GAMEPAD:
			return "gamepad"
		ControlScheme.HYBRID:
			return "hybrid"
		_:
			return "keyboard_mouse"

func _string_to_scheme(scheme_string: String) -> ControlScheme:
	match scheme_string:
		"keyboard_mouse":
			return ControlScheme.KEYBOARD_MOUSE
		"touch":
			return ControlScheme.TOUCH
		"gamepad":
			return ControlScheme.GAMEPAD
		"hybrid":
			return ControlScheme.HYBRID
		_:
			return ControlScheme.KEYBOARD_MOUSE

func _on_gamepad_connection_changed(device: int, connected: bool) -> void:
	gamepad_connected = connected
	if connected and current_scheme != ControlScheme.GAMEPAD:
		set_control_scheme(ControlScheme.GAMEPAD)
