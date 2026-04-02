extends ColorRect
# Подключение пути к объекту в сцене
@onready var Delete = $Delete

# Запуск действий в бд
func _run_action(action_type: DB.ActionTypes) -> void:
	DB.match_actions(action_type, get_parent().page_type, str(get_parent().idx), get_parent().get_values())

# Обработки нажатия кнопок
# Отмена
func on_close_button_down() -> void:
	Global.delete_child(Global.g_p(self), get_parent())

# Сохранение / изменение
func _on_apply_button_down() -> void:
	if not get_parent().check_object(): return
	if get_parent().idx == 0: _run_action(DB.ActionTypes.INSERT)
	else: _run_action(DB.ActionTypes.UPDATE)
	_apply_changes()

# Удаление
func _on_delete_button_down() -> void: $ConfirmationDialog.visible = true

# Изменение объекта
func _apply_changes() -> void:
	Global.emit_signal("update_page")
	on_close_button_down()

# Подтверждение удаления объекта
func _on_confirmation_dialog_confirmed() -> void:
	_run_action(DB.ActionTypes.DELETE)
	Global.g_p(self).close_inf_page()
	_apply_changes()
