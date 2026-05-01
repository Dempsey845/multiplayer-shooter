extends Node

static var instance: UIAudioManager

@onready var button_stream_player: AudioStreamPlayer = $ButtonStreamPlayer

func _ready() -> void:
	instance = self

func register_buttons(buttons: Array):
	for button in buttons:
		button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	instance.button_stream_player.play()
