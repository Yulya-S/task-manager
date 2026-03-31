extends Control
# Экспортируемые переменные
@export var next_page: Global.Pages = Global.Pages.TASKS # Страниц перехода
@export var next_page_dir: Global.Dirs = Global.Dirs.PAGES # Директория перехода

# Переменная
var state: Global.MouseOver = Global.MouseOver.NORMAL # Текущее состояние объекта
var id: int = 0 # Индекс объекта

# Применение текстового значения и индекса целевого объекта
func set_object(new_text: String, new_id: int) -> void:
	set("text", new_text)
	id = new_id

# Обработка нажатия
func _input(event: InputEvent) -> void:
	if state == Global.MouseOver.NORMAL or not id: return
	if event.is_action("click") and event.is_pressed():
		if next_page_dir == Global.Dirs.PAGES: Global.open_new_page(next_page)
		else: Global.open_window(next_page, id, next_page_dir)

# Обработка наведения мыши
func _on_mouse_entered() -> void: state = Global.MouseOver.HOVER

func _on_mouse_exited() -> void: state = Global.MouseOver.NORMAL
