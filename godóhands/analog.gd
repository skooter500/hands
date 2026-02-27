class_name Analog
extends Node3D

var hand: Node3D = null
var grab_offset: float = 0
var start_local: float = 0
var end_local: float = 0
var previous_value: float = 0

@export var value: float = 0
@export var height: float = 0.5
@export var min_value: float = 0
@export var max_value: float = 1
@export var round_value: bool = false
@export var title: String = "SLIDE ME" 

signal value_changed(new_value: float)

func _ready() -> void:
	# Set random color
	var c = Color.from_hsv(randf(), 1, 1, 0.5)
	if has_node("mesh"):
		var mat = $mesh.get_surface_override_material(0)
		if mat:
			mat = mat.duplicate()
			mat.albedo_color = c
			$mesh.set_surface_override_material(0, mat)
	
	# Set rod color if it exists
	if has_node("../rod"):
		var rod_mat = get_node("../rod").get_surface_override_material(0)
		if rod_mat:
			rod_mat = rod_mat.duplicate()
			rod_mat.albedo_color = c
			get_node("../rod").set_surface_override_material(0, rod_mat)
	
	# Use LOCAL position for constraints
	start_local = position.y
	end_local = position.y + height
	
	# Set initial position based on value
	var y = remap(value, min_value, max_value, start_local, end_local)
	position.y = y
	previous_value = value
	
	create_rod()

func create_rod():
	if has_node("rod"):
		var rod = get_node("rod")
		var y = start_local + (height / 2.0)
		rod.position.y = y
		rod.scale.y = height

func set_value(new_value: float):
	value = clamp(new_value, min_value, max_value)
	var y = remap(value, min_value, max_value, start_local, end_local)
	position.y = y
	previous_value = value
	update_label()

func _on_grab_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	
	# Find hand controller
	var node = area
	for i in range(5):
		if node.get_parent():
			node = node.get_parent()
		else:
			break
	hand = node
	
	# Calculate offset in PARENT'S local space
	var hand_local_y = get_parent().to_local(hand.global_position).y
	grab_offset = position.y - hand_local_y

func _on_grab_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	hand = null

func _process(delta: float) -> void:
	if hand:
		# Convert hand position to parent's local space
		var hand_local_y = get_parent().to_local(hand.global_position).y
		var new_y = hand_local_y + grab_offset
		position.y = clamp(new_y, start_local, end_local)
	
	# Update value based on LOCAL position
	value = remap(position.y, start_local, end_local, min_value, max_value)
	
	# Only emit signal when value actually changes
	if value != previous_value:
		value_changed.emit(value)
		previous_value = value
	
	update_label()

func update_label():
	if round_value:
		$grab/label.text = str(int(round(value)))
	else:
		$grab/label.text = "%.2f" % value
