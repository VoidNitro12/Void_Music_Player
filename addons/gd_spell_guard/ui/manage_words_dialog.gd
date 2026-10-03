@tool
extends AcceptDialog

signal remove_ignored_word_requested(word: String)
signal add_ignored_word_requested(word: String)
signal settings_apply_requested(locale: String, ignore_short_words: bool)

const DICTIONARY_LOCALES := ["en_GB", "en_US"]
const DICTIONARY_LABELS := ["English (UK) - en_GB", "English (US) - en_US"]

var _tabs: TabContainer
var _ignored_list: ItemList
var _ignored_word_input: LineEdit
var _add_button: Button
var _remove_button: Button
var _dictionary_option: OptionButton
var _ignore_short_words_check: CheckBox
var _settings_apply_button: Button
var _active_locale := "en_GB"
var _active_ignore_short_words := true


func _ready() -> void:
	title = "GDSpellGuard Settings"
	min_size = Vector2i(720, 580)
	ok_button_text = "Close"
	var root := VBoxContainer.new()
	add_child(root)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)
	_create_ignored_words_tab()
	_create_settings_tab()


func set_state(ignored_words: PackedStringArray, active_locale: String, ignore_short_words: bool) -> void:
	if _ignored_list == null:
		return
	_ignored_list.clear()
	for word in ignored_words:
		_ignored_list.add_item(word)
	_active_locale = active_locale
	_active_ignore_short_words = ignore_short_words
	for index in range(_dictionary_option.item_count):
		if _dictionary_option.get_item_metadata(index) == active_locale:
			_dictionary_option.select(index)
			break
	_ignore_short_words_check.button_pressed = ignore_short_words
	_update_remove_state()
	_update_settings_apply_state()


func _create_ignored_words_tab() -> void:
	var tab := VBoxContainer.new()
	tab.name = "Ignored Words"
	_tabs.add_child(tab)
	var description := Label.new()
	description.text = (
		"Words listed here are skipped during spelling checks.\n"
		+ "GDSpellGuard creates res://gd_spell_guard/ignored_words.txt after you add the first word."
	)
	tab.add_child(description)
	_ignored_list = ItemList.new()
	_ignored_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ignored_list.item_selected.connect(func(_index): _update_remove_state())
	tab.add_child(_ignored_list)
	var add_row := HBoxContainer.new()
	_ignored_word_input = LineEdit.new()
	_ignored_word_input.placeholder_text = "Word to ignore"
	_ignored_word_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ignored_word_input.text_changed.connect(func(_text): _update_add_state())
	_ignored_word_input.text_submitted.connect(func(_text): _on_add_pressed())
	add_row.add_child(_ignored_word_input)
	_add_button = Button.new()
	_add_button.text = "Add Word"
	_add_button.disabled = true
	_add_button.pressed.connect(_on_add_pressed)
	add_row.add_child(_add_button)
	tab.add_child(add_row)
	_remove_button = Button.new()
	_remove_button.text = "Remove Selected Word"
	_remove_button.disabled = true
	_remove_button.pressed.connect(_on_remove_pressed)
	tab.add_child(_remove_button)


func _create_settings_tab() -> void:
	var tab := VBoxContainer.new()
	tab.name = "Settings"
	_tabs.add_child(tab)
	var dictionary_label := Label.new()
	dictionary_label.text = "Dictionary"
	tab.add_child(dictionary_label)
	_dictionary_option = OptionButton.new()
	for index in range(DICTIONARY_LOCALES.size()):
		_dictionary_option.add_item(DICTIONARY_LABELS[index])
		_dictionary_option.set_item_metadata(index, DICTIONARY_LOCALES[index])
	_dictionary_option.item_selected.connect(func(_index): _update_settings_apply_state())
	tab.add_child(_dictionary_option)
	var separator := HSeparator.new()
	tab.add_child(separator)
	_ignore_short_words_check = CheckBox.new()
	_ignore_short_words_check.text = "Ignore unknown words with 3 letters or fewer"
	_ignore_short_words_check.tooltip_text = "Unknown words with 3 letters or fewer will not be reported."
	_ignore_short_words_check.toggled.connect(func(_enabled): _update_settings_apply_state())
	tab.add_child(_ignore_short_words_check)
	_settings_apply_button = Button.new()
	_settings_apply_button.text = "Apply"
	_settings_apply_button.disabled = true
	_settings_apply_button.pressed.connect(_on_settings_apply_pressed)
	tab.add_child(_settings_apply_button)


func _update_remove_state() -> void:
	if _remove_button != null:
		_remove_button.disabled = _ignored_list.get_selected_items().is_empty()


func _update_add_state() -> void:
	if _add_button != null:
		_add_button.disabled = _ignored_word_input.text.strip_edges().is_empty()


func _update_settings_apply_state() -> void:
	if _settings_apply_button == null:
		return
	_settings_apply_button.disabled = (
		_selected_locale() == _active_locale
		and _ignore_short_words_check.button_pressed == _active_ignore_short_words
	)


func _selected_locale() -> String:
	if _dictionary_option == null or _dictionary_option.selected < 0:
		return ""
	return _dictionary_option.get_item_metadata(_dictionary_option.selected)


func _on_remove_pressed() -> void:
	var selected := _ignored_list.get_selected_items()
	if selected.is_empty():
		return
	remove_ignored_word_requested.emit(_ignored_list.get_item_text(selected[0]))


func _on_add_pressed() -> void:
	var word := _ignored_word_input.text.strip_edges()
	if word.is_empty():
		return
	add_ignored_word_requested.emit(word)
	_ignored_word_input.clear()
	_update_add_state()


func _on_settings_apply_pressed() -> void:
	var locale := _selected_locale()
	if locale.is_empty() or _settings_apply_button.disabled:
		return
	settings_apply_requested.emit(locale, _ignore_short_words_check.button_pressed)
