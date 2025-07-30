extends Node

## Localization Manager
## Handles multi-language support with CSV-based translation files
## Dynamic language switching and text formatting

signal language_changed(new_language: String)
signal translation_loaded(language: String)
signal translation_failed(language: String, error: String)

# Language management
var current_language: String = "en"
var available_languages: Array[String] = ["en", "es", "fr", "de", "pt"]
var fallback_language: String = "en"

# Translation data
var translations: Dictionary = {}
var language_names: Dictionary = {
	"en": "English",
	"es": "Español",
	"fr": "Français",
	"de": "Deutsch",
	"pt": "Português"
}

# File paths
var translation_csv_path: String = "res://localization/translations.csv"
var custom_translations_path: String = "user://custom_translations.json"

# Text formatting
var text_direction: String = "ltr"  # left-to-right or right-to-left
var date_format: String = "MM/DD/YYYY"
var number_format: String = "1,234.56"

func _ready():
	_load_translations()
	_set_initial_language()

## Get translated text for a key
func get_text(key: String, args: Array = []) -> String:
	var text = _get_translation(key)
	
	if args.size() > 0:
		text = _format_text(text, args)
	
	return text

## Get translated text with plural support
func get_plural_text(key: String, count: int, args: Array = []) -> String:
	var plural_key = key
	
	# Simple plural rules - extend for more complex languages
	if count != 1:
		plural_key = key + "_plural"
	
	var text = _get_translation(plural_key)
	if text == plural_key and count != 1:
		# Fallback to singular if plural not found
		text = _get_translation(key)
	
	# Replace count placeholder
	args.insert(0, count)
	text = _format_text(text, args)
	
	return text

## Set current language
func set_language(language_code: String) -> bool:
	if language_code == current_language:
		return true
	
	if not available_languages.has(language_code):
		push_warning("Language not available: " + language_code)
		return false
	
	var old_language = current_language
	current_language = language_code
	
	# Update Godot's locale
	TranslationServer.set_locale(language_code)
	
	# Update text direction and formatting
	_update_language_settings()
	
	# Refresh all UI text
	_refresh_ui_text()
	
	language_changed.emit(current_language)
	return true

## Get current language code
func get_current_language() -> String:
	return current_language

## Get current language display name
func get_current_language_name() -> String:
	return language_names.get(current_language, current_language)

## Get all available languages
func get_available_languages() -> Array[String]:
	return available_languages

## Get language display names
func get_language_names() -> Dictionary:
	return language_names

## Add custom translation
func add_translation(key: String, language: String, text: String) -> void:
	if not translations.has(language):
		translations[language] = {}
	
	translations[language][key] = text

## Load custom translations from file
func load_custom_translations() -> bool:
	var file = FileAccess.open(custom_translations_path, FileAccess.READ)
	if not file:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return false
	
	var custom_data = json.data
	for language in custom_data.keys():
		if not translations.has(language):
			translations[language] = {}
		
		translations[language].merge(custom_data[language])
	
	return true

## Save custom translations to file
func save_custom_translations(custom_data: Dictionary) -> bool:
	var file = FileAccess.open(custom_translations_path, FileAccess.WRITE)
	if not file:
		return false
	
	var json_string = JSON.stringify(custom_data, "\t")
	file.store_string(json_string)
	file.close()
	
	return true

## Format date according to current locale
func format_date(datetime: Dictionary) -> String:
	match current_language:
		"en":
			return "%02d/%02d/%04d" % [datetime.month, datetime.day, datetime.year]
		"de", "fr":
			return "%02d.%02d.%04d" % [datetime.day, datetime.month, datetime.year]
		"es", "pt":
			return "%02d/%02d/%04d" % [datetime.day, datetime.month, datetime.year]
		_:
			return "%04d-%02d-%02d" % [datetime.year, datetime.month, datetime.day]

## Format number according to current locale
func format_number(number: float, decimals: int = 2) -> String:
	var formatted = "%.{0}f".format([decimals]) % number
	
	match current_language:
		"de", "fr":
			# Use comma for decimal separator and space for thousands
			formatted = formatted.replace(".", ",")
			return _add_thousands_separator(formatted, " ")
		"es", "pt":
			# Use comma for decimal separator and period for thousands
			formatted = formatted.replace(".", ",")
			return _add_thousands_separator(formatted, ".")
		_:
			# English format: period for decimal, comma for thousands
			return _add_thousands_separator(formatted, ",")

## Get text direction for current language
func get_text_direction() -> String:
	return text_direction

## Check if language is right-to-left
func is_rtl() -> bool:
	return text_direction == "rtl"

# Private methods

func _load_translations() -> void:
	# Load from CSV file
	var file = FileAccess.open(translation_csv_path, FileAccess.READ)
	if not file:
		push_error("Could not load translation file: " + translation_csv_path)
		return
	
	var csv_text = file.get_as_text()
	file.close()
	
	_parse_csv_translations(csv_text)
	
	# Load custom translations
	load_custom_translations()

func _parse_csv_translations(csv_text: String) -> void:
	var lines = csv_text.split("\n")
	if lines.size() < 2:
		return
	
	# Parse header to get language columns
	var header = lines[0].split(",")
	var language_columns = {}
	
	for i in range(1, header.size()):
		var lang_code = header[i].strip_edges()
		language_columns[i] = lang_code
		if not translations.has(lang_code):
			translations[lang_code] = {}
	
	# Parse translation rows
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			continue
		
		var columns = line.split(",")
		if columns.size() < 2:
			continue
		
		var key = columns[0].strip_edges()
		
		for col_index in language_columns.keys():
			if col_index < columns.size():
				var lang_code = language_columns[col_index]
				var text = columns[col_index].strip_edges()
				
				# Remove quotes if present
				if text.begins_with('"') and text.ends_with('"'):
					text = text.substr(1, text.length() - 2)
				
				translations[lang_code][key] = text

func _set_initial_language() -> void:
	# Try to get language from config
	var saved_language = "en"
	if ConfigManager:
		saved_language = ConfigManager.get_setting("game", "language", "en")
	
	# Try to detect system language
	if saved_language == "en":
		var system_locale = OS.get_locale()
		var system_language = system_locale.substr(0, 2)
		
		if available_languages.has(system_language):
			saved_language = system_language
	
	set_language(saved_language)

func _get_translation(key: String) -> String:
	if translations.has(current_language) and translations[current_language].has(key):
		return translations[current_language][key]
	
	# Fallback to fallback language
	if current_language != fallback_language and translations.has(fallback_language):
		if translations[fallback_language].has(key):
			return translations[fallback_language][key]
	
	# Return key if no translation found
	return key

func _format_text(text: String, args: Array) -> String:
	var formatted_text = text
	
	for i in range(args.size()):
		var placeholder = "{" + str(i) + "}"
		formatted_text = formatted_text.replace(placeholder, str(args[i]))
	
	return formatted_text

func _update_language_settings() -> void:
	match current_language:
		"ar", "he", "fa":
			text_direction = "rtl"
		_:
			text_direction = "ltr"

func _refresh_ui_text() -> void:
	# Find all nodes with translatable text and update them
	_refresh_node_text(get_tree().root)

func _refresh_node_text(node: Node) -> void:
	# Update Label nodes
	if node is Label:
		var label = node as Label
		var text = label.text
		if text.begins_with("TR_") or translations.has(current_language) and translations[current_language].has(text):
			label.text = get_text(text)
	
	# Update Button nodes
	elif node is Button:
		var button = node as Button
		var text = button.text
		if text.begins_with("TR_") or translations.has(current_language) and translations[current_language].has(text):
			button.text = get_text(text)
	
	# Update RichTextLabel nodes
	elif node is RichTextLabel:
		var rich_label = node as RichTextLabel
		var text = rich_label.text
		if text.begins_with("TR_") or translations.has(current_language) and translations[current_language].has(text):
			rich_label.text = get_text(text)
	
	# Recursively update children
	for child in node.get_children():
		_refresh_node_text(child)

func _add_thousands_separator(number_string: String, separator: String) -> String:
	var parts = number_string.split(".")
	var integer_part = parts[0]
	var decimal_part = parts[1] if parts.size() > 1 else ""
	
	# Add thousands separator to integer part
	var formatted_integer = ""
	var count = 0
	
	for i in range(integer_part.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted_integer = separator + formatted_integer
		formatted_integer = integer_part[i] + formatted_integer
		count += 1
	
	if decimal_part.is_empty():
		return formatted_integer
	else:
		return formatted_integer + "." + decimal_part
