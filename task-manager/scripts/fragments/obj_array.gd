extends ScrollContainer
# Подключение пути к объекту в сцене
@onready var Objects = $Objects
# Экспортируемые переменные
@export var obj: DB.Tables = DB.Tables.TASKS # Выбранный объект списка
@export var first_line: bool = true # Будет ли создан заголовок списка
# Переменная объекта для создания строк списка
var lines: Array = [] # Список для создания
var path: Resource = null # Путь к сцене объекта для создания

# Применение размера VBoxContainer
func _ready() -> void:
	path = load("res://scenes/fragments/list_elements/"+DB.enum_key(DB.Tables, obj).left(-1)+".tscn")
	if not first_line: Objects.alignment = VBoxContainer.ALIGNMENT_END
	update_data()

# Динамическое заполнение страницы
func _process(_delta: float) -> void:
	if len(lines) > 0: Global.add_new_child(Objects, path, [lines.pop_front()])

# Изменение размера контейнера
func set_container_size(new_size: Vector2) -> void:
	Objects.custom_minimum_size = new_size
	size = new_size

# Получение количества объектов
func obj_count() -> int: return Objects.get_child_count() - 1

# Получение данных для списка
func update_data(filter: Variant = {}) -> void:
	Global.clear_scene(Objects)
	Objects.add_child(path.instantiate())
	lines = DB.match_select(obj, Global.get_filter(filter))
