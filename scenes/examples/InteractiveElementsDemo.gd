extends Node3D

## InteractiveElementsDemo - Demonstration Scene for Interactive Environmental Elements
##
## This scene demonstrates the comprehensive Interactive Environmental Elements system
## with examples of manuscripts, artifacts, architectural features, and cultural objects
## that provide educational content and support gameplay mechanics.

# Demo element IDs for tracking
var demo_manuscript_id: String
var demo_artifact_id: String
var demo_architectural_id: String
var demo_cultural_object_id: String

# Player interaction tracking
var current_player_id: String = "demo_player"
var active_interaction_session: String = ""

func _ready():
	_setup_demo_scene()
	_create_demo_elements()
	_setup_demo_ui()
	_connect_signals()

## Setup the demo scene environment
func _setup_demo_scene() -> void:
	print("[InteractiveElementsDemo] Setting up demonstration scene...")
	
	# Create basic lighting
	var light = DirectionalLight3D.new()
	light.position = Vector3(0, 10, 5)
	light.rotation_degrees = Vector3(-45, 0, 0)
	add_child(light)
	
	# Create ground plane
	var ground = StaticBody3D.new()
	var ground_mesh = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(20, 20)
	ground_mesh.mesh = plane_mesh
	ground.add_child(ground_mesh)
	
	var ground_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(20, 0.1, 20)
	ground_collision.shape = box_shape
	ground.add_child(ground_collision)
	add_child(ground)

## Create demonstration interactive elements
func _create_demo_elements() -> void:
	print("[InteractiveElementsDemo] Creating interactive elements...")
	
	# Create manuscript element
	demo_manuscript_id = InteractiveElements.create_manuscript_element({
		"position": Vector3(2, 1, 0),
		"manuscript_type": "prayer_scroll",
		"language": "middle_persian",
		"script": "manichaean",
		"educational_level": "intermediate",
		"cultural_context": "manichaean_daily_practice",
		"preservation_state": "good"
	})
	
	if not demo_manuscript_id.is_empty():
		print("[InteractiveElementsDemo] Created manuscript element: ", demo_manuscript_id)
	
	# Create artifact element
	demo_artifact_id = InteractiveElements.create_artifact_element({
		"position": Vector3(-2, 1, 0),
		"artifact_type": "ceremonial_lamp",
		"material": "bronze",
		"time_period": "sassanid_era",
		"cultural_origin": "persian",
		"religious_significance": "manichaean_light_symbolism",
		"preservation_state": "intact"
	})
	
	if not demo_artifact_id.is_empty():
		print("[InteractiveElementsDemo] Created artifact element: ", demo_artifact_id)
	
	# Create architectural feature
	demo_architectural_id = InteractiveElements.create_architectural_element({
		"position": Vector3(0, 0, -3),
		"feature_type": "persian_arch",
		"architectural_style": "sassanid",
		"construction_period": "6th_century",
		"construction_technique": "stone_masonry",
		"symbolic_meaning": "divine_ascension",
		"functional_purpose": "structural_support"
	})
	
	if not demo_architectural_id.is_empty():
		print("[InteractiveElementsDemo] Created architectural element: ", demo_architectural_id)
	
	# Create cultural object
	demo_cultural_object_id = InteractiveElements.create_cultural_object_element({
		"position": Vector3(0, 1, 2),
		"object_type": "prayer_beads",
		"cultural_function": "meditation_aid",
		"social_context": "personal_devotion",
		"symbolic_meaning": "spiritual_focus",
		"usage_instructions": "traditional_counting_method"
	})
	
	if not demo_cultural_object_id.is_empty():
		print("[InteractiveElementsDemo] Created cultural object element: ", demo_cultural_object_id)

## Setup demonstration UI
func _setup_demo_ui() -> void:
	print("[InteractiveElementsDemo] Setting up demonstration UI...")
	
	# Create UI overlay for instructions
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	var instruction_panel = Panel.new()
	instruction_panel.size = Vector2(400, 300)
	instruction_panel.position = Vector2(20, 20)
	ui_layer.add_child(instruction_panel)
	
	var instruction_label = RichTextLabel.new()
	instruction_label.size = Vector2(380, 280)
	instruction_label.position = Vector2(10, 10)
	instruction_label.bbcode_enabled = true
	instruction_label.text = """[b]Interactive Elements Demo[/b]

[color=yellow]Available Elements:[/color]
• [color=cyan]Manuscript[/color] (Right) - Prayer scroll with Manichaean text
• [color=green]Artifact[/color] (Left) - Ceremonial bronze lamp
• [color=orange]Architecture[/color] (Back) - Persian arch with symbolism
• [color=purple]Cultural Object[/color] (Front) - Prayer beads for meditation

[color=yellow]Interaction Instructions:[/color]
• Press [color=white]E[/color] near elements to interact
• Use [color=white]1-8[/color] to reveal different content levels
• Press [color=white]C[/color] for comparative analysis
• Press [color=white]ESC[/color] to exit interactions

[color=yellow]Content Levels:[/color]
1. Surface Observation
2. Basic Information
3. Detailed Description
4. Cultural Context
5. Historical Significance
6. Scholarly Analysis
7. Expert Interpretation
8. Comparative Insights"""
	
	instruction_panel.add_child(instruction_label)

## Connect system signals for demonstration
func _connect_signals() -> void:
	# Connect InteractiveElements signals
	InteractiveElements.element_created.connect(_on_element_created)
	InteractiveElements.interaction_started.connect(_on_interaction_started)
	InteractiveElements.interaction_completed.connect(_on_interaction_completed)
	InteractiveElements.content_revealed.connect(_on_content_revealed)
	InteractiveElements.cultural_context_discovered.connect(_on_cultural_context_discovered)
	InteractiveElements.learning_objective_achieved.connect(_on_learning_objective_achieved)

## Handle input for demonstration
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E:
				_try_interact_with_nearest_element()
			KEY_1:
				_reveal_content_level(InteractiveElements.ContentLevel.SURFACE_OBSERVATION)
			KEY_2:
				_reveal_content_level(InteractiveElements.ContentLevel.BASIC_INFORMATION)
			KEY_3:
				_reveal_content_level(InteractiveElements.ContentLevel.DETAILED_DESCRIPTION)
			KEY_4:
				_reveal_content_level(InteractiveElements.ContentLevel.CULTURAL_CONTEXT)
			KEY_5:
				_reveal_content_level(InteractiveElements.ContentLevel.HISTORICAL_SIGNIFICANCE)
			KEY_6:
				_reveal_content_level(InteractiveElements.ContentLevel.SCHOLARLY_ANALYSIS)
			KEY_7:
				_reveal_content_level(InteractiveElements.ContentLevel.EXPERT_INTERPRETATION)
			KEY_8:
				_reveal_content_level(InteractiveElements.ContentLevel.COMPARATIVE_INSIGHTS)
			KEY_C:
				_conduct_comparative_analysis()
			KEY_ESCAPE:
				_exit_current_interaction()

## Try to interact with the nearest element
func _try_interact_with_nearest_element() -> void:
	var player_position = Vector3.ZERO  # In a real game, this would be the player's position
	var nearest_element_id = _find_nearest_element(player_position)
	
	if not nearest_element_id.is_empty():
		var success = InteractiveElements.start_element_interaction(
			nearest_element_id,
			current_player_id,
			InteractiveElements.InteractionMode.EDUCATIONAL_STUDY
		)
		
		if success:
			print("[InteractiveElementsDemo] Started interaction with element: ", nearest_element_id)
		else:
			print("[InteractiveElementsDemo] Failed to start interaction with element: ", nearest_element_id)

## Find the nearest interactive element
func _find_nearest_element(player_position: Vector3) -> String:
	var element_ids = [demo_manuscript_id, demo_artifact_id, demo_architectural_id, demo_cultural_object_id]
	var nearest_id = ""
	var nearest_distance = INF
	
	for element_id in element_ids:
		if element_id.is_empty():
			continue
		
		# In a real implementation, you would get the actual element position
		# For demo purposes, we'll just return the first valid element
		if nearest_id.is_empty():
			nearest_id = element_id
	
	return nearest_id

## Reveal content level in current interaction
func _reveal_content_level(content_level: InteractiveElements.ContentLevel) -> void:
	if active_interaction_session.is_empty():
		print("[InteractiveElementsDemo] No active interaction session")
		return
	
	InteractiveElements.reveal_content_level(active_interaction_session, content_level)
	print("[InteractiveElementsDemo] Revealed content level: ", content_level)

## Conduct comparative analysis of all elements
func _conduct_comparative_analysis() -> void:
	var element_ids = [demo_manuscript_id, demo_artifact_id, demo_architectural_id, demo_cultural_object_id]
	var valid_ids = []
	
	for element_id in element_ids:
		if not element_id.is_empty():
			valid_ids.append(element_id)
	
	if valid_ids.size() >= 2:
		var analysis_results = InteractiveElements.conduct_comparative_analysis(
			valid_ids,
			"cultural_significance",
			current_player_id
		)
		
		print("[InteractiveElementsDemo] Comparative analysis results: ", analysis_results)
	else:
		print("[InteractiveElementsDemo] Need at least 2 elements for comparative analysis")

## Exit current interaction
func _exit_current_interaction() -> void:
	if not active_interaction_session.is_empty():
		var learning_data = InteractiveElements.complete_interaction(active_interaction_session)
		print("[InteractiveElementsDemo] Completed interaction with learning data: ", learning_data)
		active_interaction_session = ""

#region Signal Handlers

func _on_element_created(element_id: String, element_type: String, position: Vector3) -> void:
	print("[InteractiveElementsDemo] Element created - ID: %s, Type: %s, Position: %s" % [element_id, element_type, position])

func _on_interaction_started(element_id: String, player_id: String, interaction_type: String) -> void:
	print("[InteractiveElementsDemo] Interaction started - Element: %s, Player: %s, Type: %s" % [element_id, player_id, interaction_type])
	active_interaction_session = element_id + "_" + player_id + "_session_" + str(Time.get_unix_time_from_system())

func _on_interaction_completed(element_id: String, player_id: String, learning_data: Dictionary) -> void:
	print("[InteractiveElementsDemo] Interaction completed - Element: %s, Player: %s" % [element_id, player_id])
	print("[InteractiveElementsDemo] Learning data: ", learning_data)
	active_interaction_session = ""

func _on_content_revealed(element_id: String, content_layer: String, educational_value: Dictionary) -> void:
	print("[InteractiveElementsDemo] Content revealed - Element: %s, Layer: %s" % [element_id, content_layer])
	print("[InteractiveElementsDemo] Educational value: ", educational_value)

func _on_cultural_context_discovered(element_id: String, context_type: String, cultural_significance: Dictionary) -> void:
	print("[InteractiveElementsDemo] Cultural context discovered - Element: %s, Type: %s" % [element_id, context_type])
	print("[InteractiveElementsDemo] Cultural significance: ", cultural_significance)

func _on_learning_objective_achieved(element_id: String, objective: String, assessment_data: Dictionary) -> void:
	print("[InteractiveElementsDemo] Learning objective achieved - Element: %s, Objective: %s" % [element_id, objective])
	print("[InteractiveElementsDemo] Assessment data: ", assessment_data)

#endregion
