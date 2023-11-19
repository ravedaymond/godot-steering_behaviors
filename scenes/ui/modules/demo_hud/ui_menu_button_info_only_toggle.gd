extends MenuButton

var popup_visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(popup_visible):
		get_popup().show()
	else:
		get_popup().hide()


func _on_pressed():
	popup_visible = !popup_visible
