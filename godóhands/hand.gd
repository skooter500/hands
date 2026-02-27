extends XRNode3D

var gesture:String


func _on_hand_pose_detector_pose_started(p_name: String) -> void:
	gesture = p_name
	pass # Replace with function body.


func _on_hand_pose_detector_pose_ended(p_name: String) -> void:
	gesture = ""
	pass # Replace with function body.
