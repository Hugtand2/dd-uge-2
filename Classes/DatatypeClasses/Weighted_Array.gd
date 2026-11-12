class_name Weighted_Array
extends RefCounted

var items: Array[Array] = []

func add(value, weight: float) -> void:
	items.append([value, weight])

func pick_weighted_random():
	var total := 0.0
	for item in items:
		total += item[1]
	var roll = randf() * total
	for item in items:
		roll -= item[1]
		if roll <= 0:
			return item[0]
	return null
