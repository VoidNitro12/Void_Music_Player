class_name ThemeManager
extends RefCounted

enum Accents {
	GREEN,
	PURPLE,
	BLUE,
	ORANGE,
}

const ACCENT_COLOURS: Dictionary[Accents, Color] = {
	Accents.GREEN: Color("a0d900ff"),
	Accents.PURPLE: Color("#6a1b9a"),
	Accents.BLUE: Color("#0058ef"),
	Accents.ORANGE: Color("#ea6019ff"),
}

var _accent_lighten_ratio: float = 0.2

var _accent_darken_ratio: float = 0.2

## The currently used accent by the player
var current_accent: Accents = Accents.GREEN

var _light_theme: Theme

var _dark_theme: Theme

## Loads the base light and dark themes from disk
func set_up() -> void:
	_light_theme = load("res://assets/light_mode_theme.tres")
	_dark_theme = load("res://assets/dark_mode_theme.tres")

## returns the current in memory theme specified by [param mode]
func get_theme(theme: AppTool.AppThemes) -> Theme:
	if _dark_theme == null or _light_theme == null:
		AppEvents.data.log_error.emit(ErrorLogger.LogLevel.WARN, "ThemeManager was not set up")
		return

	match theme:
		AppTool.AppThemes.LIGHT:
			return _light_theme
		AppTool.AppThemes.DARK:
			return _dark_theme
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid theme mode int of %d" % theme,
			)
			return

## Sets the lighten ratio for the current accent, clamped from 0.0 to 1.0. [param save_value]
## dictates if this change should be immediately saved to disk
func set_accent_lighten_ratio(amount: float, save_value: bool = true) -> void:
	amount = clamp(amount, 0.0, 1.0)
	_accent_lighten_ratio = amount
	change_accent(current_accent, true)
	# The user facing setting for this uses a debouncing timer so this isnt as expensive
	# as it looks (when not changed directly that is)
	if save_value:
		AppEvents.data.save_app_data.emit()
	

## Sets the darken ratio for the current accent, clamped from 0.0 to 1.0. [param save_value]
## dictates if this change should be immediately saved to disk
func set_accent_darken_ratio(amount: float, save_value: bool = true) -> void: 
	amount = clamp(amount, 0.0, 1.0)
	_accent_darken_ratio = amount
	change_accent(current_accent, true)
	if save_value:
		AppEvents.data.save_app_data.emit()

## Returns a [PackedFloat64Array] containing both the current lighten and darken ratio
## of the accents. The first item in the array is the lighten ratio and the second is the
## darken ratio.[br]
## see [member set_accent_darken_ratio] and [member set_accent_lighthen_ratio] to set the values
func get_accent_ratios() -> PackedFloat64Array: 
	return PackedFloat64Array([_accent_lighten_ratio,_accent_darken_ratio])

func change_accent(to: Accents, reshade: bool = false) -> void:
	if to == current_accent and not reshade:
		return

	var base_colour: Color = ACCENT_COLOURS[to]
	var highlight_colour: Color = base_colour.lightened(_accent_lighten_ratio)
	var selected_colour: Color = base_colour.darkened(_accent_darken_ratio)

	var colours: Dictionary[String, Color] = {
		"base": base_colour,
		"highlight": highlight_colour,
		"selected": selected_colour,
	}

	for i: Theme in [_dark_theme, _light_theme]:
		_edit_btn(i, colours)
		_edit_hslider(i, colours)
		_edit_line_edit(i, colours)
		_edit_link_btn(i, colours)
		_edit_popup_menu(i, colours)
		_edit_text_edit(i, colours)
		_edit_v_scrollbar(i, colours)
		_edit_window(i, colours)

	current_accent = to
	AppEvents.data.save_app_data.emit()


func _edit_btn(base_theme: Theme, colours: Dictionary[String, Color]) -> void:
	var hover: StyleBoxFlat = base_theme.get_stylebox("hover", &"Button")
	hover.border_color = colours["highlight"]

	var hover_pressed: StyleBoxFlat = base_theme.get_stylebox("hover_pressed", &"Button")
	hover_pressed.border_color = colours["highlight"]
	hover_pressed.bg_color = colours["base"]

	var pressed: StyleBoxFlat = base_theme.get_stylebox("pressed", &"Button")
	pressed.bg_color = colours["selected"]


func _edit_hslider(base_theme: Theme, colours: Dictionary[String, Color]) -> void:
	var grabber_area: StyleBoxFlat = base_theme.get_stylebox("grabber_area", &"HSlider")
	grabber_area.bg_color = colours["base"]
	grabber_area.border_color = colours["base"]

	var grabber_area_highlight: StyleBoxFlat = base_theme.get_stylebox(
		"grabber_area_highlight",
		&"HSlider",
	)
	grabber_area_highlight.bg_color = colours["base"]
	grabber_area_highlight.border_color = colours["base"]


func _edit_line_edit(base_theme: Theme, colours: Dictionary[String, Color]) -> void:
	var focus: StyleBoxFlat = base_theme.get_stylebox("focus", &"LineEdit")
	focus.border_color = colours["highlight"]


func _edit_link_btn(base_theme: Theme, colours: Dictionary[String, Color]) -> void:
	base_theme.set_color("font_hover_color", &"LinkButton", colours["highlight"])


func _edit_popup_menu(base_theme: Theme, colours: Dictionary[String, Color]) -> void:
	var hover: StyleBoxFlat = base_theme.get_stylebox("hover", &"PopupMenu")
	hover.bg_color = colours["highlight"]

	var labeled_separator_left: StyleBoxLine = base_theme.get_stylebox(
		"labeled_separator_left",
		&"PopupMenu",
	)
	labeled_separator_left.color = colours["base"]

	var labeled_separator_right: StyleBoxLine = base_theme.get_stylebox(
		"labeled_separator_right",
		&"PopupMenu",
	)
	labeled_separator_right.color = colours["base"]

	var separator: StyleBoxLine = base_theme.get_stylebox("separator", &"PopupMenu")
	separator.color = colours["base"]


func _edit_text_edit(base_theme: Theme, colours: Dictionary[String, Color]) -> void:
	var focus: StyleBoxFlat = base_theme.get_stylebox("focus", &"TextEdit")
	focus.border_color = colours["highlight"]


func _edit_v_scrollbar(base_theme: Theme, colours: Dictionary[String, Color]) -> void:
	var grabber: StyleBoxFlat = base_theme.get_stylebox("grabber", &"VScrollBar")
	grabber.bg_color = colours["base"]

	var grabber_highlight: StyleBoxFlat = base_theme.get_stylebox(
		"grabber_highlight",
		&"VScrollBar",
	)
	grabber_highlight.bg_color = colours["highlight"]

	var grabber_pressed: StyleBoxFlat = base_theme.get_stylebox("grabber_pressed", &"VScrollBar")
	grabber_pressed.bg_color = colours["selected"]


func _edit_window(base_theme: Theme, colours: Dictionary[String, Color]) -> void:
	var embedded_border: StyleBoxFlat = base_theme.get_stylebox("embedded_border", &"Window")
	embedded_border.border_color = colours["base"]

	var embedded_unfocued_border: StyleBoxFlat = base_theme.get_stylebox(
		"embedded_unfocused_border",
		&"Window",
	)
	embedded_unfocued_border.border_color = colours["base"]
