extends ColorRect
class_name PageWindow

# Обработка нажатия кнопки закрытия окна
func _on_close_button_down() -> void:
	Global.delete_child(get_parent(), self)
	ColorScheme.color_reading()
	Global.emit_signal("update_page")
