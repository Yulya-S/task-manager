extends Node
# Переменные
var settings_data: Dictionary = {} # Сохранение настроек приложения
var chart_gradient: Gradient = _custom_gradient([Color(1, 0, 0), Color(1, 1, 0)]) # Градиент для графиков
var scales_gradient: Gradient = _custom_gradient([Color.from_rgba8(0, 109, 0),
		Color(1, 1, 0), Color(1, 0, 0)]) # Градиент для шкал
var system_gradient: Gradient = Gradient.new() # Градиент для системы
var highlighter_color: Color = Color.AQUAMARINE # Цвет подсветки

# Составление цветовой палитры
func color_assembly(colors: Array, theme: bool) -> void:
	system_gradient = _custom_gradient([_color_from_theme(theme)] + colors + [_color_from_theme(not theme)], true)
	
# Замена цвета текста
func _set_font_color(obj: Variant, column: String = "", color_idx: int = 0) -> void:
	obj.add_theme_color_override("font_"+column+"color", _get_sys_color(color_idx))

# Изменение цвета кнопки
func _set_buttons_color(obj: Variant, a: float = 0.5, column: String = "normal") -> void:
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	_change_color(style_box, 0, "bg_color")
	style_box.bg_color.a = a
	style_box.set_corner_radius_all(2)
	obj.add_theme_stylebox_override(column, style_box)

# Изменение всех цветовых параметров кнопки
func _set_all_button_color_parametrs(obj: Variant) -> void:
	_set_buttons_color(obj)
	_set_buttons_color(obj, 0.8, "hover")
	_set_buttons_color(obj, 0.5, "pressed")
	_set_font_color(obj, "outline_")
	for i in ["", "focus_", "hover_", "hover_pressed_", "pressed_"]: _set_font_color(obj, i, 6)		

# Применение цвета без прямого обращения
func _change_color(obj: Variant, idx: float, column: String = "color") -> void:
	obj.set(column, _get_sys_color(idx))

# Изменение цветовой палитры объектов ColorRect
func _set_ColorRect(obj) -> void:
	match obj.name:
		"Head", "Border": _change_color(obj, 1)
		"Menu", "Marker", "FastCreations": _change_color(obj, 2)
		"Background": _change_color(obj, 6)
		"Date":
			_change_color(obj, 0)
			obj.color.a = 0.2
		"Filter", "Load", "Total": _change_color(obj, 3)
		"Example": for i in range(2): _change_color(obj.get_child(1 + i), 4 + i)
		_:
			if Global.g_p(obj, 3).name == "FastCreations": _change_color(obj, 4)
			else: match obj.get_parent().get_class():
				"HBoxContainer": _change_color(obj, 5)
				"GridContainer": _change_color(obj, 6)
				"VBoxContainer":
					_change_color(obj, 4 + int(obj.get_parent().get_child_count() != 1))

# Замена системных иконок
func _set_icon(obj: Variant, theme_name: String, icon: String) -> void:
	obj.add_theme_icon_override(theme_name, load("res://img/godot_icon/" + theme_name + "_" + icon))

# Замена цвета ячеек окна выбора даты
func set_DS_cell_color(obj: Variant, text: String, selected: bool, hovered: bool) -> void:
	if hovered: _change_color(obj, 4)
	elif selected: _change_color(obj, 2)
	elif text != "": _change_color(obj, 6)
	else: _change_color(obj, 5)

# Замена цвета ячеек календаря на странице событий
func set_calendar_cell_color(obj: Variant, day_off: bool, current: bool, complete: bool) -> void:
	if obj.Number.text != "":
		if current: _change_color(obj, 3)
		elif day_off: _change_color(obj, 4.7)
	else: _change_color(obj, 5.2)
	if complete:
		obj.get_child(-2).color = ColorScheme.get_color(95, 100)
		obj.get_child(-2).color.a = 101. / 255.

# Создание градиента
func _custom_gradient(values: Array, system: bool = false) -> Gradient:
	var new_grad: Gradient = Gradient.new()
	new_grad.colors = PackedColorArray(values)
	var offsets: Array = []
	if not system: for i in range(len(values)): offsets.append(i * (1. / (len(values) - 1.)))
	else:
		for i in range(len(values) - 2): offsets.append(0.2 + (0.8 / (len(values) - 2.)) * i)
		offsets = [0.] + offsets + [1.]
	new_grad.offsets = PackedFloat32Array(offsets)
	return new_grad

# Получение значения цвета из градиента по индексу
func get_color(index: float, count: float, gradient: Gradient = chart_gradient) -> Color:
	if count == 0: count = 1
	return gradient.sample(index / count)

# Получение значения цвета из градиента системы
func _get_sys_color(index: float, count: float = 6) -> Color:
	return get_color(index, count, system_gradient)

# Получение значения цвета из градиента шкал
func get_scale_color(index: float, count: float = 1) -> Color:
	return get_color(index, count, scales_gradient)

# Получение цвета текста и рамок
func border_color() -> Color: return ColorScheme._get_sys_color(0, 1)

# Получение цветов из базы данных
func color_reading() -> void:
	var colors: Array = []
	settings_data = DB.select_settings()
	for i in range(4): colors.append(settings_data["color_" + str(i + 1)])
	color_assembly(colors.filter(func(value): return value != null), settings_data.dark_theme)
	# Изменение градиента для графиков и цвета подсветки под выбранную цветовую тему
	chart_gradient = _custom_gradient([_get_sys_color(10, 100), _get_sys_color(55, 100)])
	highlighter_color = Color.AQUAMARINE * _get_sys_color(50, 100) / Color("c8c8c8")

# Получение стандартного цвета, черного или белого
func _color_from_theme(theme: bool) -> Color: return Color.WHITE if theme else Color.BLACK

# Применение цветовой палитры к странице
func repainting(obj: Variant) -> void:
	match obj.get_class():
		"ColorRect": _set_ColorRect(obj)
		"ProgressBar": _change_color(obj, 1, "modulate")
		"Button", "TextEdit": _set_all_button_color_parametrs(obj)
		"OptionButton":
			_set_all_button_color_parametrs(obj)
			_set_icon(obj, "arrow", str(int(settings_data.dark_theme))+".png")
		"CheckButton":
			var dark_theme: String = str(int(settings_data.dark_theme))
			for i in ["", "un"]: _set_icon(obj, i +"checked", dark_theme + ".tres")
			for i in ["", "focus_", "pressed_"]: _set_font_color(obj, i)
			_set_font_color(obj, "hover_", 3)
		"Label":
			if obj.name != "Error": _set_font_color(obj)
			_set_font_color(obj, "outline_", 6)
		_: match obj.name:
			"Gradient": obj.texture.gradient = ColorScheme.chart_gradient
			"X", "Border", "Separator": _change_color(obj, 0, "default_color")
			"Frame": _change_color(obj, 3.5, "default_color")
			"SelectedCell": _change_color(obj, 1, "default_color")
	for i in obj.get_children(): repainting(i)
