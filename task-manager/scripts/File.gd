extends Node
# Переменные
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
		"CheckButton":
			if lang[key] is Array: set_CB(obj)
			else: obj.set_text(lang[key])
		"ColorPickerButton": obj.get_child(0).set_text(lang[key]+" "+obj.name.split("_")[1])
		"Label", "CheckBox":
			if obj.text != "" and "-" not in obj.text and not Global.text_is_number(obj.text):
				obj.set_text(lang[key])
		"Button":
			if obj.text in ["", "X"]: obj.tooltip_text = lang[key]
			else: obj.set_text(lang[key])
		"OptionButton":
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
	if obj.name == "Filter": Global.run_func(obj, "reset_OB")
	if obj.get("text") and "__" in obj.get("text") and \
		obj.get("text") in lang.keys() and obj is not OptionButton:
			key = obj.text
	if (key != "" and "@" not in obj.get_parent().name) or obj is OptionButton: _lang_match(obj, key)
	for i in obj.get_children(): set_lang(i)

# Создание стандартных вариантов локализации
func _standard_language() -> Dictionary: return {
	# Шапка
	"Hints": "Инструкция", "Setting": "Настройки", "Exit": "Выход", "Projects": "Проекты", "Sections": "Действия", "Tasks": "Задачи",
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
	# Фильтры
	"FilterTitleLabel": "Фрагмент названия", "FilterOrderLabel": "Порядок сортировки",
	"FilterButton": "Применить", "StateLabel": "Статус",
	# Страница проектов
	"ProjectsMenuAdd": "Создать проект", "ProjectsFilterOrder": ["По количеству активных задач"],
	"ProjectTitle": "Название проекта", "ProjectCompleted": "Выполненные", "ProjectCanceled": "Отклоненные", "ProjectCount": "Оставшиеся",
	# Страница информации о проекте
	"Back": "Назад", "Update": "Изменить", "AddTask": "Создать задачу",
	"InformationMenuLabel": "Информация о проекте", "TotalLabel": "Шкала выполнения задач:",
	"Date": "Дата завершения", "Project": "Проект", "Section": "Действие", "TaskTitle": "Текст задачи",
	# Окна создания / изменения
	"Apply": "Сохранить", "Close": "Отменить изменения", "Delete": "Удалить",
	# Окно создания проекта
	"CommentLabel": "Комментарий", "ProjectTitleLabel": "Название проекта:",
	# Задачи
	"TasksFilterOrder": ["По дате обновления"], "TaskLabel": "Текст задачи:",
	"TasksMenuAdd": "Создать задачу",
	# Действия
	"SectionsFilterOrder": ["По суммарному количеству задач", "По количеству активных задач"],
	"SectionTitle": "Текст действия", "SectionCount": "Количесто активных задач",
	"SectionSum_count": "Суммарное количество задач", "SectionsMenuAdd": "Создать действие",
	"SectionTitleLabel": "Текст действия:",
	# Состояния объекта
	"__ST1": "В процессе", "__ST2": "Завершено", "__ST3": "Отменено",
	# Окно подтверждения
	"_ConfirmationDialog": {"cancel": "Нет", "ok": "Да"}, "__sure": "Вы уверены?",
	# Общие фрагменты для фильтра сортировки (По id, по алфавиту)
	"__FO1": "По дате добавления", "__FO2": "По алфавиту",
	# Подсказки
	# Подсказки
	"_Hints": [
		'При выборе языка в соответствующем выпадающем списке, язык текста приложения будет изменен.\nВажно: в случае не полного перевода текст будет автоматически дополнен Русским переводом (создается по умолчанию)',
		"Для начала использования приложения необходимо создать аккаунт пользователя, для этого заполните поля логина (будет отображено в верхней части приложения) и пароля",
		'После чего нажмите кнопку "Регистрация", если пользователь существует, то при нажатии кнопки "Вход" будет совершен вход в его аккаунт.\nВажно: Имя пользователя должно быть уникальным!',
		'При установке галочки у параметра "Показать пароль" текст в поле пароля станет видимым',
		'При установке галочки у параметра "Запомни меня" следующий вход в аккаунт пользователя будет совершен автоматически',
		# Задачи
		"После входа в аккаунт пользователя появится страница задач, на которой отображается информация о всех активных и завершенных задачах",
		'При нажатии на знак "+" будет открыто окно создания новой задачи.\nВажно: Для создания задачи требуется по крайней мере один проект и одно действие',
		"При нажатии на текст задачи будет открыто окно изменения выбранной задачи",
		'Если нажать на текст текущего состояния задачи будет сменен статус задачи в циклическом порядке: "В процессе", "Завершено", "Отменено"',
		'Для перехода в меню настроек приложения нужно нажать на кнопку "Настройки" в верхней части приложения',
		# Настройки
		"Изменения, внесенные на странице настроек, имеют только косметический характер и затрагивают только внешний вид приложения у текущего пользователя",
		"На выбор существуют 9 предустановленных цветовых тем, каждая из них отличается в зависимости от выбора между светлой и темной темой",
		"Кроме того пользователь может создать свою собственную цветовую тему при переключении режима предустановленной и пользовательской темы",
		"В пользовательской теме можно настроить количество используемых цветов (от 1 до 4).\nВажно: При выборе темной темы в пользовательской палитре, яркость и контраст выбранных цветов настраивается вручную",
		"Все изменения цветовой палитры будут отображаться в примере внешнего вида приложения.\nВажно: При смене между светлой и темной темой приложения меняются цветовые настройки текста и всех видов кнопок",
		'Нажатие кнопки "Удалить" удалит все данные о пользователе безвозвратно, предварительно предложив отменить решение об удалении пользователя',
		'Изменения в окне настроек будут сохранены только при нажатии кнопки "Сохранить", если закрыть окно нажатием на "Крестик" изменения будут отменены, за исключением выбора языка программы, который применяется без сохранения изменений',
		# Проекты
		"При переходе на страницу проектов отображается информация об активных и завершенных проектах, а также статистика о количестве оставшихся, выполненных и отмененных задач",
		'Если нажать на текст текущего состояния проекта будет сменен статус задачи в циклическом порядке: "В процессе", "Завершено"',
		"При нажатии на имя проекта в списке будет совершен переход на страницу информации о выбранном проекте",
		# Информация о проекте
		"На странице информации приведен список всех задач относящихся в выбранному проекту",
		"В нижней части страницы отображается шкала выполнения проекта, где с правой стороны шкала отмененных задач, а слева выполненных",
		'При нажатии на текст текущего состояния проекта будет сменен статус задачи в циклическом порядке: "В процессе", "Завершено"',
		"Кнопки в верхней части страницы информации позволяют изменять проект, а также создавать задачи в рамках выбранного проекта",
		'Для закрытия страницы информации нужно нажать на кнопку "Назад" или перейти на одну из страниц в шапке приложения',
		# Действия
		"На странице действий отображается список всех созданных действий, а также количество задач в процессе выполнения и суммарное количество задач",
		"При нажатии на текст действия будет открыто окно изменения выбранного действия",
		# Выход
		'Для того, чтобы выйти из аккаунта пользователя нужно нажать на кнопку "Выход".\nВажно: При выходе из аккаунта автоматический вход будет сброшен и авторизацию нужно будет повторить для входа в аккаунт текущего пользователя',
	],
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
	# Шапка
	"Hints": "Instructions", "Setting": "Settings", "Exit": "Exit", "Projects": "Projects", "Sections": "Actions", "Tasks": "Tasks",
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
	# Фильтры
	"FilterTitleLabel": "Title fragment", "FilterOrderLabel": "Sorting order",
	"StateLabel": "Status", "FilterButton": "Apply",
	# Страница проектов
	"ProjectsMenuAdd": "Create a project", "ProjectsFilterOrder": ["By number of active tasks"],
	"ProjectTitle": "Project Title", "ProjectCompleted": "Completed", "ProjectCanceled": "Rejected", "ProjectCount": "Remaining",
	# Страница информации о проекте
	"Back": "Back", "Update": "Edit", "AddTask": "Create task",
	"InformationMenuLabel": "Project Information", "TotalLabel": "Task Progress Bar:",
	"Date": "Completion date", "Project": "Project", "Section": "Action", "TaskTitle": "Task text",
	# Окна создания / изменения
	"Apply": "Save", "Close": "Cancel changes", "Delete": "Delete",
	# Окно создания проекта
	"CommentLabel": "Comment", "ProjectTitleLabel": "Project Title:",
	# Задачи
	"TasksFilterOrder": ["By update date"], "TaskLabel": "Problem text:",
	"TasksMenuAdd": "Create a task",
	# Действия
	"SectionsFilterOrder": ["By total number of tasks", "By number of active tasks"],
	"SectionTitle": "Action name", "SectionCount": "Number of active tasks",
	"SectionSum_count": "Total number of tasks", "SectionsMenuAdd": "Create an action",
	"SectionTitleLabel": "Action name:",
	# Состояния объекта
	"__ST1": "In progress", "__ST2": "Completed", "__ST3": "Canceled",
	# Окно подтверждения
	"_ConfirmationDialog": {"cancel": "No", "ok": "Yes"}, "__sure": "Are you sure?",
	# Общие фрагменты для фильтра сортировки (По id, по алфавиту)
	"__FO1": "By date added", "__FO2": "Alphabetically",
	# Подсказки
	"_Hints": [
		'When you select a language from the corresponding drop-down list, the language of the application text will be changed.\nImportant: if the translation is incomplete, the text will be automatically supplemented with a Russian translation (created by default)',
		"To start using the application, you need to create a user account. To do this, fill in the login (will be displayed at the top of the application) and password fields",
		'Then click the "Register" button. If the user exists, then clicking the "Login" button will log you into his account.\nImportant: The username must be unique!',
		'By checking the "Show password" box, the text in the password field will become visible',
		'By checking the box next to the "Remember me" option, the next time you log into your user account, it will be done automatically',
		# Задачи
		"After logging in to the user's account, the tasks page will appear, displaying a list of all active and completed tasks",
		'Clicking the "+" sign will open a window for creating a new task.\nImportant: Creating a task requires at least one project and one action',
		"Clicking the task text will open a window for editing the selected task",
		'Clicking on the task\'s current status text will cycle through the following: "In Progress", "Completed" and "Canceled"',
		'To access the app\'s settings menu, click the "Settings" button at the top of the app',
		# Настройки
		"Changes made on the Settings page are cosmetic only and affect the app's appearance for the current user",
		"There are 9 preset color themes to choose from, each with a different color theme depending on whether you choose Light or Dark mode",
		"In addition, the user can create their own color theme by switching between preset and custom themes",
		"In the custom theme, you can customize the number of colors used (from 1 to 4).\nImportant: When selecting a dark theme in the custom palette, the brightness and contrast of the selected colors must be adjusted manually",
		"All color palette changes will be reflected in the sample app appearance.\nImportant: When switching between the light and dark app themes, the color settings for the text and all button types change",
		'Clicking the "Delete" button will permanently delete all user data, prompting you to cancel the deletion decision',
		'Changes in the settings window will only be saved when you click the "Save" button. Closing the window by clicking the "X" will discard the changes, with the exception of the program language selection, which is applied without saving the changes',
		# Проекты
		"When you go to the projects page, information about active and completed projects is displayed, as well as statistics about the number of remaining, completed, and canceled tasks",
		'Clicking on the text of the current project status will change the task status in a cyclic order: "In progress", "Completed"',
		'Clicking on a project name in the list will take you to the information page for the selected project',
		# Информация о проекте
		"The information page lists all tasks related to the selected project",
		"The project progress bar is displayed at the bottom of the page, with canceled tasks on the right and completed tasks on the left",
		'Clicking on the text of the current project status will change the task status in a cyclic order: "In progress", "Completed"',
		"The buttons at the top of the information page allow you to edit the project and create tasks within the selected project",
		'To close the information page, you need to press the "Back" button or go to one of the pages in the application header',
		# Действия
		"The Actions page displays a list of all created actions, as well as the number of tasks in progress and the total number of tasks",
		"Clicking on the action text will open a window for editing the selected action",
		# Выход
		'To log out of a user account, click the "Log Out" button.\nImportant: When you log out of an account, automatic login will be reset and you will need to re-authorize to log into the current user\'s account',
	],
	# Ошибки
	"_Errors": {
			"_E1": "Required fields must be filled in",
			"_E2": "Username taken",
			"_E3": "Incorrect login or password",
			"_E4": "An object with the selected name already exists"
		}
	})
