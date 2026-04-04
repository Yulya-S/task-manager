extends PageWindow
# Переменные
var idx: int = 0  # Индекс выбранной подсказки
@onready var count: int = len(File.lang._Hints) # Количество подсказок

# Применение перевода
func _ready() -> void:
	File.set_lang(self)
	$Idx/Count.set_text(str(count))
	_set_hint()

# Изменение значения подсказки
func _set_hint() -> void:
	$Idx.set_text(str(idx + 1))
	$Label.set_text(File.lang._Hints[idx])
	_match_marker()

# Изменение размера и расположения маркера подсказки
func _set_marker(x: float, y: float, w: float, h: float, img_idx: int = 2) -> void:
	$AnimatedSprite2D.frame = img_idx
	$Marker.position = Vector2(x, y)
	$Marker.size = Vector2(w, h)

# Определение расположения и размера маркера
func _match_marker() -> void:
	match idx:
		0: _set_marker(808, 64, 107, 31, 0)
		1: _set_marker(391, 177, 309, 82, 0)
		2: _set_marker(338, 298, 462, 39, 0)
		3: _set_marker(697, 231, 114, 24, 0)
		4: _set_marker(606, 263, 100, 21, 0)
		5: _set_marker(324, 59, 41, 38)
		6: _set_marker(225, 90, 41, 38)
		7: _set_marker(222, 208, 266, 27)
		8: _set_marker(837, 209, 86, 79)
		9: _set_marker(243, 59, 41, 38)
		10: _set_marker(0, 0, 0, 0, 1)
		11: _set_marker(275, 152, 402, 38, 1)
		12: _set_marker(368, 123, 161, 26, 1)
		13: _set_marker(275, 152, 402, 38, 1)
		14: _set_marker(251, 223, 639, 173, 1)
		15: _set_marker(311, 403, 202, 40, 1)
		16: _set_marker(624, 403, 202, 40, 1)
		17: _set_marker(270, 59, 41, 38, 3)
		18: _set_marker(844, 180, 72, 22, 3)
		19: _set_marker(224, 180, 119, 22, 3)
		20: _set_marker(216, 155, 704, 101, 5)
		21: _set_marker(306, 422, 612, 37, 5)
		22: _set_marker(693, 126, 218, 30, 5)
		23: _set_marker(253, 91, 65, 38, 5)
		24: _set_marker(225, 91, 41, 38, 5)
		25: _set_marker(298, 59, 41, 38, 4)
		26: _set_marker(298, 59, 41, 38, 4)
		27: _set_marker(224, 217, 113, 23, 4)
		28: _set_marker(880, 59, 41, 38, 4)

# Смена подсказки
# Следующая
func _on_next_button_down() -> void:
	idx += 1
	if idx >= count: idx = 0
	_set_hint()

# Предыдущая
func _on_last_button_down() -> void:
	idx -= 1
	if idx < 0: idx = count - 1
	_set_hint()
