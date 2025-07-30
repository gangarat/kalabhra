extends Node

## CharacterManager - Educational Character System
##
## Manages character loading, animation, interaction, and educational dialogue
## for the Light of the Kalabhra educational experience. Supports the uploaded
## character assets: Babak1, Bundos, Guard, and Pushtigan 2.
##
## Key Features:
## - Dynamic character loading and instantiation
## - Educational dialogue and interaction system
## - Character animation and state management
## - Accessibility features for character interactions
## - Performance optimization for multiple characters
##
## Usage Example:
## ```gdscript
## # Spawn an educational guide character
## var babak = CharacterManager.spawn_character("babak1", {
##     "position": Vector3(0, 0, 5),
##     "role": "guide",
##     "dialogue_set": "ancient_architecture_intro"
## })
## 
## # Start character interaction
## CharacterManager.start_character_interaction("babak1", "welcome_lesson")
## ```

# Character system signals
signal character_spawned(character_id: String, character_type: String)
signal character_removed(character_id: String)
signal character_interaction_started(character_id: String, interaction_type: String)
signal character_interaction_ended(character_id: String)
signal character_dialogue_started(character_id: String, dialogue_id: String)
signal character_dialogue_ended(character_id: String, dialogue_id: String)

# Animation and movement signals
signal character_animation_changed(character_id: String, animation_name: String)
signal character_moved(character_id: String, new_position: Vector3)
signal character_state_changed(character_id: String, old_state: String, new_state: String)

## Character types based on uploaded assets
enum CharacterType {
	BABAK1,      # Educational guide character
	BUNDOS,      # Interactive companion
	GUARD,       # Authority/security character
	PUSHTIGAN2   # Cultural expert character
}

## Character states
enum CharacterState {
	IDLE,
	TALKING,
	WALKING,
	INTERACTING,
	TEACHING,
	LISTENING
}

## Interaction types
enum InteractionType {
	DIALOGUE,
	TEACHING,
	QUESTIONING,
	GUIDANCE,
	CULTURAL_INFO
}

# Character management
var active_characters: Dictionary = {}
var character_templates: Dictionary = {}
var character_dialogue_data: Dictionary = {}
var character_animations: Dictionary = {}

# Educational integration
var current_interactions: Dictionary = {}
var dialogue_queue: Array[Dictionary] = []
var educational_context: String = ""

# Performance and optimization
var max_active_characters: int = 4
var character_lod_enabled: bool = true
var interaction_distance: float = 5.0

# Asset paths for uploaded characters
var character_assets: Dictionary = {
	"babak1": "res://assets/models/characters/Babak1.glb",
	"bundos": "res://assets/models/characters/Bundos.glb", 
	"guard": "res://assets/models/characters/Guard.glb",
	"pushtigan2": "res://assets/models/characters/Pushtigan 2.glb"
}

func _ready():
	_initialize_character_system()
	_load_character_templates()
	_setup_dialogue_system()

#region Character Management

## Spawn a character in the scene
## @param character_type: Type of character to spawn
## @param config: Configuration for character spawning
## @return: Character ID if successful, empty string if failed
func spawn_character(character_type: String, config: Dictionary = {}) -> String:
	if active_characters.size() >= max_active_characters:
		push_warning("[CharacterManager] Maximum active characters reached")
		return ""
	
	if not character_assets.has(character_type):
		push_error("[CharacterManager] Unknown character type: " + character_type)
		return ""
	
	var character_id = _generate_character_id(character_type)
	var character_node = await _load_character_model(character_type)
	
	if not character_node:
		push_error("[CharacterManager] Failed to load character: " + character_type)
		return ""
	
	# Configure character
	_setup_character_node(character_node, character_id, config)
	
	# Add to scene
	var spawn_position = config.get("position", Vector3.ZERO)
	character_node.global_position = spawn_position
	get_tree().current_scene.add_child(character_node)
	
	# Track character
	active_characters[character_id] = {
		"node": character_node,
		"type": character_type,
		"state": CharacterState.IDLE,
		"config": config,
		"spawn_time": Time.get_unix_time_from_system(),
		"interactions_count": 0
	}
	
	character_spawned.emit(character_id, character_type)
	return character_id

## Remove a character from the scene
## @param character_id: ID of character to remove
func remove_character(character_id: String) -> void:
	if not active_characters.has(character_id):
		return
	
	var character_data = active_characters[character_id]
	var character_node = character_data["node"]
	
	# End any active interactions
	if current_interactions.has(character_id):
		end_character_interaction(character_id)
	
	# Remove from scene
	if is_instance_valid(character_node):
		character_node.queue_free()
	
	# Clean up tracking
	active_characters.erase(character_id)
	character_removed.emit(character_id)

## Get character node by ID
## @param character_id: Character to get
## @return: Character node or null if not found
func get_character(character_id: String) -> Node3D:
	if active_characters.has(character_id):
		return active_characters[character_id]["node"]
	return null

## Set character state
## @param character_id: Character to update
## @param new_state: New state for the character
func set_character_state(character_id: String, new_state: CharacterState) -> void:
	if not active_characters.has(character_id):
		return
	
	var character_data = active_characters[character_id]
	var old_state = character_data["state"]
	
	if old_state != new_state:
		character_data["state"] = new_state
		_handle_state_change(character_id, old_state, new_state)
		character_state_changed.emit(character_id, _state_to_string(old_state), _state_to_string(new_state))

## Move character to position
## @param character_id: Character to move
## @param target_position: Target position
## @param duration: Movement duration in seconds
func move_character(character_id: String, target_position: Vector3, duration: float = 2.0) -> void:
	var character_node = get_character(character_id)
	if not character_node:
		return
	
	set_character_state(character_id, CharacterState.WALKING)
	
	# Create movement tween
	var tween = create_tween()
	tween.tween_property(character_node, "global_position", target_position, duration)
	tween.tween_callback(func(): set_character_state(character_id, CharacterState.IDLE))
	
	character_moved.emit(character_id, target_position)

#endregion

#region Educational Interactions

## Start an educational interaction with a character
## @param character_id: Character to interact with
## @param interaction_type: Type of interaction
## @param context: Educational context data
func start_character_interaction(character_id: String, interaction_type: String, context: Dictionary = {}) -> bool:
	if not active_characters.has(character_id):
		return false
	
	if current_interactions.has(character_id):
		end_character_interaction(character_id)
	
	# Set up interaction
	var interaction_data = {
		"type": interaction_type,
		"context": context,
		"start_time": Time.get_unix_time_from_system(),
		"dialogue_queue": [],
		"current_dialogue": ""
	}
	
	current_interactions[character_id] = interaction_data
	set_character_state(character_id, CharacterState.INTERACTING)
	
	# Load interaction content
	_load_interaction_content(character_id, interaction_type, context)
	
	character_interaction_started.emit(character_id, interaction_type)
	return true

## End character interaction
## @param character_id: Character to stop interacting with
func end_character_interaction(character_id: String) -> void:
	if not current_interactions.has(character_id):
		return
	
	var interaction_data = current_interactions[character_id]
	
	# Stop any active dialogue
	if not interaction_data["current_dialogue"].is_empty():
		_stop_dialogue(character_id)
	
	# Clean up interaction
	current_interactions.erase(character_id)
	set_character_state(character_id, CharacterState.IDLE)
	
	character_interaction_ended.emit(character_id)

## Start character dialogue
## @param character_id: Character to speak
## @param dialogue_id: Dialogue content identifier
## @param auto_advance: Whether to auto-advance dialogue
func start_character_dialogue(character_id: String, dialogue_id: String, auto_advance: bool = false) -> void:
	if not active_characters.has(character_id):
		return
	
	var dialogue_content = _get_dialogue_content(dialogue_id)
	if dialogue_content.is_empty():
		push_warning("[CharacterManager] Dialogue content not found: " + dialogue_id)
		return
	
	set_character_state(character_id, CharacterState.TALKING)
	
	# Update interaction data
	if current_interactions.has(character_id):
		current_interactions[character_id]["current_dialogue"] = dialogue_id
	
	# Start dialogue display
	_display_dialogue(character_id, dialogue_content, auto_advance)
	
	character_dialogue_started.emit(character_id, dialogue_id)

## Advance to next dialogue line
## @param character_id: Character whose dialogue to advance
func advance_dialogue(character_id: String) -> void:
	if not current_interactions.has(character_id):
		return
	
	var interaction_data = current_interactions[character_id]
	var dialogue_queue = interaction_data["dialogue_queue"]
	
	if dialogue_queue.size() > 0:
		var next_line = dialogue_queue.pop_front()
		_display_dialogue_line(character_id, next_line)
	else:
		# End dialogue
		_end_dialogue(character_id)

## Get all active characters
## @return: Dictionary of active character data
func get_active_characters() -> Dictionary:
	return active_characters.duplicate()

## Get characters within interaction distance of a position
## @param position: Position to check from
## @return: Array of character IDs within range
func get_nearby_characters(position: Vector3) -> Array[String]:
	var nearby = []
	
	for character_id in active_characters.keys():
		var character_node = get_character(character_id)
		if character_node:
			var distance = position.distance_to(character_node.global_position)
			if distance <= interaction_distance:
				nearby.append(character_id)
	
	return nearby

#endregion
