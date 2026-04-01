extends Node
var user_base_path: String = "user://bases/" # Директория хранения баз данных
var lang_base_path: String = user_base_path + "language/" # Директория хранения переводов
var conf_file_path: String = user_base_path + "conf.json" # Путь к файлу конфигураций
var config: Dictionary = _empty_conf() # Данные конфигураций
var lang: Dictionary = {} # Текущий перевод

# Стартовое создание директорий
func _ready() -> void:
	for i in [user_base_path, lang_base_path]:
		if not DirAccess.dir_exists_absolute(i): DirAccess.make_dir_absolute(i)
	_create_config()
	_create_langs()

# Работа с файлами
# Сохранение данных в файл
func _store_json(file_path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_line(JSON.stringify(data))
	file.close()
	
# Чтение данных из файла
func _read_file(file_path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var json: JSON = JSON.new()
	if not json.parse(file.get_line()) == OK: return {}
	file.close()
	return json.data
	
# Шифрование данных
func hide_data(data: String) -> String: return Marshalls.utf8_to_base64(data)

# Дешифрование данных
func show_data(data: String) -> String: return Marshalls.base64_to_utf8(data)

# Файл конфигураций
# Проверка наличия созданного файла конфигураций
func _create_config() -> void:
	if FileAccess.file_exists(conf_file_path):
		var new: Dictionary = _read_file(conf_file_path)
		if new.keys() == config.keys():
			config = new
			return
	save_config()

# Сохранение данных конфигураций в файл
func save_config() -> void: _store_json(conf_file_path, config)

# Пустой словарь конфигурации
func _empty_conf() -> Dictionary: return {"enter": false, "lang": "ru", "login": "", "password": ""}

# Очистка данных пользователя
func clear_config() -> void:
	config = _empty_conf()
	save_config()

# Файл локализации
# Заполнение поля выбора языка
func load_lang(container: OptionButton) -> void:
	for i in DirAccess.get_files_at(lang_base_path): if "json" in i and len(i.split(".")) == 2:
		container.add_item(i.split(".")[0])
		# Применение языка, если он соответствует выбранному в файле конфигураций
		if i.split(".")[0] == config.lang:
			container.select(container.item_count-1)
			read_lang(container)

# Создание файлов языков
func _create_langs() -> void:
	# Убрать позже - нужно для автоматического обновления перевода
	DirAccess.remove_absolute(lang_base_path+"ru.json")
	DirAccess.remove_absolute(lang_base_path+"en.json")
	
	_cr_ru()
	_cr_en()

# Создание файла перевода
func _cr_lang_file(f_name: String, value: Dictionary) -> void:
	if FileAccess.file_exists(lang_base_path+f_name+".json"): return
	_store_json(lang_base_path+f_name+".json", value)

# Считывание перевода
func read_lang(container: OptionButton) -> void:
	lang = _read_file(lang_base_path+Global.get_OB_text(container)+".json")
	lang.merge(_standard_language())
	set_lang(container.get_parent())
	# Сохранение выбора в файле конфигураций
	config.lang = Global.get_OB_text(container)
	save_config()

# Поиск ключа в базе перевода
func _find_lang_keys(obj: Variant, key: String = "") -> String:
	if not obj or obj.name == "main": return ""
	key = obj.name + key
	if "_" in key and len(key.split("_")) <= 2 and key.split("_")[1].is_valid_int(): key = key.split("_")[0]
	if key not in lang.keys(): return _find_lang_keys(obj.get_parent(), key)
	return key

# Изменение текста объекта в зависимости от типа объекта
func _lang_match(obj: Variant, key: String) -> void:
	match obj.get_class():
		"CheckButton": set_CB(obj)
		"ColorPickerButton": obj.get_child(0).set_text(lang[key]+" "+obj.name.split("_")[1])
		"Label", "CheckBox":
			if obj.text != "" and "-" not in obj.text and not Global.text_is_number(obj.text):
				obj.set_text(lang[key])
		"Button":
			if obj.text in ["", "X"]: obj.tooltip_text = lang[key]
			else: obj.set_text(lang[key])
		"OptionButton":
			if obj.name == "Order": obj.get_parent().reset_order()
			var idx: int = 0
			for i in range(obj.get_item_count()):
				if obj.get_item_text(i) == "" or (obj.get_item_text(i) not in lang.keys() and key not in lang.keys()):
					continue
				elif "__" in obj.get_item_text(i):
					obj.set_item_text(i, lang[obj.get_item_text(i)])
				elif lang[key] is Array:
					if idx >= len(lang[key]): return
					obj.set_item_text(i, lang[key][idx])
					idx += 1
		"ConfirmationDialog":
			if "_ConfirmationDialog" in lang.keys():
				for i in ["cancel", "ok"]:
					if i in lang._ConfirmationDialog.keys():
						obj.call("set_"+i+"_button_text", lang._ConfirmationDialog[i])
			if "text" in lang[key].keys(): obj.set_text(lang["__sure"]+" "+lang[key].text)
			if "title" in lang[key].keys(): obj.set_title(lang[key].title)

# Изменение текста состояния кнопки переключателя
func set_CB(obj: CheckButton) -> void:
	var key: String = _find_lang_keys(obj)
	if key == "": return
	if lang[key] is Array: if len(lang[key]) >= int(obj.button_pressed): obj.set_text(lang[key][int(obj.button_pressed)])
	else: obj.set_text(lang[key])

# Замена текста элементов выпадающего списка
func set_OB_elements(obj: OptionButton) -> void:
	for i in range(obj.get_item_count()): if obj.get_item_text(i) in lang.keys(): obj.set_item_text(i, lang[obj.get_item_text(i)])

# Применение перевода
func set_lang(obj: Variant) -> void:
	var key: String = _find_lang_keys(obj)
	if obj is OptionButton and obj.name == "Month": key = "_Months"
	elif obj is Label and "__" in obj.text and obj.text in lang.keys(): key = obj.text
	if key != "" or obj is OptionButton: _lang_match(obj, key)
	for i in obj.get_children(): set_lang(i)

# Создание стандартных вариантов локализации
func _standard_language() -> Dictionary: return {
	# Регистрация
	"Registration": "Регистрация", "Enter": "Вход", "LanguageLabel": "Язык:", "LoginLabel": "Логин:",
	"PasswordLabel": "Пароль:", "Remember": "Запомни меня", "Show": "Показать пароль",
	# Настройки
	"DeleteUser": "Удалить пользователя", "ColorSchemePreLabel": "Цветовое оформление",
	"ColorSchemeCusLabel": "Количество цветов", "TestButton": "Пример кнопки", "ColorsColor": "Цвет",
	"TestLabel": "Пример текста", "Dark_Theme": ["Светлая тема", "Тёмная тема"],
	"Color_Preset": ["Предустановленная тема", "Пользовательская тема"],
	"ColorSchemePre": ["Стандартный", "Серый", "Лимон со смородиной", "Ржавый металл", "Лиса на поляне", "Ягода на ветке", "Ежевика", "Пингвин"],
	"ColorSchemeCus": ["Моно", "Контраст", "Триада", "Тетрада"],
	"SettingsConfirmationDialog": {"text": "Все данные пользователя будут удалены", "title": "Удаление пользователя"},
	# Окна создания / изменения
	"Apply": "Сохранить", "Close": "Отменить изменения",
	# Страница проектов
	"__ST1": "В процессе", "__ST2": "Завершено", "__ST3": "Отменено",
	# Окно подтверждения
	"_ConfirmationDialog": {"cancel": "Нет", "ok": "Да"}, "__sure": "Вы уверены?",
	# Общие фрагменты для фильтра сортировки (По id, по алфавиту)
	"__FO1": "По дате добавления", "__FO2": "По алфавиту",
	# Подсказки
	"_Hints": [],
	# Ошибки
	"_Errors": {
			"_E1": "Обязательные поля должны быть заполнены",
			"_E2": "Имя пользователя занято",
			"_E3": "Неверный логин или пароль",
			"_E4": "Объект с выбранным именем уже существует"
		}
	}

# Русский
func _cr_ru() -> void: _cr_lang_file("ru", _standard_language())

# Английский
func _cr_en() -> void: _cr_lang_file("en", {
	# Регистрация
	"Registration": "Registration", "Enter": "Entry", "LanguageLabel": "Language:", "LoginLabel": "Login:",
	"PasswordLabel": "Password:", "Remember": "Remember me", "Show": "Show password",
	# Настройки
	"DeleteUser": "Delete user", "ColorSchemePreLabel": "Color design", "ColorsColor": "Color",
	"ColorSchemeCusLabel": "Number of colors", "TestButton": "Button example",
	"TestLabel": "Example text", "Dark_Theme": ["Light theme", "Dark theme"],
	"Color_Preset": ["Pre-installed theme", "Custom Theme"],
	"ColorSchemePre": ["Standard", "Grey", "Lemon with currants", "Rusty metal", "A fox in a clearing", "Berry on a branch", "Blackberry", "Penguin"],
	"ColorSchemeCus": ["Mono", "Contrast", "Triad", "Tetrad"],
	"SettingsConfirmationDialog": {"text": "All user data will be deleted", "title": "Deleting a user"},
	# Окна создания / изменения
	"Apply": "Save", "Close": "Cancel changes",
	# Страница проектов
	"__ST1": "In progress", "__ST2": "Completed", "__ST3": "Canceled",
	# Окно подтверждения
	"_ConfirmationDialog": {"cancel": "No", "ok": "Yes"}, "__sure": "Are you sure?",
	# Общие фрагменты для фильтра сортировки (По id, по алфавиту)
	"__FO1": "By date added", "__FO2": "Alphabetically",
	# Подсказки
	"_Hints": [],
	# Ошибки
	"_Errors": {
			"_E1": "Required fields must be filled in",
			"_E2": "Username taken",
			"_E3": "Incorrect login or password",
			"_E4": "An object with the selected name already exists"
		}
	})
