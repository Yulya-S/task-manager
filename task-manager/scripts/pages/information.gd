extends Page
var idx: int = 0 # Индекс выбранного объекта

# Применение значения индекса
func set_page(new_idx: int) -> void:
	idx = new_idx
	update_data()

# Получение данных фильтра
func _get_filter() -> Array: return [{"where": "p.id="+str(idx)}]

# Обновление данных
func update_data(obj: Variant = self) -> void:
	if idx == 0: return
	var data: Dictionary = DB.select_all(DB.Tables.PROJECTS, "id="+str(idx))[0]
	Global.set_label_from_data($Filter/Title, data)
	if data.comment.strip_edges() != "": $Filter/Title.tooltip_text = str(data.comment)
	$Filter/Completed.set_obj(data.state)
	set_progress_bars()
	super.update_data(obj)

# Изменение шкал проекта
func set_progress_bars() -> void:
	var data: Dictionary = DB.select(DB.fragment_pregress_bar_data(), _get_filter()[0].where)[0]
	var sum: int = data.count + data.canceled + data.completed
	if sum > 0: for i in [$Total/Canceled, $Total/Completed]:
		i.max_value = sum
		i.value = data[i.name.to_lower()]

# Назад
func _on_back_button_down() -> void:
	Global.delete_child(get_parent(), self)
	idx = 0

# Изменить
func _on_update_button_down() -> void: Global.open_window(Global.Pages.PROJECTS, idx)
