## Rules and turn order. Both humans and AIs submit moves through here,
## so every move is validated the same way. Illegal moves lose the game.
extends RefCounted

const Board = preload("res://scripts/board.gd")

enum Turn { CAT, CATCHER }
enum Result { ONGOING, CAT_WINS, CATCHER_WINS }

var board
var turn: int = Turn.CAT
var result: int = Result.ONGOING
var reason := ""
var move_count := 0
var history: Array = []


func new_game(side: int, block_count: int, rng_seed: int = -1) -> void:
	board = Board.new(side)
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	board.reset(block_count, rng)
	turn = Turn.CAT
	result = Result.ONGOING
	reason = ""
	move_count = 0
	history.clear()
	if board.cat_is_trapped():
		_finish(Result.CATCHER_WINS, "The cat started fully surrounded.")


func cat_move(p: Vector2i) -> void:
	if result != Result.ONGOING or turn != Turn.CAT:
		return
	history.append({"who": "cat", "cell": p})
	if p == board.cat:
		_finish(Result.CATCHER_WINS, "Invalid cat move: stayed in place at %s." % _fmt(p))
		return
	if not Board.are_neighbors(board.cat, p):
		_finish(Result.CATCHER_WINS, "Invalid cat move: %s is not a neighbor." % _fmt(p))
		return
	if not board.is_inside(p):
		_finish(Result.CATCHER_WINS, "Invalid cat move: %s is off the board." % _fmt(p))
		return
	if board.is_blocked(p):
		_finish(Result.CATCHER_WINS, "Invalid cat move: %s is blocked." % _fmt(p))
		return

	board.cat = p
	move_count += 1
	if board.is_border(p):
		_finish(Result.CAT_WINS, "The cat reached the border at %s." % _fmt(p))
		return
	turn = Turn.CATCHER


func catcher_move(p: Vector2i) -> void:
	if result != Result.ONGOING or turn != Turn.CATCHER:
		return
	history.append({"who": "catcher", "cell": p})
	if not board.is_inside(p):
		_finish(Result.CAT_WINS, "Invalid catcher move: %s is off the board." % _fmt(p))
		return
	if board.is_blocked(p):
		_finish(Result.CAT_WINS, "Invalid catcher move: %s is already blocked." % _fmt(p))
		return
	if p == board.cat:
		_finish(Result.CAT_WINS, "Invalid catcher move: the cat is on %s." % _fmt(p))
		return

	board.blocked[p] = true
	move_count += 1
	if board.cat_is_trapped():
		_finish(Result.CATCHER_WINS, "The cat is surrounded at %s." % _fmt(board.cat))
		return
	turn = Turn.CAT


func is_over() -> bool:
	return result != Result.ONGOING


func _finish(r: int, why: String) -> void:
	result = r
	reason = why


static func _fmt(p: Vector2i) -> String:
	return "{%d, %d}" % [p.x, p.y]
