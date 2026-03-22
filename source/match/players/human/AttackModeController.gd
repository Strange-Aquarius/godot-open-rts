extends Node

signal attack_mode_toggled(is_active)
signal attack_target_selected(position)

var attack_mode_active: bool = false:
	set(value):
		attack_mode_active = value
		attack_mode_toggled.emit(attack_mode_active)
		_update_cursor()


func _ready():
	set_process_unhandled_input(true)


func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_A and event.pressed:
		toggle_attack_mode()
		get_viewport().set_input_as_handled()
	
	if attack_mode_active and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_attack_click(event.position)
			get_viewport().set_input_as_handled()


func toggle_attack_mode():
	attack_mode_active = not attack_mode_active


func _handle_attack_click(mouse_position: Vector2):
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_direction = camera.project_ray_normal(mouse_position)
	var plane = Plane(Vector3.UP, 0)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	
	if intersection:
		attack_target_selected.emit(intersection as Vector3)
		attack_mode_active = false


func _update_cursor():
	if attack_mode_active:
		Input.set_custom_mouse_cursor(null)
	else:
		Input.set_custom_mouse_cursor(null)
