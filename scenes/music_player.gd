extends AudioStreamPlayer

class_name MusicPlayer


func play_song(song_name: String):
	get_stream_playback().switch_to_clip_by_name(song_name)
