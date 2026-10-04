extends Node2D

class_name Cutscene

@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect
@onready var dialogue_box: DialogueBox = $VBoxContainer/PanelContainer/DialogueBox2

var slides: Array[Dictionary] = [
	{"texture": preload("res://assets/art/cutscenes/s1.PNG"), "text": "You’ve been drifting around as a caddy around the course until you caught wind of a certain rumour…"},
	{"texture": preload("res://assets/art/cutscenes/s2.PNG"), "text": "The VoleIPs, the ultimate prestigious golf club, has been recruiting for new talent…"},
	{"texture": preload("res://assets/art/cutscenes/s3.PNG"), "text": "The majority of the club wants respect and swag, but there was another incentive: free beetroot juice refills!"},
	{"texture": preload("res://assets/art/cutscenes/e_sus.PNG"), "text": "You got reported for criminal mischief, fraud, property damage, and breaking laws of gravity? Maybe cheating won’t get you through this one, get a lawyer instead."},
	#{"texture": preload("res://assets/art/cutscenes/e_embarrass.PNG"), "text": "After embarrassing yourself with diabolical excuses and strokes the developers can’t even account for edge cases for, you got fired as a caddy. Maybe try a career as a casino dealer instead?"},
	#{"texture": preload("res://assets/art/cutscenes/e_win.PNG"), "text": "After your match with the VoleIP, she officially invited you to the club. Once you got your greedy paws on the juice fountain, the VoleIP stopped you: “just so you know, there’s a membership fee of 10 beetroots a month”. Welp, it’s time to cheat through your payments too."}
]

func play_cutscene() -> void:
	show()
	for slide in slides:
		texture_rect.texture = slide["texture"]
		await dialogue_box.play_paragraphs("narrator", [slide["text"]], false)
	hide()
