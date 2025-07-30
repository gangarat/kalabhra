extends CharacterBody3D

## BabakController - Advanced 3D Character Controller
##
## Comprehensive character controller for Babak with stealth mechanics, educational
## interactions, and cultural authenticity. Designed for the Light of the Kalabhra
## educational experience with support for both gameplay and learning objectives.
##
## Key Features:
## - Smooth movement with walking, running, and crouching states
## - Advanced stealth mechanics with noise and visibility systems
## - Educational interaction system for manuscripts and artifacts
## - Inventory management for scrolls, tools, and personal items
## - Stamina system reflecting physical demands
## - Climbing and traversal abilities
## - Contextual animation system
## - Cross-platform input support

# Character state signals
signal movement_state_changed(old_state: String, new_state: String)
signal stealth_state_changed(detected: bool, detection_level: float)
signal stamina_changed(current: float, maximum: float)
signal interaction_available(object: Node3D, interaction_type: String)
signal interaction_started(object: Node3D, interaction_type: String)
signal inventory_changed(item_added: String, total_items: int)

# Educational signals
signal manuscript_examined(manuscript_id: String, examination_data: Dictionary)
signal cultural_element_discovered(element_id: String, cultural_context: Dictionary)
signal learning_objective_progress(objective_id: String, progress: float)

## Movement states
enum MovementState {
	IDLE,
	WALKING,
	RUNNING,
	CROUCHING,
	CLIMBING,
	HIDING,
	INTERACTING
}

## Stealth states
enum StealthState {
	UNDETECTED,
	SUSPICIOUS,
	DETECTED,
	ALERTED
}

# Movement configuration
@export var walk_speed: float = 3.0
@export var run_speed: float = 6.0
@export var crouch_speed: float = 1.5
@export var climb_speed: float = 2.0
@export var acceleration: float = 10.0
@export var friction: float = 15.0
@export var jump_velocity: float = 8.0

# Stealth configuration
@export var noise_generation: Dictionary = {
	"walking": 0.3,
	"running": 0.8,
	"crouching": 0.1,
	"climbing": 0.2
}
@export var visibility_modifiers: Dictionary = {
	"standing": 1.0,
	"crouching": 0.6,
	"hiding": 0.2
}

# Stamina system
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 20.0  # per second when running
@export var stamina_recovery_rate: float = 15.0  # per second when not running
@export var stamina_threshold_run: float = 20.0  # minimum stamina to run

# Interaction system
@export var interaction_range: float = 2.0
@export var examination_range: float = 1.5

# Character state
var current_movement_state: MovementState = MovementState.IDLE
var current_stealth_state: StealthState = StealthState.UNDETECTED
var current_stamina: float = 100.0
var is_exhausted: bool = false

# Movement variables
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_vector: Vector2 = Vector2.ZERO
var movement_velocity: Vector3 = Vector3.ZERO
var is_on_ground: bool = true

# Stealth variables
var current_noise_level: float = 0.0
var visibility_level: float = 1.0
var detection_level: float = 0.0
var is_in_cover: bool = false

# Interaction variables
var nearby_interactables: Array[Node3D] = []
var current_interaction_target: Node3D = null
var is_interacting: bool = false

# Inventory system
var inventory: Dictionary = {
	"scrolls": [],
	"tools": [],
	"personal_items": [],
	"manuscripts": []
}
var max_inventory_weight: float = 10.0
var current_inventory_weight: float = 0.0

# Animation and visual
@onready var character_mesh = $CharacterMesh
@onready var animation_player = $AnimationPlayer
@onready var interaction_detector = $InteractionDetector
@onready var stealth_detector = $StealthDetector
@onready var camera_controller = $CameraController

func _ready():
	_setup_character_controller()
	_connect_signals()
	_initialize_systems()

func _physics_process(delta):
	_handle_input(delta)
	_update_movement(delta)
	_update_stealth_system(delta)
	_update_stamina_system(delta)
	_update_interaction_system(delta)
	_update_animations(delta)

#region Movement System

## Handle input for character movement
func _handle_input(delta: float) -> void:
	# Get movement input
	if InputManager:
		input_vector = InputManager.get_movement_vector()
	else:
		input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Handle state changes
	_handle_movement_state_input()
	_handle_interaction_input()
	_handle_stealth_input()

## Handle movement state input
func _handle_movement_state_input() -> void:
	var new_state = current_movement_state
	
	# Check for crouching
	if Input.is_action_pressed("crouch"):
		if current_movement_state != MovementState.CROUCHING and current_movement_state != MovementState.HIDING:
			new_state = MovementState.CROUCHING
	
	# Check for running (only if not exhausted and has stamina)
	elif Input.is_action_pressed("run") and not is_exhausted and current_stamina > stamina_threshold_run:
		if input_vector.length() > 0.1:
			new_state = MovementState.RUNNING
	
	# Check for walking
	elif input_vector.length() > 0.1:
		new_state = MovementState.WALKING
	
	# Default to idle
	else:
		new_state = MovementState.IDLE
	
	# Handle jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	_set_movement_state(new_state)

## Update character movement
func _update_movement(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		is_on_ground = false
	else:
		is_on_ground = true
	
	# Calculate target velocity based on state
	var target_velocity = _calculate_target_velocity()
	
	# Apply movement with acceleration/friction
	if input_vector.length() > 0.1:
		movement_velocity = movement_velocity.move_toward(target_velocity, acceleration * delta)
	else:
		movement_velocity = movement_velocity.move_toward(Vector3.ZERO, friction * delta)
	
	# Apply movement
	velocity.x = movement_velocity.x
	velocity.z = movement_velocity.z
	
	# Move character
	move_and_slide()
	
	# Update noise generation
	_update_noise_generation()

## Calculate target velocity based on current state
func _calculate_target_velocity() -> Vector3:
	var speed = walk_speed
	
	match current_movement_state:
		MovementState.RUNNING:
			speed = run_speed
		MovementState.CROUCHING, MovementState.HIDING:
			speed = crouch_speed
		MovementState.CLIMBING:
			speed = climb_speed
		MovementState.INTERACTING:
			speed = 0.0
	
	# Convert input to world space
	var camera_basis = camera_controller.get_camera_basis() if camera_controller else global_transform.basis
	var direction = (camera_basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	
	return direction * speed

## Set movement state with validation
func _set_movement_state(new_state: MovementState) -> void:
	if current_movement_state != new_state:
		var old_state = current_movement_state
		current_movement_state = new_state
		movement_state_changed.emit(_movement_state_to_string(old_state), _movement_state_to_string(new_state))

#endregion

#region Stealth System

## Update stealth detection system
func _update_stealth_system(delta: float) -> void:
	# Update visibility based on current state and environment
	_calculate_visibility_level()
	
	# Update detection level based on nearby guards
	_update_detection_level(delta)
	
	# Check for stealth state changes
	_update_stealth_state()

## Calculate current visibility level
func _calculate_visibility_level() -> void:
	var base_visibility = visibility_modifiers.get(_movement_state_to_string(current_movement_state).to_lower(), 1.0)
	
	# Modify based on cover
	if is_in_cover:
		base_visibility *= 0.3
	
	# Modify based on lighting (if lighting system is available)
	var lighting_modifier = _get_lighting_modifier()
	base_visibility *= lighting_modifier
	
	visibility_level = base_visibility

## Update noise generation based on movement
func _update_noise_generation() -> void:
	var base_noise = 0.0
	
	if input_vector.length() > 0.1:
		var state_key = _movement_state_to_string(current_movement_state).to_lower()
		base_noise = noise_generation.get(state_key, 0.3)
	
	# Modify based on surface type
	var surface_modifier = _get_surface_noise_modifier()
	current_noise_level = base_noise * surface_modifier

## Update detection level from nearby guards
func _update_detection_level(delta: float) -> void:
	var nearby_guards = _get_nearby_guards()
	var max_detection = 0.0
	
	for guard in nearby_guards:
		var guard_detection = _calculate_guard_detection(guard)
		max_detection = max(max_detection, guard_detection)
	
	# Smooth detection level changes
	var target_detection = max_detection
	detection_level = lerp(detection_level, target_detection, 2.0 * delta)

## Update stealth state based on detection level
func _update_stealth_state() -> void:
	var new_state = current_stealth_state
	
	if detection_level < 0.2:
		new_state = StealthState.UNDETECTED
	elif detection_level < 0.5:
		new_state = StealthState.SUSPICIOUS
	elif detection_level < 0.8:
		new_state = StealthState.DETECTED
	else:
		new_state = StealthState.ALERTED
	
	if new_state != current_stealth_state:
		current_stealth_state = new_state
		stealth_state_changed.emit(new_state != StealthState.UNDETECTED, detection_level)

#endregion

#region Stamina System

## Update stamina based on current activity
func _update_stamina_system(delta: float) -> void:
	var stamina_change = 0.0
	
	# Drain stamina when running
	if current_movement_state == MovementState.RUNNING:
		stamina_change = -stamina_drain_rate * delta
	
	# Drain stamina when climbing
	elif current_movement_state == MovementState.CLIMBING:
		stamina_change = -stamina_drain_rate * 0.5 * delta
	
	# Recover stamina when not exerting
	else:
		stamina_change = stamina_recovery_rate * delta
	
	# Apply stamina change
	var old_stamina = current_stamina
	current_stamina = clamp(current_stamina + stamina_change, 0.0, max_stamina)
	
	# Check for exhaustion
	if current_stamina <= 0.0 and not is_exhausted:
		is_exhausted = true
	elif current_stamina > stamina_threshold_run and is_exhausted:
		is_exhausted = false
	
	# Emit signal if stamina changed significantly
	if abs(current_stamina - old_stamina) > 0.1:
		stamina_changed.emit(current_stamina, max_stamina)

#endregion

#region Interaction System

## Handle interaction input
func _handle_interaction_input() -> void:
	if Input.is_action_just_pressed("interact"):
		if current_interaction_target:
			start_interaction(current_interaction_target)

## Update interaction system
func _update_interaction_system(delta: float) -> void:
	_scan_for_interactables()
	_update_interaction_target()

## Start interaction with target object
func start_interaction(target: Node3D) -> void:
	if is_interacting or not target:
		return

	is_interacting = true
	_set_movement_state(MovementState.INTERACTING)

	var interaction_type = _get_interaction_type(target)
	interaction_started.emit(target, interaction_type)

	match interaction_type:
		"manuscript":
			_examine_manuscript(target)
		"artifact":
			_examine_artifact(target)
		"scroll":
			_collect_scroll(target)

## End current interaction
func end_interaction() -> void:
	if not is_interacting:
		return
	is_interacting = false
	_set_movement_state(MovementState.IDLE)

#endregion

#region Inventory System

## Add item to inventory
func add_to_inventory(item_id: String, item_type: String, item_data: Dictionary) -> bool:
	var item_weight = item_data.get("weight", 1.0)
	if current_inventory_weight + item_weight > max_inventory_weight:
		return false

	var item_entry = {
		"id": item_id,
		"data": item_data,
		"acquired_time": Time.get_unix_time_from_system()
	}

	match item_type:
		"scroll":
			inventory["scrolls"].append(item_entry)
		"tool":
			inventory["tools"].append(item_entry)
		"manuscript":
			inventory["manuscripts"].append(item_entry)
		"personal_item":
			inventory["personal_items"].append(item_entry)

	current_inventory_weight += item_weight
	inventory_changed.emit(item_id, _get_total_inventory_items())
	return true

## Get inventory contents
func get_inventory() -> Dictionary:
	return inventory.duplicate(true)

#endregion

#region Private Helper Methods

## Setup character controller
func _setup_character_controller() -> void:
	if not $CollisionShape3D:
		var collision_shape = CollisionShape3D.new()
		var capsule_shape = CapsuleShape3D.new()
		capsule_shape.height = 1.8
		capsule_shape.radius = 0.4
		collision_shape.shape = capsule_shape
		add_child(collision_shape)

## Connect signals
func _connect_signals() -> void:
	pass

## Initialize systems
func _initialize_systems() -> void:
	current_stamina = max_stamina
	current_movement_state = MovementState.IDLE
	current_stealth_state = StealthState.UNDETECTED

## Update animations based on current state
func _update_animations(delta: float) -> void:
	if not animation_player:
		return
	var animation_name = _get_animation_for_state()
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)

## Get animation name for current state
func _get_animation_for_state() -> String:
	match current_movement_state:
		MovementState.IDLE: return "idle"
		MovementState.WALKING: return "walk"
		MovementState.RUNNING: return "run"
		MovementState.CROUCHING: return "crouch_walk" if input_vector.length() > 0.1 else "crouch_idle"
		MovementState.CLIMBING: return "climb"
		MovementState.HIDING: return "hide"
		MovementState.INTERACTING: return "interact"
		_: return "idle"

## Convert movement state to string
func _movement_state_to_string(state: MovementState) -> String:
	match state:
		MovementState.IDLE: return "idle"
		MovementState.WALKING: return "walking"
		MovementState.RUNNING: return "running"
		MovementState.CROUCHING: return "crouching"
		MovementState.CLIMBING: return "climbing"
		MovementState.HIDING: return "hiding"
		MovementState.INTERACTING: return "interacting"
		_: return "unknown"

## Get total inventory items
func _get_total_inventory_items() -> int:
	var total = 0
	for category in inventory.values():
		total += category.size()
	return total

## Placeholder methods
func _scan_for_interactables() -> void: pass
func _update_interaction_target() -> void: pass
func _get_interaction_type(target: Node3D) -> String: return "generic"
func _examine_manuscript(target: Node3D) -> void: pass
func _examine_artifact(target: Node3D) -> void: pass
func _collect_scroll(target: Node3D) -> void: pass

#endregion
