extends Control

var main_scene: PackedScene = preload("uid://itf38p6njb0r")

@onready var single_player_button: Button = %SinglePlayerButton
@onready var multiplayer_button: Button = %MultiplayerButton
@onready var quit_button: Button = %QuitButton
@onready var options_button: Button = %OptionsButton

@onready var multiplayer_menu_scene: PackedScene = load("uid://clr5tgeiffx7s")

var options_menu_scene: PackedScene = preload("uid://bwyoghsoipp5l")

func _ready() -> void:
	single_player_button.pressed.connect(_on_single_player_btn_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_btn_pressed)
	quit_button.pressed.connect(_on_quit_btn_pressed)
	options_button.pressed.connect(_on_options_pressed)
	
	UIAudioManager.instance.register_buttons([
		single_player_button,
		multiplayer_button,
		quit_button,
		options_button
	])
	
func _on_single_player_btn_pressed():
	get_tree().change_scene_to_packed(main_scene)
	
func _on_multiplayer_btn_pressed():
	get_tree().change_scene_to_packed(multiplayer_menu_scene)
	
func _on_quit_btn_pressed():
	get_tree().quit()
	
func _on_options_pressed():
	var options_menu := options_menu_scene.instantiate()
	add_child(options_menu)
