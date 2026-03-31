extends ColorRect

func _ready() -> void:
	$Login.set_text(File.show_data(File.config.login))
	$Marker.position.x = 45. * Global.current_page + 2.5
	#update_date()
