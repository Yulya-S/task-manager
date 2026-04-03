extends Node
# Сигналы
signal update_page(close_page: String) # Обновление данных на странице
# Перечисление
enum Dirs {PAGES, WINDOWS} # Директории объектов
enum Pages {HINTS, SETTINGS, PROJECTS, SECTIONS, TASKS, REGISTRATION, INFORMATION} # Страницы
enum MouseOver {NORMAL, HOVER}
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
func open_new_page(page: Pages) -> void:
	current_page = page
	for child in main_scene.get_children(): delete_child(main_scene, child)
	open_window(page, null, Dirs.PAGES)

# Открытие окна
func open_window(page: Pages, id: Variant = null, dir: Dirs = Dirs.WINDOWS, parent: Variant = null) -> void:
	add_new_child(main_scene, load("res://scenes/"+DB.enum_key(Global.Dirs, dir)+"/"+DB.enum_key(Pages, page)+".tscn"))
	if dir == Dirs.WINDOWS and id:
		if parent != null: main_scene.get_child(-1).set_from_page(id, parent)
		else: main_scene.get_child(-1).set_page(id)

# Получение родителя определенного уровня
func g_p(obj: Variant, level: int = 2, save_level: int = 1) -> Variant:
	return obj.get_parent() if level == save_level else g_p(obj.get_parent(), level, save_level + 1)

# Проверки для текстовых объектов
# Проверка что текст - это число
func text_is_number(text: String) -> bool:
	return text.is_valid_int() or text.is_valid_float()

# Преобразование текста в числовой формат
func _valide_numeric_text(text_container: TextEdit) -> void:
	var text: String = text_container.get_text()
	if len(text) > 0:
		# Удаление лишних точек дроби
		var text_copy: PackedStringArray = text.split(".")
		if len(text_copy) > 2:
			for i in range(1, len(text_copy) - 1, 1):
				text_copy[0] += text_copy[1]
				text_copy.remove_at(1)
		# Проверка что фрагменты текста, кроме одной точки является числами
		var filtered_text: Variant = []
		for i in text_copy:
			filtered_text.append("")
			for l in i: if l.is_valid_int(): filtered_text[-1] += l
		filtered_text = ".".join(filtered_text)
		# Проверка отличается ли результат от начального значения
		if filtered_text != text:
			var caret: int = text_container.get_caret_column()
			text_container.set_text(filtered_text)
			text_container.set_caret_column(caret - (len(text) - len(filtered_text)))

# Изменение текста в TextEdit
func text_changed_TextEdit(container: TextEdit, is_numeric: bool = false) -> void:
	var text: String = container.get_text()
	if is_numeric: _valide_numeric_text(container)
	if len(text) > 0 and ("\t" in text or "\n" in text):
		container.set_text(container.get_text().replace("\t", "").replace("\n", ""))
		if container.find_next_valid_focus(): container.find_next_valid_focus().grab_focus()

# Получение индекса выбранного элемента выпадающего списка
func get_OB_id(button: OptionButton) -> int: return button.get_item_id(button.selected)

# Получение текстового значения элемента выпадающего списка
func get_OB_text(button: OptionButton) -> String: return button.get_item_text(button.selected)

# Применить значение объекта выпадающего списка по его id
func set_OB_id(container: OptionButton, idx: int) -> void: container.selected = container.get_item_index(idx)

# Заполнение выпадающего списка объектами
func fill_optionButton(container: OptionButton, objects: Array, clear_OB: bool = true) -> void:
	if not container: return
	if clear_OB: container.clear()
	for i in objects: container.add_item(i.title, i.id)
	File.set_lang(container)

# Получение пустого фильтра
func _empty_filter() -> Dictionary: return {"where": "", "order": ""}

# Получение результата работы функции get_filter, на случай пустого фильтра
func get_filter(filter: Variant = {}) -> Dictionary:
	if filter is not Dictionary:
		if not filter.get("get_filter"): return _empty_filter()
		return filter.get_filter()
	var new_filter: Dictionary = _empty_filter()
	filter = filter.duplicate()
	for i in new_filter.keys(): if i not in filter.keys(): filter[i] = new_filter[i]
	return filter

# Применение цвета и перевода
func set_color_and_lang(obj: Variant) -> void:
	File.set_lang(obj)
	ColorScheme.repainting(obj)

# Проверка наличия ключа в данных и применение при наличии
func set_label_from_data(obj: Label, data: Dictionary) -> void:
	if obj.name.to_lower() in data.keys(): obj.set_text(str(data[obj.name.to_lower()]))

# Запуск поиска родителя с требуемой функцией
func find_parent_with_func(obj: Node, func_name: String, values: Array = []) -> void:
	while obj.name != "Main":
		if obj.get(func_name):
			obj.callv(func_name, values)
			break
		obj = obj.get_parent()
