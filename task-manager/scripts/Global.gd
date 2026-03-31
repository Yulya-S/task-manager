extends Node
# Сигналы
signal update_page(close_page: String) # Обновление данных на странице
# Перечисление
enum Dirs {PAGES, WINDOWS} # Директории объектов
# Переменные
var main_scene: Node = null # Главная сцена проекта сцена
var current_page: DB.Tables = DB.Tables.USERS # Текущая страница

# Открытие страницы
func open_new_page(page: DB.Tables, id: Variant = null, dir: Dirs = Dirs.PAGES, parent: Variant = null) -> void:
	pass

# Открытие окна
func open_window(page: DB.Tables, id: Variant = null, dir: Dirs = Dirs.WINDOWS, parent: Variant = null) -> void:
	pass

# Получение родителя определенного уровня
func g_p(obj: Variant, level: int = 2, save_level: int = 1) -> Variant:
	return obj.get_parent() if level == save_level else g_p(obj.get_parent(), level, save_level + 1)
