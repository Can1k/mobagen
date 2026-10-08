## Shared path finding helpers used by both agents.
extends RefCounted

const PriorityQueue = preload("res://scripts/priority_queue.gd")
const Board = preload("res://scripts/board.gd")

const UNREACHABLE := 1 << 30


static func border_heuristic(board, p: Vector2i) -> int:
	return mini(board.half - absi(p.x), board.half - absi(p.y))


static func find_path_to_border(board, start: Vector2i) -> Array:
	if board.is_border(start):
		return []
	var frontier = PriorityQueue.new()
	var came_from := {start: start}     # unordered_map<Point2D, Point2D>
	var cost_so_far := {start: 0}       # unordered_map<Point2D, int>
	var closed := {}                    # unordered_set<Point2D>
	frontier.push(start, border_heuristic(board, start))

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop()
		if closed.has(current):
			continue
		closed[current] = true

		if board.is_border(current):
			return _rebuild_path(came_from, start, current)

		for next in Board.neighbors_of(current):
			if not board.is_walkable(next) or closed.has(next):
				continue
			var new_cost: int = cost_so_far[current] + 1
			if not cost_so_far.has(next) or new_cost < cost_so_far[next]:
				cost_so_far[next] = new_cost
				came_from[next] = current
				frontier.push(next, new_cost + border_heuristic(board, next))
	return []


static func _rebuild_path(came_from: Dictionary, start: Vector2i, goal: Vector2i) -> Array:
	var path := []
	var p := goal
	while p != start:
		path.push_front(p)
		p = came_from[p]
	return path


## Multi-source BFS over walkable cells. Returns Vector2i -> distance.
static func bfs_distances(board, sources: Array, extra_blocked := Vector2i(1 << 20, 0)) -> Dictionary:
	var dist := {}
	var queue := []
	for s in sources:
		if s != extra_blocked and not dist.has(s):
			dist[s] = 0
			queue.append(s)
	var head := 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		for n in Board.neighbors_of(cur):
			if dist.has(n) or n == extra_blocked or not board.is_walkable(n):
				continue
			dist[n] = dist[cur] + 1
			queue.append(n)
	return dist


## Shortest distance from the cat to any border plus how many distinct
static func escape_stats(board, extra_blocked := Vector2i(1 << 20, 0)) -> Dictionary:
	var dist := {board.cat: 0}
	var ways := {board.cat: 1}
	var queue := [board.cat]
	var head := 0
	var best := UNREACHABLE
	var routes := 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		var d: int = dist[cur]
		if d > best:
			break
		if board.is_border(cur):
			best = d
			routes += ways[cur]
			continue
		for n in Board.neighbors_of(cur):
			if n == extra_blocked or not board.is_walkable(n):
				continue
			if not dist.has(n):
				dist[n] = d + 1
				ways[n] = ways[cur]
				queue.append(n)
			elif dist[n] == d + 1:
				ways[n] += ways[cur]
	return {"distance": best, "routes": routes}


## Number of cells reachable from `start` (used when no exit exists).
static func reachable_area(board, start: Vector2i, extra_blocked := Vector2i(1 << 20, 0)) -> int:
	return bfs_distances(board, [start], extra_blocked).size()


static func border_cells(board) -> Array:
	var out := []
	for c in board.all_cells():
		if board.is_border(c) and board.is_walkable(c):
			out.append(c)
	return out
