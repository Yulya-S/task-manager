extends Node
# Сигналы
signal update_page(close_page: String) # Обновление данных на странице
# Перечисление
enum Dirs {PAGES, WINDOWS} # Директории объектов
enum Pages {REGISTRATION, SETTINGS, PROJECTS, SECTIONS, TASKS, HINTS} # Страницы
# Переменные
var main_scene: Node = null # Главная сцена проекта сцена
var current_page: Pages = Pages.REGISTRATION # Текущая страница

# Вызов функции у родителя, если она у него есть
func run_func(obj: Variant, func_name: String, args: Array = []) -> void:
	if obj.get(func_name): obj.callv(func_name, args)

# Очистка сцены
func clear_scene(obj: Variant) -> void: for child in obj.get_children(): delete_child(obj, child)

# Создание и изменение значения элемента
func add_new_child(parent: Variant, path: Resource, values: Array = [], func_name: String = "set_values") -> void:
	parent.add_child(path.instantiate())
	run_func(parent.get_child(-1), func_name, values)

# Удаление объекта сцены
func delete_child(parent: Variant, child: Variant) -> void:
	child.queue_free()
	parent.remove_child(child)

# Открытие страницы
func open_new_page(page: Pages, id: Variant = null, dir: Dirs = Dirs.PAGES, parent: Variant = null) -> void:
	current_page = page
	for child in main_scene.get_children(): delete_child(main_scene, child)
	open_window(page, id, Dirs.PAGES, parent)

# Проверка имени крайней страницы
func _check_inf_page() -> bool:
	if _ch_inf(-2) or _ch_inf(): return false
	if _ch_par("page_type") and _ch_par(): return true
	return false

# Проверка что страница является инфомрационной
func _ch_inf(idx: int = -1) -> bool:
	return not _ch_name("@", idx) and not _ch_name("Inf", idx)
	
# Проверка фрагмена названия дочернего элемента
func _ch_name(text: String = "@", idx: int = -1) -> bool: return text in main_scene.get_child(idx).name

# Проверка равенства параметров двух дочерних элементов
func _ch_par(param_name: String = "idx", idx_1: int = -1, idx_2: int = -2) -> bool:
	return main_scene.get_child(idx_1).get(param_name) == main_scene.get_child(idx_2).get(param_name)

# Открытие окна
func open_window(page: Pages, id: Variant = null, dir: Dirs = Dirs.WINDOWS, parent: Variant = null) -> void:
	add_new_child(main_scene, load("res://scenes/"+DB.enum_key(Global.Dirs, dir)+"/"+DB.enum_key(Pages, page)+".tscn"))
	if not _ch_inf(): main_scene.get_child(-1).set_page(id, page)
	if dir == Dirs.WINDOWS and id:
		if parent != null: main_scene.get_child(-1).set_from_page(id, parent)
		else: main_scene.get_child(-1).set_page(id)
	if main_scene.get_child_count() > 1 and _check_inf_page(): delete_child(main_scene, main_scene.get_child(-1))

# Получение родителя определенного уровня
func g_p(obj: Variant, level: int = 2, save_level: int = 1) -> Variant:
	return obj.get_parent() if level == save_level else g_p(obj.get_parent(), level, save_level + 1)
