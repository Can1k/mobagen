## The game world: board size, blocked cells, cat position and hex geometry.
## Coordinates follow the assignment: {0,0} is the center, x grows right,
## y grows down. Rows are "pointy top" hexes; the top row is aligned left and
## every odd row is shifted half a cell to the right.
##
## Vector2i plays the role of Point2D: it is hashable and comparable out of
## the box, so it can key Dictionaries (GDScript's unordered_map/set).
extends RefCounted

var side: int
var half: int
var blocked := {}
var cat := Vector2i.ZERO


func _init(p_side: int = 11) -> void:
	assert(p_side >= 5 and (p_side - 1) % 4 == 0, "Board side must be 1 + 4x")
	side = p_side
	half = p_side / 2


## The 6 neighbors of a cell, clockwise from East.
## Odd rows are shifted right, so their diagonal neighbors lean right.
static func neighbors_of(p: Vector2i) -> Array:
	if posmod(p.y, 2) == 1:
		return [
			p + Vector2i(1, 0),   # E
			p + Vector2i(1, 1),   # SE
			p + Vector2i(0, 1),   # SW
			p + Vector2i(-1, 0),  # W
			p + Vector2i(0, -1),  # NW
			p + Vector2i(1, -1),  # NE
		]
	return [
		p + Vector2i(1, 0),       # E
		p + Vector2i(0, 1),       # SE
		p + Vector2i(-1, 1),      # SW
		p + Vector2i(-1, 0),      # W
		p + Vector2i(-1, -1),     # NW
		p + Vector2i(0, -1),      # NE
	]


static func are_neighbors(a: Vector2i, b: Vector2i) -> bool:
	return neighbors_of(a).has(b)


func is_inside(p: Vector2i) -> bool:
	return absi(p.x) <= half and absi(p.y) <= half


func is_border(p: Vector2i) -> bool:
	return absi(p.x) == half or absi(p.y) == half


func is_blocked(p: Vector2i) -> bool:
	return blocked.has(p)


## A cell the cat could stand on (ignores the cat itself).
func is_walkable(p: Vector2i) -> bool:
	return is_inside(p) and not blocked.has(p)


## A cell the catcher may legally block.
func can_block(p: Vector2i) -> bool:
	return is_inside(p) and not blocked.has(p) and p != cat


func free_neighbors(p: Vector2i) -> Array:
	var out := []
	for n in neighbors_of(p):
		if is_walkable(n):
			out.append(n)
	return out


func cat_is_trapped() -> bool:
	return free_neighbors(cat).is_empty()


func all_cells() -> Array:
	var out := []
	for y in range(-half, half + 1):
		for x in range(-half, half + 1):
			out.append(Vector2i(x, y))
	return out


## Places the cat in the center and scatters `count` random blocks
func reset(block_count: int, rng: RandomNumberGenerator) -> void:
	blocked.clear()
	cat = Vector2i.ZERO
	var candidates := all_cells()
	candidates.erase(cat)
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	for i in mini(block_count, candidates.size()):
		blocked[candidates[i]] = true


func duplicate_board():
	var b = get_script().new(side)
	b.blocked = blocked.duplicate()
	b.cat = cat
	return b
