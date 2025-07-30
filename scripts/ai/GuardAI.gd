extends Node

## GuardAI - Intelligent Guard and Patrol System
##
## Advanced AI system for Pushtibagan Guards providing challenging but fair
## stealth gameplay while supporting educational objectives about military
## organization and tactics in the ancient world.
##
## Key Features:
## - Realistic patrol patterns reflecting military training and tactical doctrine
## - Detection system based on sight, sound, and logical investigation
## - Communication system for guard coordination and information sharing
## - Escalation system increasing threat level based on player actions
## - Cultural behavior patterns reflecting disciplined imperial troops
## - Investigation behaviors creating tension without unfair punishment
## - Combat AI emphasizing capture over killing
##
## Usage Example:
## ```gdscript
## # Create guard patrol
## var guard_id = GuardAI.create_guard("pushtibagan_guard", {
##     "patrol_route": "main_hall_circuit",
##     "alertness_level": "normal",
##     "military_rank": "soldier"
## })
## 
## # Setup patrol pattern
## GuardAI.setup_patrol_pattern(guard_id, patrol_points, "systematic_sweep")
## 
## # Trigger investigation
## GuardAI.investigate_disturbance(guard_id, disturbance_location, "sound")
## ```

# Guard AI signals
signal guard_created(guard_id: String, guard_type: String, patrol_assignment: String)
signal guard_state_changed(guard_id: String, old_state: String, new_state: String)
signal detection_event(guard_id: String, detection_type: String, target: String, confidence: float)
signal investigation_started(guard_id: String, investigation_type: String, location: Vector3)
signal communication_sent(sender_id: String, receiver_id: String, message_type: String, content: Dictionary)

# Educational signals for military tactics
signal military_formation_demonstrated(formation_type: String, tactical_purpose: String, historical_context: Dictionary)
signal tactical_doctrine_exhibited(doctrine_type: String, implementation: String, educational_value: Dictionary)
signal guard_coordination_displayed(coordination_type: String, effectiveness: String, learning_opportunity: Dictionary)

# Escalation and alert signals
signal alert_level_changed(area: String, old_level: String, new_level: String, reason: String)
signal search_pattern_initiated(search_type: String, area: String, participating_guards: Array)
signal capture_attempt_started(guard_id: String, target: String, capture_method: String)

## Guard AI states
enum GuardState {
	PATROLLING,
	INVESTIGATING,
	SEARCHING,
	PURSUING,
	COMMUNICATING,
	COORDINATING,
	CAPTURING,
	REPORTING,
	RESTING,
	ALERT_RESPONSE
}

## Detection types
enum DetectionType {
	VISUAL_DIRECT,
	VISUAL_PERIPHERAL,
	AUDIO_FOOTSTEPS,
	AUDIO_DISTURBANCE,
	ENVIRONMENTAL_CHANGE,
	LOGICAL_DEDUCTION,
	COMMUNICATION_ALERT
}

## Alert levels for escalation system
enum AlertLevel {
	PEACEFUL,
	SUSPICIOUS,
	CONCERNED,
	ALERT,
	HIGH_ALERT,
	EMERGENCY
}

## Military formations and tactics
enum MilitaryFormation {
	SINGLE_PATROL,
	PAIRED_PATROL,
	TRIANGLE_FORMATION,
	LINE_FORMATION,
	ENCIRCLEMENT,
	SEARCH_GRID,
	DEFENSIVE_POSITION
}

# Core guard management
var active_guards: Dictionary = {}
var patrol_routes: Dictionary = {}
var guard_communications: Dictionary = {}
var tactical_formations: Dictionary = {}

# Detection and investigation systems
var detection_parameters: Dictionary = {}
var investigation_protocols: Dictionary = {}
var search_patterns: Dictionary = {}

# Alert and escalation system
var area_alert_levels: Dictionary = {}
var escalation_triggers: Dictionary = {}
var communication_networks: Dictionary = {}

# Cultural and educational elements
var military_doctrines: Dictionary = {}
var historical_tactics: Dictionary = {}
var cultural_behaviors: Dictionary = {}

# Performance optimization
var guard_update_frequency: float = 0.2
var max_active_guards: int = 8
var detection_optimization: bool = true
var communication_range: float = 20.0

func _ready():
	_initialize_guard_ai_system()
	_load_military_doctrines()
	_setup_patrol_systems()

#region Guard Management

## Create a new guard AI
## @param guard_type: Type of guard to create
## @param config: Configuration for the guard
## @return: Guard ID if successful, empty string if failed
func create_guard(guard_type: String, config: Dictionary = {}) -> String:
	if active_guards.size() >= max_active_guards:
		push_warning("[GuardAI] Maximum active guards reached")
		return ""
	
	var guard_id = _generate_guard_id(guard_type)
	
	# Create guard data structure
	var guard_data = {
		"id": guard_id,
		"type": guard_type,
		"state": GuardState.PATROLLING,
		"military_rank": config.get("military_rank", "soldier"),
		"alertness_level": config.get("alertness_level", "normal"),
		"patrol_assignment": config.get("patrol_route", "default"),
		"detection_range": _get_detection_range(guard_type),
		"communication_range": communication_range,
		"current_patrol_point": 0,
		"investigation_data": {},
		"communication_log": [],
		"cultural_behavior": _get_cultural_behavior(guard_type),
		"tactical_knowledge": _get_tactical_knowledge(guard_type),
		"created_time": Time.get_unix_time_from_system()
	}
	
	# Initialize guard AI systems
	_initialize_guard_ai(guard_data, config)
	
	# Store guard
	active_guards[guard_id] = guard_data
	
	guard_created.emit(guard_id, guard_type, guard_data["patrol_assignment"])
	return guard_id

## Setup patrol pattern for guard
## @param guard_id: Guard to setup patrol for
## @param patrol_points: Array of patrol waypoints
## @param patrol_type: Type of patrol pattern
func setup_patrol_pattern(guard_id: String, patrol_points: Array, patrol_type: String = "circuit") -> void:
	if not active_guards.has(guard_id):
		return
	
	var guard = active_guards[guard_id]
	
	# Create patrol route data
	var patrol_route = {
		"points": patrol_points,
		"type": patrol_type,
		"timing": _calculate_patrol_timing(patrol_points, patrol_type),
		"cultural_elements": _add_cultural_patrol_elements(guard, patrol_points),
		"tactical_considerations": _analyze_tactical_patrol_value(patrol_points)
	}
	
	patrol_routes[guard_id] = patrol_route
	guard["patrol_assignment"] = guard_id + "_custom"
	
	# Start patrol
	_begin_patrol_execution(guard_id, patrol_route)

## Set guard state with cultural authenticity
## @param guard_id: Guard to update
## @param new_state: New state for the guard
## @param context: Additional context for the state change
func set_guard_state(guard_id: String, new_state: GuardState, context: Dictionary = {}) -> void:
	if not active_guards.has(guard_id):
		return
	
	var guard = active_guards[guard_id]
	var old_state = guard["state"]
	
	if old_state != new_state:
		# Validate state transition based on military protocol
		if not _is_valid_military_transition(old_state, new_state, guard):
			return
		
		guard["state"] = new_state
		_handle_guard_state_transition(guard, old_state, new_state, context)
		guard_state_changed.emit(guard_id, _state_to_string(old_state), _state_to_string(new_state))

#endregion

#region Detection and Investigation

## Process detection event
## @param guard_id: Guard making the detection
## @param detection_type: Type of detection
## @param target_position: Position of detected target
## @param confidence: Confidence level of detection (0.0 to 1.0)
func process_detection(guard_id: String, detection_type: DetectionType, target_position: Vector3, confidence: float = 1.0) -> void:
	if not active_guards.has(guard_id):
		return
	
	var guard = active_guards[guard_id]
	
	# Validate detection based on guard capabilities and state
	if not _validate_detection(guard, detection_type, target_position, confidence):
		return
	
	# Record detection event
	var detection_data = {
		"type": detection_type,
		"position": target_position,
		"confidence": confidence,
		"timestamp": Time.get_unix_time_from_system(),
		"guard_state": guard["state"]
	}
	
	# Process detection based on type and confidence
	_process_detection_response(guard_id, detection_data)
	
	detection_event.emit(guard_id, _detection_type_to_string(detection_type), "player", confidence)

## Start investigation of disturbance
## @param guard_id: Guard to investigate
## @param disturbance_location: Location of disturbance
## @param investigation_type: Type of investigation to conduct
func investigate_disturbance(guard_id: String, disturbance_location: Vector3, investigation_type: String) -> void:
	if not active_guards.has(guard_id):
		return
	
	var guard = active_guards[guard_id]
	
	# Setup investigation data
	var investigation_data = {
		"location": disturbance_location,
		"type": investigation_type,
		"start_time": Time.get_unix_time_from_system(),
		"search_radius": _calculate_search_radius(investigation_type),
		"investigation_steps": _get_investigation_protocol(guard, investigation_type),
		"cultural_approach": _get_cultural_investigation_approach(guard)
	}
	
	guard["investigation_data"] = investigation_data
	set_guard_state(guard_id, GuardState.INVESTIGATING)
	
	# Begin investigation sequence
	_execute_investigation_sequence(guard_id, investigation_data)
	
	investigation_started.emit(guard_id, investigation_type, disturbance_location)

## Conduct logical deduction based on evidence
## @param guard_id: Guard conducting deduction
## @param evidence_data: Available evidence for analysis
## @return: Deduction results and confidence level
func conduct_logical_deduction(guard_id: String, evidence_data: Dictionary) -> Dictionary:
	if not active_guards.has(guard_id):
		return {}
	
	var guard = active_guards[guard_id]
	
	# Analyze evidence based on guard's training and experience
	var deduction_results = _analyze_evidence(guard, evidence_data)
	
	# Apply cultural and military training to deduction
	var cultural_analysis = _apply_cultural_deduction_methods(guard, evidence_data)
	deduction_results.merge(cultural_analysis)
	
	# Generate educational content about investigation methods
	if EducationManager:
		EducationManager.record_learning_event("military_investigation_observed", {
			"guard_id": guard_id,
			"investigation_methods": deduction_results.get("methods_used", []),
			"cultural_context": cultural_analysis,
			"educational_value": "ancient_investigation_techniques"
		})
	
	return deduction_results

#endregion

#region Capture and Non-Lethal Combat

## Attempt to capture target
## @param guard_id: Guard attempting capture
## @param target_position: Position of target to capture
## @param capture_method: Method of capture to use
func attempt_capture(guard_id: String, target_position: Vector3, capture_method: String = "restraint") -> void:
	if not active_guards.has(guard_id):
		return

	var guard = active_guards[guard_id]

	# Validate capture attempt based on guard training and cultural values
	if not _validate_capture_attempt(guard, capture_method):
		return

	# Setup capture data
	var capture_data = {
		"target_position": target_position,
		"method": capture_method,
		"cultural_approach": _get_cultural_capture_approach(guard),
		"non_lethal_priority": true,
		"educational_objective": "demonstrate_ancient_law_enforcement"
	}

	set_guard_state(guard_id, GuardState.CAPTURING)

	# Execute capture attempt
	_execute_capture_attempt(guard_id, capture_data)

	capture_attempt_started.emit(guard_id, "player", capture_method)

## Get guard tactical assessment
## @param guard_id: Guard making assessment
## @param situation_data: Data about current situation
## @return: Tactical assessment and recommended actions
func get_tactical_assessment(guard_id: String, situation_data: Dictionary) -> Dictionary:
	if not active_guards.has(guard_id):
		return {}

	var guard = active_guards[guard_id]

	# Analyze situation using military training
	var assessment = {
		"threat_level": _assess_threat_level(guard, situation_data),
		"tactical_options": _identify_tactical_options(guard, situation_data),
		"cultural_considerations": _apply_cultural_tactical_analysis(guard, situation_data),
		"recommended_actions": _generate_tactical_recommendations(guard, situation_data),
		"educational_value": _identify_educational_opportunities(situation_data)
	}

	return assessment

#endregion

#region Private Implementation

## Initialize guard AI system
func _initialize_guard_ai_system() -> void:
	# Setup detection parameters
	detection_parameters = {
		"visual_range": 15.0,
		"audio_range": 10.0,
		"peripheral_vision_angle": 120.0,
		"investigation_thoroughness": 0.8
	}

	# Initialize alert levels for different areas
	area_alert_levels = {
		"main_hall": AlertLevel.PEACEFUL,
		"library": AlertLevel.PEACEFUL,
		"courtyard": AlertLevel.PEACEFUL,
		"passages": AlertLevel.PEACEFUL
	}

## Load military doctrines
func _load_military_doctrines() -> void:
	military_doctrines = {
		"pushtibagan_doctrine": {
			"core_principles": ["discipline", "coordination", "non_lethal_force", "cultural_respect"],
			"patrol_methods": ["systematic_coverage", "unpredictable_timing", "cultural_sensitivity"],
			"investigation_protocols": ["thorough_examination", "logical_deduction", "evidence_preservation"],
			"communication_hierarchy": ["rank_based", "clear_reporting", "tactical_coordination"]
		},
		"imperial_guard_training": {
			"detection_methods": ["visual_scanning", "audio_monitoring", "environmental_awareness"],
			"response_protocols": ["graduated_response", "capture_priority", "minimal_force"],
			"cultural_behavior": ["respectful_authority", "disciplined_conduct", "honor_code"]
		}
	}

## Setup patrol systems
func _setup_patrol_systems() -> void:
	# Define standard patrol routes
	patrol_routes = {
		"main_hall_circuit": {
			"points": [],  # Would be populated with actual Vector3 positions
			"timing": 120.0,  # 2 minutes per circuit
			"cultural_stops": ["prayer_area", "manuscript_display"]
		},
		"perimeter_sweep": {
			"points": [],
			"timing": 180.0,  # 3 minutes per sweep
			"cultural_stops": ["entrance_blessing", "garden_observation"]
		}
	}

## Generate unique guard ID
func _generate_guard_id(guard_type: String) -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 1000
	return "%s_guard_%d_%03d" % [guard_type, timestamp, random_suffix]

## Get detection range for guard type
func _get_detection_range(guard_type: String) -> Dictionary:
	match guard_type:
		"pushtibagan_guard":
			return {
				"visual_range": 15.0,
				"audio_range": 10.0,
				"investigation_range": 8.0
			}
		"elite_guard":
			return {
				"visual_range": 20.0,
				"audio_range": 12.0,
				"investigation_range": 10.0
			}
		_:
			return {
				"visual_range": 12.0,
				"audio_range": 8.0,
				"investigation_range": 6.0
			}

## Get cultural behavior for guard type
func _get_cultural_behavior(guard_type: String) -> Dictionary:
	return {
		"respect_for_sacred_spaces": true,
		"disciplined_conduct": true,
		"honor_code_adherence": true,
		"cultural_sensitivity": "high",
		"religious_observance": "orthodox_persian"
	}

## Get tactical knowledge for guard type
func _get_tactical_knowledge(guard_type: String) -> Dictionary:
	match guard_type:
		"pushtibagan_guard":
			return {
				"formation_training": "advanced",
				"investigation_skills": "high",
				"communication_protocols": "military_standard",
				"capture_techniques": "non_lethal_specialist"
			}
		_:
			return {
				"formation_training": "basic",
				"investigation_skills": "medium",
				"communication_protocols": "standard",
				"capture_techniques": "basic"
			}

## Convert state enum to string
func _state_to_string(state: GuardState) -> String:
	match state:
		GuardState.PATROLLING: return "patrolling"
		GuardState.INVESTIGATING: return "investigating"
		GuardState.SEARCHING: return "searching"
		GuardState.PURSUING: return "pursuing"
		GuardState.COMMUNICATING: return "communicating"
		GuardState.COORDINATING: return "coordinating"
		GuardState.CAPTURING: return "capturing"
		GuardState.REPORTING: return "reporting"
		GuardState.RESTING: return "resting"
		GuardState.ALERT_RESPONSE: return "alert_response"
		_: return "unknown"

## Convert detection type to string
func _detection_type_to_string(detection_type: DetectionType) -> String:
	match detection_type:
		DetectionType.VISUAL_DIRECT: return "visual_direct"
		DetectionType.VISUAL_PERIPHERAL: return "visual_peripheral"
		DetectionType.AUDIO_FOOTSTEPS: return "audio_footsteps"
		DetectionType.AUDIO_DISTURBANCE: return "audio_disturbance"
		DetectionType.ENVIRONMENTAL_CHANGE: return "environmental_change"
		DetectionType.LOGICAL_DEDUCTION: return "logical_deduction"
		DetectionType.COMMUNICATION_ALERT: return "communication_alert"
		_: return "unknown"

## Convert alert level to string
func _alert_level_to_string(alert_level: AlertLevel) -> String:
	match alert_level:
		AlertLevel.PEACEFUL: return "peaceful"
		AlertLevel.SUSPICIOUS: return "suspicious"
		AlertLevel.CONCERNED: return "concerned"
		AlertLevel.ALERT: return "alert"
		AlertLevel.HIGH_ALERT: return "high_alert"
		AlertLevel.EMERGENCY: return "emergency"
		_: return "unknown"

## Convert formation type to string
func _formation_type_to_string(formation_type: MilitaryFormation) -> String:
	match formation_type:
		MilitaryFormation.SINGLE_PATROL: return "single_patrol"
		MilitaryFormation.PAIRED_PATROL: return "paired_patrol"
		MilitaryFormation.TRIANGLE_FORMATION: return "triangle_formation"
		MilitaryFormation.LINE_FORMATION: return "line_formation"
		MilitaryFormation.ENCIRCLEMENT: return "encirclement"
		MilitaryFormation.SEARCH_GRID: return "search_grid"
		MilitaryFormation.DEFENSIVE_POSITION: return "defensive_position"
		_: return "unknown"

## Placeholder methods for missing functionality
func _initialize_guard_ai(guard_data: Dictionary, config: Dictionary) -> void: pass
func _calculate_patrol_timing(patrol_points: Array, patrol_type: String) -> float: return 120.0
func _add_cultural_patrol_elements(guard: Dictionary, patrol_points: Array) -> Array: return []
func _analyze_tactical_patrol_value(patrol_points: Array) -> Dictionary: return {}
func _begin_patrol_execution(guard_id: String, patrol_route: Dictionary) -> void: pass
func _is_valid_military_transition(old_state: GuardState, new_state: GuardState, guard: Dictionary) -> bool: return true
func _handle_guard_state_transition(guard: Dictionary, old_state: GuardState, new_state: GuardState, context: Dictionary) -> void: pass
func _validate_detection(guard: Dictionary, detection_type: DetectionType, target_position: Vector3, confidence: float) -> bool: return true
func _process_detection_response(guard_id: String, detection_data: Dictionary) -> void: pass
func _calculate_search_radius(investigation_type: String) -> float: return 5.0
func _get_investigation_protocol(guard: Dictionary, investigation_type: String) -> Array: return []
func _get_cultural_investigation_approach(guard: Dictionary) -> Dictionary: return {}
func _execute_investigation_sequence(guard_id: String, investigation_data: Dictionary) -> void: pass
func _analyze_evidence(guard: Dictionary, evidence_data: Dictionary) -> Dictionary: return {}
func _apply_cultural_deduction_methods(guard: Dictionary, evidence_data: Dictionary) -> Dictionary: return {}
func _validate_communication_protocol(sender: Dictionary, message_type: String, receiver_id: String) -> bool: return true
func _get_military_communication_protocol(sender: Dictionary, message_type: String) -> Dictionary: return {}
func _broadcast_communication(communication: Dictionary) -> void: pass
func _send_direct_communication(communication: Dictionary) -> void: pass
func _record_military_communication_example(communication: Dictionary) -> void: pass
func _validate_formation_composition(participating_guards: Array, formation_type: MilitaryFormation) -> bool: return true
func _get_formation_doctrine(formation_type: MilitaryFormation) -> Dictionary: return {}
func _get_formation_cultural_context(formation_type: MilitaryFormation) -> Dictionary: return {}
func _create_formation_execution_plan(formation_type: MilitaryFormation, objective: String) -> Dictionary: return {}
func _execute_military_formation(formation_data: Dictionary) -> void: pass
func _get_formation_historical_context(formation_type: MilitaryFormation) -> Dictionary: return {}
func _apply_alert_level_to_area_guards(area_name: String, new_alert_level: AlertLevel) -> void: pass
func _trigger_escalation_responses(area_name: String, new_alert_level: AlertLevel, reason: String) -> void: pass
func _create_military_search_plan(search_type: String, search_area: String, available_guards: Array) -> Dictionary: return {}
func _assign_guards_to_search_positions(search_plan: Dictionary) -> void: pass
func _execute_coordinated_search(search_plan: Dictionary) -> void: pass
func _validate_capture_attempt(guard: Dictionary, capture_method: String) -> bool: return true
func _get_cultural_capture_approach(guard: Dictionary) -> Dictionary: return {}
func _execute_capture_attempt(guard_id: String, capture_data: Dictionary) -> void: pass
func _assess_threat_level(guard: Dictionary, situation_data: Dictionary) -> String: return "low"
func _identify_tactical_options(guard: Dictionary, situation_data: Dictionary) -> Array: return []
func _apply_cultural_tactical_analysis(guard: Dictionary, situation_data: Dictionary) -> Dictionary: return {}
func _generate_tactical_recommendations(guard: Dictionary, situation_data: Dictionary) -> Array: return []
func _identify_educational_opportunities(situation_data: Dictionary) -> Array: return []

#endregion

#region Communication and Coordination

## Send communication between guards
## @param sender_id: Guard sending the message
## @param receiver_id: Guard receiving the message (or "all" for broadcast)
## @param message_type: Type of communication
## @param message_content: Content of the message
func send_guard_communication(sender_id: String, receiver_id: String, message_type: String, message_content: Dictionary) -> void:
	if not active_guards.has(sender_id):
		return
	
	var sender = active_guards[sender_id]
	
	# Validate communication based on military protocol
	if not _validate_communication_protocol(sender, message_type, receiver_id):
		return
	
	# Create communication message
	var communication = {
		"sender_id": sender_id,
		"receiver_id": receiver_id,
		"message_type": message_type,
		"content": message_content,
		"timestamp": Time.get_unix_time_from_system(),
		"military_protocol": _get_military_communication_protocol(sender, message_type)
	}
	
	# Process communication
	if receiver_id == "all":
		_broadcast_communication(communication)
	else:
		_send_direct_communication(communication)
	
	# Record communication for educational purposes
	_record_military_communication_example(communication)
	
	communication_sent.emit(sender_id, receiver_id, message_type, message_content)

## Coordinate guard formation
## @param formation_leader_id: Guard leading the formation
## @param participating_guards: Array of guard IDs in formation
## @param formation_type: Type of military formation
## @param objective: Objective for the formation
func coordinate_guard_formation(formation_leader_id: String, participating_guards: Array, formation_type: MilitaryFormation, objective: String) -> void:
	if not active_guards.has(formation_leader_id):
		return
	
	# Validate formation based on military doctrine
	if not _validate_formation_composition(participating_guards, formation_type):
		return
	
	# Create formation data
	var formation_data = {
		"leader_id": formation_leader_id,
		"participants": participating_guards,
		"formation_type": formation_type,
		"objective": objective,
		"tactical_doctrine": _get_formation_doctrine(formation_type),
		"cultural_significance": _get_formation_cultural_context(formation_type),
		"execution_plan": _create_formation_execution_plan(formation_type, objective)
	}
	
	# Execute formation
	_execute_military_formation(formation_data)
	
	# Provide educational context
	var historical_context = _get_formation_historical_context(formation_type)
	military_formation_demonstrated.emit(_formation_type_to_string(formation_type), objective, historical_context)

#endregion

#region Alert and Escalation System

## Update area alert level
## @param area_name: Name of the area to update
## @param new_alert_level: New alert level for the area
## @param reason: Reason for the alert level change
func update_area_alert_level(area_name: String, new_alert_level: AlertLevel, reason: String) -> void:
	var old_level = area_alert_levels.get(area_name, AlertLevel.PEACEFUL)
	
	if old_level == new_alert_level:
		return
	
	area_alert_levels[area_name] = new_alert_level
	
	# Apply alert level changes to guards in area
	_apply_alert_level_to_area_guards(area_name, new_alert_level)
	
	# Trigger appropriate responses based on escalation
	_trigger_escalation_responses(area_name, new_alert_level, reason)
	
	alert_level_changed.emit(area_name, _alert_level_to_string(old_level), _alert_level_to_string(new_alert_level), reason)

## Initiate coordinated search pattern
## @param search_type: Type of search to conduct
## @param search_area: Area to search
## @param available_guards: Guards available for search
func initiate_search_pattern(search_type: String, search_area: String, available_guards: Array) -> void:
	if available_guards.is_empty():
		return
	
	# Create search plan based on military doctrine
	var search_plan = _create_military_search_plan(search_type, search_area, available_guards)
	
	# Assign guards to search positions
	_assign_guards_to_search_positions(search_plan)
	
	# Execute coordinated search
	_execute_coordinated_search(search_plan)
	
	search_pattern_initiated.emit(search_type, search_area, available_guards)

#endregion
