extends Node2D

enum ButtonState {
	FREE,
	BLOCKED,
	CAT
}

@onready var tile := $Control/TextureButton
var state: ButtonState = ButtonState.FREE

func _on_texture_button_pressed() -> void:
	if state != ButtonState.CAT:
		state = ButtonState.BLOCKED
