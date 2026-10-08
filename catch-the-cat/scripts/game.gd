## Main scene: draws the hex board, builds the side panel, and drives turns.
## Either side can be the AI or a human (click a hex to move / block).
extends Node2D

const Referee = preload("res://scripts/referee.gd")
const Board = preload("res://scripts/board.gd")
const CatAgent = preload("res://scripts/cat_agent.gd")
const CatcherAgent = preload("res://scripts/catcher_agent.gd")
const PathFinding = preload("res://scripts/pathfinding.gd")

const SIZES := [5, 9, 13, 17, 21, 25, 29]
const PANEL_WIDTH := 300.0
const SQRT3 := 1.7320508

const COL_BG := Color("1b1f2a")
const COL_CELL := Color("d9d4c7")
const COL_BORDER_CELL := Color("b9cfa8")
const COL_BLOCKED := Color("3a3f4d")
const COL_BLOCK_TOP := Color("5a6072")
const COL_OUTLINE := Color("1b1f2a")
const COL_HOVER_OK := Color("f2c94c")
const COL_HOVER_BAD := Color("e05555")
const COL_PATH := Color("f2994a")
const COL_CANDIDATE := Color("6fa8dc")
const COL_LAST := Color("e05555")
const COL_CAT := Color("f2994a")
const COL_CAT_DARK := Color("b35f1e")

var ref = Referee.new()
var cat_ai = CatAgent.new()
var catcher_ai = CatcherAgent.new()

var cat_is_human := false
var catcher_is_human := false
var autoplay := true
var show_thinking := true
var ai_delay := 0.35
var _ai_timer := 0.0

var hover := Vector2i(9999, 9999)
var last_block := Vector2i(9999, 9999)

# layout (recomputed on resize)
var hex_r := 20.0
var origin := Vector2.ZERO

# UI nodes
var size_option: OptionButton
var blocks_spin: SpinBox
var cat_option: OptionButton
var catcher_option: OptionButton
var speed_slider: HSlider
var play_button: Button
var step_button: Button
var thinking_check: CheckBox
var status_label: Label
var reason_label: Label
var log_list: ItemList
var score_label: Label
var cat_score := 0
var catcher_score := 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(COL_BG)
	_build_ui()
	get_viewport().size_changed.connect(_on_resized)
	_new_game()


func _new_game() -> void:
	var side: int = SIZES[size_option.selected]
	ref.new_game(side, int(blocks_spin.value))
	cat_ai.last_path = []
	catcher_ai.last_candidates = []
	last_block = Vector2i(9999, 9999)
	_ai_timer = 0.0
	log_list.clear()
	_compute_layout()
	if ref.is_over():
		_on_game_over()
	_refresh_status()
	_update_thinking()
	queue_redraw()


func _process(delta: float) -> void:
	if ref.is_over() or _current_is_human():
		return
	if not autoplay:
		return
	_ai_timer += delta
	if _ai_timer >= ai_delay:
		_ai_timer = 0.0
		_ai_step()


func _current_is_human() -> bool:
	if ref.turn == Referee.Turn.CAT:
		return cat_is_human
	return catcher_is_human


func _ai_step() -> void:
	if ref.is_over() or _current_is_human():
		return
	if ref.turn == Referee.Turn.CAT:
		_submit_cat(cat_ai.choose_move(ref.board))
	else:
		_submit_catcher(catcher_ai.choose_move(ref.board))
	_update_thinking()


func _submit_cat(p: Vector2i) -> void:
	ref.cat_move(p)
	_log("Cat → {%d, %d}" % [p.x, p.y])
	_after_move()


func _submit_catcher(p: Vector2i) -> void:
	ref.catcher_move(p)
	last_block = p
	_log("Catcher ■ {%d, %d}" % [p.x, p.y])
	_after_move()


func _after_move() -> void:
	if ref.is_over():
		_on_game_over()
	_refresh_status()
	queue_redraw()


func _update_thinking() -> void:
	if ref.is_over() or not show_thinking:
		return
	cat_ai.last_path = PathFinding.find_path_to_border(ref.board, ref.board.cat)
	if ref.turn == Referee.Turn.CATCHER:
		catcher_ai.choose_move(ref.board)
	else:
		catcher_ai.last_candidates = []
	queue_redraw()


func _on_game_over() -> void:
	if ref.result == Referee.Result.CAT_WINS:
		cat_score += 1
	else:
		catcher_score += 1
	_log(ref.reason)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var c := _cell_at(event.position)
		if c != hover:
			hover = c
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := _cell_at(event.position)
		if not ref.board.is_inside(c) or ref.is_over() or not _current_is_human():
			return
		if ref.turn == Referee.Turn.CAT:
			if Board.are_neighbors(ref.board.cat, c) and ref.board.is_walkable(c):
				_submit_cat(c)
		else:
			if ref.board.can_block(c):
				_submit_catcher(c)
		_ai_timer = 0.0
		_update_thinking()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_play()
			KEY_N, KEY_R:
				_new_game()
			KEY_RIGHT, KEY_S:
				_ai_step()


func _compute_layout() -> void:
	var vp := get_viewport_rect().size
	var area := Rect2(PANEL_WIDTH, 0, vp.x - PANEL_WIDTH, vp.y)
	var n: int = ref.board.side
	var margin := 24.0
	var r_w := (area.size.x - margin * 2) / ((n + 0.5) * SQRT3)
	var r_h := (area.size.y - margin * 2) / (1.5 * (n - 1) + 2.0)
	hex_r = maxf(4.0, minf(r_w, r_h))
	var board_w := (n + 0.5) * SQRT3 * hex_r
	var board_h := (1.5 * (n - 1) + 2.0) * hex_r
	origin = area.position + (area.size - Vector2(board_w, board_h)) * 0.5


func _cell_center(p: Vector2i) -> Vector2:
	var w := SQRT3 * hex_r
	var h: int = ref.board.half
	var shift := w * 0.5 if posmod(p.y, 2) == 1 else 0.0
	return origin + Vector2((p.x + h) * w + w * 0.5 + shift, (p.y + h) * 1.5 * hex_r + hex_r)


func _cell_at(pos: Vector2) -> Vector2i:
	var best := Vector2i(9999, 9999)
	var best_d := hex_r * hex_r
	for c in ref.board.all_cells():
		var d := _cell_center(c).distance_squared_to(pos)
		if d < best_d:
			best_d = d
			best = c
	return best


func _hex_points(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i - 90.0)   # pointy top
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


func _draw() -> void:
	if ref.board == null:
		return
	var b = ref.board
	var inner := hex_r * 0.94

	for c in b.all_cells():
		var center := _cell_center(c)
		var pts := _hex_points(center, inner)
		if b.is_blocked(c):
			draw_colored_polygon(pts, COL_BLOCKED)
			draw_colored_polygon(_hex_points(center + Vector2(0, -hex_r * 0.08), inner * 0.62), COL_BLOCK_TOP)
		else:
			draw_colored_polygon(pts, COL_BORDER_CELL if b.is_border(c) else COL_CELL)
		if c == last_block:
			_draw_outline(_hex_points(center, inner * 0.9), COL_LAST, maxf(2.0, hex_r * 0.1))

	# AI thinking overlay
	if show_thinking and not ref.is_over():
		for c in catcher_ai.last_candidates:
			if not b.is_blocked(c):
				draw_circle(_cell_center(c), hex_r * 0.14, COL_CANDIDATE)
		var prev := _cell_center(b.cat)
		for c in cat_ai.last_path:
			var p := _cell_center(c)
			draw_line(prev, p, COL_PATH, maxf(2.0, hex_r * 0.12), true)
			draw_circle(p, hex_r * 0.16, COL_PATH)
			prev = p

	if b.is_inside(hover) and not ref.is_over() and _current_is_human():
		var ok: bool
		if ref.turn == Referee.Turn.CAT:
			ok = Board.are_neighbors(b.cat, hover) and b.is_walkable(hover)
		else:
			ok = b.can_block(hover)
		_draw_outline(_hex_points(_cell_center(hover), inner), COL_HOVER_OK if ok else COL_HOVER_BAD, maxf(2.0, hex_r * 0.12))

	_draw_cat(_cell_center(b.cat), hex_r)


func _draw_outline(pts: PackedVector2Array, col: Color, width: float) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, col, width, true)


func _draw_cat(c: Vector2, r: float) -> void:
	var s := r * 0.62
	# ears
	draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.95, -s * 0.2), c + Vector2(-s * 0.75, -s * 1.15), c + Vector2(-s * 0.2, -s * 0.75)]), COL_CAT_DARK)
	draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.95, -s * 0.2), c + Vector2(s * 0.75, -s * 1.15), c + Vector2(s * 0.2, -s * 0.75)]), COL_CAT_DARK)
	# head
	draw_circle(c, s, COL_CAT)
	# eyes
	var eye := s * 0.16
	draw_circle(c + Vector2(-s * 0.38, -s * 0.1), eye, Color.BLACK)
	draw_circle(c + Vector2(s * 0.38, -s * 0.1), eye, Color.BLACK)
	# nose
	draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.12, s * 0.18), c + Vector2(s * 0.12, s * 0.18), c + Vector2(0, s * 0.32)]), Color("7a2e2e"))
	if ref.is_over() and ref.result == Referee.Result.CATCHER_WINS:
		# X eyes when caught
		for side in [-1.0, 1.0]:
			var e := c + Vector2(side * s * 0.38, -s * 0.1)
			draw_line(e + Vector2(-eye, -eye) * 1.3, e + Vector2(eye, eye) * 1.3, COL_CAT, eye * 0.9)
			draw_line(e + Vector2(-eye, -eye), e + Vector2(eye, eye), Color.BLACK, eye * 0.5)
			draw_line(e + Vector2(-eye, eye), e + Vector2(eye, -eye), Color.BLACK, eye * 0.5)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2.ZERO
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.size = Vector2(PANEL_WIDTH, get_viewport_rect().size.y)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("232838")
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	_panel = panel

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Catch the Cat"
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	score_label = Label.new()
	score_label.add_theme_color_override("font_color", Color("9aa3b5"))
	box.add_child(score_label)

	box.add_child(HSeparator.new())

	size_option = OptionButton.new()
	for s in SIZES:
		size_option.add_item("%d × %d" % [s, s])
	size_option.selected = 2
	size_option.item_selected.connect(func(_i): blocks_spin.value = SIZES[size_option.selected]; _new_game())
	_row(box, "Board size", size_option)

	blocks_spin = SpinBox.new()
	blocks_spin.min_value = 0
	blocks_spin.max_value = 200
	blocks_spin.value = SIZES[2]
	_row(box, "Random blocks", blocks_spin)

	cat_option = OptionButton.new()
	cat_option.add_item("AI")
	cat_option.add_item("Human")
	cat_option.item_selected.connect(func(i): cat_is_human = i == 1; _ai_timer = 0.0; queue_redraw())
	_row(box, "Cat", cat_option)

	catcher_option = OptionButton.new()
	catcher_option.add_item("AI")
	catcher_option.add_item("Human")
	catcher_option.item_selected.connect(func(i): catcher_is_human = i == 1; _ai_timer = 0.0; queue_redraw())
	_row(box, "Catcher", catcher_option)

	speed_slider = HSlider.new()
	speed_slider.min_value = 0.02
	speed_slider.max_value = 1.0
	speed_slider.step = 0.01
	speed_slider.value = ai_delay
	speed_slider.custom_minimum_size = Vector2(130, 0)
	speed_slider.value_changed.connect(func(v): ai_delay = v)
	_row(box, "AI delay", speed_slider)

	thinking_check = CheckBox.new()
	thinking_check.text = "Show AI thinking"
	thinking_check.button_pressed = show_thinking
	thinking_check.toggled.connect(func(on): show_thinking = on; _update_thinking(); queue_redraw())
	box.add_child(thinking_check)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	var new_btn := Button.new()
	new_btn.text = "New game"
	new_btn.pressed.connect(_new_game)
	new_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(new_btn)
	play_button = Button.new()
	play_button.text = "Pause"
	play_button.pressed.connect(_toggle_play)
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(play_button)
	step_button = Button.new()
	step_button.text = "Step"
	step_button.pressed.connect(_ai_step)
	step_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(step_button)

	box.add_child(HSeparator.new())

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	box.add_child(status_label)

	reason_label = Label.new()
	reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason_label.add_theme_color_override("font_color", Color("9aa3b5"))
	box.add_child(reason_label)

	log_list = ItemList.new()
	log_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_list.focus_mode = Control.FOCUS_NONE
	box.add_child(log_list)

	var help := Label.new()
	help.text = "Space: play/pause   S: step   N: new game\nOrange line = cat's A* path\nBlue dots = catcher's candidate blocks"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("7d8699"))
	box.add_child(help)

var _panel: PanelContainer

func _row(parent: Control, label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	control.focus_mode = Control.FOCUS_NONE
	row.add_child(control)
	parent.add_child(row)


func _toggle_play() -> void:
	autoplay = not autoplay
	play_button.text = "Pause" if autoplay else "Play"


func _refresh_status() -> void:
	score_label.text = "Cat %d  ·  Catcher %d" % [cat_score, catcher_score]
	if ref.is_over():
		status_label.text = "Cat wins!" if ref.result == Referee.Result.CAT_WINS else "Catcher wins!"
		reason_label.text = ref.reason
	else:
		var who := "Cat" if ref.turn == Referee.Turn.CAT else "Catcher"
		var human := cat_is_human if ref.turn == Referee.Turn.CAT else catcher_is_human
		status_label.text = "%s's turn%s" % [who, " (you)" if human else ""]
		reason_label.text = "Turn %d" % (ref.move_count / 2 + 1)


func _log(text: String) -> void:
	log_list.add_item(text)
	log_list.select(log_list.item_count - 1)
	log_list.ensure_current_is_visible()


func _on_resized() -> void:
	if _panel:
		_panel.size = Vector2(PANEL_WIDTH, get_viewport_rect().size.y)
	_compute_layout()
	queue_redraw()
