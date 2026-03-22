extends "res://source/match/players/Player.gd"

@onready var _attack_mode_controller = find_child("AttackModeController")
@onready var _unit_actions_controller = find_child("UnitActionsController")


func _ready():
	if _attack_mode_controller:
		_attack_mode_controller.attack_target_selected.connect(_on_attack_target_selected)


func _on_attack_target_selected(position: Vector3):
	if _unit_actions_controller:
		_unit_actions_controller._try_attacking_selected_units_towards_position(position)
