extends Page
# Подключение пути к объекту в сцене
@onready var Title = $Filter/Title
# Переменная
var idx: int = 0 # Индекс выбранного объекта

# Применение значения индекса
func set_page(new_idx: int) -> void:
	idx = new_idx
	update_data()

# Получение данных фильтра
func _get_filter() -> Array: return [{"where": "p.id="+str(idx), "order": "id DESC"}]

# Обновление данных
func update_data(obj: Variant = self) -> void:
	if idx == 0: return
	var data: Dictionary = DB.select_all(DB.Tables.PROJECTS, "id="+str(idx))[0]
	Global.set_label_from_data(Title, data)
	if data.comment.strip_edges() != "": Title.tooltip_text = str(data.comment)
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

# Изменение состояния объекта
func update_state(new_state: int) -> void: DB.update_state(DB.Tables.PROJECTS, idx, new_state)

# Назад
func _on_back_button_down() -> void:
	Global.delete_child(get_parent(), self)
	idx = 0
	Global.emit_signal("update_page")

# Изменить
func _on_update_button_down() -> void: Global.open_window(Global.Pages.PROJECTS, idx)

# Создание задачи
func _on_add_task_button_down() -> void: Global.open_window(Global.Pages.TASKS, idx, Global.Dirs.WINDOWS, self)
