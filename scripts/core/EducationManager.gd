extends Node

## EducationManager - Educational Content and Progress System
##
## The EducationManager handles all educational aspects of Light of the Kalabhra,
## including lesson management, assessment tracking, learning analytics, and
## adaptive learning features.
##
## Key Responsibilities:
## - Lesson and curriculum management
## - Assessment creation and evaluation
## - Learning progress tracking and analytics
## - Adaptive difficulty adjustment
## - Educational content delivery
## - Learning objective management
## - Performance analytics and reporting
##
## Usage Example:
## ```gdscript
## # Start a new lesson
## EducationManager.start_lesson("ancient_architecture")
## 
## # Create an assessment
## var assessment = EducationManager.create_assessment("quiz_basic", {
##     "questions": 5,
##     "difficulty": "beginner"
## })
## 
## # Track learning progress
## EducationManager.record_learning_event("interaction", {
##     "object": "column_detail",
##     "time_spent": 15.5
## })
## 
## # Get adaptive recommendations
## var next_content = EducationManager.get_adaptive_content()
## ```

# Educational content signals
signal lesson_started(lesson_id: String, lesson_data: Dictionary)
signal lesson_completed(lesson_id: String, completion_data: Dictionary)
signal lesson_objective_completed(lesson_id: String, objective_id: String)

# Assessment signals
signal assessment_started(assessment_id: String, assessment_data: Dictionary)
signal assessment_completed(assessment_id: String, results: Dictionary)
signal assessment_question_answered(assessment_id: String, question_id: String, answer_data: Dictionary)

# Progress signals
signal learning_progress_updated(progress_data: Dictionary)
signal mastery_level_changed(topic: String, old_level: float, new_level: float)
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)

# Adaptive learning signals
signal difficulty_adjusted(content_type: String, old_difficulty: float, new_difficulty: float)
signal content_recommended(content_id: String, reason: String)

## Learning states for content
enum LearningState {
	NOT_STARTED,
	IN_PROGRESS,
	COMPLETED,
	MASTERED,
	NEEDS_REVIEW
}

## Assessment types
enum AssessmentType {
	QUIZ,
	PRACTICAL,
	EXPLORATION,
	INTERACTION,
	REFLECTION
}

## Difficulty levels
enum DifficultyLevel {
	BEGINNER,
	INTERMEDIATE,
	ADVANCED,
	EXPERT
}

# Core educational data
var current_lesson: Dictionary = {}
var active_assessments: Dictionary = {}
var learning_progress: Dictionary = {}
var mastery_levels: Dictionary = {}
var learning_objectives: Dictionary = {}

# Content management
var lesson_catalog: Dictionary = {}
var assessment_templates: Dictionary = {}
var curriculum_structure: Dictionary = {}

# Analytics and tracking
var learning_events: Array[Dictionary] = []
var session_analytics: Dictionary = {}
var performance_metrics: Dictionary = {}

# Adaptive learning
var learner_profile: Dictionary = {}
var difficulty_adjustments: Dictionary = {}
var content_recommendations: Array[Dictionary] = []

# Configuration
var analytics_enabled: bool = true
var adaptive_learning_enabled: bool = true
var max_events_stored: int = 1000
var auto_save_progress: bool = true

func _ready():
	_initialize_education_system()

#region System Management

## Initialize the education system
func initialize_system() -> bool:
	_load_curriculum_data()
	_load_learner_profile()
	_setup_analytics()
	_initialize_adaptive_system()
	
	print("[EducationManager] Education system initialized successfully")
	return true

## Get system health status
func get_health_status() -> Dictionary:
	var health = {
		"status": "healthy",
		"lessons_loaded": lesson_catalog.size(),
		"active_assessments": active_assessments.size(),
		"events_tracked": learning_events.size(),
		"last_check": Time.get_unix_time_from_system()
	}
	
	# Check for potential issues
	if learning_events.size() > max_events_stored * 0.9:
		health["status"] = "warning"
		health["message"] = "Learning events storage near capacity"
	
	return health

## Shutdown the education system
func shutdown_system() -> void:
	_save_all_progress()
	_save_analytics_data()
	print("[EducationManager] Education system shutdown completed")

#endregion

#region Lesson Management

## Start a new lesson
## @param lesson_id: Unique identifier for the lesson
## @param config: Optional configuration for lesson customization
## @return: True if lesson started successfully
func start_lesson(lesson_id: String, config: Dictionary = {}) -> bool:
	if not lesson_catalog.has(lesson_id):
		push_error("[EducationManager] Lesson not found: " + lesson_id)
		return false
	
	# End current lesson if active
	if not current_lesson.is_empty():
		_end_current_lesson()
	
	var lesson_data = lesson_catalog[lesson_id].duplicate(true)
	lesson_data.merge(config, true)
	
	current_lesson = {
		"id": lesson_id,
		"data": lesson_data,
		"start_time": Time.get_unix_time_from_system(),
		"objectives_completed": [],
		"events": [],
		"state": LearningState.IN_PROGRESS
	}
	
	# Initialize learning objectives
	if lesson_data.has("learning_objectives"):
		for objective in lesson_data["learning_objectives"]:
			learning_objectives[objective["id"]] = {
				"lesson_id": lesson_id,
				"data": objective,
				"state": LearningState.NOT_STARTED,
				"progress": 0.0
			}
	
	# Record learning event
	_record_learning_event("lesson_started", {
		"lesson_id": lesson_id,
		"difficulty": lesson_data.get("difficulty", "intermediate")
	})
	
	lesson_started.emit(lesson_id, lesson_data)
	return true

## Complete the current lesson
## @param completion_data: Additional data about lesson completion
## @return: Completion results and performance data
func complete_lesson(completion_data: Dictionary = {}) -> Dictionary:
	if current_lesson.is_empty():
		push_warning("[EducationManager] No active lesson to complete")
		return {}
	
	var lesson_id = current_lesson["id"]
	var completion_time = Time.get_unix_time_from_system()
	var duration = completion_time - current_lesson["start_time"]
	
	# Calculate completion metrics
	var results = {
		"lesson_id": lesson_id,
		"duration": duration,
		"objectives_completed": current_lesson["objectives_completed"].size(),
		"total_objectives": current_lesson["data"].get("learning_objectives", []).size(),
		"completion_rate": 0.0,
		"performance_score": 0.0
	}
	
	if results["total_objectives"] > 0:
		results["completion_rate"] = float(results["objectives_completed"]) / float(results["total_objectives"])
	
	# Calculate performance score based on various factors
	results["performance_score"] = _calculate_lesson_performance(current_lesson, completion_data)
	
	# Update learning progress
	learning_progress[lesson_id] = {
		"state": LearningState.COMPLETED,
		"completion_time": completion_time,
		"results": results,
		"mastery_level": results["performance_score"]
	}
	
	# Update mastery levels for topics covered
	_update_mastery_levels(current_lesson["data"], results["performance_score"])
	
	# Record completion event
	_record_learning_event("lesson_completed", results)
	
	# Save progress if auto-save is enabled
	if auto_save_progress:
		_save_progress_data()
	
	lesson_completed.emit(lesson_id, results)
	
	# Clear current lesson
	current_lesson.clear()
	
	return results

## Complete a learning objective
## @param objective_id: ID of the objective to complete
## @param completion_data: Data about how the objective was completed
func complete_objective(objective_id: String, completion_data: Dictionary = {}) -> void:
	if not learning_objectives.has(objective_id):
		push_warning("[EducationManager] Objective not found: " + objective_id)
		return
	
	var objective = learning_objectives[objective_id]
	objective["state"] = LearningState.COMPLETED
	objective["completion_time"] = Time.get_unix_time_from_system()
	objective["completion_data"] = completion_data
	
	# Add to current lesson's completed objectives
	if not current_lesson.is_empty():
		current_lesson["objectives_completed"].append(objective_id)
	
	# Record event
	_record_learning_event("objective_completed", {
		"objective_id": objective_id,
		"lesson_id": objective["lesson_id"]
	})
	
	lesson_objective_completed.emit(objective["lesson_id"], objective_id)

## Get current lesson information
## @return: Dictionary with current lesson data or empty if no active lesson
func get_current_lesson() -> Dictionary:
	return current_lesson.duplicate(true)

## Get lesson progress for a specific lesson
## @param lesson_id: ID of the lesson to check
## @return: Progress data for the lesson
func get_lesson_progress(lesson_id: String) -> Dictionary:
	return learning_progress.get(lesson_id, {})

## Get all completed lessons
## @return: Array of lesson IDs that have been completed
func get_completed_lessons() -> Array[String]:
	var completed = []
	for lesson_id in learning_progress.keys():
		if learning_progress[lesson_id].get("state") == LearningState.COMPLETED:
			completed.append(lesson_id)
	return completed

#endregion

#region Assessment Management

## Create and start an assessment
## @param assessment_type: Type of assessment (quiz, practical, etc.)
## @param config: Configuration for the assessment
## @return: Assessment ID if successful, empty string if failed
func create_assessment(assessment_type: String, config: Dictionary = {}) -> String:
	var assessment_id = _generate_assessment_id()

	# Get template for assessment type
	var template = assessment_templates.get(assessment_type, {})
	if template.is_empty():
		push_error("[EducationManager] Assessment template not found: " + assessment_type)
		return ""

	# Create assessment data
	var assessment_data = template.duplicate(true)
	assessment_data.merge(config, true)
	assessment_data["id"] = assessment_id
	assessment_data["type"] = assessment_type
	assessment_data["start_time"] = Time.get_unix_time_from_system()
	assessment_data["state"] = "active"
	assessment_data["responses"] = {}
	assessment_data["current_question"] = 0

	# Adapt difficulty if adaptive learning is enabled
	if adaptive_learning_enabled:
		_adapt_assessment_difficulty(assessment_data)

	active_assessments[assessment_id] = assessment_data

	# Record event
	_record_learning_event("assessment_started", {
		"assessment_id": assessment_id,
		"type": assessment_type,
		"difficulty": assessment_data.get("difficulty", "intermediate")
	})

	assessment_started.emit(assessment_id, assessment_data)
	return assessment_id

## Submit an answer to an assessment question
## @param assessment_id: ID of the active assessment
## @param question_id: ID of the question being answered
## @param answer_data: The answer data (answer, time_taken, etc.)
## @return: True if answer was recorded successfully
func submit_assessment_answer(assessment_id: String, question_id: String, answer_data: Dictionary) -> bool:
	if not active_assessments.has(assessment_id):
		push_error("[EducationManager] Assessment not found: " + assessment_id)
		return false

	var assessment = active_assessments[assessment_id]

	# Record the answer
	assessment["responses"][question_id] = {
		"answer": answer_data,
		"timestamp": Time.get_unix_time_from_system(),
		"time_taken": answer_data.get("time_taken", 0.0)
	}

	# Evaluate the answer
	var evaluation = _evaluate_answer(assessment, question_id, answer_data)
	assessment["responses"][question_id]["evaluation"] = evaluation

	# Record learning event
	_record_learning_event("question_answered", {
		"assessment_id": assessment_id,
		"question_id": question_id,
		"correct": evaluation.get("correct", false),
		"time_taken": answer_data.get("time_taken", 0.0)
	})

	assessment_question_answered.emit(assessment_id, question_id, answer_data)

	# Check if assessment is complete
	var questions = assessment.get("questions", [])
	if assessment["responses"].size() >= questions.size():
		_complete_assessment(assessment_id)

	return true

## Complete an assessment and calculate results
## @param assessment_id: ID of the assessment to complete
## @return: Assessment results
func complete_assessment(assessment_id: String) -> Dictionary:
	if not active_assessments.has(assessment_id):
		push_error("[EducationManager] Assessment not found: " + assessment_id)
		return {}

	return _complete_assessment(assessment_id)

## Get current assessment data
## @param assessment_id: ID of the assessment
## @return: Assessment data or empty dictionary if not found
func get_assessment_data(assessment_id: String) -> Dictionary:
	return active_assessments.get(assessment_id, {}).duplicate(true)

## Get all active assessments
## @return: Dictionary of active assessments
func get_active_assessments() -> Dictionary:
	return active_assessments.duplicate(true)

#endregion

#region Learning Analytics

## Record a learning event for analytics
## @param event_type: Type of learning event
## @param event_data: Additional data about the event
func record_learning_event(event_type: String, event_data: Dictionary = {}) -> void:
	_record_learning_event(event_type, event_data)

## Get learning analytics for a specific time period
## @param start_time: Start timestamp (0 for all time)
## @param end_time: End timestamp (0 for current time)
## @return: Analytics data for the specified period
func get_learning_analytics(start_time: float = 0.0, end_time: float = 0.0) -> Dictionary:
	if end_time == 0.0:
		end_time = Time.get_unix_time_from_system()

	var filtered_events = []
	for event in learning_events:
		var event_time = event.get("timestamp", 0.0)
		if event_time >= start_time and event_time <= end_time:
			filtered_events.append(event)

	return _analyze_learning_events(filtered_events)

## Get mastery level for a specific topic
## @param topic: Topic to check mastery for
## @return: Mastery level (0.0 to 1.0)
func get_mastery_level(topic: String) -> float:
	return mastery_levels.get(topic, 0.0)

## Get overall learning progress
## @return: Dictionary with comprehensive progress data
func get_learning_progress() -> Dictionary:
	var progress = {
		"lessons_completed": get_completed_lessons().size(),
		"total_lessons": lesson_catalog.size(),
		"overall_mastery": _calculate_overall_mastery(),
		"time_spent": _calculate_total_time_spent(),
		"assessments_taken": _count_completed_assessments(),
		"achievements": _get_unlocked_achievements()
	}

	progress["completion_rate"] = float(progress["lessons_completed"]) / float(progress["total_lessons"]) if progress["total_lessons"] > 0 else 0.0

	return progress

## Export learning data for external analysis
## @param format: Export format ("json", "csv")
## @return: Exported data as string
func export_learning_data(format: String = "json") -> String:
	var export_data = {
		"learner_profile": learner_profile,
		"learning_progress": learning_progress,
		"mastery_levels": mastery_levels,
		"performance_metrics": performance_metrics,
		"learning_events": learning_events
	}

	match format.to_lower():
		"json":
			return JSON.stringify(export_data, "\t")
		"csv":
			return _convert_to_csv(export_data)
		_:
			push_error("[EducationManager] Unsupported export format: " + format)
			return ""

#endregion

#region Adaptive Learning

## Get adaptive content recommendations
## @return: Array of recommended content items
func get_adaptive_content() -> Array[Dictionary]:
	if not adaptive_learning_enabled:
		return []

	_update_content_recommendations()
	return content_recommendations.duplicate(true)

## Adjust difficulty for a content type
## @param content_type: Type of content to adjust
## @param performance_score: Recent performance score (0.0 to 1.0)
func adjust_difficulty(content_type: String, performance_score: float) -> void:
	if not adaptive_learning_enabled:
		return

	var current_difficulty = difficulty_adjustments.get(content_type, 0.5)
	var new_difficulty = _calculate_adaptive_difficulty(current_difficulty, performance_score)

	if abs(new_difficulty - current_difficulty) > 0.1:  # Only adjust if significant change
		difficulty_adjustments[content_type] = new_difficulty
		difficulty_adjusted.emit(content_type, current_difficulty, new_difficulty)

## Update learner profile based on recent performance
## @param performance_data: Recent performance metrics
func update_learner_profile(performance_data: Dictionary) -> void:
	# Update learning style preferences
	_analyze_learning_style(performance_data)

	# Update skill levels
	_update_skill_levels(performance_data)

	# Update preferences
	_update_learning_preferences(performance_data)

	# Save updated profile
	if auto_save_progress:
		_save_learner_profile()

## Get personalized learning path
## @param target_topic: Topic to create learning path for
## @return: Array of content items in recommended order
func get_learning_path(target_topic: String) -> Array[Dictionary]:
	var path = []

	# Get prerequisite topics
	var prerequisites = _get_topic_prerequisites(target_topic)

	# Check mastery levels and add content as needed
	for prereq in prerequisites:
		if get_mastery_level(prereq) < 0.7:  # Below mastery threshold
			var content = _get_content_for_topic(prereq)
			path.append_array(content)

	# Add main topic content
	var main_content = _get_content_for_topic(target_topic)
	path.append_array(main_content)

	# Sort by difficulty and dependencies
	path.sort_custom(_compare_content_difficulty)

	return path

#endregion

#region Private Implementation

## Initialize the education system
func _initialize_education_system() -> void:
	# Initialize data structures
	learning_progress = {}
	mastery_levels = {}
	learning_objectives = {}
	session_analytics = {}
	performance_metrics = {}
	learner_profile = {}
	difficulty_adjustments = {}

	print("[EducationManager] Education system core initialized")

## Load curriculum and lesson data
func _load_curriculum_data() -> void:
	# Load lesson catalog
	var lessons_path = "res://resources/data/educational/lessons/"
	var dir = DirAccess.open(lessons_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".json"):
				var lesson_id = file_name.get_basename()
				var lesson_data = _load_json_file(lessons_path + file_name)
				if not lesson_data.is_empty():
					lesson_catalog[lesson_id] = lesson_data
			file_name = dir.get_next()

	# Load assessment templates
	var assessments_path = "res://resources/data/educational/assessments/"
	_load_assessment_templates(assessments_path)

	# Load curriculum structure
	var curriculum_file = "res://resources/data/educational/curriculum.json"
	curriculum_structure = _load_json_file(curriculum_file)

	print("[EducationManager] Loaded %d lessons and %d assessment templates" % [lesson_catalog.size(), assessment_templates.size()])

## Load assessment templates
func _load_assessment_templates(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".json"):
			var template_id = file_name.get_basename()
			var template_data = _load_json_file(path + file_name)
			if not template_data.is_empty():
				assessment_templates[template_id] = template_data
		file_name = dir.get_next()

## Load learner profile
func _load_learner_profile() -> void:
	var profile_file = "user://learner_profile.json"
	learner_profile = _load_json_file(profile_file)

	if learner_profile.is_empty():
		# Create default profile
		learner_profile = {
			"learning_style": "visual",
			"skill_levels": {},
			"preferences": {
				"difficulty_preference": "adaptive",
				"feedback_frequency": "normal",
				"hint_usage": "when_needed"
			},
			"created_time": Time.get_unix_time_from_system()
		}

## Setup analytics system
func _setup_analytics() -> void:
	# Load existing analytics data
	var analytics_file = "user://learning_analytics.json"
	var analytics_data = _load_json_file(analytics_file)

	if analytics_data.has("events"):
		learning_events = analytics_data["events"]
	if analytics_data.has("performance_metrics"):
		performance_metrics = analytics_data["performance_metrics"]

## Initialize adaptive learning system
func _initialize_adaptive_system() -> void:
	# Load difficulty adjustments
	var adaptive_file = "user://adaptive_settings.json"
	var adaptive_data = _load_json_file(adaptive_file)

	if adaptive_data.has("difficulty_adjustments"):
		difficulty_adjustments = adaptive_data["difficulty_adjustments"]

## Record a learning event
func _record_learning_event(event_type: String, event_data: Dictionary) -> void:
	if not analytics_enabled:
		return

	var event = {
		"type": event_type,
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": GameManager.current_session_id if GameManager else "",
		"data": event_data
	}

	learning_events.append(event)

	# Limit stored events
	if learning_events.size() > max_events_stored:
		learning_events = learning_events.slice(-max_events_stored)

## End current lesson
func _end_current_lesson() -> void:
	if current_lesson.is_empty():
		return

	var lesson_id = current_lesson["id"]
	var duration = Time.get_unix_time_from_system() - current_lesson["start_time"]

	_record_learning_event("lesson_ended", {
		"lesson_id": lesson_id,
		"duration": duration,
		"completed": false
	})

## Calculate lesson performance score
func _calculate_lesson_performance(lesson_data: Dictionary, completion_data: Dictionary) -> float:
	var score = 0.0
	var factors = 0

	# Objective completion rate
	var total_objectives = lesson_data["data"].get("learning_objectives", []).size()
	if total_objectives > 0:
		score += float(lesson_data["objectives_completed"].size()) / float(total_objectives)
		factors += 1

	# Time efficiency (compared to expected duration)
	var expected_duration = lesson_data["data"].get("duration_minutes", 15) * 60
	var actual_duration = Time.get_unix_time_from_system() - lesson_data["start_time"]
	if expected_duration > 0:
		var time_efficiency = min(1.0, expected_duration / actual_duration)
		score += time_efficiency
		factors += 1

	# Additional completion data
	if completion_data.has("quality_score"):
		score += completion_data["quality_score"]
		factors += 1

	return score / max(1, factors)

## Update mastery levels based on performance
func _update_mastery_levels(lesson_data: Dictionary, performance_score: float) -> void:
	var topics = lesson_data.get("topics", [])

	for topic in topics:
		var current_mastery = mastery_levels.get(topic, 0.0)
		var new_mastery = _calculate_new_mastery(current_mastery, performance_score)

		if abs(new_mastery - current_mastery) > 0.05:  # Significant change
			mastery_levels[topic] = new_mastery
			mastery_level_changed.emit(topic, current_mastery, new_mastery)

## Calculate new mastery level
func _calculate_new_mastery(current_mastery: float, performance_score: float) -> float:
	# Use exponential moving average with learning rate
	var learning_rate = 0.3
	return current_mastery * (1.0 - learning_rate) + performance_score * learning_rate

## Load JSON file utility
func _load_json_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("[EducationManager] Failed to parse JSON file: " + file_path)
		return {}

	return json.data

## Generate unique assessment ID
func _generate_assessment_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "assessment_%d_%04d" % [timestamp, random_suffix]

## Complete assessment implementation
func _complete_assessment(assessment_id: String) -> Dictionary:
	var assessment = active_assessments[assessment_id]
	var completion_time = Time.get_unix_time_from_system()
	var duration = completion_time - assessment["start_time"]

	# Calculate results
	var results = _calculate_assessment_results(assessment)
	results["duration"] = duration
	results["completion_time"] = completion_time

	# Update performance metrics
	_update_performance_metrics(assessment, results)

	# Record completion event
	_record_learning_event("assessment_completed", results)

	# Remove from active assessments
	active_assessments.erase(assessment_id)

	# Save progress
	if auto_save_progress:
		_save_progress_data()

	assessment_completed.emit(assessment_id, results)
	return results

## Calculate assessment results
func _calculate_assessment_results(assessment: Dictionary) -> Dictionary:
	var questions = assessment.get("questions", [])
	var responses = assessment.get("responses", {})

	var correct_answers = 0
	var total_time = 0.0
	var detailed_results = []

	for question in questions:
		var question_id = question.get("id", "")
		var response = responses.get(question_id, {})
		var evaluation = response.get("evaluation", {})

		if evaluation.get("correct", false):
			correct_answers += 1

		total_time += response.get("time_taken", 0.0)

		detailed_results.append({
			"question_id": question_id,
			"correct": evaluation.get("correct", false),
			"score": evaluation.get("score", 0.0),
			"time_taken": response.get("time_taken", 0.0)
		})

	var score_percentage = float(correct_answers) / float(questions.size()) if questions.size() > 0 else 0.0

	return {
		"assessment_id": assessment["id"],
		"type": assessment["type"],
		"total_questions": questions.size(),
		"correct_answers": correct_answers,
		"score_percentage": score_percentage,
		"total_time": total_time,
		"average_time_per_question": total_time / questions.size() if questions.size() > 0 else 0.0,
		"detailed_results": detailed_results
	}

## Evaluate an answer
func _evaluate_answer(assessment: Dictionary, question_id: String, answer_data: Dictionary) -> Dictionary:
	var questions = assessment.get("questions", [])
	var question = null

	for q in questions:
		if q.get("id") == question_id:
			question = q
			break

	if not question:
		return {"correct": false, "score": 0.0}

	var correct_answer = question.get("correct_answer")
	var user_answer = answer_data.get("answer")
	var question_type = question.get("type", "multiple_choice")

	match question_type:
		"multiple_choice":
			return {"correct": user_answer == correct_answer, "score": 1.0 if user_answer == correct_answer else 0.0}
		"true_false":
			return {"correct": user_answer == correct_answer, "score": 1.0 if user_answer == correct_answer else 0.0}
		"text_input":
			var similarity = _calculate_text_similarity(str(user_answer).to_lower(), str(correct_answer).to_lower())
			return {"correct": similarity > 0.8, "score": similarity}
		_:
			return {"correct": false, "score": 0.0}

## Calculate text similarity for text input questions
func _calculate_text_similarity(text1: String, text2: String) -> float:
	# Simple similarity calculation - could be enhanced with more sophisticated algorithms
	if text1 == text2:
		return 1.0

	var words1 = text1.split(" ")
	var words2 = text2.split(" ")
	var common_words = 0

	for word in words1:
		if words2.has(word):
			common_words += 1

	var total_words = max(words1.size(), words2.size())
	return float(common_words) / float(total_words) if total_words > 0 else 0.0

## Save all progress data
func _save_all_progress() -> void:
	_save_progress_data()
	_save_analytics_data()
	_save_learner_profile()

## Save progress data
func _save_progress_data() -> void:
	var progress_file = "user://education_progress.json"
	var progress_data = {
		"learning_progress": learning_progress,
		"mastery_levels": mastery_levels,
		"learning_objectives": learning_objectives,
		"last_updated": Time.get_unix_time_from_system()
	}

	_save_json_file(progress_file, progress_data)

## Save analytics data
func _save_analytics_data() -> void:
	var analytics_file = "user://learning_analytics.json"
	var analytics_data = {
		"events": learning_events,
		"performance_metrics": performance_metrics,
		"session_analytics": session_analytics,
		"last_updated": Time.get_unix_time_from_system()
	}

	_save_json_file(analytics_file, analytics_data)

## Save learner profile
func _save_learner_profile() -> void:
	var profile_file = "user://learner_profile.json"
	learner_profile["last_updated"] = Time.get_unix_time_from_system()
	_save_json_file(profile_file, learner_profile)

## Save JSON file utility
func _save_json_file(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("[EducationManager] Failed to open file for writing: " + file_path)
		return false

	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	return true

#endregion
