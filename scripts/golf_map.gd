extends GridMap

class_name GolfMap
@export var par_count = 0

func get_hole_position():
	return self.get_used_cells_by_item(6)[0] # id of hole
