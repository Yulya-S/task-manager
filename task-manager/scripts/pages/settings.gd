extends PageWindow
# Подключение путей к объектам в сцене
@onready var Language = $Language
@onready var Preinstalled = $Color_Preset
@onready var DarkTheme = $Dark_Theme
@onready var ColorSchemePre = $ColorSchemePre
@onready var ColorSchemeCus = $ColorSchemeCus
@onready var Colors = $Colors

# Стартовое изменение страницы настроек
func _ready() -> void:
	File.load_lang(Language)
	for i in get_children():
		match i.get_class():
			"CheckButton":
				i.button_pressed = bool(ColorScheme.settings_data[i.name.to_lower()])
				call("_on_"+i.name.to_lower()+"_toggled", i.button_pressed)
			"OptionButton":
				call("_on_"+str("cus" if ColorScheme.settings_data.color_preset else "pre"), ColorScheme.settings_data.color_scheme)
			"Control":
				for l in i.get_children():
					var picker: ColorPicker = l.get_picker()
					picker.picker_shape = ColorPicker.SHAPE_VHS_CIRCLE
					picker.color_modes_visible = false
					picker.sliders_visible = false
					picker.presets_visible = false
					if ColorScheme.settings_data[l.name.to_lower()] != null:
						l.color = Color("#"+ColorScheme.settings_data[l.name.to_lower()])

# Изменение цвета
func _set_colors(color_values: Array) -> void:
	ColorSchemeCus.selected = len(color_values) - 1
	for i in range(len(color_values)): Colors.get_child(i).color = Color("#" + color_values[i])

# Изменение цветов в примере
func changed_color() -> void:
	_color_reading()
	ColorScheme.repainting($Example)
		
# Сборка цветовой палитры
func _color_reading() -> void:
	var colors: Array = []
	for i in range(ColorSchemeCus.selected + 1): colors.append(Colors.get_child(i).color)
	ColorScheme.color_assembly(colors, DarkTheme.button_pressed)
	
# Скрытие параметров цвета
func hide_colors() -> void: for i in Colors.get_children(): i.visible = false

# Отображение параметров цвета
func show_colors() -> void:
	hide_colors()
	for i in range(ColorSchemeCus.selected + 1): Colors.get_child(i).visible = true

# Изменение цветов
func _on_color_1_changed(_color: Color) -> void: changed_color()

func _on_color_2_changed(_color: Color) -> void: changed_color()

func _on_color_3_changed(_color: Color) -> void: changed_color()

func _on_color_4_changed(_color: Color) -> void: changed_color()

# Обработка изменения языка приложения
func _on_language_item_selected(_index: int) -> void: File.read_lang(Language)

# Обработка изменения темы оформления между предустановленной и персонализированной
func _on_color_preset_toggled(toggled_on: bool) -> void:
	File.set_CB(Preinstalled)
	ColorSchemeCus.visible = toggled_on
	ColorSchemePre.visible = not toggled_on
	call("_on_"+str("cus" if toggled_on else "pre"))
	changed_color()
	
# Обработка изменения светлой и тёмной темы
func _on_dark_theme_toggled(_toggled_on: bool) -> void:
	File.set_CB(DarkTheme)
	if Preinstalled.button_pressed: changed_color()
	else: _on_pre()

# Смена темы между светлой и тёмной
func _change_theme(light: Array, dark: Array) -> void:
	_set_colors(dark if DarkTheme.button_pressed else light)

# Обработка выбора количества цветов
func _on_cus(index: int = ColorSchemeCus.selected) -> void:
	ColorSchemeCus.selected = index
	show_colors()
	changed_color()

# Стандартные цветовые схемы
func _on_pre(index: int = ColorSchemePre.selected) -> void:
	hide_colors()
	ColorSchemePre.selected = index
	match index:
		0: _change_theme(["3a9891", "c8c8c8"], ["3aa49c", "414141"]) # Стандартная
		2: _change_theme(["aa76c6", "dfdf62"], ["6b6316", "52306a"]) # Лимон со смородиной
		3: _change_theme(["ad5252", "808080"], ["813333", "3b3b3b"]) # Ржавый металл
		4: _change_theme(["df8662", "72c8a3"], ["8f4e33", "2d5d57"]) # Лиса на поляне
		5: _change_theme(["e198ae", "b9e198"], ["801938", "44622b"]) # Ягода на ветке
		6: _change_theme(["981475", "3b9fc8"], ["ab3c96", "2c3498"]) # Ежевика
		7: _change_theme(["474745", "9c9c98", "ffe1ca"], ["9c9c98", "ab5732", "474745"]) # Пингвин
		_: _set_colors(["636363"]) # Серая
	changed_color()

# Обработка нажатия кнопки удаления пользователя
func _on_delete_button_down() -> void: $ConfirmationDialog.visible = true

# Обработка подтверждения удаления пользователя
func _on_confirmation_dialog_confirmed() -> void:
	DB.delete_user()
	Global.open_new_page(Global.Pages.REGISTRATION)

# Обработка нажатия кнопки сохранения настроек
func _on_apply_button_down() -> void:
	# Получение данных со страницы
	var values: Array = []
	for i in get_children():
		if not i.visible: continue
		match i.get_class():
			"CheckButton": values.append(i.button_pressed)
			"OptionButton": values.append(i.selected)
			"Control": for l in i.get_children():
				if int(l.name.split("_")[-1]) - 1 <= ColorSchemeCus.selected:
					values.append('"'+l.color.to_html()+'"')
				else: values.append("null")
	values.pop_front()
	# Сохранение записи в базе данных
	DB.update_with_columns(Global.Pages.SETTINGS, 1, values)
	_on_close_button_down()
