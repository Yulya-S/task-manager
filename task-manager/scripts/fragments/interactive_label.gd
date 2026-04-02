extends InteractiveObj
# Экспортируемые переменные
@export var next_page: Global.Pages = Global.Pages.TASKS # Страниц перехода
@export var next_page_dir: Global.Dirs = Global.Dirs.PAGES # Директория перехода
# Переменная
var idx: int = 0 # Индекс объекта

# Применение текстового значения и индекса целевого объекта
func set_object(new_text: String, new_id: int) -> void:
	set("text", new_text)
	idx = new_id

# Функция запускаемая при нажатии на объект
func _start_func() -> void:
	if next_page_dir == Global.Dirs.PAGES: Global.open_new_page(next_page)
	else: Global.open_window(next_page, idx, Global.Dirs.WINDOWS)
