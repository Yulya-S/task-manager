extends Control
class_name InteractiveObj
# Переменная
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта

# Под проверка возможности обработки нажатия на объект
func _other_check() -> bool: return false

# Функция запускаемая при нажатии на объект
func _start_func() -> void: return

# Обработка нажатия
func _input(event: InputEvent) -> void:
	if state == Global.MouseOver.NORMAL or _other_check(): return
	if event.is_action("click") and event.is_pressed(): _start_func()

# Обработка наведения мыши
func _on_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_mouse_exited() -> void: state = Global.MouseOver.NORMAL
