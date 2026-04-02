extends Control
class_name Page
# Подключение путей к объектам в сцене
@onready var Objects = get_node_or_null("ObjArray")
@onready var Filter = get_node_or_null("Filter")

# Подключение сигнала
func _ready() -> void:
	if Global.current_page > Global.Pages.PROJECTS: Filter.set_OB_items(Global.Pages.PROJECTS)
	if Global.current_page == Global.Pages.TASKS: Filter.set_OB_items(Global.Pages.SECTIONS)
	Global.connect("update_page", Callable(self, "_update_page"))
	_update_page()

# Получение данных фильтра
func _get_filter() -> Array: return [Filter]

# Запуск обновления данных на странице
func _update_page() -> void:
	Global.set_color_and_lang(self)
	update_data()

# Обновление данных
func update_data(obj: Variant = self) -> void:
	if obj != self: Global.run_func(obj, "update_data", _get_filter())
	for i in obj.get_children(): update_data(i)

# Нажатие кнопки создания объекта
func _on_add_button_down() -> void: Global.open_window(Global.Pages.get(name.to_upper()))
