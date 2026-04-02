extends ColorRect
class_name ListElement

# Изменение размера контейнера по размеру родителя
func _ready() -> void:
	custom_minimum_size[0] = Global.g_p(self).size[0]
	_set_line_size()
	Global.set_color_and_lang(self)

# Получение имени строки со словом id
func _name_id(obj: Variant) -> String: return obj.name.to_lower().split("title")[0]+"id"

# Изменение высоты строки списка
func _set_line_size() -> void:
	var max_count: int = 1
	var front_size: int = 16
	for i in get_children(): if i is Label: if i.get_line_count() > max_count:
		max_count = i.get_line_count() 
		front_size = i.get_theme_font_size("front_size")
	custom_minimum_size[1] = max_count * front_size + ((max_count - 1) * 2) + 10.
	for i in get_children(): if i.get("size"): i.size[1] = custom_minimum_size[1]

# Изменение значений в сцене
func set_values(data: Dictionary) -> void:
	for i in get_children():
		if i.name.to_lower() not in data.keys(): continue # Отмена применения значения
		# Применение значений
		if "title" not in i.name.to_lower() or not i.get("set_object"):
			i.set_text(str(data[i.name.to_lower()]))
		else:
			if _name_id(i) in data.keys():
				if data[_name_id(i)]: i.set_object(data[i.name.to_lower()],  data[_name_id(i)])
				elif data[i.name.to_lower()] == null: i.set_text("-")
	match scene_file_path.split("/")[-1].replace(".tscn", ""):
		_: $StateLabel.set_obj(data.state)
	File.set_lang(self)
	_set_line_size()
