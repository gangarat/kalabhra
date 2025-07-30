extends Node

## UIManager - Advanced User Interface Coordination System
##
## The UIManager coordinates all user interface elements, educational overlays,
## accessibility options, and responsive design features for Light of the Kalabhra.
##
## Key Features:
## - Dynamic UI layout and responsive design
## - Educational overlay management
## - Accessibility features (screen reader, high contrast, etc.)
## - Multi-modal input support (touch, keyboard, gamepad)
## - Localization and text scaling
## - Performance-optimized UI rendering
##
## Usage Example:
## ```gdscript
## # Show educational overlay
## UIManager.show_educational_overlay("artifact_info", {
##     "title": "Ancient Column",
##     "description": "This column represents...",
##     "interactive_elements": ["zoom", "rotate", "info_panel"]
## })
## 
## # Enable accessibility features
## UIManager.enable_accessibility_mode(true)
## UIManager.set_text_scale(1.5)
## UIManager.enable_high_contrast(true)
## 
## # Create responsive layout
## UIManager.set_layout_mode("adaptive")
## UIManager.register_breakpoint("mobile", 768)
## ```

# UI system signals
signal ui_system_ready()
signal layout_changed(layout_mode: String, screen_size: Vector2)
signal accessibility_mode_changed(enabled: bool)

# Interface management signals
signal overlay_shown(overlay_id: String, overlay_type: String)
signal overlay_hidden(overlay_id: String)
signal modal_opened(modal_id: String)
signal modal_closed(modal_id: String)

# Educational UI signals
signal educational_content_displayed(content_id: String, content_type: String)
signal interactive_element_activated(element_id: String, element_type: String)
signal learning_progress_updated(progress_data: Dictionary)

# Accessibility signals
signal text_scale_changed(scale: float)
signal high_contrast_toggled(enabled: bool)
signal screen_reader_announcement(text: String, priority: int)
signal focus_changed(element: Control, focus_type: String)

# Input and navigation signals
signal navigation_mode_changed(mode: String)
signal input_method_detected(method: String)
signal screen_resized(new_size: Vector2)
signal focus_gained()
signal focus_lost()

## UI layout modes
enum LayoutMode {
	FIXED,
	RESPONSIVE,
	ADAPTIVE,
	EDUCATIONAL,
	MOBILE,
	TABLET,
	DESKTOP
}

## Overlay types
enum OverlayType {
	EDUCATIONAL,
	INFORMATIONAL,
	INTERACTIVE,
	ASSESSMENT,
	NOTIFICATION,
	MODAL
}

## Accessibility levels
enum AccessibilityLevel {
	NONE,
	BASIC,
	ENHANCED,
	FULL
}

# Core UI management
var active_overlays: Dictionary = {}
var ui_layers: Dictionary = {}
var modal_stack: Array[String] = []
var current_layout_mode: LayoutMode = LayoutMode.ADAPTIVE

# Screen and layout management
var screen_size: Vector2
var layout_breakpoints: Dictionary = {
	"mobile": 768,
	"tablet": 1024,
	"desktop": 1440,
	"large": 1920
}
var current_breakpoint: String = "desktop"

# Educational UI components
var educational_overlays: Dictionary = {}
var interactive_elements: Dictionary = {}
var learning_widgets: Dictionary = {}
var progress_indicators: Dictionary = {}

# Accessibility features
var accessibility_level: AccessibilityLevel = AccessibilityLevel.BASIC
var text_scale: float = 1.0
var high_contrast_enabled: bool = false
var screen_reader_enabled: bool = false
var keyboard_navigation_enabled: bool = true
var focus_indicators_enabled: bool = true

# Input and navigation
var current_input_method: String = "mouse"
var navigation_mode: String = "pointer"
var touch_enabled: bool = false
var gamepad_navigation: bool = false

# Performance and optimization
var ui_update_frequency: float = 60.0
var animation_quality: int = 2  # 0=none, 1=basic, 2=normal, 3=high
var ui_effects_enabled: bool = true
var render_scale: float = 1.0

# Theme and styling
var current_theme: String = "default"
var theme_variants: Dictionary = {}
var custom_styles: Dictionary = {}

func _ready():
	_initialize_ui_system()

func _notification(what):
	match what:
		NOTIFICATION_WM_SIZE_CHANGED:
			_handle_screen_resize()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_handle_focus_change(true)
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_handle_focus_change(false)

#region System Management

## Initialize the UI system
func initialize_system() -> bool:
	_setup_ui_layers()
	_setup_accessibility_features()
	_setup_responsive_design()
	_load_ui_configuration()
	_connect_input_signals()
	
	print("[UIManager] UI system initialized successfully")
	ui_system_ready.emit()
	return true

## Get system health status
func get_health_status() -> Dictionary:
	var health = {
		"status": "healthy",
		"active_overlays": active_overlays.size(),
		"modal_stack_depth": modal_stack.size(),
		"current_layout": current_layout_mode,
		"accessibility_level": accessibility_level,
		"screen_size": screen_size,
		"last_check": Time.get_unix_time_from_system()
	}
	
	# Check for potential issues
	if modal_stack.size() > 3:
		health["status"] = "warning"
		health["message"] = "Deep modal stack detected"
	
	if active_overlays.size() > 10:
		health["status"] = "warning"
		health["message"] = "High number of active overlays"
	
	return health

## Shutdown the UI system
func shutdown_system() -> void:
	_close_all_overlays()
	_clear_modal_stack()
	_save_ui_settings()
	print("[UIManager] UI system shutdown completed")

#endregion

#region Layout and Responsive Design

## Set the UI layout mode
## @param mode: Layout mode to use
func set_layout_mode(mode: LayoutMode) -> void:
	if current_layout_mode == mode:
		return
	
	current_layout_mode = mode
	_apply_layout_mode(mode)
	layout_changed.emit(_layout_mode_to_string(mode), screen_size)

## Register a layout breakpoint
## @param name: Breakpoint name
## @param width: Screen width threshold
func register_breakpoint(name: String, width: int) -> void:
	layout_breakpoints[name] = width
	_update_current_breakpoint()

## Get current screen breakpoint
## @return: Current breakpoint name
func get_current_breakpoint() -> String:
	return current_breakpoint

## Set render scale for performance optimization
## @param scale: Render scale factor (0.5 to 2.0)
func set_render_scale(scale: float) -> void:
	render_scale = clamp(scale, 0.5, 2.0)
	_apply_render_scale()

#endregion

#region Educational UI Management

## Show an educational overlay
## @param overlay_id: Unique identifier for the overlay
## @param config: Configuration for the overlay content and behavior
## @return: True if overlay was shown successfully
func show_educational_overlay(overlay_id: String, config: Dictionary) -> bool:
	if active_overlays.has(overlay_id):
		push_warning("[UIManager] Educational overlay already active: " + overlay_id)
		return false
	
	var overlay_type = config.get("type", "informational")
	var overlay_data = _create_educational_overlay(overlay_id, config)
	
	if not overlay_data:
		push_error("[UIManager] Failed to create educational overlay: " + overlay_id)
		return false
	
	# Add to appropriate UI layer
	var layer_name = config.get("layer", "educational")
	var ui_layer = _get_or_create_ui_layer(layer_name)
	ui_layer.add_child(overlay_data["node"])
	
	# Configure overlay behavior
	_configure_overlay_behavior(overlay_data, config)
	
	# Track the overlay
	active_overlays[overlay_id] = overlay_data
	educational_overlays[overlay_id] = overlay_data
	
	# Animate in if requested
	if config.get("animate_in", true):
		_animate_overlay_in(overlay_data["node"], config.get("animation", "fade"))
	
	overlay_shown.emit(overlay_id, overlay_type)
	educational_content_displayed.emit(overlay_id, overlay_type)
	
	return true

## Hide an educational overlay
## @param overlay_id: ID of the overlay to hide
## @param animate_out: Whether to animate the overlay out
func hide_educational_overlay(overlay_id: String, animate_out: bool = true) -> void:
	if not active_overlays.has(overlay_id):
		return
	
	var overlay_data = active_overlays[overlay_id]
	
	if animate_out:
		await _animate_overlay_out(overlay_data["node"], "fade")
	
	# Remove from UI
	overlay_data["node"].queue_free()
	
	# Clean up tracking
	active_overlays.erase(overlay_id)
	educational_overlays.erase(overlay_id)
	
	overlay_hidden.emit(overlay_id)

## Create an interactive learning element
## @param element_id: Unique identifier for the element
## @param element_type: Type of interactive element
## @param config: Configuration for the element
## @return: The created element node
func create_interactive_element(element_id: String, element_type: String, config: Dictionary) -> Control:
	var element_node = _create_element_by_type(element_type, config)
	
	if not element_node:
		push_error("[UIManager] Failed to create interactive element: " + element_type)
		return null
	
	# Setup interaction handling
	_setup_element_interactions(element_node, element_id, config)
	
	# Track the element
	interactive_elements[element_id] = {
		"node": element_node,
		"type": element_type,
		"config": config,
		"created_time": Time.get_unix_time_from_system()
	}
	
	return element_node

## Update learning progress display
## @param progress_data: Progress information to display
func update_learning_progress(progress_data: Dictionary) -> void:
	# Update progress indicators
	for indicator_id in progress_indicators.keys():
		var indicator = progress_indicators[indicator_id]
		_update_progress_indicator(indicator, progress_data)
	
	learning_progress_updated.emit(progress_data)

#endregion

#region Accessibility Features

## Enable or disable accessibility mode
## @param enabled: Whether to enable accessibility features
## @param level: Level of accessibility features to enable
func enable_accessibility_mode(enabled: bool, level: AccessibilityLevel = AccessibilityLevel.ENHANCED) -> void:
	if enabled:
		accessibility_level = level
		_apply_accessibility_features(level)
	else:
		accessibility_level = AccessibilityLevel.NONE
		_disable_accessibility_features()

	accessibility_mode_changed.emit(enabled)

## Set text scaling factor
## @param scale: Text scale multiplier (0.5 to 3.0)
func set_text_scale(scale: float) -> void:
	text_scale = clamp(scale, 0.5, 3.0)
	_apply_text_scaling()
	text_scale_changed.emit(text_scale)

## Enable or disable high contrast mode
## @param enabled: Whether to enable high contrast
func enable_high_contrast(enabled: bool) -> void:
	high_contrast_enabled = enabled
	_apply_high_contrast_theme(enabled)
	high_contrast_toggled.emit(enabled)

## Announce text to screen reader
## @param text: Text to announce
## @param priority: Announcement priority (0=low, 1=normal, 2=high)
func announce_to_screen_reader(text: String, priority: int = 1) -> void:
	if not screen_reader_enabled:
		return

	screen_reader_announcement.emit(text, priority)

#endregion

#region Private Implementation

## Initialize the UI system
func _initialize_ui_system() -> void:
	# Get initial screen size
	screen_size = get_viewport().get_visible_rect().size
	_update_current_breakpoint()

	# Initialize data structures
	active_overlays = {}
	ui_layers = {}
	educational_overlays = {}
	interactive_elements = {}
	learning_widgets = {}
	progress_indicators = {}

## Setup UI layers
func _setup_ui_layers() -> void:
	var layer_names = ["background", "game", "educational", "ui", "overlays", "modals", "notifications"]

	for i in range(layer_names.size()):
		var layer_name = layer_names[i]
		var layer = CanvasLayer.new()
		layer.name = layer_name
		layer.layer = i
		get_tree().root.add_child(layer)
		ui_layers[layer_name] = layer

## Update current breakpoint
func _update_current_breakpoint() -> void:
	var width = screen_size.x
	var new_breakpoint = "mobile"

	for breakpoint_name in layout_breakpoints.keys():
		if width >= layout_breakpoints[breakpoint_name]:
			new_breakpoint = breakpoint_name

	if new_breakpoint != current_breakpoint:
		current_breakpoint = new_breakpoint

## Get or create UI layer
func _get_or_create_ui_layer(layer_name: String) -> CanvasLayer:
	if ui_layers.has(layer_name):
		return ui_layers[layer_name]

	var layer = CanvasLayer.new()
	layer.name = layer_name
	layer.layer = ui_layers.size()
	get_tree().root.add_child(layer)
	ui_layers[layer_name] = layer

	return layer

## Create educational overlay
func _create_educational_overlay(overlay_id: String, config: Dictionary) -> Dictionary:
	# This would create the actual overlay UI based on config
	# For now, return a placeholder structure
	var overlay_node = Control.new()
	overlay_node.name = overlay_id

	return {
		"node": overlay_node,
		"type": config.get("type", "informational"),
		"config": config
	}

## Configure overlay behavior
func _configure_overlay_behavior(overlay_data: Dictionary, config: Dictionary) -> void:
	# Configure overlay-specific behavior
	pass

## Animate overlay in
func _animate_overlay_in(node: Control, animation: String) -> void:
	# Implement overlay animation
	pass

## Animate overlay out
func _animate_overlay_out(node: Control, animation: String) -> void:
	# Implement overlay animation
	pass

## Create element by type
func _create_element_by_type(element_type: String, config: Dictionary) -> Control:
	# Create different types of interactive elements
	match element_type:
		"button":
			return Button.new()
		"slider":
			return HSlider.new()
		"text_input":
			return LineEdit.new()
		_:
			return Control.new()

## Setup element interactions
func _setup_element_interactions(element: Control, element_id: String, config: Dictionary) -> void:
	# Setup interaction callbacks
	if element is Button:
		element.pressed.connect(_on_element_activated.bind(element_id, "button_press"))

## Update progress indicator
func _update_progress_indicator(indicator: Dictionary, progress_data: Dictionary) -> void:
	# Update progress display
	pass

## Apply accessibility features
func _apply_accessibility_features(level: AccessibilityLevel) -> void:
	# Apply accessibility features based on level
	pass

## Disable accessibility features
func _disable_accessibility_features() -> void:
	# Disable accessibility features
	pass

## Apply text scaling
func _apply_text_scaling() -> void:
	# Apply text scale to all UI elements
	pass

## Apply high contrast theme
func _apply_high_contrast_theme(enabled: bool) -> void:
	# Apply high contrast theme
	pass

## Element activated callback
func _on_element_activated(element_id: String, activation_type: String) -> void:
	interactive_element_activated.emit(element_id, activation_type)

#endregion

# Missing function implementations

func _handle_screen_resize() -> void:
	# Handle screen resize events
	var new_size = get_viewport().get_visible_rect().size
	if new_size != screen_size:
		screen_size = new_size
		screen_resized.emit(screen_size)
		_update_responsive_layout()

func _handle_focus_change(focused: bool) -> void:
	# Handle application focus changes
	if focused:
		focus_gained.emit()
	else:
		focus_lost.emit()

func _setup_accessibility_features() -> void:
	# Setup accessibility features
	pass

func _setup_responsive_design() -> void:
	# Setup responsive design system
	_update_responsive_layout()

func _load_ui_configuration() -> void:
	# Load UI configuration from settings
	if ConfigManager:
		render_scale = ConfigManager.get_setting("ui", "render_scale", 1.0)
		current_layout_mode = ConfigManager.get_setting("ui", "layout_mode", LayoutMode.ADAPTIVE)

func _connect_input_signals() -> void:
	# Connect input-related signals
	pass

func _close_all_overlays() -> void:
	# Close all open overlays
	for overlay in active_overlays.values():
		if overlay and is_instance_valid(overlay):
			overlay.queue_free()
	active_overlays.clear()

func _clear_modal_stack() -> void:
	# Clear modal dialog stack
	modal_stack.clear()

func _save_ui_settings() -> void:
	# Save UI settings
	if ConfigManager:
		ConfigManager.set_setting("ui", "render_scale", render_scale)
		ConfigManager.set_setting("ui", "layout_mode", current_layout_mode)

func _apply_layout_mode(mode: LayoutMode) -> void:
	# Apply the specified layout mode
	match mode:
		LayoutMode.MOBILE:
			_setup_mobile_layout()
		LayoutMode.TABLET:
			_setup_tablet_layout()
		LayoutMode.DESKTOP:
			_setup_desktop_layout()
		LayoutMode.ADAPTIVE:
			_setup_adaptive_layout()

func _layout_mode_to_string(mode: LayoutMode) -> String:
	match mode:
		LayoutMode.MOBILE:
			return "mobile"
		LayoutMode.TABLET:
			return "tablet"
		LayoutMode.DESKTOP:
			return "desktop"
		LayoutMode.ADAPTIVE:
			return "adaptive"
		_:
			return "unknown"

func _apply_render_scale() -> void:
	# Apply render scale to viewport
	if get_viewport():
		get_viewport().set_snap_2d_transforms_to_pixel(render_scale < 1.0)
		get_viewport().set_snap_2d_vertices_to_pixel(render_scale < 1.0)

func _update_responsive_layout() -> void:
	# Update layout based on screen size
	var width = screen_size.x

	# Determine layout mode based on screen width
	if width < layout_breakpoints["mobile"]:
		current_layout_mode = LayoutMode.MOBILE
	elif width < layout_breakpoints["tablet"]:
		current_layout_mode = LayoutMode.TABLET
	elif width < layout_breakpoints["desktop"]:
		current_layout_mode = LayoutMode.DESKTOP
	else:
		current_layout_mode = LayoutMode.DESKTOP

	_apply_layout_mode(current_layout_mode)

func _setup_mobile_layout() -> void:
	# Setup mobile-specific layout
	pass

func _setup_tablet_layout() -> void:
	# Setup tablet-specific layout
	pass

func _setup_desktop_layout() -> void:
	# Setup desktop-specific layout
	pass

func _setup_adaptive_layout() -> void:
	# Setup adaptive layout based on screen size
	var width = screen_size.x
	if width < 768:
		_setup_mobile_layout()
	elif width < 1024:
		_setup_tablet_layout()
	else:
		_setup_desktop_layout()
