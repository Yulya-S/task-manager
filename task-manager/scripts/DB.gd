extends Node
var db: SQLite = null # Подключенная база данных
enum Tables {USERS, SETTINGS, PROJECTS, SECTIONS, TASKS, SQLITE_SEQUENCE} # Таблицы в базе данных

# Стартовый запуск БД
func _ready() -> void: connection_user_db()

# Получение имени объекта из перечисления
func enum_key(enums: Dictionary, obj: int) -> String: return enums.keys()[obj].to_lower()

# Открытие базы данных
func _open_db(db_name: String = "users") -> void:
	db = SQLite.new()
	db.path = File.user_base_path + db_name + ".db"
	db.open_db()

# Подключение базы данных пользователей
func connection_user_db() -> void:
	_open_db()
	db.query("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT,
		login VARCHAR(255), password VARCHAR(255), base VARCHAR(255));")

# Подключение базы данных
func connection_db(db_name: String) -> void:
	_open_db(db_name)
	# Создание таблиц в базе
	_create_table(Tables.SECTIONS)
	_create_table(Tables.PROJECTS, ["state BOOLEAN", "comment VARHAR (255)"])
	_create_table(Tables.TASKS, ["project_id INT", "section_id INT", "state INT", "create_date DATE", "update_date DATE"])
	db.query("CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY AUTOINCREMENT,
		color_preset BOOLEAN, color_scheme INT, color_1 VARCHAR(255), color_2 VARCHAR(255),
		color_3 VARCHAR(255), color_4 VARCHAR(255), dark_theme BOOLEAN);")
	# Создание стандартных данных
	_insert_witn_columns(Tables.SETTINGS, [0, 0, '"3a9891ff"', '"c8c8c8ff"', "null", "null", 0])

# Запрос на создание таблицы
func _create_table(title: Tables, t_columns: Array = []) -> void:
	t_columns = ["title VARCHAR(255)"] + t_columns
	var foreign: Array = []
	for i in t_columns: if "id" in i:
		foreign.append("(`"+i.split(" ")[0]+"`) REFERENCES `"+i.split("_id")[0]+"s`(`id`)")
	if len(foreign) != 0: foreign = [""] + foreign
	db.query("CREATE TABLE IF NOT EXISTS " + enum_key(Tables, title) +
		" (id INTEGER PRIMARY KEY AUTOINCREMENT, " + ", ".join(t_columns) +
		", FOREIGN KEY ".join(foreign) + ");")

# Фрагменты запросов
# Название таблицы
func _get_table_name(table: Variant) -> String:
	if table is String: return table
	return enum_key(Tables, table)

# Названия колонок в таблице
func _get_columns(table: Variant) -> Array:
	db.query("PRAGMA table_info(`"+_get_table_name(table)+"`)")
	var result: Array = []
	for i in db.query_result: result.append(i.name)
	result.pop_front()
	return result

# Создание записей
# Основной запрос
func _insert(table: Variant, columns: String, values: Array) -> void:
	db.query("INSERT INTO `" + _get_table_name(table) + "` (" + columns +
		") VALUES (" + ", ".join(values) + ");")

# Со всеми колонками таблицы
func _insert_witn_columns(table: Variant, values: Array) -> void:
	_insert(table, ", ".join(_get_columns(table)), values)

# Обновление записей
# Основной запрос
func _update(table: Variant, columns: Array, values: Array, where: String = "") -> void:
	var v: Array = []
	if where: where = " WHERE " + where
	for i in range([len(columns), len(values)].min()):
		v.append(columns[i] + " = " + str(values[i]))
	db.query("UPDATE `" + _get_table_name(table) + "` SET " + ",".join(v) + where + ";")

# По индексу
func _update_record(table: Variant, columns: Array, values: Array,
			idx: Variant, other: String = "") -> void:
	if other: other = "AND " + other
	_update(table, columns, values, "id = " + str(idx) + other)

# Все колонки у записи
func update_with_columns(table: Variant, idx: Variant, values: Array, other: String = "") -> void:
	_update_record(table, _get_columns(table), values, idx, other)

# Удаление записей
# Основной запрос
func _delete(table: Variant, where: String = "") -> void:
	if where: where = " WHERE " + where
	db.query("DELETE FROM `"+_get_table_name(table)+"`"+where+";")

# По индексу
func _delete_record(table: Variant, idx: int, other: String = "") -> void:
	if other: other = "AND " + other
	var where_idx: String = "id = " + str(idx)
	_delete(table, where_idx + other)
	_update(table, ["id"], ["id - 1"], "id > " + str(idx))
	_update(Tables.SQLITE_SEQUENCE, ["seq"], ["seq - 1"], 'name = "' + _get_table_name(table) + '"')

# Пользователь
func delete_user() -> void:
	connection_user_db()
	var data: Dictionary = select_all(Tables.USERS, 'login="'+File.config.login+'"')[0]
	DirAccess.remove_absolute(File.user_base_path + File.show_data(data.base) + ".db")
	_delete_record(Tables.USERS, data.id)
	File.clear_config()

# Запросы на поиск объектов
# Основная функция
func select(req_text: String, where: String = "", order: String = "", group: String = "") -> Array:
	if where: where = " WHERE " + where
	if group: group = " GROUP BY " + group
	if order: order = " ORDER BY " + order
	db.query("SELECT " + req_text + where + group + order + ";")
	return db.query_result

# Все записи из таблицы
func select_all(table: Variant, where: String = "", order: String = "") -> Array:
	return select("* FROM "+_get_table_name(table), where, order)

# Существование выбранного пользователя
func select_existence_user(login: bool) -> bool:
	var req: String = 'login="' + File.config["login"] + '"'
	if login: req += ' AND password="' + File.config["password"] + '"'
	var res: Array = select("COUNT(id)==" + str(int(login)) + " res FROM users", req)
	if len(res) == 0: return false
	return res[0].res

# Пользователь, в аккаунт которого совершается вход
func select_user() -> Dictionary:
	var user_data: Array = []
	for i in File.config.keys(): if i in _get_columns(Tables.USERS):
		user_data.append(i + '="' + File.config[i] + '"')
	return select_all(Tables.USERS, "AND ".join(user_data))[0]

# Настройки
func select_settings() -> Dictionary: return select_all(Tables.SETTINGS)[0]

func select_projects(where: String, order: String = "") -> Array:
	return select("p.*, (SELECT COUNT(t.id) FROM tasks t WHERE t.project_id = p.id AND state = 1) completed,
		(SELECT COUNT(t.id) FROM tasks t WHERE t.project_id = p.id AND state = 2) canceled,
		(SELECT COUNT(t.id) FROM tasks t WHERE t.project_id = p.id AND state = 0) count FROM projects p", where, order)

# Распределители
# Получение списков объектов
func match_select(table: Tables, filter: Dictionary) -> Array:
	match table:
		Tables.PROJECTS: return select_projects(filter.where, filter.order)
	return []
