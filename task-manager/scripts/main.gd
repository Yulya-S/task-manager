extends Node2D

# Связь глобального скрипта со сценой main
func _ready() -> void: Global.main_scene = self

# Закрытие БД во время закрытия приложения
func _notification(what: int) -> void:
	if DB.db and what == Window.NOTIFICATION_WM_CLOSE_REQUEST:
		DB.db.close_db()
		DB.db = null

# Проверка закрытия окна информации при удалении объекта
func close_inf_page() -> void: if get_child(-1).name == "Project": get_child(-2)._on_back_button_down()
