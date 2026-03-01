extends Node

@onready var player: AudioStreamPlayer = $"../AudioStreamPlayer"
var playback: AudioStreamGeneratorPlayback

var is_recording := false
var recorded_frames: PackedVector2Array = []

func _ready() -> void:
	$"../label".text = str($"../on_off".state)
	$"../label2".text = str($"../toggle".state)
	
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = AudioServer.get_input_mix_rate()
	gen.buffer_length = 0.1
	player.stream = gen
	player.play()
	playback = player.get_stream_playback()
	AudioServer.set_input_device_active(true)

func _on_button_1_value_changed(new_value:bool) -> void:
	$"../label".text = str(new_value)
	pass # Replace with function body.


func _on_button_2_value_changed(new_value: bool) -> void:
	$"../label2".text = str(new_value)
	pass # Replace with function body.



func _process(_delta):
	var available = AudioServer.get_input_frames_available()
	if available > 0:
		var frames = AudioServer.get_input_frames(available)
		
		# Uncomment to hear the mic
		# playback.push_buffer(frames)
		if is_recording:
			recorded_frames.append_array(frames)

var wav: AudioStreamWAV = null

var _bake_thread: Thread = null

func _on_record_value_changed(new_value: bool) -> void:
	if new_value:
		recorded_frames.clear()
		wav = null
		is_recording = true
	else:
		is_recording = false
		_bake_thread = Thread.new()
		_bake_thread.start(_bake_wav)
	$"../label7".text = "RECORDING..." if is_recording else "RECORD"

func _bake_wav() -> void:
	if recorded_frames.is_empty():
		return
	var mix_rate = AudioServer.get_input_mix_rate()
	var new_wav = AudioStreamWAV.new()
	new_wav.mix_rate = mix_rate
	new_wav.stereo = true
	new_wav.format = AudioStreamWAV.FORMAT_16_BITS
	var byte_array = PackedByteArray()
	byte_array.resize(recorded_frames.size() * 4)
	for i in recorded_frames.size():
		var left  = int(clamp(recorded_frames[i].x, -1.0, 1.0) * 32767)
		var right = int(clamp(recorded_frames[i].y, -1.0, 1.0) * 32767)
		byte_array.encode_s16(i * 4,     left)
		byte_array.encode_s16(i * 4 + 2, right)
	new_wav.data = byte_array
	wav = new_wav

func _on_play_value_changed(new_value: bool) -> void:
	if new_value and wav != null:
		if _bake_thread and _bake_thread.is_alive():
			_bake_thread.wait_to_finish()
		var pb_player = AudioStreamPlayer.new()
		add_child(pb_player)
		pb_player.stream = wav
		pb_player.play()
		pb_player.finished.connect(pb_player.queue_free)
