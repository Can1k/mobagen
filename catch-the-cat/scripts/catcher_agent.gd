extends RefCounted

const Board = preload("res://scripts/board.gd")
const PathFinding = preload("res://scripts/pathfinding.gd")

var last_candidates: Array = []   # for the debug overlay


func choose_move(board) -> Vector2i:
	last_candidates.clear()
	var stats := PathFinding.escape_stats(board)

	if stats.distance == PathFinding.UNREACHABLE:
		return _tighten(board)

	var from_cat := PathFinding.bfs_distances(board, [board.cat])
	var from_border := PathFinding.bfs_distances(board, PathFinding.border_cells(board))
	var shortest: int = stats.distance

	for c in from_cat:
		if c == board.cat or not from_border.has(c):
			continue
		if from_cat[c] + from_border[c] == shortest:
			last_candidates.append(c)

	var best: Vector2i = last_candidates[0]
	var best_score := [-1, 0, 0]
	for c in last_candidates:
		var after := PathFinding.escape_stats(board, c)
		var d: int = after.distance
		var r: int = after.routes
		var score := [d, -r, from_cat[c]]
		if _greater(score, best_score):
			best_score = score
			best = c
	return best


func _tighten(board) -> Vector2i:
	var options: Array = board.free_neighbors(board.cat)
	if options.is_empty():
		return _any_free_cell(board)   # game should already be over
	var best: Vector2i = options[0]
	var best_area := -1
	for n in options:
		var area := PathFinding.reachable_area(board, n, board.cat)
		if area > best_area:
			best_area = area
			best = n
	return best


func _any_free_cell(board) -> Vector2i:
	for c in board.all_cells():
		if board.can_block(c):
			return c
	return board.cat


static func _greater(a: Array, b: Array) -> bool:
	for i in a.size():
		if a[i] != b[i]:
			return a[i] > b[i]
	return false
