## Cat AI: run toward the border along the shortest open route.
##
## 1. A* finds the shortest path to the border (also drawn as the debug path).
## 2. Among the neighbors that keep the cat on a shortest route, it prefers
##    the one with the most distinct shortest escape routes, since a single
##    block from the catcher can't cut all of them.
## 3. If no exit exists, it moves to the neighbor with the most room so it
##    survives as long as possible.
extends RefCounted

const Board = preload("res://scripts/board.gd")
const PathFinding = preload("res://scripts/pathfinding.gd")

var last_path: Array = []


func choose_move(board) -> Vector2i:
	last_path = PathFinding.find_path_to_border(board, board.cat)
	var options: Array = board.free_neighbors(board.cat)
	if options.is_empty():
		return board.cat

	for n in options:
		if board.is_border(n):
			last_path = [n]
			return n

	if last_path.is_empty():
		return _survive(board, options)

	var best_move: Vector2i = last_path[0]
	var best_dist := PathFinding.UNREACHABLE
	var best_routes := -1
	var original: Vector2i = board.cat
	for n in options:
		board.cat = n
		var stats := PathFinding.escape_stats(board)
		board.cat = original
		var d: int = stats.distance
		var r: int = stats.routes
		if d < best_dist or (d == best_dist and r > best_routes):
			best_dist = d
			best_routes = r
			best_move = n
	# Keep the debug path consistent with the move we actually picked.
	if last_path[0] != best_move:
		board.cat = best_move
		var rest := PathFinding.find_path_to_border(board, best_move)
		board.cat = original
		last_path = [best_move] + rest
	return best_move


func _survive(board, options: Array) -> Vector2i:
	var best: Vector2i = options[0]
	var best_area := -1
	for n in options:
		var area := PathFinding.reachable_area(board, n, board.cat)
		if area > best_area:
			best_area = area
			best = n
	return best
