extends Node2D

var test_object = preload("res://Game/objects/test_object.tscn")
var walk_test = preload("res://Game/AI/walk.tscn")
var scp_found = preload("res://Game/menus/scp_found.tscn")
var mode = 0
@onready var astar = AStar2D.new()

func _ready():
	$Personnel.get_walking_path.connect(_on_get_path)
	_on_get_path($Personnel, $Marker2D.global_position)
	_create_path_finding_routes()
	
func _create_path_finding_routes():
	var tile_map: TileMap = $TileMap
	var walkable_cells: Array[Vector2i] = tile_map.get_used_cells(1).filter(func(e: Vector2i): return not tile_map.get_used_cells(0).has(e))

	for i in walkable_cells.size():
		astar.add_point(i, walkable_cells[i])
	
	for i in astar.get_point_ids():
		# Bidirectional Paths
		for vector in [Vector2(0, 1), Vector2(1, 0)]:
			var connection_id = walkable_cells.find(Vector2i(astar.get_point_position(i) + vector))
			if connection_id != -1:
				astar.connect_points(i, connection_id, true)
		# Diagonal paths, avoid when there is an obstructing tile 
		for vector in [Vector2(1, 1), Vector2(1, -1)]:
			var connection_success = true
			for vector2 in [Vector2(0, 1), Vector2(1, 0)]:
				connection_success = connection_success and walkable_cells.has(Vector2i(astar.get_point_position(i) + vector2))
			var connection_id = walkable_cells.find(Vector2i(astar.get_point_position(i) + vector))
			if connection_id != -1 and connection_success:
				astar.connect_points(i, connection_id, true)

func _on_get_path(character: Personnel, final_path: Vector2):
	var init_cell: Vector2i = $TileMap.local_to_map($TileMap.to_local(character.global_position))
	var final_cell: Vector2i =  $TileMap.local_to_map($TileMap.to_local(final_path))
	var local_path: Array[Vector2]
	local_path.assign(Array(astar.get_point_path(astar.get_closest_point(init_cell),astar. get_closest_point(final_cell))))
	
	local_path.assign(local_path.map(func(e: Vector2): return $TileMap.map_to_local(e)))
	if local_path.is_empty():
		return
	if not character.path.is_empty() and local_path[0] != character.path[0]:
		local_path.pop_front()
	character.path = local_path

func _unhandled_input(event):
	if Global.can_create:
		if event.is_action_pressed("ui_leftclick"):
			if Global.item_selected == 1:
				var clone = test_object.instantiate()
				clone.position = get_global_mouse_position()
				get_parent().add_child(clone)
			elif Global.item_selected == 2:
				var clone = walk_test.instantiate()
				clone.position = get_global_mouse_position()
				get_parent().add_child(clone)
	if event.is_action_pressed("item1"):
		Global.item_selected = 1
	if event.is_action_pressed("item2"):
		Global.item_selected = 2

func _physics_process(delta):
	_on_get_path($Personnel, $walk.global_position)

func _on_button_pressed():
	var i = scp_found.instantiate()
	i.position.y = 10
	get_parent().add_child(i)
