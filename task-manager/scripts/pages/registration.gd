extends Control
# Подключение путей к объектам в сцене
@onready var Language = $Language
@onready var Password = $Password
@onready var Error = $Error

# Заполнение списка языков программы
func _ready() -> void: File.load_lang(Language)

# Автоматический вход
func _process(_delta: float) -> void: if File.config.enter: _on_enter_button_down(false, true)

# Обработка смены языка приложения
func _on_language_item_selected(_index: int) -> void: File.read_lang(Language)

# Обработка ввода значений в текстовые поля
func _on_text_changed(container_idx: int) -> void:
	Global.text_changed_TextEdit([$Login, Password][container_idx])

# Изменение видимости пароля
func _on_show_toggled(toggled_on: bool) -> void:
	Password.add_theme_color_override("font_color", Color.WHITE if toggled_on else Color.html("#00000000"))

# Обработка входов в программу
# Проверка пользователя
func _check_user(login: bool, check_field: bool = true) -> bool:
	Error.clear()
	# Заполнение файла конфигурации
	if check_field: for i in get_children(): if i is TextEdit:
		if Error.check(i): return false
		File.config[i.name.to_lower()] = File.hide_data(i.get_text())
	return DB.select_existence_user(login) # Получение результата проверки из базы данных

# Вход в программу
func _entrance(auto: bool = false) -> void:
	# Сохранение файла конфигурации для автоматического входа
	if not auto:
		File.config.enter = $Remember.button_pressed
		if File.config.enter: File.save_config()
	# Вход в аккаунт
	var data: Dictionary = DB.select_user()
	DB.connection_db(File.show_data(data.base))
	ColorScheme.color_reading()
	Global.open_new_page(Global.Pages.TASKS)

# Генерация названия базы данных
func _generate_db_name() -> String:
	var base_name: String = ""
	const chars: String = 'abcdefghijklmnopqrstuvwxyz1234567890'
	for i in range(10): base_name += chars[randi()%len(chars)]
	return File.hide_data(base_name)

# Регистрация
func _on_registration_button_down() -> void:
	if not _check_user(false):
		Error.set_state(Error.States._E2)
		return
	DB._insert_witn_columns("users", ['"'+File.config.login+'"', '"'+File.config.password+'"', '"'+_generate_db_name()+'"'])
	_entrance()

# Вход
func _on_enter_button_down(check_field: bool = true, auto: bool = false) -> void:
	if not _check_user(true, check_field):
		File.clear_config()
		Error.set_state(Error.States._E3)
		return
	_entrance(auto)

# Подсказки
func _on_hints_button_down() -> void: Global.open_window(Global.Pages.HINTS, null, Global.Dirs.PAGES)
