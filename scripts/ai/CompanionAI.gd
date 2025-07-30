extends Node

## CompanionAI - Intelligent Companion Behavior System
##
## Advanced AI system for Bundos and other sanctuary inhabitants that supports
## both gameplay and educational objectives with culturally authentic behavior.
##
## Key Features:
## - Pathfinding system navigating complex sanctuary architecture
## - Educational dialogue system with natural conversation flow
## - Assistance behaviors for game mechanics and cultural context
## - Emergency response behaviors during sanctuary attack
## - Teaching behaviors for religious objects and cultural practices
## - Group coordination system for escape sequences
## - Adaptive behavior responding to player actions and learning progress
##
## Usage Example:
## ```gdscript
## # Create companion AI for Bundos
## var bundos_ai = CompanionAI.create_companion("bundos", {
##     "personality": "helpful_scholar",
##     "cultural_knowledge": "high",
##     "teaching_style": "patient"
## })
## 
## # Start educational dialogue
## CompanionAI.start_educational_dialogue(bundos_ai, "manuscript_introduction")
## 
## # Coordinate group escape
## CompanionAI.coordinate_group_escape([bundos_ai, other_companions])
## ```

# Companion AI signals
signal companion_created(companion_id: String, companion_type: String)
signal companion_state_changed(companion_id: String, old_state: String, new_state: String)
signal dialogue_initiated(companion_id: String, dialogue_type: String, educational_content: Dictionary)
signal assistance_provided(companion_id: String, assistance_type: String, context: Dictionary)
signal teaching_demonstration_started(companion_id: String, practice_type: String, cultural_context: Dictionary)

# Educational AI signals
signal cultural_knowledge_shared(companion_id: String, knowledge_type: String, learning_objective: String)
signal player_progress_acknowledged(companion_id: String, achievement: String, encouragement: String)
signal adaptive_behavior_triggered(companion_id: String, adaptation_reason: String, new_behavior: String)

# Emergency and coordination signals
signal emergency_response_activated(companion_id: String, emergency_type: String, response_plan: Dictionary)
signal group_coordination_started(leader_id: String, group_members: Array, objective: String)
signal escape_route_suggested(companion_id: String, route_data: Dictionary, safety_assessment: Dictionary)

## Companion AI states
enum CompanionState {
	IDLE,
	FOLLOWING,
	TEACHING,
	ASSISTING,
	DIALOGUE,
	EMERGENCY_RESPONSE,
	GROUP_COORDINATION,
	PATHFINDING,
	CULTURAL_DEMONSTRATION,
	ADAPTIVE_LEARNING
}

## Companion types with different personalities and roles
enum CompanionType {
	BUNDOS,           # Helpful scholar companion
	ELDER_MONK,       # Wise religious teacher
	YOUNG_STUDENT,    # Eager learner
	SANCTUARY_GUIDE,  # Knowledgeable guide
	CULTURAL_EXPERT   # Cultural practice specialist
}

## Educational assistance types
enum AssistanceType {
	GAME_MECHANICS,
	CULTURAL_CONTEXT,
	HISTORICAL_BACKGROUND,
	RELIGIOUS_PRACTICES,
	NAVIGATION_HELP,
	OBJECT_INTERACTION,
	LEARNING_ENCOURAGEMENT
}

## Emergency response types
enum EmergencyType {
	SANCTUARY_ATTACK,
	GUARD_DETECTION,
	FIRE_OUTBREAK,
	STRUCTURAL_COLLAPSE,
	GROUP_SEPARATION,
	PLAYER_INJURY
}

# Core companion management
var active_companions: Dictionary = {}
var companion_personalities: Dictionary = {}
var cultural_knowledge_base: Dictionary = {}
var teaching_curricula: Dictionary = {}

# AI behavior systems
var pathfinding_system: Dictionary = {}
var dialogue_system: Dictionary = {}
var decision_trees: Dictionary = {}
var adaptive_learning_data: Dictionary = {}

# Group coordination
var group_formations: Dictionary = {}
var escape_routes: Dictionary = {}
var coordination_protocols: Dictionary = {}

# Educational integration
var learning_objectives_tracking: Dictionary = {}
var player_progress_analysis: Dictionary = {}
var cultural_teaching_sequences: Dictionary = {}

# Performance and optimization
var ai_update_frequency: float = 0.1
var max_active_companions: int = 4
var pathfinding_optimization: bool = true
var dialogue_caching: bool = true

func _ready():
	_initialize_companion_ai_system()
	_load_companion_personalities()
	_setup_cultural_knowledge_base()

#region Companion Management

## Create a new companion AI
## @param companion_type: Type of companion to create
## @param config: Configuration for the companion
## @return: Companion ID if successful, empty string if failed
func create_companion(companion_type: String, config: Dictionary = {}) -> String:
	if active_companions.size() >= max_active_companions:
		push_warning("[CompanionAI] Maximum active companions reached")
		return ""
	
	var companion_id = _generate_companion_id(companion_type)
	
	# Create companion data structure
	var companion_data = {
		"id": companion_id,
		"type": companion_type,
		"state": CompanionState.IDLE,
		"personality": _get_companion_personality(companion_type),
		"cultural_knowledge": config.get("cultural_knowledge", "medium"),
		"teaching_style": config.get("teaching_style", "adaptive"),
		"current_objective": "",
		"pathfinding_data": {},
		"dialogue_context": {},
		"learning_progress": {},
		"emergency_protocols": _get_emergency_protocols(companion_type),
		"created_time": Time.get_unix_time_from_system()
	}
	
	# Initialize AI systems for this companion
	_initialize_companion_ai(companion_data, config)
	
	# Store companion
	active_companions[companion_id] = companion_data
	
	companion_created.emit(companion_id, companion_type)
	return companion_id

## Set companion state
## @param companion_id: Companion to update
## @param new_state: New state for the companion
## @param context: Additional context for the state change
func set_companion_state(companion_id: String, new_state: CompanionState, context: Dictionary = {}) -> void:
	if not active_companions.has(companion_id):
		return
	
	var companion = active_companions[companion_id]
	var old_state = companion["state"]
	
	if old_state != new_state:
		companion["state"] = new_state
		_handle_state_transition(companion, old_state, new_state, context)
		companion_state_changed.emit(companion_id, _state_to_string(old_state), _state_to_string(new_state))

## Start educational dialogue with companion
## @param companion_id: Companion to start dialogue with
## @param dialogue_type: Type of educational dialogue
## @param educational_context: Educational content and objectives
func start_educational_dialogue(companion_id: String, dialogue_type: String, educational_context: Dictionary = {}) -> void:
	if not active_companions.has(companion_id):
		return
	
	var companion = active_companions[companion_id]
	
	# Transition to dialogue state
	set_companion_state(companion_id, CompanionState.DIALOGUE)
	
	# Setup dialogue context
	var dialogue_data = _prepare_educational_dialogue(companion, dialogue_type, educational_context)
	companion["dialogue_context"] = dialogue_data
	
	# Start dialogue sequence
	_begin_dialogue_sequence(companion_id, dialogue_data)
	
	dialogue_initiated.emit(companion_id, dialogue_type, educational_context)

## Request assistance from companion
## @param companion_id: Companion to request assistance from
## @param assistance_type: Type of assistance needed
## @param context: Context for the assistance request
func request_assistance(companion_id: String, assistance_type: AssistanceType, context: Dictionary = {}) -> void:
	if not active_companions.has(companion_id):
		return
	
	var companion = active_companions[companion_id]
	
	# Check if companion can provide this type of assistance
	if not _can_provide_assistance(companion, assistance_type):
		return
	
	# Transition to assisting state
	set_companion_state(companion_id, CompanionState.ASSISTING)
	
	# Provide assistance based on type
	_provide_assistance(companion_id, assistance_type, context)
	
	assistance_provided.emit(companion_id, _assistance_type_to_string(assistance_type), context)

## Start cultural teaching demonstration
## @param companion_id: Companion to perform demonstration
## @param practice_type: Type of cultural practice to demonstrate
## @param cultural_context: Cultural and educational context
func start_cultural_demonstration(companion_id: String, practice_type: String, cultural_context: Dictionary = {}) -> void:
	if not active_companions.has(companion_id):
		return
	
	var companion = active_companions[companion_id]
	
	# Check cultural knowledge level
	var knowledge_level = companion["cultural_knowledge"]
	if not _has_cultural_knowledge(companion, practice_type, knowledge_level):
		push_warning("[CompanionAI] Companion lacks knowledge for practice: " + practice_type)
		return
	
	# Transition to demonstration state
	set_companion_state(companion_id, CompanionState.CULTURAL_DEMONSTRATION)
	
	# Start demonstration sequence
	_begin_cultural_demonstration(companion_id, practice_type, cultural_context)
	
	teaching_demonstration_started.emit(companion_id, practice_type, cultural_context)

#endregion

#region Pathfinding and Navigation

## Set companion to follow player
## @param companion_id: Companion to set following
## @param follow_distance: Distance to maintain from player
## @param formation_position: Position in group formation
func set_companion_following(companion_id: String, follow_distance: float = 3.0, formation_position: String = "behind") -> void:
	if not active_companions.has(companion_id):
		return
	
	var companion = active_companions[companion_id]
	
	# Setup following behavior
	companion["pathfinding_data"] = {
		"mode": "following",
		"target": "player",
		"follow_distance": follow_distance,
		"formation_position": formation_position,
		"avoid_guards": true,
		"use_stealth_paths": true
	}
	
	set_companion_state(companion_id, CompanionState.FOLLOWING)

## Navigate companion to specific location
## @param companion_id: Companion to navigate
## @param target_position: Target position to navigate to
## @param navigation_options: Options for navigation behavior
func navigate_to_location(companion_id: String, target_position: Vector3, navigation_options: Dictionary = {}) -> void:
	if not active_companions.has(companion_id):
		return
	
	var companion = active_companions[companion_id]
	
	# Setup pathfinding
	var pathfinding_data = {
		"mode": "navigate_to_point",
		"target_position": target_position,
		"avoid_guards": navigation_options.get("avoid_guards", true),
		"use_stealth_paths": navigation_options.get("use_stealth", false),
		"urgency_level": navigation_options.get("urgency", "normal"),
		"cultural_movement": navigation_options.get("cultural_movement", true)
	}
	
	companion["pathfinding_data"] = pathfinding_data
	set_companion_state(companion_id, CompanionState.PATHFINDING)
	
	# Calculate and execute path
	_calculate_and_execute_path(companion_id, pathfinding_data)

#endregion

#region Adaptive Learning and Player Response

## Update companion behavior based on player progress
## @param companion_id: Companion to update
## @param player_progress_data: Data about player's learning progress
func adapt_to_player_progress(companion_id: String, player_progress_data: Dictionary) -> void:
	if not active_companions.has(companion_id):
		return

	var companion = active_companions[companion_id]

	# Analyze player progress
	var adaptation_needed = _analyze_adaptation_needs(companion, player_progress_data)

	if adaptation_needed.is_empty():
		return

	# Apply behavioral adaptations
	_apply_behavioral_adaptations(companion_id, adaptation_needed)

	# Update teaching style if needed
	if adaptation_needed.has("teaching_style"):
		companion["teaching_style"] = adaptation_needed["teaching_style"]

	# Acknowledge player progress
	var acknowledgment = _generate_progress_acknowledgment(companion, player_progress_data)
	if not acknowledgment.is_empty():
		player_progress_acknowledged.emit(companion_id, acknowledgment["achievement"], acknowledgment["encouragement"])

	adaptive_behavior_triggered.emit(companion_id, adaptation_needed.get("reason", "progress_update"), adaptation_needed.get("new_behavior", "adjusted"))

## Share cultural knowledge based on context
## @param companion_id: Companion sharing knowledge
## @param knowledge_context: Context for knowledge sharing
## @param learning_objective: Specific learning objective to address
func share_cultural_knowledge(companion_id: String, knowledge_context: String, learning_objective: String = "") -> void:
	if not active_companions.has(companion_id):
		return

	var companion = active_companions[companion_id]
	var knowledge_data = _get_relevant_cultural_knowledge(companion, knowledge_context)

	if knowledge_data.is_empty():
		return

	# Present knowledge through appropriate method
	var presentation_method = _determine_knowledge_presentation_method(companion, knowledge_data)
	_present_cultural_knowledge(companion_id, knowledge_data, presentation_method)

	# Record educational event
	if EducationManager:
		EducationManager.record_learning_event("cultural_knowledge_shared", {
			"companion_id": companion_id,
			"knowledge_type": knowledge_context,
			"learning_objective": learning_objective,
			"presentation_method": presentation_method
		})

	cultural_knowledge_shared.emit(companion_id, knowledge_context, learning_objective)

## Get companion recommendations for player
## @param companion_id: Companion providing recommendations
## @param current_context: Current game/learning context
## @return: Dictionary with recommendations
func get_companion_recommendations(companion_id: String, current_context: Dictionary) -> Dictionary:
	if not active_companions.has(companion_id):
		return {}

	var companion = active_companions[companion_id]

	# Generate recommendations based on companion's knowledge and player context
	var recommendations = {
		"next_actions": _suggest_next_actions(companion, current_context),
		"learning_opportunities": _identify_learning_opportunities(companion, current_context),
		"cultural_insights": _provide_cultural_insights(companion, current_context),
		"navigation_suggestions": _suggest_navigation_options(companion, current_context)
	}

	return recommendations

#endregion

#region Private Implementation

## Initialize companion AI system
func _initialize_companion_ai_system() -> void:
	# Setup pathfinding system
	pathfinding_system = {
		"navigation_mesh": null,
		"obstacle_avoidance": true,
		"guard_detection_radius": 10.0,
		"stealth_path_preference": 0.8
	}

	# Initialize decision trees
	_create_companion_decision_trees()

	# Setup group formations
	_initialize_group_formations()

## Load companion personalities
func _load_companion_personalities() -> void:
	companion_personalities = {
		"bundos": {
			"traits": ["helpful", "scholarly", "patient", "encouraging"],
			"teaching_style": "adaptive",
			"cultural_knowledge_level": "high",
			"emergency_response": "protective",
			"dialogue_patterns": ["questioning", "explanatory", "supportive"]
		},
		"elder_monk": {
			"traits": ["wise", "calm", "authoritative", "spiritual"],
			"teaching_style": "traditional",
			"cultural_knowledge_level": "expert",
			"emergency_response": "leadership",
			"dialogue_patterns": ["philosophical", "instructional", "contemplative"]
		},
		"young_student": {
			"traits": ["eager", "curious", "energetic", "learning"],
			"teaching_style": "peer_learning",
			"cultural_knowledge_level": "medium",
			"emergency_response": "following",
			"dialogue_patterns": ["questioning", "enthusiastic", "collaborative"]
		}
	}

## Setup cultural knowledge base
func _setup_cultural_knowledge_base() -> void:
	cultural_knowledge_base = {
		"religious_practices": {
			"daily_prayers": {
				"description": "Manichaean daily prayer rituals",
				"cultural_significance": "Connection to divine light",
				"teaching_points": ["proper posture", "prayer timing", "spiritual focus"]
			},
			"manuscript_reverence": {
				"description": "Proper approach to sacred texts",
				"cultural_significance": "Respect for divine knowledge",
				"teaching_points": ["ritual cleansing", "reverent handling", "contemplative reading"]
			}
		},
		"social_customs": {
			"greetings": {
				"description": "Traditional Persian greeting customs",
				"cultural_significance": "Social hierarchy and respect",
				"teaching_points": ["appropriate gestures", "verbal formulas", "social context"]
			}
		},
		"architectural_knowledge": {
			"sanctuary_layout": {
				"description": "Understanding of sanctuary architecture",
				"cultural_significance": "Sacred space organization",
				"teaching_points": ["functional areas", "symbolic meanings", "navigation principles"]
			}
		}
	}

## Generate unique companion ID
func _generate_companion_id(companion_type: String) -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 1000
	return "%s_companion_%d_%03d" % [companion_type, timestamp, random_suffix]

## Get companion personality data
func _get_companion_personality(companion_type: String) -> Dictionary:
	return companion_personalities.get(companion_type, companion_personalities.get("bundos", {}))

## Get emergency protocols for companion type
func _get_emergency_protocols(companion_type: String) -> Dictionary:
	var base_protocols = {
		"sanctuary_attack": {
			"priority": "protect_player",
			"actions": ["assess_threat", "guide_to_safety", "coordinate_escape"],
			"fallback": "individual_escape"
		},
		"guard_detection": {
			"priority": "avoid_detection",
			"actions": ["signal_warning", "create_distraction", "guide_alternate_route"],
			"fallback": "hide_and_wait"
		}
	}

	# Customize based on companion type
	match companion_type:
		"elder_monk":
			base_protocols["sanctuary_attack"]["priority"] = "protect_group"
		"young_student":
			base_protocols["guard_detection"]["actions"].append("seek_elder_guidance")

	return base_protocols

## Convert state enum to string
func _state_to_string(state: CompanionState) -> String:
	match state:
		CompanionState.IDLE: return "idle"
		CompanionState.FOLLOWING: return "following"
		CompanionState.TEACHING: return "teaching"
		CompanionState.ASSISTING: return "assisting"
		CompanionState.DIALOGUE: return "dialogue"
		CompanionState.EMERGENCY_RESPONSE: return "emergency_response"
		CompanionState.GROUP_COORDINATION: return "group_coordination"
		CompanionState.PATHFINDING: return "pathfinding"
		CompanionState.CULTURAL_DEMONSTRATION: return "cultural_demonstration"
		CompanionState.ADAPTIVE_LEARNING: return "adaptive_learning"
		_: return "unknown"

## Convert assistance type to string
func _assistance_type_to_string(assistance_type: AssistanceType) -> String:
	match assistance_type:
		AssistanceType.GAME_MECHANICS: return "game_mechanics"
		AssistanceType.CULTURAL_CONTEXT: return "cultural_context"
		AssistanceType.HISTORICAL_BACKGROUND: return "historical_background"
		AssistanceType.RELIGIOUS_PRACTICES: return "religious_practices"
		AssistanceType.NAVIGATION_HELP: return "navigation_help"
		AssistanceType.OBJECT_INTERACTION: return "object_interaction"
		AssistanceType.LEARNING_ENCOURAGEMENT: return "learning_encouragement"
		_: return "unknown"

## Convert emergency type to string
func _emergency_type_to_string(emergency_type: EmergencyType) -> String:
	match emergency_type:
		EmergencyType.SANCTUARY_ATTACK: return "sanctuary_attack"
		EmergencyType.GUARD_DETECTION: return "guard_detection"
		EmergencyType.FIRE_OUTBREAK: return "fire_outbreak"
		EmergencyType.STRUCTURAL_COLLAPSE: return "structural_collapse"
		EmergencyType.GROUP_SEPARATION: return "group_separation"
		EmergencyType.PLAYER_INJURY: return "player_injury"
		_: return "unknown"

## Placeholder methods for missing functionality
func _initialize_companion_ai(companion_data: Dictionary, config: Dictionary) -> void: pass
func _handle_state_transition(companion: Dictionary, old_state: CompanionState, new_state: CompanionState, context: Dictionary) -> void: pass
func _prepare_educational_dialogue(companion: Dictionary, dialogue_type: String, educational_context: Dictionary) -> Dictionary: return {}
func _begin_dialogue_sequence(companion_id: String, dialogue_data: Dictionary) -> void: pass
func _can_provide_assistance(companion: Dictionary, assistance_type: AssistanceType) -> bool: return true
func _provide_assistance(companion_id: String, assistance_type: AssistanceType, context: Dictionary) -> void: pass
func _has_cultural_knowledge(companion: Dictionary, practice_type: String, knowledge_level: String) -> bool: return true
func _begin_cultural_demonstration(companion_id: String, practice_type: String, cultural_context: Dictionary) -> void: pass
func _calculate_and_execute_path(companion_id: String, pathfinding_data: Dictionary) -> void: pass
func _execute_emergency_response(companion_id: String, protocol: Dictionary, emergency_data: Dictionary) -> void: pass
func _select_group_leader(companion_ids: Array) -> String: return companion_ids[0] if not companion_ids.is_empty() else ""
func _calculate_optimal_escape_route(escape_objective: String) -> Dictionary: return {}
func _generate_contingency_plans(companion_ids: Array, escape_objective: String) -> Array: return []
func _execute_group_coordination(coordination_plan: Dictionary) -> void: pass
func _analyze_adaptation_needs(companion: Dictionary, player_progress_data: Dictionary) -> Dictionary: return {}
func _apply_behavioral_adaptations(companion_id: String, adaptation_needed: Dictionary) -> void: pass
func _generate_progress_acknowledgment(companion: Dictionary, player_progress_data: Dictionary) -> Dictionary: return {}
func _get_relevant_cultural_knowledge(companion: Dictionary, knowledge_context: String) -> Dictionary: return {}
func _determine_knowledge_presentation_method(companion: Dictionary, knowledge_data: Dictionary) -> String: return "dialogue"
func _present_cultural_knowledge(companion_id: String, knowledge_data: Dictionary, presentation_method: String) -> void: pass
func _suggest_next_actions(companion: Dictionary, current_context: Dictionary) -> Array: return []
func _identify_learning_opportunities(companion: Dictionary, current_context: Dictionary) -> Array: return []
func _provide_cultural_insights(companion: Dictionary, current_context: Dictionary) -> Array: return []
func _suggest_navigation_options(companion: Dictionary, current_context: Dictionary) -> Array: return []
func _create_companion_decision_trees() -> void: pass
func _initialize_group_formations() -> void: pass

#endregion

#region Emergency Response and Group Coordination

## Activate emergency response for companion
## @param companion_id: Companion to activate emergency response for
## @param emergency_type: Type of emergency
## @param emergency_data: Data about the emergency situation
func activate_emergency_response(companion_id: String, emergency_type: EmergencyType, emergency_data: Dictionary = {}) -> void:
	if not active_companions.has(companion_id):
		return
	
	var companion = active_companions[companion_id]
	
	# Get emergency protocol for this companion type
	var protocol = companion["emergency_protocols"].get(_emergency_type_to_string(emergency_type), {})
	
	if protocol.is_empty():
		push_warning("[CompanionAI] No emergency protocol for: " + _emergency_type_to_string(emergency_type))
		return
	
	# Transition to emergency response state
	set_companion_state(companion_id, CompanionState.EMERGENCY_RESPONSE)
	
	# Execute emergency response
	_execute_emergency_response(companion_id, protocol, emergency_data)
	
	emergency_response_activated.emit(companion_id, _emergency_type_to_string(emergency_type), protocol)

## Coordinate group of companions for escape
## @param companion_ids: Array of companion IDs to coordinate
## @param escape_objective: Objective for the escape sequence
## @param coordination_data: Data for coordination behavior
func coordinate_group_escape(companion_ids: Array, escape_objective: String = "sanctuary_exit", coordination_data: Dictionary = {}) -> void:
	if companion_ids.is_empty():
		return
	
	# Select group leader (most experienced companion)
	var leader_id = _select_group_leader(companion_ids)
	
	# Setup group coordination
	var coordination_plan = {
		"leader_id": leader_id,
		"group_members": companion_ids,
		"objective": escape_objective,
		"formation": coordination_data.get("formation", "protective"),
		"escape_route": _calculate_optimal_escape_route(escape_objective),
		"contingency_plans": _generate_contingency_plans(companion_ids, escape_objective)
	}
	
	# Transition all companions to group coordination state
	for companion_id in companion_ids:
		if active_companions.has(companion_id):
			set_companion_state(companion_id, CompanionState.GROUP_COORDINATION)
			active_companions[companion_id]["group_coordination"] = coordination_plan
	
	# Execute coordination plan
	_execute_group_coordination(coordination_plan)
	
	group_coordination_started.emit(leader_id, companion_ids, escape_objective)

#endregion
