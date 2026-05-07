class_name UpgradeResource
extends Resource

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var max_upgrade_count: int = 1

@export var peer_conditions: Array[PeerConditionManager.PeerCondition]
