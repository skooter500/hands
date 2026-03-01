extends AnimationPlayer


func _ready() -> void:
	play("Idle")

func _on_animation_finished(anim_name: StringName) -> void:
	play("Idle")
	pass # Replace with function body.
