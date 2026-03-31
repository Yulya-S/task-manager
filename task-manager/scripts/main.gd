extends Node2D

# Связь глобального скрипта со сценой main
func _ready() -> void: Global.main_scene = self

# Закрытие БД во время закрытия приложения
func _notification(what: int) -> void:
	if DB.db and what == Window.NOTIFICATION_WM_CLOSE_REQUEST:
		DB.db.close_db()
		DB.db = null
