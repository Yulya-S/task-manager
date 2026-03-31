extends ColorRect

# Изменение данных в шапке
func _ready() -> void:
	$Login.set_text(File.show_data(File.config.login))
	$Marker.position.x = 45. * Global.current_page + 2.5

# Переход по страницам
func _on_pages_button_down(page_idx: int) -> void:
	if page_idx >= 2: Global.open_new_page(page_idx as Global.Pages)
	else: Global.open_window(page_idx as Global.Pages, null, Global.Dirs.PAGES)

# Выход из аккаунта
func _on_exit_button_down() -> void:
	File.clear_config()
	DB.connection_user_db()
	Global.open_new_page(Global.Pages.REGISTRATION)
