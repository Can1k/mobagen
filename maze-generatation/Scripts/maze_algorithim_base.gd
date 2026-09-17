class_name MazeAlgorithmBase extends RefCounted

enum Dir { UP, RIGHT, DOWN, LEFT }

const RANDOM_NUMBERS: PackedByteArray = [
	72, 99, 56, 34, 43, 62, 31, 4, 70, 22,
	6, 65, 96, 71, 29, 9, 98, 41, 90, 7,
	30, 3, 97, 49, 63, 88, 47, 82, 91, 54,
	74, 2, 86, 14, 58, 35, 89, 11, 10, 60,
	28, 21, 52, 50, 55, 69, 76, 94, 23, 66,
	15, 57, 44, 18, 67, 5, 24, 33, 77, 53,
	51, 59, 20, 42, 80, 61, 1, 0, 38, 64,
	45, 92, 46, 79, 93, 95, 37, 40, 83, 13,
	12, 78, 75, 73, 84, 81, 8, 32, 27, 19,
	87, 85, 16, 25, 17, 68, 26, 39, 48, 36,
]

var cols: int
var lines: int
var rng_index: int

## wall_*[row][col] == true means the wall is present (closed)
var wall_north: Array = []
var wall_south: Array = []
var wall_east: Array = []
var wall_west: Array = []
var visited: Array = []

var current_row: int = 0
var current_col: int = 0

var last_backtrack: Vector2i = Vector2i(-1, -1)
var finished: bool = false

func _init(p_cols: int, p_lines: int, p_start_index: int) -> void:
	cols = p_cols
	lines = p_lines
	rng_index = ((p_start_index % 100) + 100) % 100
	_reset_grid()

func _reset_grid() -> void:
	wall_north.clear()
	wall_south.clear()
	wall_east.clear()
	wall_west.clear()
	visited.clear()
	for r in range(lines):
		var n_row: Array = []
		var s_row: Array = []
		var e_row: Array = []
		var w_row: Array = []
		var v_row: Array = []
		for c in range(cols):
			n_row.append(true)
			s_row.append(true)
			e_row.append(true)
			w_row.append(true)
			v_row.append(false)
		wall_north.append(n_row)
		wall_south.append(s_row)
		wall_east.append(e_row)
		wall_west.append(w_row)
		visited.append(v_row)

func _next_random() -> int:
	var value: int = RANDOM_NUMBERS[rng_index]
	rng_index += 1
	if rng_index > 99:
		rng_index = 0
	return value

func _remove_wall(row: int, col: int, dir: int, n_row: int, n_col: int) -> void:
	match dir:
		Dir.UP:
			wall_north[row][col] = false
			wall_south[n_row][n_col] = false
		Dir.DOWN:
			wall_south[row][col] = false
			wall_north[n_row][n_col] = false
		Dir.RIGHT:
			wall_east[row][col] = false
			wall_west[n_row][n_col] = false
		Dir.LEFT:
			wall_west[row][col] = false
			wall_east[n_row][n_col] = false

## Unvisited, in-bounds neighbors of (row, col), sorted clockwise
func _unvisited_neighbors(row: int, col: int) -> Array:
	var result: Array = []
	if row > 0 and not visited[row - 1][col]:
		result.append({"dir": Dir.UP, "row": row - 1, "col": col})
	if col < cols - 1 and not visited[row][col + 1]:
		result.append({"dir": Dir.RIGHT, "row": row, "col": col + 1})
	if row < lines - 1 and not visited[row + 1][col]:
		result.append({"dir": Dir.DOWN, "row": row + 1, "col": col})
	if col > 0 and not visited[row][col - 1]:
		result.append({"dir": Dir.LEFT, "row": row, "col": col - 1})
	return result

## Visited, in-bounds neighbors of (row, col), same clockwise order.
func _visited_neighbors(row: int, col: int) -> Array:
	var result: Array = []
	if row > 0 and visited[row - 1][col]:
		result.append({"dir": Dir.UP, "row": row - 1, "col": col})
	if col < cols - 1 and visited[row][col + 1]:
		result.append({"dir": Dir.RIGHT, "row": row, "col": col + 1})
	if row < lines - 1 and visited[row + 1][col]:
		result.append({"dir": Dir.DOWN, "row": row + 1, "col": col})
	if col > 0 and visited[row][col - 1]:
		result.append({"dir": Dir.LEFT, "row": row, "col": col - 1})
	return result

## Override: reset state and mark the starting cell.
func start() -> void:
	push_error("MazeAlgorithmBase.start() must be overridden")

## Override: advance generation by exactly one move. Return false
## once generation is complete.
func step() -> bool:
	push_error("MazeAlgorithmBase.step() must be overridden")
	return false

## Runs the whole generation instantly.
func generate() -> void:
	start()
	while step():
		pass
