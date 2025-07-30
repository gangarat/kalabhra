# Light of the Kalabhra - System Architecture Guide

## Core System Overview

The Light of the Kalabhra project implements a sophisticated modular architecture with seven core systems that work together to provide a comprehensive educational gaming experience. Each system is implemented as a singleton with clear interfaces and proper error handling.

## System Initialization Order

The systems are initialized in a specific order to ensure proper dependencies:

1. **ConfigManager** - Configuration and settings management
2. **AssetManager** - Asset loading and memory management  
3. **AudioManager** - Audio system with spatial audio support
4. **UIManager** - User interface coordination and accessibility
5. **SceneManager** - Scene loading and transition management
6. **EducationManager** - Educational content and progress tracking
7. **InputManager** - Unified input handling
8. **SaveManager** - Save/load system for progress data
9. **LocalizationManager** - Multi-language support
10. **GameManager** - Main coordinator and system orchestrator

## System Interfaces and Communication

### GameManager - System Coordinator

**Primary Responsibilities:**
- System lifecycle management (initialization, shutdown)
- Global state management and persistence
- Inter-system communication coordination
- Error handling and recovery
- Performance monitoring and optimization
- Educational session management

**Key Methods:**
```gdscript
# System management
GameManager.initialize_system() -> bool
GameManager.get_system(system_name: String) -> Node
GameManager.are_systems_ready() -> bool

# Session management
GameManager.start_new_session(session_type: String, config: Dictionary) -> String
GameManager.end_current_session(save_data: bool) -> float

# State management
GameManager.transition_to_state(new_state: GameState, force: bool) -> bool
GameManager.get_performance_metrics() -> Dictionary
```

### EducationManager - Educational Content System

**Primary Responsibilities:**
- Lesson and curriculum management
- Assessment creation and evaluation
- Learning progress tracking and analytics
- Adaptive difficulty adjustment
- Educational content delivery
- Learning objective management

**Key Methods:**
```gdscript
# Lesson management
EducationManager.start_lesson(lesson_id: String, config: Dictionary) -> bool
EducationManager.complete_lesson(completion_data: Dictionary) -> Dictionary
EducationManager.complete_objective(objective_id: String, completion_data: Dictionary)

# Assessment system
EducationManager.create_assessment(assessment_type: String, config: Dictionary) -> String
EducationManager.submit_assessment_answer(assessment_id: String, question_id: String, answer_data: Dictionary) -> bool

# Analytics and progress
EducationManager.get_learning_analytics(start_time: float, end_time: float) -> Dictionary
EducationManager.get_mastery_level(topic: String) -> float
```

### SceneManager - Advanced Scene Management

**Primary Responsibilities:**
- Asynchronous scene loading with progress tracking
- Advanced state preservation and restoration
- Memory-efficient scene caching and unloading
- Smooth transitions with customizable effects
- Educational context preservation

**Key Methods:**
```gdscript
# Scene loading
SceneManager.load_scene_async(scene_id: String, config: Dictionary) -> bool
SceneManager.preload_scene_batch(scene_ids: Array[String], priority: int)
SceneManager.unload_scene(scene_id: String, force: bool) -> int

# State management
SceneManager.preserve_current_scene_state(include_education_context: bool)
SceneManager.restore_scene_state(scene_id: String, scene_node: Node)
SceneManager.set_global_state(key: String, value)
```

### AudioManager - Spatial Audio and Accessibility

**Primary Responsibilities:**
- 3D spatial audio with distance attenuation and occlusion
- Advanced music management with seamless transitions
- Accessibility features (audio descriptions, sound visualization)
- Educational audio support (narration, interactive sounds)
- Dynamic audio mixing and effects processing

**Key Methods:**
```gdscript
# Spatial audio
AudioManager.play_spatial_sfx(sfx_name: String, position: Vector3, config: Dictionary) -> String
AudioManager.update_spatial_listener(position: Vector3, forward: Vector3, up: Vector3)
AudioManager.create_audio_zone(zone_id: String, position: Vector3, radius: float, audio_config: Dictionary)

# Advanced music
AudioManager.start_adaptive_music(track_name: String, config: Dictionary)
AudioManager.set_music_intensity(intensity: float, transition_time: float)
AudioManager.trigger_adaptive_music(trigger: String, context: Dictionary)

# Accessibility
AudioManager.enable_audio_descriptions(enabled: bool)
AudioManager.set_sound_visualization(enabled: bool)
AudioManager.play_audio_description(description_id: String, text: String, priority: int)
```

### UIManager - Interface Coordination and Accessibility

**Primary Responsibilities:**
- Dynamic UI layout and responsive design
- Educational overlay management
- Accessibility features (screen reader, high contrast, etc.)
- Multi-modal input support (touch, keyboard, gamepad)
- Localization and text scaling

**Key Methods:**
```gdscript
# Educational UI
UIManager.show_educational_overlay(overlay_id: String, config: Dictionary) -> bool
UIManager.create_interactive_element(element_id: String, element_type: String, config: Dictionary) -> Control
UIManager.update_learning_progress(progress_data: Dictionary)

# Accessibility
UIManager.enable_accessibility_mode(enabled: bool, level: AccessibilityLevel)
UIManager.set_text_scale(scale: float)
UIManager.enable_high_contrast(enabled: bool)
UIManager.announce_to_screen_reader(text: String, priority: int)

# Layout management
UIManager.set_layout_mode(mode: LayoutMode)
UIManager.register_breakpoint(name: String, width: int)
```

### AssetManager - Advanced Asset Management

**Primary Responsibilities:**
- Advanced 3D model loading with LOD support
- Texture streaming and compression management
- Audio asset optimization and spatial audio support
- Memory-efficient caching with intelligent cleanup
- Educational content asset organization

**Key Methods:**
```gdscript
# 3D model management
AssetManager.load_3d_model_async(model_id: String, config: Dictionary) -> bool
AssetManager.get_3d_model(model_id: String, distance: float) -> Resource
AssetManager.generate_model_colliders(model_id: String, collider_type: String) -> bool

# Texture streaming
AssetManager.stream_texture(texture_id: String, config: Dictionary) -> bool
AssetManager.set_texture_quality_level(level: int)

# Educational content
AssetManager.preload_educational_content(lesson_id: String) -> bool
AssetManager.get_educational_asset_group(group_id: String) -> Dictionary
```

### ConfigManager - Advanced Configuration Management

**Primary Responsibilities:**
- Hierarchical configuration with inheritance
- Real-time setting validation and constraints
- Platform-specific configuration profiles
- Educational setting templates and presets
- Performance auto-tuning based on hardware

**Key Methods:**
```gdscript
# Configuration management
ConfigManager.get_setting(category: String, key: String, default_value) -> Variant
ConfigManager.set_setting(category: String, key: String, value) -> bool
ConfigManager.validate_setting(category: String, key: String, value) -> bool

# Performance profiles
ConfigManager.apply_performance_profile(profile_name: String) -> bool
ConfigManager.auto_tune_performance() -> Dictionary
ConfigManager.get_platform_capabilities() -> Dictionary

# Educational presets
ConfigManager.apply_educational_preset(preset_name: String, config: Dictionary) -> bool
ConfigManager.create_learning_profile(profile_data: Dictionary) -> String
```

## System Communication Patterns

### Event-Driven Communication
Systems communicate primarily through signals to maintain loose coupling:

```gdscript
# Example: Educational progress updates
EducationManager.lesson_completed.connect(GameManager._on_lesson_completed)
EducationManager.assessment_completed.connect(UIManager._on_assessment_completed)
```

### Service Locator Pattern
Systems access each other through the GameManager's service locator:

```gdscript
# Safe system access
var education_mgr = GameManager.get_system("EducationManager")
if education_mgr:
    education_mgr.start_lesson("introduction")
```

### Shared State Management
Global state is managed through dedicated managers:

```gdscript
# Scene-persistent state
SceneManager.set_global_state("current_lesson", "ancient_architecture")

# Educational context
EducationManager.set_educational_context("assessment_mode", true)
```

## Error Handling and Recovery

### System Health Monitoring
Each system provides health status information:

```gdscript
# Check system health
var health = GameManager.get_system_health()
for system_name in health.keys():
    var system_health = health[system_name]
    if system_health["status"] != "healthy":
        print("System issue: ", system_name, " - ", system_health["message"])
```

### Graceful Degradation
Systems are designed to continue functioning even when dependencies fail:

```gdscript
# Example: Audio system fallback
if not AudioManager.spatial_audio_enabled:
    AudioManager.play_sfx(sfx_name)  # Fallback to 2D audio
```

### Automatic Recovery
The GameManager attempts automatic recovery for failed systems:

```gdscript
# Automatic system recovery
GameManager.system_error.connect(_on_system_error)

func _on_system_error(system_name: String, error_message: String):
    GameManager._attempt_system_recovery(system_name)
```

## Performance Optimization

### Memory Management
- Automatic cache cleanup based on memory pressure
- Asset streaming for large educational content
- LOD systems for 3D models and textures

### Browser Optimization
- WebGL-compatible rendering pipeline
- Compressed asset formats for web delivery
- Progressive loading for educational content

### Educational Content Optimization
- Lesson-based asset grouping
- Adaptive quality based on device capabilities
- Efficient assessment data storage

## Integration Best Practices

1. **Always check system availability** before calling methods
2. **Use signals for loose coupling** between systems
3. **Implement graceful fallbacks** for missing dependencies
4. **Monitor system health** regularly
5. **Follow the initialization order** when adding new systems
6. **Use the GameManager** as the central coordination point
7. **Validate configurations** before applying settings
8. **Handle errors gracefully** with user-friendly messages

This architecture provides a robust, scalable foundation for educational game development with comprehensive error handling, performance optimization, and accessibility support.
