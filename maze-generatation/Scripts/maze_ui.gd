extends Control

## Grid coloring (cell fill):
##   gray       = unvisited cell
##   dark red   = visited cell
##   green      = current cell (the algorithm's active position)
##   black      = a cell that's fully done - Recursive Back-Tracker


const COLOR_UNVISITED := Color(0.75, 0.75, 0.75)
const COLOR_VISITED := Color(0.5, 0.08, 0.08)
const COLOR_CURRENT := Color(0.2, 0.8, 0.25)
const COLOR_BACKTRACK := Color(0, 0, 0)
const COLOR_WALL := Color(0.95, 0.95, 0.95)
const COLOR_PANEL_BG := Color(0.13, 0.14, 0.17, 0.55)

const GRID_MARGIN := Vector2(16, 16)
const PANEL_WIDTH := 230.0
const WALL_THICKNESS := 3.0

@export var side_size: int = 21

var maze: MazeAlgorithmBase
var running: bool = false
var turn_duration: float = 0.0
var time_to_next_turn: float = 0.0
var move_duration_ms: float = 0.0
var total_duration_ms: float = 0.0
var frame_times: Array = []
var backtracked: Array = []

# UI references
var stats_label: Label
var side_size_value_label: Label
var side_size_slider: HSlider
var move_duration_label: Label
var total_duration_label: Label
var turn_duration_value_label: Label
var turn_duration_slider: HSlider
var next_turn_label: Label
var generator_dropdown: OptionButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(func() -> void: queue_redraw())
	_build_ui()
	_reset_maze()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = GRID_MARGIN
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_BG
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "▼ Settings"
	vbox.add_child(title)

	stats_label = Label.new()
	vbox.add_child(stats_label)

	vbox.add_child(HSeparator.new())

	# Side Size row
	var side_row := HBoxContainer.new()
	side_size_value_label = Label.new()
	side_size_value_label.custom_minimum_size = Vector2(28, 0)
	side_size_slider = HSlider.new()
	side_size_slider.min_value = 3
	side_size_slider.max_value = 61
	side_size_slider.step = 1
	side_size_slider.value = side_size
	side_size_slider.custom_minimum_size = Vector2(90, 0)
	side_size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_size_slider.value_changed.connect(_on_side_size_changed)
	var side_label := Label.new()
	side_label.text = "Side Size"
	side_row.add_child(side_size_value_label)
	side_row.add_child(side_size_slider)
	side_row.add_child(side_label)
	vbox.add_child(side_row)

	vbox.add_child(HSeparator.new())

	var sim_title := Label.new()
	sim_title.text = "Simulation"
	vbox.add_child(sim_title)

	var sim_row := HBoxContainer.new()
	var step_button := Button.new()
	step_button.text = "Step"
	step_button.pressed.connect(_on_step_pressed)
	var start_button := Button.new()
	start_button.text = "Start"
	start_button.pressed.connect(_on_start_pressed)
	var pause_button := Button.new()
	pause_button.text = "Pause"
	pause_button.pressed.connect(_on_pause_pressed)
	var reset_button := Button.new()
	reset_button.text = "RESET"
	reset_button.pressed.connect(_on_reset_pressed)
	sim_row.add_child(step_button)
	sim_row.add_child(start_button)
	sim_row.add_child(pause_button)
	sim_row.add_child(reset_button)
	vbox.add_child(sim_row)

	move_duration_label = Label.new()
	vbox.add_child(move_duration_label)

	total_duration_label = Label.new()
	vbox.add_child(total_duration_label)

	var turn_row := HBoxContainer.new()
	turn_duration_value_label = Label.new()
	turn_duration_value_label.custom_minimum_size = Vector2(48, 0)
	turn_duration_slider = HSlider.new()
	turn_duration_slider.min_value = 0.0
	turn_duration_slider.max_value = 1.0
	turn_duration_slider.step = 0.01
	turn_duration_slider.value = turn_duration
	turn_duration_slider.custom_minimum_size = Vector2(70, 0)
	turn_duration_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turn_duration_slider.value_changed.connect(_on_turn_duration_changed)
	var turn_label := Label.new()
	turn_label.text = "Turn Dur."
	turn_row.add_child(turn_duration_value_label)
	turn_row.add_child(turn_duration_slider)
	turn_row.add_child(turn_label)
	vbox.add_child(turn_row)

	next_turn_label = Label.new()
	vbox.add_child(next_turn_label)

	vbox.add_child(HSeparator.new())

	var gen_label := Label.new()
	gen_label.text = "Generator:"
	vbox.add_child(gen_label)

	generator_dropdown = OptionButton.new()
	generator_dropdown.add_item("Recursive Back-Tracker")
	generator_dropdown.add_item("Hunt and Kill")
	generator_dropdown.selected = 0
	generator_dropdown.item_selected.connect(_on_generator_selected)
	vbox.add_child(generator_dropdown)

func _reset_maze() -> void:
	match generator_dropdown.selected:
		1:
			maze = HuntAndKillGenerator.new(side_size, side_size, randi() % 100)
		_:
			maze = RecursiveBacktrackerGenerator.new(side_size, side_size, randi() % 100)
	maze.start()
	running = false
	total_duration_ms = 0.0
	move_duration_ms = 0.0
	time_to_next_turn = turn_duration
	backtracked.clear()
	for r in range(side_size):
		var row: Array = []
		row.resize(side_size)
		row.fill(false)
		backtracked.append(row)
	queue_redraw()

func _do_step() -> void:
	if maze == null or maze.finished:
		running = false
		return
	var t0: int = Time.get_ticks_usec()
	maze.step()
	var t1: int = Time.get_ticks_usec()
	move_duration_ms = (t1 - t0) / 1000.0
	total_duration_ms += move_duration_ms

	if maze.last_backtrack != Vector2i(-1, -1):
		backtracked[maze.last_backtrack.x][maze.last_backtrack.y] = true

	if maze.finished:
		running = false
	queue_redraw()

func _on_side_size_changed(value: float) -> void:
	side_size = int(value)
	_reset_maze()

func _on_generator_selected(_index: int) -> void:
	_reset_maze()

func _on_turn_duration_changed(value: float) -> void:
	turn_duration = value
	time_to_next_turn = min(time_to_next_turn, turn_duration)

func _on_step_pressed() -> void:
	running = false
	_do_step()

func _on_start_pressed() -> void:
	if maze != null and not maze.finished:
		running = true
		time_to_next_turn = turn_duration

func _on_pause_pressed() -> void:
	running = false

func _on_reset_pressed() -> void:
	_reset_maze()

func _process(delta: float) -> void:
	frame_times.append(delta * 1000.0)
	if frame_times.size() > 60:
		frame_times.pop_front()
	var avg_ms: float = 0.0
	for t in frame_times:
		avg_ms += t
	avg_ms /= max(frame_times.size(), 1)

	stats_label.text = "%.1fms %dFPS | AVG: %.2fms" % [
		delta * 1000.0, Engine.get_frames_per_second(), avg_ms
	]
	side_size_value_label.text = str(side_size)
	turn_duration_value_label.text = "%.3f" % turn_duration
	move_duration_label.text = "Move duration: %d" % int(round(move_duration_ms))
	total_duration_label.text = "Total duration: %d" % int(round(total_duration_ms))

	if running and maze != null and not maze.finished:
		time_to_next_turn -= delta
		if time_to_next_turn <= 0.0:
			_do_step()
			time_to_next_turn = turn_duration

	next_turn_label.text = "Next turn in %.1f" % max(time_to_next_turn, 0.0)
	queue_redraw()

func _draw() -> void:
	if maze == null:
		return

	var origin := Vector2(PANEL_WIDTH + GRID_MARGIN.x * 2, GRID_MARGIN.y)
	var available := size - origin - GRID_MARGIN
	if available.x <= 0 or available.y <= 0:
		return
	var cell_px: float = min(available.x / maze.cols, available.y / maze.lines)
	if cell_px <= 0:
		return

	# Cell fills.
	for r in range(maze.lines):
		for c in range(maze.cols):
			var color: Color = COLOR_VISITED if maze.visited[r][c] else COLOR_UNVISITED
			if backtracked[r][c]:
				color = COLOR_BACKTRACK
			if not maze.finished and r == maze.current_row and c == maze.current_col:
				color = COLOR_CURRENT
			var rect := Rect2(origin + Vector2(c, r) * cell_px, Vector2(cell_px, cell_px))
			draw_rect(rect, color)

	# Walls: only drawn where that specific wall is still closed.
	for r in range(maze.lines):
		for c in range(maze.cols):
			var top_left: Vector2 = origin + Vector2(c, r) * cell_px
			var top_right: Vector2 = top_left + Vector2(cell_px, 0)
			var bottom_left: Vector2 = top_left + Vector2(0, cell_px)
			var bottom_right: Vector2 = top_left + Vector2(cell_px, cell_px)

			if maze.wall_north[r][c]:
				draw_line(top_left, top_right, COLOR_WALL, WALL_THICKNESS)
			if maze.wall_west[r][c]:
				draw_line(top_left, bottom_left, COLOR_WALL, WALL_THICKNESS)
			if r == maze.lines - 1 and maze.wall_south[r][c]:
				draw_line(bottom_left, bottom_right, COLOR_WALL, WALL_THICKNESS)
			if c == maze.cols - 1 and maze.wall_east[r][c]:
				draw_line(top_right, bottom_right, COLOR_WALL, WALL_THICKNESS)
