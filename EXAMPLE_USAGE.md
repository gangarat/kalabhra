# Light of the Kalabhra - Example Usage Guide

## Complete Educational Game Session Example

This guide demonstrates how to use the core architectural systems together to create a complete educational gaming experience.

## Scenario: Ancient Architecture Lesson

Let's walk through implementing a complete lesson about ancient architecture, from initialization to assessment completion.

### 1. System Initialization and Setup

```gdscript
# In your main game scene or controller script
extends Node

func _ready():
    # Wait for all systems to be ready
    if not GameManager.are_systems_ready():
        await GameManager.systems_initialized
    
    # Configure the game for educational mode
    _setup_educational_session()

func _setup_educational_session():
    # Apply educational performance profile
    ConfigManager.apply_performance_profile("educational_optimized")
    
    # Enable accessibility features
    UIManager.enable_accessibility_mode(true, UIManager.AccessibilityLevel.ENHANCED)
    UIManager.set_text_scale(1.2)  # Slightly larger text for readability
    
    # Configure audio for educational content
    AudioManager.enable_audio_descriptions(true)
    AudioManager.set_sound_visualization(false)  # Disable for focus
    
    # Set up educational context
    EducationManager.update_learner_profile({
        "learning_style": "visual",
        "difficulty_preference": "adaptive",
        "accessibility_needs": ["large_text", "audio_descriptions"]
    })
```

### 2. Starting an Educational Session

```gdscript
func start_ancient_architecture_lesson():
    # Start a new educational session
    var session_id = GameManager.start_new_session("lesson", {
        "lesson_id": "ancient_architecture",
        "estimated_duration": 1800,  # 30 minutes
        "learning_objectives": [
            "identify_column_types",
            "understand_architectural_periods",
            "recognize_cultural_influences"
        ]
    })
    
    if session_id.is_empty():
        _handle_session_start_error()
        return
    
    # Preload lesson assets
    _preload_lesson_assets()
    
    # Start the lesson in the education system
    var lesson_started = EducationManager.start_lesson("ancient_architecture", {
        "difficulty": "intermediate",
        "enable_hints": true,
        "adaptive_pacing": true
    })
    
    if lesson_started:
        # Load the sanctuary scene
        _load_sanctuary_scene()
    else:
        _handle_lesson_start_error()

func _preload_lesson_assets():
    # Preload 3D models for the lesson
    AssetManager.load_3d_model_async("doric_column", {
        "lod_levels": 3,
        "auto_generate_colliders": true,
        "educational_metadata": true
    })
    
    AssetManager.load_3d_model_async("ionic_column", {
        "lod_levels": 3,
        "auto_generate_colliders": true,
        "educational_metadata": true
    })
    
    # Preload educational content batch
    AssetManager.preload_educational_content("lesson_ancient_architecture")
    
    # Preload related scenes
    SceneManager.preload_scene_batch([
        "sanctuary_main_hall",
        "column_detail_view",
        "architectural_timeline"
    ], 2)  # High priority

func _load_sanctuary_scene():
    # Load the main sanctuary scene with educational context
    SceneManager.load_scene_async("sanctuary_main_hall", {
        "transition": "educational_wipe",
        "preserve_education_state": true,
        "preload_adjacent": true
    })
```

### 3. Interactive Learning Experience

```gdscript
# In the sanctuary scene script
extends Node3D

@onready var player = $Player
@onready var doric_column = $Environment/DoricColumn
@onready var ionic_column = $Environment/IonicColumn

func _ready():
    _setup_interactive_elements()
    _setup_spatial_audio()
    _show_lesson_introduction()

func _setup_interactive_elements():
    # Create interactive zones around architectural elements
    _create_column_interaction_zone("doric_column", doric_column.global_position)
    _create_column_interaction_zone("ionic_column", ionic_column.global_position)
    
    # Set up educational overlays
    _setup_educational_overlays()

func _create_column_interaction_zone(column_id: String, position: Vector3):
    # Create audio zone for ambient educational content
    AudioManager.create_audio_zone(column_id + "_audio", position, 5.0, {
        "ambient_sound": "ancient_atmosphere",
        "narration_trigger": column_id + "_description",
        "volume": 0.7
    })
    
    # Create UI interaction zone
    var interaction_area = Area3D.new()
    var collision_shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = 3.0
    
    collision_shape.shape = sphere_shape
    interaction_area.add_child(collision_shape)
    interaction_area.global_position = position
    
    # Connect interaction signals
    interaction_area.body_entered.connect(_on_column_area_entered.bind(column_id))
    interaction_area.body_exited.connect(_on_column_area_exited.bind(column_id))
    
    add_child(interaction_area)

func _on_column_area_entered(column_id: String, body: Node3D):
    if body == player:
        # Show educational overlay
        UIManager.show_educational_overlay(column_id + "_info", {
            "type": "interactive",
            "title": _get_column_title(column_id),
            "description": _get_column_description(column_id),
            "interactive_elements": ["examine", "compare", "learn_more"],
            "position": "bottom_center",
            "animation": "fade_in"
        })
        
        # Play spatial audio description
        AudioManager.play_spatial_sfx("info_chime", player.global_position)
        
        # Record learning event
        EducationManager.record_learning_event("area_explored", {
            "area": column_id,
            "time_spent": 0,
            "interaction_type": "proximity"
        })

func _on_column_area_exited(column_id: String, body: Node3D):
    if body == player:
        # Hide educational overlay
        UIManager.hide_educational_overlay(column_id + "_info", true)

func _setup_spatial_audio():
    # Update spatial listener to follow player
    var update_listener = func():
        if player:
            AudioManager.update_spatial_listener(
                player.global_position,
                -player.global_transform.basis.z,  # Forward vector
                player.global_transform.basis.y    # Up vector
            )
    
    # Connect to player movement (assuming player has a moved signal)
    if player.has_signal("moved"):
        player.moved.connect(update_listener)

func _show_lesson_introduction():
    # Show lesson introduction overlay
    UIManager.show_educational_overlay("lesson_intro", {
        "type": "modal",
        "title": "Ancient Architecture: Columns and Culture",
        "content": "Welcome to the sanctuary of Kalabhra. Explore the different column styles and learn about their cultural significance.",
        "buttons": ["start_exploration", "view_objectives", "accessibility_options"],
        "auto_close": false
    })
    
    # Start adaptive background music
    AudioManager.start_adaptive_music("exploration", {
        "intensity": 0.3,  # Calm for learning
        "educational_context": "ancient_architecture",
        "mood": "contemplative"
    })
```

### 4. Assessment Integration

```gdscript
func start_column_identification_assessment():
    # Create an interactive assessment
    var assessment_id = EducationManager.create_assessment("practical", {
        "title": "Column Type Identification",
        "description": "Identify the different types of columns in the sanctuary",
        "time_limit": 300,  # 5 minutes
        "questions": [
            {
                "id": "q1",
                "type": "3d_interaction",
                "question": "Click on the Doric column",
                "target_object": "doric_column",
                "hints": ["Look for the simple, sturdy column without decorative capital"]
            },
            {
                "id": "q2", 
                "type": "3d_interaction",
                "question": "Click on the Ionic column",
                "target_object": "ionic_column",
                "hints": ["Look for the column with scroll-like decorations (volutes) on the capital"]
            }
        ]
    })
    
    if not assessment_id.is_empty():
        _setup_assessment_ui(assessment_id)
        _enable_assessment_interactions(assessment_id)

func _setup_assessment_ui(assessment_id: String):
    # Show assessment HUD
    UIManager.show_educational_overlay("assessment_hud", {
        "type": "persistent",
        "position": "top_right",
        "content": {
            "timer": true,
            "progress": true,
            "hint_button": true,
            "question_counter": true
        }
    })
    
    # Update music intensity for assessment
    AudioManager.set_music_intensity(0.6, 2.0)  # Slightly more intense

func _enable_assessment_interactions(assessment_id: String):
    # Enable click interactions on assessment targets
    doric_column.input_event.connect(_on_column_clicked.bind("doric_column", assessment_id))
    ionic_column.input_event.connect(_on_column_clicked.bind("ionic_column", assessment_id))

func _on_column_clicked(column_id: String, assessment_id: String, camera: Camera3D, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        # Submit assessment answer
        var answer_data = {
            "answer": column_id,
            "time_taken": _get_question_time(),
            "click_position": position,
            "confidence": 1.0  # High confidence for direct interaction
        }
        
        var current_question = _get_current_assessment_question(assessment_id)
        EducationManager.submit_assessment_answer(assessment_id, current_question, answer_data)
        
        # Provide immediate feedback
        _show_assessment_feedback(column_id, current_question)

func _show_assessment_feedback(selected_column: String, question_id: String):
    var is_correct = _check_answer_correctness(selected_column, question_id)
    
    if is_correct:
        # Show positive feedback
        UIManager.show_educational_overlay("correct_feedback", {
            "type": "notification",
            "message": "Correct! Well done identifying the column type.",
            "style": "success",
            "duration": 3.0
        })
        
        # Play success sound
        AudioManager.play_sfx("success_chime")
        
        # Visual feedback on the column
        _highlight_column(selected_column, Color.GREEN)
    else:
        # Show corrective feedback
        UIManager.show_educational_overlay("incorrect_feedback", {
            "type": "notification", 
            "message": "Not quite right. Look more carefully at the column's capital decoration.",
            "style": "hint",
            "duration": 4.0
        })
        
        # Play gentle error sound
        AudioManager.play_sfx("gentle_error")
        
        # Visual feedback
        _highlight_column(selected_column, Color.YELLOW)
```

### 5. Progress Tracking and Analytics

```gdscript
func _on_assessment_completed(assessment_id: String, results: Dictionary):
    # Update learning progress
    UIManager.update_learning_progress({
        "lesson_id": "ancient_architecture",
        "assessment_score": results["score_percentage"],
        "time_taken": results["total_time"],
        "objectives_completed": _get_completed_objectives()
    })
    
    # Show results overlay
    UIManager.show_educational_overlay("assessment_results", {
        "type": "modal",
        "title": "Assessment Complete",
        "content": {
            "score": results["score_percentage"],
            "time": results["total_time"],
            "feedback": _generate_personalized_feedback(results),
            "next_steps": _get_adaptive_recommendations(results)
        },
        "buttons": ["continue_lesson", "review_mistakes", "take_break"]
    })
    
    # Adjust music back to exploration mode
    AudioManager.set_music_intensity(0.3, 3.0)
    
    # Record completion in education system
    EducationManager.complete_objective("column_identification", {
        "score": results["score_percentage"],
        "attempts": results.get("attempts", 1),
        "time_taken": results["total_time"]
    })

func _generate_personalized_feedback(results: Dictionary) -> String:
    var score = results["score_percentage"]
    var time_taken = results["total_time"]
    
    if score >= 0.9:
        return "Excellent work! You have a strong understanding of column types."
    elif score >= 0.7:
        return "Good job! You're developing a solid grasp of architectural elements."
    else:
        return "Keep practicing! Architecture takes time to master. Try exploring the columns more closely."

func _get_adaptive_recommendations(results: Dictionary) -> Array[String]:
    var recommendations = []
    var score = results["score_percentage"]
    
    if score < 0.7:
        recommendations.append("Review the column detail view for closer examination")
        recommendations.append("Listen to the audio descriptions for additional context")
    
    if results["total_time"] > 240:  # Took longer than 4 minutes
        recommendations.append("Practice with the interactive timeline for better pacing")
    
    recommendations.append("Explore the cultural context section to deepen understanding")
    
    return recommendations
```

### 6. Session Completion and Data Persistence

```gdscript
func complete_lesson_session():
    # Complete the lesson in the education system
    var completion_data = EducationManager.complete_lesson({
        "quality_score": _calculate_lesson_quality(),
        "engagement_level": _calculate_engagement(),
        "areas_explored": _get_explored_areas(),
        "time_distribution": _get_time_distribution()
    })
    
    # Save progress
    SaveManager.auto_save()
    
    # End the game session
    var session_duration = GameManager.end_current_session(true)
    
    # Show completion summary
    UIManager.show_educational_overlay("lesson_complete", {
        "type": "modal",
        "title": "Lesson Complete: Ancient Architecture",
        "content": {
            "completion_rate": completion_data["completion_rate"],
            "mastery_level": completion_data["performance_score"],
            "session_duration": session_duration,
            "achievements": _get_unlocked_achievements(),
            "next_lesson": "architectural_periods"
        },
        "buttons": ["next_lesson", "review_progress", "main_menu"]
    })
    
    # Transition music to completion theme
    AudioManager.play_music("lesson_complete", {
        "fade_in": true,
        "loop": false
    })

func _calculate_lesson_quality() -> float:
    # Calculate based on various factors
    var exploration_score = _get_exploration_completeness()
    var interaction_score = _get_interaction_quality()
    var assessment_score = _get_assessment_performance()
    
    return (exploration_score + interaction_score + assessment_score) / 3.0
```

## Error Handling Example

```gdscript
func _handle_system_errors():
    # Connect to system error signals
    GameManager.system_error.connect(_on_system_error)
    EducationManager.asset_loading_failed.connect(_on_asset_loading_failed)
    SceneManager.scene_loading_failed.connect(_on_scene_loading_failed)

func _on_system_error(system_name: String, error_message: String):
    print("System error in ", system_name, ": ", error_message)
    
    # Show user-friendly error message
    UIManager.show_educational_overlay("system_error", {
        "type": "modal",
        "title": "Technical Issue",
        "message": "We're experiencing a technical issue. Your progress has been saved.",
        "buttons": ["retry", "main_menu", "report_issue"]
    })
    
    # Attempt recovery
    GameManager._attempt_system_recovery(system_name)

func _on_asset_loading_failed(asset_id: String, error: String):
    print("Failed to load asset: ", asset_id, " - ", error)
    
    # Provide fallback content
    _load_fallback_content(asset_id)
    
    # Continue lesson with reduced fidelity
    UIManager.announce_to_screen_reader("Some content is loading in reduced quality", 1)
```

This comprehensive example demonstrates how all the core systems work together to create a rich, accessible, and educationally effective gaming experience. The modular architecture allows for graceful degradation when issues occur while maintaining the educational objectives.
