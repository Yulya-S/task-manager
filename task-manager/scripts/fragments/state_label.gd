extends InteractiveObj
@export var states_count: int = 3 # Максимальное количество состаяний
var state_idx: int = 0 # Текущее состояние объекта

# Применение значения статуса
func set_obj(new_sate: int) -> void:
	state_idx = new_sate
	Global.run_func(self, "set_text", [File.lang["__ST" + str(state_idx + 1)]])
	if get_parent().get_node_or_null("Date"): get_parent().get_node("Date").visible = bool(state_idx)
	ColorScheme.new_font_color(self, [ColorScheme._get_sys_color(0), Color.FOREST_GREEN, Color.FIREBRICK][state_idx])

# Функция запускаемая при нажатии на объект
func _start_func() -> void:
	if get_parent().get("idx") == 0 or get_parent().get_node("Title").get("idx") == 0: return
	var new_state: int = state_idx + 1
	set_obj(0 if new_state >= states_count else new_state)
	Global.find_parent_with_func(self, "update_state", [state_idx])
	if get_parent().get_node("Date"):
		DB._update_record(DB.Tables.TASKS, ["date"], [DB.DB_date()], get_parent().get_node("Title").idx)
		get_parent().get_node("Date").set_text(DB.DB_date().replace('"', ""))
