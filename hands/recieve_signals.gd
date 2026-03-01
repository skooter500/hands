extends Node

func _ready() -> void:
	$"../label".text = str($"../on_off".state)
	$"../label2".text = str($"../toggle".state)

func _on_button_1_value_changed(new_value:bool) -> void:
	$"../label".text = str(new_value)
	pass # Replace with function body.


func _on_button_2_value_changed(new_value: bool) -> void:
	$"../label2".text = str(new_value)
	pass # Replace with function body.
