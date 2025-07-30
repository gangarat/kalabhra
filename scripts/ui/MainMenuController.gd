extends Control

## Main Menu Controller
## Handles main menu interactions and navigation

@onready var start_button = $VBoxContainer/StartButton
@onready var continue_button = $VBoxContainer/ContinueButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var credits_button = $VBoxContainer/CreditsButton
@onready var exit_button = $VBoxContainer/ExitButton

func _ready():
	_setup_menu()
	_update_continue_button()

func _setup_menu():
	# Update text with localized versions
	if LocalizationManager:
		$VBoxContainer/Title.text = LocalizationManager.get_text("LIGHT_OF_KALABHRA_TITLE")
		$VBoxContainer/Subtitle.text = LocalizationManager.get_text("EDUCATIONAL_ADVENTURE_SUBTITLE")
		start_button.text = LocalizationManager.get_text("START_GAME_BUTTON")
		continue_button.text = LocalizationManager.get_text("CONTINUE_BUTTON")
		settings_button.text = LocalizationManager.get_text("SETTINGS_BUTTON")
		credits_button.text = LocalizationManager.get_text("CREDITS_BUTTON")
		exit_button.text = LocalizationManager.get_text("EXIT_BUTTON")

func _update_continue_button():
	# Enable continue button only if save data exists
	if SaveManager:
		continue_button.disabled = not SaveManager.has_save_data(0)

func _on_start_button_pressed():
	if GameManager:
		GameManager.start_new_game()

func _on_continue_button_pressed():
	if GameManager:
		GameManager.continue_game()

func _on_settings_button_pressed():
	# Load settings scene
	SceneManager.change_scene_by_key("settings")

func _on_credits_button_pressed():
	# Load credits scene
	SceneManager.change_scene_by_key("credits")

func _on_exit_button_pressed():
	# On web, this won't actually quit, but we can hide the game
	if OS.has_feature("web"):
		# Could show a "thanks for playing" message
		pass
	else:
		get_tree().quit()
