extends RefCounted

var _heap: Array = []
var _counter := 0


func push(item, priority: float) -> void:
	_heap.append([priority, _counter, item])
	_counter += 1
	_sift_up(_heap.size() - 1)


func pop():
	var top = _heap[0][2]
	var last = _heap.pop_back()
	if not _heap.is_empty():
		_heap[0] = last
		_sift_down(0)
	return top


func is_empty() -> bool:
	return _heap.is_empty()


func size() -> int:
	return _heap.size()


func _less(a: Array, b: Array) -> bool:
	if a[0] != b[0]:
		return a[0] < b[0]
	return a[1] < b[1]


func _sift_up(i: int) -> void:
	while i > 0:
		var parent := (i - 1) / 2
		if _less(_heap[i], _heap[parent]):
			var t = _heap[i]
			_heap[i] = _heap[parent]
			_heap[parent] = t
			i = parent
		else:
			return


func _sift_down(i: int) -> void:
	var n := _heap.size()
	while true:
		var l := i * 2 + 1
		var r := l + 1
		var smallest := i
		if l < n and _less(_heap[l], _heap[smallest]):
			smallest = l
		if r < n and _less(_heap[r], _heap[smallest]):
			smallest = r
		if smallest == i:
			return
		var t = _heap[i]
		_heap[i] = _heap[smallest]
		_heap[smallest] = t
		i = smallest
