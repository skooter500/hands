class_name HoloButton

extends Area3D

var in_color:Color
var out_color:Color

enum BType {IN_OUT, TOGGLE}

@export var behavior:BType = BType.IN_OUT

@export var state = false

signal value_changed(new_value:bool)

func _ready() -> void:
	in_color = Color.from_hsv(randf(), 1, 1, 0.5)
	out_color = Color.from_hsv(fmod(in_color.h + 0.5, 1.0), 1, 1, 0.5)	
	var mat = $MeshInstance3D.get_surface_override_material(0)
	mat = mat.duplicate()
	mat.albedo_color = out_color
	$MeshInstance3D.set_surface_override_material(0, mat)	

func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
		
	if behavior == BType.IN_OUT:
		$MeshInstance3D.get_surface_override_material(0).albedo_color = in_color 
		state = true
		value_changed.emit(state)
	elif behavior == BType.TOGGLE:
		if ! state:
			state = true
			value_changed.emit(state)
			$MeshInstance3D.get_surface_override_material(0).albedo_color = in_color 
		else:
			state = false
			value_changed.emit(state)

			$MeshInstance3D.get_surface_override_material(0).albedo_color = out_color 

	pass # Replace with function body.


func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	if behavior == BType.IN_OUT:
		$MeshInstance3D.get_surface_override_material(0).albedo_color = out_color	
		state = false
		value_changed.emit(state)

	pass # Replace with function body.
