extends ColorRect
# Экспортируемые переменные
@export var OB_items: Dictionary = {} # Дополнительные фильтры
@export var title_pref: String = "" # Приставка для запроса по названию
# Переменные
var filter: Dictionary = _get_empty_filter() # Параметры запроса фильтрации
var order_item_texts: Array = [] # Список параметров сортировки

# Стартовое заполнение фильтров времени
func _ready() -> void:
	if get_node("Order") and len(order_item_texts) == 0:
		for l in range(get_node("Order").get_item_count()):
			order_item_texts.append(get_node("Order").get_item_text(l))

# Применение значений фильтра
func set_filter(obj: Variant, value: int) -> void: obj.selected = value

# Заполнение выпадающего списка в фильтре
func set_OB_items(table: DB.Tables) -> void:
	var node_name: String = Global.enum_key(DB.Tables, table)
	var node: OptionButton = get_node(node_name[0].to_upper() + node_name.substr(1, len(node_name)-2))
	node.clear()
	node.add_item("", 0)
	File.fill_optionButton(node, DB.select_all(table), false)

# Изменение значения фильтра
func _update_value(obj: Variant, value_name: String, sep: String) -> void:
	if filter[value_name] != "": filter[value_name] += sep
	filter[value_name] += OB_items[obj.name][str(obj.selected)]

# Получение пустого фильтра
func _get_empty_filter() -> Dictionary: return {"where": "", "order": ""}

# Сборка фильтра
func get_filter() -> Dictionary:
	filter = _get_empty_filter()
	for i in get_children():
		if "OR" in filter.where.split("AND")[-1] and filter.where[-1] != ")":
			filter.where = "("+filter.where+")"
		match i.name:
			"Title": filter.where = title_pref + 'title LIKE "%' + i.get_text() + '%"'
			"Button": continue
			_: _other_filters(i)
	return filter

# Обработка дополнительных фильтров
func _other_filters(obj: Variant) -> void:
	if obj.name not in OB_items.keys(): return
	# Фильтры с добавлением объектов
	if "section" in _get_keys(obj):
		if Global.call("get_OB_id", obj) == 0: return
		if filter.where != "": filter.where += " AND "
		filter.where += OB_items[obj.name].text.replace("__id__", str(Global.call("get_OB_id", obj)))
		return
	if str(obj.selected) not in _get_keys(obj): return
	if "filter" not in _get_keys(obj): _update_value(obj, "where", " AND ")
	else: _update_value(obj, "order", ", ")

# Получение списка ключей
func _get_keys(obj: Variant) -> Array: return OB_items[obj.name].keys()

# Сброс перевода способа сортировки
func reset_order() -> void:
	if $Order: for i in range($Order.get_item_count()): $Order.set_item_text(i, order_item_texts[i])

# Обработки нажатия кнопок
# Применение фильтра
func _on_button_button_down() -> void: Global.run_func(get_parent(), "update_data")

# Изменение значения текстового контейнера
func _on_title_text_changed() -> void: Global.text_changed_TextEdit($Title)
