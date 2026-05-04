class_name GameUI
extends CanvasLayer

@export var enemy_manager: EnemyManager
@export var lobby_manager: LobbyManager
@export var upgrade_manager: UpgradeManager

@onready var round_label: Label = %RoundLabel
@onready var timer_label: Label = %TimerLabel
@onready var health_progress_bar: ProgressBar = %HealthProgressBar
@onready var display_name_label: Label = %DisplayNameLabel

@onready var ready_label: Label = %ReadyLabel
@onready var not_ready_label: Label = %NotReadyLabel
@onready var ready_count_label: Label = %ReadyCountLabel
@onready var ready_up_container: VBoxContainer = %ReadyUpContainer
@onready var round_info_container: VBoxContainer = %RoundInfoContainer

@onready var players_upgrading_label: Label = $MarginContainer/PlayersUpgradingLabel

func _ready() -> void:
	enemy_manager.round_changed.connect(_on_round_changed)
	
	lobby_manager.self_peer_ready.connect(_on_self_peer_ready)
	lobby_manager.lobby_closed.connect(_on_lobby_closed)
	lobby_manager.peer_ready_states_changed.connect(_on_peer_ready_states_changed)
	
	var is_single_player := multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	
	ready_up_container.visible = not is_single_player
	round_info_container.visible = is_single_player
	
	ready_label.visible = false
	not_ready_label.visible = true
	
	players_upgrading_label.visible = false
	
	if is_multiplayer_authority():
		upgrade_manager.upgrades_started.connect(_on_upgrades_started)
		upgrade_manager.upgrade_selected.connect(_on_upgrade_selected)
		upgrade_manager.upgrades_completed.connect(_on_upgrades_completed)
		
		multiplayer.peer_connected.connect(_on_peer_connected)

func _process(_delta: float) -> void:
	timer_label.text = str(ceili(enemy_manager.get_round_time_remainding()))

func connect_player(player: Player):
	(func():
		if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
			display_name_label.text = "Player"
		else:
			display_name_label.text = player.display_name
		player.health_component.health_changed.connect(_on_health_changed)
		_on_health_changed(player.health_component.current_health,\
			player.health_component.max_health)
	).call_deferred()

func _on_round_changed(round_count: int):
	round_label.text = "Round %s" % round_count

func _on_health_changed(current_health: int, max_health: int):
	health_progress_bar.value = current_health / float(max_health) if max_health != 0 else 0.0

func _on_self_peer_ready():
	ready_label.visible = true
	not_ready_label.visible = false

func _on_lobby_closed():
	ready_up_container.visible = false
	round_info_container.visible = true

func _on_peer_ready_states_changed(ready_count: int, total_count: int):
	ready_count_label.text = "%s/%s READY" % [ready_count, total_count]

@rpc("authority", "call_local", "reliable")
func update_players_upgrading_label(peer_count: int):
	players_upgrading_label.visible = true
	
	if peer_count == 1:
		players_upgrading_label.text = "1 PLAYER IS UPGRADING"
	elif peer_count < 1:
		players_upgrading_label.visible = false
	else:
		players_upgrading_label.text = "%s PLAYERS UPGRADING" % peer_count
	
@rpc("authority", "call_local", "reliable")
func hide_players_upgrading_label():
	players_upgrading_label.visible = false

func _on_upgrades_started(peer_count: int):
	update_players_upgrading_label.rpc(peer_count)
	
func _on_upgrade_selected(peer_count: int):
	update_players_upgrading_label.rpc(peer_count)

func _on_upgrades_completed():
	hide_players_upgrading_label.rpc()
	
func _on_peer_connected(peer_id: int):
	var peers_upgrading := upgrade_manager.outstanding_peers_to_upgrade.size()
	if peers_upgrading > 0:
		update_players_upgrading_label.rpc_id(peer_id, peers_upgrading)
