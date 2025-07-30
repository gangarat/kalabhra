# Light of the Kalabhra - API Documentation

## Core System APIs

This document provides comprehensive API documentation for all core systems in Light of the Kalabhra.

## GameManager API

### System Management

```gdscript
# Initialize a new educational session
func start_new_session(session_type: String, session_config: Dictionary = {}) -> String
# Parameters:
#   session_type: "lesson", "assessment", "exploration", "free_play"
#   session_config: Optional configuration data
# Returns: Session ID if successful, empty string if failed

# End the current educational session
func end_current_session(save_data: bool = true) -> float
# Parameters:
#   save_data: Whether to save session data
# Returns: Session duration in seconds

# Transition to a new game state with validation
func transition_to_state(new_state: GameState, force: bool = false) -> bool
# Parameters:
#   new_state: Target game state (MAIN_MENU, LOADING, PLAYING, etc.)
#   force: Whether to force transition even if invalid
# Returns: True if transition was successful

# Get a reference to a system safely
func get_system(system_name: String) -> Node
# Parameters:
#   system_name: Name of the system to retrieve
# Returns: System reference or null if not found/ready

# Check if all critical systems are ready
func are_systems_ready() -> bool
# Returns: True if all systems are initialized and ready
```

### Example Usage

```gdscript
# Start a lesson session
var session_id = GameManager.start_new_session("lesson", {
    "lesson_id": "ancient_architecture",
    "difficulty": "intermediate",
    "time_limit": 1800  # 30 minutes
})

# Safely access education system
var education_mgr = GameManager.get_system("EducationManager")
if education_mgr:
    education_mgr.start_lesson("introduction")
```

## EducationManager API

### Lesson Management

```gdscript
# Start a new lesson
func start_lesson(lesson_id: String, config: Dictionary = {}) -> bool
# Parameters:
#   lesson_id: Unique identifier for the lesson
#   config: Optional configuration for lesson customization
# Returns: True if lesson started successfully

# Complete the current lesson
func complete_lesson(completion_data: Dictionary = {}) -> Dictionary
# Parameters:
#   completion_data: Additional data about lesson completion
# Returns: Completion results and performance data

# Complete a learning objective
func complete_objective(objective_id: String, completion_data: Dictionary = {}) -> void
# Parameters:
#   objective_id: ID of the objective to complete
#   completion_data: Data about how the objective was completed
```

### Assessment System

```gdscript
# Create and start an assessment
func create_assessment(assessment_type: String, config: Dictionary = {}) -> String
# Parameters:
#   assessment_type: "quiz", "practical", "exploration", "interaction", "reflection"
#   config: Configuration for the assessment
# Returns: Assessment ID if successful, empty string if failed

# Submit an answer to an assessment question
func submit_assessment_answer(assessment_id: String, question_id: String, answer_data: Dictionary) -> bool
# Parameters:
#   assessment_id: ID of the active assessment
#   question_id: ID of the question being answered
#   answer_data: The answer data (answer, time_taken, etc.)
# Returns: True if answer was recorded successfully
```

### Analytics and Progress

```gdscript
# Get learning analytics for a specific time period
func get_learning_analytics(start_time: float = 0.0, end_time: float = 0.0) -> Dictionary
# Parameters:
#   start_time: Start timestamp (0 for all time)
#   end_time: End timestamp (0 for current time)
# Returns: Analytics data for the specified period

# Get mastery level for a specific topic
func get_mastery_level(topic: String) -> float
# Parameters:
#   topic: Topic to check mastery for
# Returns: Mastery level (0.0 to 1.0)
```

### Example Usage

```gdscript
# Start a lesson with custom configuration
var lesson_started = EducationManager.start_lesson("ancient_architecture", {
    "difficulty": "advanced",
    "enable_hints": true,
    "time_tracking": true
})

# Create a quiz assessment
var assessment_id = EducationManager.create_assessment("quiz", {
    "questions": 10,
    "time_limit": 600,  # 10 minutes
    "randomize_questions": true,
    "difficulty": "intermediate"
})

# Submit an answer
EducationManager.submit_assessment_answer(assessment_id, "q1", {
    "answer": 2,  # Multiple choice option
    "time_taken": 15.5,
    "confidence": 0.8
})
```

## SceneManager API

### Scene Loading

```gdscript
# Load a scene asynchronously with advanced options
func load_scene_async(scene_id: String, config: Dictionary = {}) -> bool
# Parameters:
#   scene_id: Identifier for the scene to load
#   config: Configuration options for loading and transition
# Returns: True if loading started successfully

# Preload multiple scenes as a batch
func preload_scene_batch(scene_ids: Array[String], priority: int = 1) -> void
# Parameters:
#   scene_ids: Array of scene IDs to preload
#   priority: Loading priority for the batch

# Unload a scene from memory
func unload_scene(scene_id: String, force: bool = false) -> int
# Parameters:
#   scene_id: Scene to unload
#   force: Force unload even if scene is in use
# Returns: Amount of memory freed in bytes
```

### State Management

```gdscript
# Preserve current scene state
func preserve_current_scene_state(include_education_context: bool = true) -> void
# Parameters:
#   include_education_context: Whether to preserve educational context

# Set global state that persists across all scenes
func set_global_state(key: String, value) -> void
# Parameters:
#   key: State key
#   value: State value

# Get global state value
func get_global_state(key: String, default_value = null)
# Parameters:
#   key: State key
#   default_value: Default value if key not found
# Returns: State value or default
```

### Example Usage

```gdscript
# Load scene with custom transition
SceneManager.load_scene_async("sanctuary_hall", {
    "transition": "fade_with_loading",
    "preserve_education_state": true,
    "preload_adjacent": true
})

# Preload related scenes
SceneManager.preload_scene_batch(["chamber_1", "chamber_2", "chamber_3"], 2)

# Set persistent state
SceneManager.set_global_state("current_lesson_progress", 0.75)
```

## AudioManager API

### Spatial Audio

```gdscript
# Play spatial sound effect
func play_spatial_sfx(sfx_name: String, position: Vector3, config: Dictionary = {}) -> String
# Parameters:
#   sfx_name: Name of the sound effect
#   position: 3D position for the sound
#   config: Additional configuration options
# Returns: Audio source ID for tracking

# Update spatial listener position and orientation
func update_spatial_listener(position: Vector3, forward: Vector3 = Vector3.FORWARD, up: Vector3 = Vector3.UP) -> void
# Parameters:
#   position: Listener position in 3D space
#   forward: Forward direction vector
#   up: Up direction vector

# Create an interactive audio zone
func create_audio_zone(zone_id: String, position: Vector3, radius: float, audio_config: Dictionary) -> void
# Parameters:
#   zone_id: Unique identifier for the zone
#   position: Center position of the zone
#   radius: Radius of the zone
#   audio_config: Audio configuration for the zone
```

### Advanced Music System

```gdscript
# Start adaptive music that responds to game context
func start_adaptive_music(track_name: String, config: Dictionary = {}) -> void
# Parameters:
#   track_name: Base music track name
#   config: Configuration for adaptive behavior

# Adjust music intensity dynamically
func set_music_intensity(intensity: float, transition_time: float = 2.0) -> void
# Parameters:
#   intensity: Intensity level (0.0 to 1.0)
#   transition_time: Time to transition to new intensity

# Trigger adaptive music event
func trigger_adaptive_music(trigger: String, context: Dictionary = {}) -> void
# Parameters:
#   trigger: Event trigger name
#   context: Additional context data
```

### Accessibility Features

```gdscript
# Enable or disable audio descriptions
func enable_audio_descriptions(enabled: bool) -> void
# Parameters:
#   enabled: Whether to enable audio descriptions

# Enable or disable sound visualization
func set_sound_visualization(enabled: bool) -> void
# Parameters:
#   enabled: Whether to enable sound visualization

# Play audio description
func play_audio_description(description_id: String, text: String, priority: int = 1) -> void
# Parameters:
#   description_id: ID of the description to play
#   text: Text content of the description
#   priority: Playback priority
```

### Example Usage

```gdscript
# Play spatial footstep sound
var audio_id = AudioManager.play_spatial_sfx("footstep_stone", player_position, {
    "max_distance": 50.0,
    "attenuation": 2.0,
    "reverb_zone": "stone_hall"
})

# Start adaptive exploration music
AudioManager.start_adaptive_music("exploration", {
    "intensity": 0.7,
    "educational_context": "ancient_architecture",
    "mood": "mysterious"
})

# Enable accessibility features
AudioManager.enable_audio_descriptions(true)
AudioManager.set_sound_visualization(true)
```

## UIManager API

### Educational UI Management

```gdscript
# Show an educational overlay
func show_educational_overlay(overlay_id: String, config: Dictionary) -> bool
# Parameters:
#   overlay_id: Unique identifier for the overlay
#   config: Configuration for the overlay content and behavior
# Returns: True if overlay was shown successfully

# Create an interactive learning element
func create_interactive_element(element_id: String, element_type: String, config: Dictionary) -> Control
# Parameters:
#   element_id: Unique identifier for the element
#   element_type: Type of interactive element
#   config: Configuration for the element
# Returns: The created element node

# Update learning progress display
func update_learning_progress(progress_data: Dictionary) -> void
# Parameters:
#   progress_data: Progress information to display
```

### Accessibility Features

```gdscript
# Enable or disable accessibility mode
func enable_accessibility_mode(enabled: bool, level: AccessibilityLevel = AccessibilityLevel.ENHANCED) -> void
# Parameters:
#   enabled: Whether to enable accessibility features
#   level: Level of accessibility features to enable

# Set text scaling factor
func set_text_scale(scale: float) -> void
# Parameters:
#   scale: Text scale multiplier (0.5 to 3.0)

# Announce text to screen reader
func announce_to_screen_reader(text: String, priority: int = 1) -> void
# Parameters:
#   text: Text to announce
#   priority: Announcement priority (0=low, 1=normal, 2=high)
```

### Example Usage

```gdscript
# Show artifact information overlay
UIManager.show_educational_overlay("artifact_info", {
    "title": "Ancient Column",
    "description": "This Doric column represents...",
    "interactive_elements": ["zoom", "rotate", "info_panel"],
    "animation": "slide_in_from_right"
})

# Enable accessibility features
UIManager.enable_accessibility_mode(true, UIManager.AccessibilityLevel.FULL)
UIManager.set_text_scale(1.5)
UIManager.enable_high_contrast(true)
```

## Error Handling Patterns

### System Availability Checking

```gdscript
# Always check system availability
var audio_mgr = GameManager.get_system("AudioManager")
if audio_mgr and audio_mgr.has_method("play_spatial_sfx"):
    audio_mgr.play_spatial_sfx("sound_name", position)
else:
    print("AudioManager not available or method not found")
```

### Graceful Fallbacks

```gdscript
# Implement fallbacks for missing features
if AudioManager.spatial_audio_enabled:
    AudioManager.play_spatial_sfx("footstep", position)
else:
    AudioManager.play_sfx("footstep")  # Fallback to 2D audio
```

### Signal-Based Error Handling

```gdscript
# Connect to error signals
GameManager.system_error.connect(_on_system_error)
EducationManager.asset_loading_failed.connect(_on_asset_loading_failed)

func _on_system_error(system_name: String, error_message: String):
    print("System error in ", system_name, ": ", error_message)
    # Implement recovery logic
```

This API documentation provides the essential interfaces for integrating with the Light of the Kalabhra core systems. Each system is designed with clear interfaces, comprehensive error handling, and extensive configuration options to support diverse educational gaming scenarios.
