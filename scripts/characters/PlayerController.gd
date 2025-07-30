extends CharacterBody3D

## Player Controller
## Handles player movement, camera, and interactions

@export var movement_speed: float = 5.0
@export var jump_velocity: float = 8.0
@export var mouse_sensitivity: float = 0.002
@export var camera_smoothing: float = 10.0

@onready var camera_controller = $CameraController
@onready var camera = $CameraController/Camera3D
@onready var interaction_ray = $CameraController/Camera3D/InteractionRay
@onready var interaction_prompt = $UI/InteractionPrompt

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_rotation: Vector2 = Vector2.ZERO
var current_interactable: Node = null

func _ready():
	_setup_player()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event.relative)

func _physics_process(delta):
	_handle_movement(delta)
	_handle_camera_smoothing(delta)
	_check_interactions()

func _handle_movement(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Get movement input
	var movement_vector = InputManager.get_movement_vector() if InputManager else Vector2.ZERO
	var direction = (transform.basis * Vector3(movement_vector.x, 0, movement_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed * delta * 3)
		velocity.z = move_toward(velocity.z, 0, movement_speed * delta * 3)
	
	move_and_slide()

func _handle_mouse_look(mouse_delta: Vector2):
	if InputManager:
		mouse_delta *= InputManager.mouse_sensitivity
	
	camera_rotation.x -= mouse_delta.y
	camera_rotation.y -= mouse_delta.x
	
	camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)

func _handle_camera_smoothing(delta):
	# Apply rotation to camera controller
	camera_controller.rotation.x = lerp(camera_controller.rotation.x, camera_rotation.x, camera_smoothing * delta)
	rotation.y = lerp(rotation.y, camera_rotation.y, camera_smoothing * delta)

func _check_interactions():
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		
		if collider and collider.has_method("can_interact") and collider.can_interact():
			if current_interactable != collider:
				_set_interactable(collider)
		else:
			_clear_interactable()
	else:
		_clear_interactable()
	
	# Handle interaction input
	if Input.is_action_just_pressed("interact") and current_interactable:
		current_interactable.interact(self)

func _set_interactable(interactable: Node):
	current_interactable = interactable
	
	# Show interaction prompt
	if interaction_prompt:
		var prompt_text = "INTERACTION_PROMPT"
		if interactable.has_method("get_interaction_text"):
			prompt_text = interactable.get_interaction_text()
		
		if LocalizationManager:
			interaction_prompt.text = LocalizationManager.get_text(prompt_text)
		else:
			interaction_prompt.text = prompt_text
		
		interaction_prompt.visible = true

func _clear_interactable():
	current_interactable = null
	if interaction_prompt:
		interaction_prompt.visible = false

func _setup_player():
	# Set up input capture
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Get save data for SaveManager
func get_save_data() -> Dictionary:
	return {
		"position": global_position,
		"rotation": rotation,
		"camera_rotation": camera_rotation
	}

## Load save data from SaveManager
func load_save_data(save_data: Dictionary):
	if save_data.has("position"):
		global_position = save_data["position"]
	if save_data.has("rotation"):
		rotation = save_data["rotation"]
	if save_data.has("camera_rotation"):
		camera_rotation = save_data["camera_rotation"]
