extends Control
class_name Windows
# Подключение пути к объекту в сцене
@onready var Error = get_child(0).get_child(2)
# Экспортируемая переменная
@export var page_type: Global.Pages = Global.Pages.PROJECTS # Тип создаваемого / Изменяемого объекта
# Переменная
var idx: int = 0 # Индекс изменяемого объекта

# Применение цветовой палитры окна
func _ready() -> void:
	Global.set_color_and_lang(self)
	if Global.current_page == Global.Pages.TASKS:
		Global.fill_optionButton($Project_id, DB.select("* FROM projects"))
		Global.fill_optionButton($Section_is, DB.select("* FROM sections"))

# Обновление данных на сранице с родительской страницы
func set_from_page(obj_idx: int) -> void:
	pass
	#_on_section_id_item_selected(obj_idx)

# Обновление данных на странице
func set_page(new_idx: int) -> void:
	var data: Dictionary = DB.select_all(page_type, "id="+str(new_idx))[0]
	if data == {}:
		_window().on_close_button_down()
		return
	idx = new_idx
	_window().Delete.visible = true
	for i in get_children():
		match i.get_class():
			"TextEdit": i.set_text(str(data[i.name.to_lower()]))
			"CheckButton":
				i.button_pressed = data[i.name.to_lower()]
				_on_completed_toggled(data[i.name.to_lower()])
			"OptionButton":
				if "id" in i.name.to_lower():
					if data[i.name.to_lower()] == null:
						if i.name.to_lower() != "wallet_id": continue
						_window().on_close_button_down()
						return
					data[i.name.to_lower()] = i.get_item_index(data[i.name.to_lower()])
				if get(_create_func_name(i)): call(_create_func_name(i), data[i.name.to_lower()])
				else: i.selected = data[i.name.to_lower()]
		if i.name == "Date": i.set_date(data[i.name.to_lower()])

# Получение пути к Window
func _window() -> Node: return get_child(0)

# Сборка имени функции
func _create_func_name(obj: Variant) -> String: return "_on_" + obj.name.to_lower() + "_item_selected"

# Получение значений со страницы
func get_values() -> Array:
	var values: Array = []
	for i in get_children():
		match i.get_class():
			"CheckButton": values.append(str(i.button_pressed))
			"OptionButton": values.append(str(Global.get_OB_id(i)))
			"TextEdit":
				values.append(i.get_text())
				if "title" in i.name.to_lower(): values[-1] = '"'+values[-1]+'"'
			_: if i.name == "Date": values.append('"'+i.get_date()+'"')
	return values

# Проверка верности заполнения полей
func check_object() -> bool:
	Error.clear()
	if Error.check($Title): return false
	if page_type != Global.Pages.TASKS:
		if not DB.check_obj(page_type as DB.Tables, $Title.get_text(), idx):
			return Error.set_state(Error.States._E4)
	return false

# Обработка нажатий кнопок
# Переключатель
func _on_completed_toggled(toggled_on: bool) -> void: $State.set_text(File.lang["__ST"+str(int(toggled_on) + 1)])
