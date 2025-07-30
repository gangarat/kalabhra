extends Node

## AccessibilityFramework - Comprehensive Accessibility Support System
##
## Advanced accessibility framework providing comprehensive support for learners
## with diverse needs, ensuring the Light of the Kalabhra educational experience
## is inclusive and accessible to all users.
##
## Key Features:
## - Screen reader support with detailed audio descriptions
## - Visual accessibility (high contrast, text scaling, color blind support)
## - Motor accessibility (alternative input methods, simplified controls)
## - Cognitive accessibility (simplified UI, extended time limits, clear navigation)
## - Hearing accessibility (visual indicators, subtitles, haptic feedback)
## - Customizable accessibility profiles for different needs
##
## Usage Example:
## ```gdscript
## # Enable comprehensive accessibility mode
## AccessibilityFramework.enable_accessibility_mode(true)
## AccessibilityFramework.apply_accessibility_profile("visual_impaired")
## 
## # Announce important information
## AccessibilityFramework.announce_to_screen_reader("Lesson started: Ancient Architecture", 2)
## 
## # Enable visual accessibility features
## AccessibilityFramework.set_high_contrast_mode(true)
## AccessibilityFramework.set_text_scale(1.5)
## ```

# Accessibility system signals
signal accessibility_mode_changed(enabled: bool, profile: String)
signal screen_reader_announcement(text: String, priority: int)
signal visual_accessibility_changed(feature: String, enabled: bool)
signal motor_accessibility_changed(feature: String, enabled: bool)
signal cognitive_accessibility_changed(feature: String, enabled: bool)
signal accessibility_profile_applied(profile_name: String, settings: Dictionary)

# User interaction signals
signal focus_changed(element: Control, focus_reason: String)
signal navigation_method_changed(method: String)
signal input_assistance_activated(assistance_type: String)

## Accessibility profiles for different needs
enum AccessibilityProfile {
	NONE,
	VISUAL_IMPAIRED,
	HEARING_IMPAIRED,
	MOTOR_IMPAIRED,
	COGNITIVE_SUPPORT,
	COMPREHENSIVE,
	CUSTOM
}

## Screen reader priority levels
enum ScreenReaderPriority {
	LOW = 0,
	NORMAL = 1,
	HIGH = 2,
	URGENT = 3
}

## Navigation methods
enum NavigationMethod {
	MOUSE,
	KEYBOARD,
	TOUCH,
	GAMEPAD,
	VOICE,
	EYE_TRACKING,
	SWITCH_CONTROL
}

# Core accessibility state
var accessibility_enabled: bool = false
var current_profile: AccessibilityProfile = AccessibilityProfile.NONE
var custom_settings: Dictionary = {}

# Visual accessibility
var high_contrast_enabled: bool = false
var text_scale_factor: float = 1.0
var color_blind_support: bool = false
var motion_reduction: bool = false
var flash_reduction: bool = false
var focus_indicators_enhanced: bool = false

# Screen reader and audio
var screen_reader_enabled: bool = false
var audio_descriptions_enabled: bool = false
var sound_visualization_enabled: bool = false
var speech_rate: float = 1.0
var audio_cues_enabled: bool = true

# Motor accessibility
var simplified_controls: bool = false
var sticky_keys: bool = false
var slow_keys: bool = false
var mouse_keys: bool = false
var dwell_clicking: bool = false
var gesture_alternatives: bool = false

# Cognitive accessibility
var simplified_ui: bool = false
var extended_time_limits: bool = false
var clear_navigation: bool = true
var reduced_distractions: bool = false
var memory_aids: bool = false
var reading_assistance: bool = false

# Navigation and focus
var current_navigation_method: NavigationMethod = NavigationMethod.MOUSE
var focus_management_enabled: bool = true
var keyboard_navigation_enabled: bool = true
var focus_history: Array[Control] = []

# Customization
var accessibility_themes: Dictionary = {}
var user_preferences: Dictionary = {}
var profile_configurations: Dictionary = {}

func _ready():
	_initialize_accessibility_framework()
	_load_accessibility_settings()
	_setup_accessibility_themes()

#region Core Accessibility Management

## Enable or disable accessibility mode
## @param enabled: Whether to enable accessibility features
## @param profile: Accessibility profile to apply
func enable_accessibility_mode(enabled: bool, profile: AccessibilityProfile = AccessibilityProfile.COMPREHENSIVE) -> void:
	accessibility_enabled = enabled
	
	if enabled:
		current_profile = profile
		_apply_accessibility_profile(profile)
	else:
		current_profile = AccessibilityProfile.NONE
		_disable_all_accessibility_features()
	
	accessibility_mode_changed.emit(enabled, _profile_to_string(profile))

## Apply a specific accessibility profile
## @param profile: Accessibility profile to apply
func apply_accessibility_profile(profile: AccessibilityProfile) -> void:
	current_profile = profile
	_apply_accessibility_profile(profile)
	
	var profile_settings = _get_profile_settings(profile)
	accessibility_profile_applied.emit(_profile_to_string(profile), profile_settings)

## Create custom accessibility profile
## @param profile_name: Name for the custom profile
## @param settings: Dictionary of accessibility settings
func create_custom_profile(profile_name: String, settings: Dictionary) -> void:
	profile_configurations[profile_name] = settings
	custom_settings = settings.duplicate()
	_apply_custom_settings(settings)

## Get current accessibility status
## @return: Dictionary with current accessibility state
func get_accessibility_status() -> Dictionary:
	return {
		"enabled": accessibility_enabled,
		"profile": _profile_to_string(current_profile),
		"visual_features": _get_visual_accessibility_status(),
		"audio_features": _get_audio_accessibility_status(),
		"motor_features": _get_motor_accessibility_status(),
		"cognitive_features": _get_cognitive_accessibility_status(),
		"navigation_method": _navigation_method_to_string(current_navigation_method)
	}

#endregion

#region Visual Accessibility

## Enable or disable high contrast mode
## @param enabled: Whether to enable high contrast
func set_high_contrast_mode(enabled: bool) -> void:
	high_contrast_enabled = enabled
	_apply_high_contrast_theme(enabled)
	visual_accessibility_changed.emit("high_contrast", enabled)

## Set text scaling factor
## @param scale: Text scale multiplier (0.5 to 3.0)
func set_text_scale(scale: float) -> void:
	text_scale_factor = clamp(scale, 0.5, 3.0)
	_apply_text_scaling(text_scale_factor)
	visual_accessibility_changed.emit("text_scale", true)

## Enable color blind support
## @param enabled: Whether to enable color blind support
## @param color_blind_type: Type of color blindness to support
func set_color_blind_support(enabled: bool, color_blind_type: String = "deuteranopia") -> void:
	color_blind_support = enabled
	_apply_color_blind_filters(enabled, color_blind_type)
	visual_accessibility_changed.emit("color_blind_support", enabled)

## Enable motion reduction
## @param enabled: Whether to reduce motion and animations
func set_motion_reduction(enabled: bool) -> void:
	motion_reduction = enabled
	_apply_motion_reduction(enabled)
	visual_accessibility_changed.emit("motion_reduction", enabled)

## Enable enhanced focus indicators
## @param enabled: Whether to show enhanced focus indicators
func set_enhanced_focus_indicators(enabled: bool) -> void:
	focus_indicators_enhanced = enabled
	_apply_enhanced_focus_indicators(enabled)
	visual_accessibility_changed.emit("focus_indicators", enabled)

#endregion

#region Screen Reader and Audio Accessibility

## Enable or disable screen reader support
## @param enabled: Whether to enable screen reader
func enable_screen_reader(enabled: bool) -> void:
	screen_reader_enabled = enabled
	
	if enabled:
		_setup_screen_reader_support()
	else:
		_disable_screen_reader_support()

## Announce text to screen reader
## @param text: Text to announce
## @param priority: Announcement priority level
func announce_to_screen_reader(text: String, priority: ScreenReaderPriority = ScreenReaderPriority.NORMAL) -> void:
	if not screen_reader_enabled:
		return
	
	_queue_screen_reader_announcement(text, priority)
	screen_reader_announcement.emit(text, priority)

## Enable audio descriptions for visual content
## @param enabled: Whether to enable audio descriptions
func enable_audio_descriptions(enabled: bool) -> void:
	audio_descriptions_enabled = enabled
	
	if AudioManager:
		AudioManager.enable_audio_descriptions(enabled)

## Enable sound visualization for hearing impaired users
## @param enabled: Whether to enable sound visualization
func enable_sound_visualization(enabled: bool) -> void:
	sound_visualization_enabled = enabled
	
	if AudioManager:
		AudioManager.set_sound_visualization(enabled)

## Set speech rate for screen reader
## @param rate: Speech rate multiplier (0.5 to 2.0)
func set_speech_rate(rate: float) -> void:
	speech_rate = clamp(rate, 0.5, 2.0)
	_apply_speech_rate(speech_rate)

#endregion

#region Motor Accessibility

## Enable simplified controls
## @param enabled: Whether to enable simplified control scheme
func enable_simplified_controls(enabled: bool) -> void:
	simplified_controls = enabled
	_apply_simplified_controls(enabled)
	motor_accessibility_changed.emit("simplified_controls", enabled)

## Enable sticky keys functionality
## @param enabled: Whether to enable sticky keys
func enable_sticky_keys(enabled: bool) -> void:
	sticky_keys = enabled
	_setup_sticky_keys(enabled)
	motor_accessibility_changed.emit("sticky_keys", enabled)

## Enable dwell clicking for mouse-free interaction
## @param enabled: Whether to enable dwell clicking
## @param dwell_time: Time to dwell before clicking (seconds)
func enable_dwell_clicking(enabled: bool, dwell_time: float = 1.0) -> void:
	dwell_clicking = enabled
	_setup_dwell_clicking(enabled, dwell_time)
	motor_accessibility_changed.emit("dwell_clicking", enabled)

## Enable gesture alternatives for complex interactions
## @param enabled: Whether to enable gesture alternatives
func enable_gesture_alternatives(enabled: bool) -> void:
	gesture_alternatives = enabled
	_setup_gesture_alternatives(enabled)
	motor_accessibility_changed.emit("gesture_alternatives", enabled)

#endregion

#region Cognitive Accessibility

## Enable simplified user interface
## @param enabled: Whether to enable simplified UI
func enable_simplified_ui(enabled: bool) -> void:
	simplified_ui = enabled
	_apply_simplified_ui(enabled)
	cognitive_accessibility_changed.emit("simplified_ui", enabled)

## Enable extended time limits for activities
## @param enabled: Whether to extend time limits
## @param multiplier: Time limit multiplier
func enable_extended_time_limits(enabled: bool, multiplier: float = 2.0) -> void:
	extended_time_limits = enabled
	_apply_extended_time_limits(enabled, multiplier)
	cognitive_accessibility_changed.emit("extended_time_limits", enabled)

## Enable memory aids and reminders
## @param enabled: Whether to enable memory aids
func enable_memory_aids(enabled: bool) -> void:
	memory_aids = enabled
	_setup_memory_aids(enabled)
	cognitive_accessibility_changed.emit("memory_aids", enabled)

## Enable reading assistance features
## @param enabled: Whether to enable reading assistance
func enable_reading_assistance(enabled: bool) -> void:
	reading_assistance = enabled
	_setup_reading_assistance(enabled)
	cognitive_accessibility_changed.emit("reading_assistance", enabled)

#endregion

#region Navigation and Focus Management

## Set navigation method
## @param method: Navigation method to use
func set_navigation_method(method: NavigationMethod) -> void:
	current_navigation_method = method
	_configure_navigation_method(method)
	navigation_method_changed.emit(_navigation_method_to_string(method))

## Set focus on element with accessibility announcement
## @param element: Element to focus
## @param reason: Reason for focus change
func set_accessible_focus(element: Control, reason: String = "programmatic") -> void:
	if not element or not is_instance_valid(element):
		return
	
	# Update focus history
	if focus_history.size() > 10:
		focus_history.pop_front()
	focus_history.append(element)
	
	# Set focus
	element.grab_focus()
	
	# Announce focus change if screen reader is enabled
	if screen_reader_enabled:
		var focus_text = _get_element_accessibility_text(element)
		announce_to_screen_reader(focus_text, ScreenReaderPriority.NORMAL)
	
	focus_changed.emit(element, reason)

## Navigate to next focusable element
## @param direction: Navigation direction (1 for forward, -1 for backward)
func navigate_focus(direction: int = 1) -> void:
	if not keyboard_navigation_enabled:
		return
	
	var current_focus = get_viewport().gui_get_focus_owner()
	var next_focus = _find_next_focusable_element(current_focus, direction)
	
	if next_focus:
		set_accessible_focus(next_focus, "keyboard_navigation")

#endregion

#region Private Implementation

## Initialize accessibility framework
func _initialize_accessibility_framework() -> void:
	_create_default_accessibility_themes()
	_initialize_profile_configurations()
	_setup_input_monitoring()

## Load accessibility settings from user preferences
func _load_accessibility_settings() -> void:
	if ConfigManager:
		var accessibility_config = ConfigManager.get_category_settings("accessibility")
		accessibility_enabled = accessibility_config.get("enabled", false)
		text_scale_factor = accessibility_config.get("text_scale", 1.0)
		high_contrast_enabled = accessibility_config.get("high_contrast", false)
		screen_reader_enabled = accessibility_config.get("screen_reader", false)

## Apply accessibility profile settings
func _apply_accessibility_profile(profile: AccessibilityProfile) -> void:
	match profile:
		AccessibilityProfile.VISUAL_IMPAIRED:
			_apply_visual_impaired_profile()
		AccessibilityProfile.HEARING_IMPAIRED:
			_apply_hearing_impaired_profile()
		AccessibilityProfile.MOTOR_IMPAIRED:
			_apply_motor_impaired_profile()
		AccessibilityProfile.COGNITIVE_SUPPORT:
			_apply_cognitive_support_profile()
		AccessibilityProfile.COMPREHENSIVE:
			_apply_comprehensive_profile()

## Apply visual impaired accessibility profile
func _apply_visual_impaired_profile() -> void:
	set_high_contrast_mode(true)
	set_text_scale(1.5)
	enable_screen_reader(true)
	enable_audio_descriptions(true)
	set_enhanced_focus_indicators(true)
	enable_sound_visualization(true)

## Apply comprehensive accessibility profile
func _apply_comprehensive_profile() -> void:
	_apply_visual_impaired_profile()
	enable_simplified_controls(true)
	enable_simplified_ui(true)
	enable_extended_time_limits(true)

## Convert profile enum to string
func _profile_to_string(profile: AccessibilityProfile) -> String:
	match profile:
		AccessibilityProfile.NONE: return "none"
		AccessibilityProfile.VISUAL_IMPAIRED: return "visual_impaired"
		AccessibilityProfile.HEARING_IMPAIRED: return "hearing_impaired"
		AccessibilityProfile.MOTOR_IMPAIRED: return "motor_impaired"
		AccessibilityProfile.COGNITIVE_SUPPORT: return "cognitive_support"
		AccessibilityProfile.COMPREHENSIVE: return "comprehensive"
		AccessibilityProfile.CUSTOM: return "custom"
		_: return "unknown"

## Convert navigation method to string
func _navigation_method_to_string(method: NavigationMethod) -> String:
	match method:
		NavigationMethod.MOUSE: return "mouse"
		NavigationMethod.KEYBOARD: return "keyboard"
		NavigationMethod.TOUCH: return "touch"
		NavigationMethod.GAMEPAD: return "gamepad"
		NavigationMethod.VOICE: return "voice"
		NavigationMethod.EYE_TRACKING: return "eye_tracking"
		NavigationMethod.SWITCH_CONTROL: return "switch_control"
		_: return "unknown"

## Get accessibility text for UI element
func _get_element_accessibility_text(element: Control) -> String:
	var text = element.get_class() + " "
	if element.has_method("get_text"):
		text += element.get_text()
	elif element.has_method("get_name"):
		text += element.get_name()
	if element.disabled:
		text += " disabled"
	return text

## Find next focusable element in navigation order
func _find_next_focusable_element(current: Control, direction: int) -> Control:
	if not current:
		return null
	var parent = current.get_parent()
	if not parent:
		return null
	var children = parent.get_children()
	var current_index = children.find(current)
	if current_index == -1:
		return null
	var next_index = current_index + direction
	if next_index >= 0 and next_index < children.size():
		var next_child = children[next_index]
		if next_child is Control and next_child.can_focus():
			return next_child
	return null

## Placeholder methods for missing functionality
func _setup_accessibility_themes() -> void: pass
func _disable_all_accessibility_features() -> void: pass
func _apply_custom_settings(settings: Dictionary) -> void: pass
func _apply_high_contrast_theme(enabled: bool) -> void: pass
func _apply_text_scaling(scale: float) -> void: pass
func _apply_color_blind_filters(enabled: bool, type: String) -> void: pass
func _apply_motion_reduction(enabled: bool) -> void: pass
func _apply_enhanced_focus_indicators(enabled: bool) -> void: pass
func _setup_screen_reader_support() -> void: pass
func _disable_screen_reader_support() -> void: pass
func _queue_screen_reader_announcement(text: String, priority: ScreenReaderPriority) -> void: pass
func _apply_speech_rate(rate: float) -> void: pass
func _apply_simplified_controls(enabled: bool) -> void: pass
func _setup_sticky_keys(enabled: bool) -> void: pass
func _setup_dwell_clicking(enabled: bool, dwell_time: float) -> void: pass
func _setup_gesture_alternatives(enabled: bool) -> void: pass
func _apply_simplified_ui(enabled: bool) -> void: pass
func _apply_extended_time_limits(enabled: bool, multiplier: float) -> void: pass
func _setup_memory_aids(enabled: bool) -> void: pass
func _setup_reading_assistance(enabled: bool) -> void: pass
func _configure_navigation_method(method: NavigationMethod) -> void: pass
func _create_default_accessibility_themes() -> void: pass
func _initialize_profile_configurations() -> void: pass
func _setup_input_monitoring() -> void: pass
func _apply_hearing_impaired_profile() -> void: pass
func _apply_motor_impaired_profile() -> void: pass
func _apply_cognitive_support_profile() -> void: pass
func _get_profile_settings(profile: AccessibilityProfile) -> Dictionary: return {}
func _string_to_profile(profile_string: String) -> AccessibilityProfile: return AccessibilityProfile.NONE
func _get_visual_accessibility_status() -> Dictionary: return {}
func _get_audio_accessibility_status() -> Dictionary: return {}
func _get_motor_accessibility_status() -> Dictionary: return {}
func _get_cognitive_accessibility_status() -> Dictionary: return {}

#endregion
