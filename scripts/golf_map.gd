extends GridMap

class_name GolfMap

func get_hole_position():
	return self.get_used_cells_by_item(6)[0] # id of hole
