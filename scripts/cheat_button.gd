extends Button

class_name CheatButton

var scale_target = Vector2(1, 1)

func _ready() -> void:
	self.mouse_entered.connect(entered)
	self.mouse_exited.connect(exited)

func entered():
	self.scale_target = Vector2(1.2, 1.2)
	
func exited():
	self.scale_target = Vector2(1, 1)
	
func _physics_process(delta: float) -> void:
	self.scale = lerp(scale, scale_target, 0.2)
