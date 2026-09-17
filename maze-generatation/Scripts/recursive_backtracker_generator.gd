class_name RecursiveBacktrackerGenerator extends MazeAlgorithmBase

var stack: Array = []

func start() -> void:
	_reset_grid()
	stack = [[0, 0]]
	visited[0][0] = true
	current_row = 0
	current_col = 0
	last_backtrack = Vector2i(-1, -1)
	finished = false

func step() -> bool:
	if finished:
		return false
	if stack.is_empty():
		finished = true
		return false

	last_backtrack = Vector2i(-1, -1)
	var top: Array = stack[stack.size() - 1]
	var row: int = top[0]
	var col: int = top[1]
	var neighbors: Array = _unvisited_neighbors(row, col)

	if neighbors.size() > 0:
		var chosen: Dictionary
		if neighbors.size() == 1:
			chosen = neighbors[0]
		else:
			var r: int = _next_random()
			chosen = neighbors[r % neighbors.size()]
		_remove_wall(row, col, chosen["dir"], chosen["row"], chosen["col"])
		visited[chosen["row"]][chosen["col"]] = true
		stack.append([chosen["row"], chosen["col"]])
		current_row = chosen["row"]
		current_col = chosen["col"]
	else:
		stack.pop_back()
		last_backtrack = Vector2i(row, col)
		if not stack.is_empty():
			var new_top: Array = stack[stack.size() - 1]
			current_row = new_top[0]
			current_col = new_top[1]

	if stack.is_empty():
		finished = true
	return true
