tool 
extends Spatial

export var GroundScene: PackedScene
export var ObstacleScene: PackedScene

var shader_material: ShaderMaterial

export (int, 1, 21) var map_width = 11 setget set_width
export (int, 1, 15) var map_depth = 11 setget set_depth

export (float, 0, 1, 0.05) var obstacle_density = 0.2 setget set_obstacle_density

export (float, 1, 5) var obstacle_min_height = 1 setget set_obs_min_height
export (float, 1, 5) var obstacle_max_height = 5 setget set_obs_max_height

export (Color) var foreground_color: Color setget set_fore_color
export (Color) var background_color: Color setget set_back_color

export (int) var rng_seed = 12345 setget set_seed

var map_coords_array := []
var map_center: Coord

class Coord:
	var x: int
	var z: int
	
# warning-ignore:shadowed_variable
# warning-ignore:shadowed_variable
	func _init(x, z):
		self.x = x
		self.z = z
		
	func _to_string() -> String:
		return "(" + str(x) + "," + str(z) + ")" 
		
	func equals(coord):
		return coord.x == self.x and coord.z == self.z

func _ready() -> void:
	generate_map()
	
func set_fore_color(var new_value):
	foreground_color = new_value
	generate_map()

func set_back_color(var new_value):
	background_color = new_value
	generate_map()

func set_obs_max_height(var new_value):
	obstacle_max_height = max(new_value, obstacle_min_height)
	generate_map()
	
func set_obs_min_height(var new_value):
	obstacle_min_height = min(new_value, obstacle_max_height)
	generate_map()
	
func set_seed(var new_value):
	rng_seed = new_value
	generate_map()
	
func set_width(var new_value):
	map_width = make_odd(new_value, map_width)
	update_map_center()
	generate_map()

func set_depth(var new_value):
	map_depth = make_odd(new_value, map_depth)
	update_map_center()
	generate_map()
	
func update_map_center():
	map_center = Coord.new(map_width / 2, map_depth / 2)
	
func set_obstacle_density(var new_value):
	obstacle_density = new_value
	generate_map()
	
func make_odd(new_int, old_int):
	if new_int % 2 == 0:
		if new_int > old_int:
			return new_int + 1
		else:
			return new_int - 1
	else:
		return new_int
		
func fill_map_coords_array():
	map_coords_array = []
	for x in range (map_width):
		for z in range (map_depth):
			map_coords_array.append(Coord.new(x, z))

func generate_map():
	print("Generating Map...")
	clear_map()
	add_ground()
	update_obstacle_material()
	add_obstacles()

func clear_map():
	for node in get_children():
		node.queue_free()

func add_ground():
	var ground: CSGBox = GroundScene.instance()
	ground.width = map_width * 2
	ground.depth = map_depth * 2
	add_child(ground)
	
func update_obstacle_material():
	var temp_obstacle: CSGBox = ObstacleScene.instance()
	shader_material = temp_obstacle.material as ShaderMaterial
	shader_material.set_shader_param("ForegroundColor", foreground_color)
	shader_material.set_shader_param("BackgroundColor", background_color)
	shader_material.set_shader_param("LevelDepth", map_depth * 2)
	
func add_obstacles():
	fill_map_coords_array()
#	print(map_coords_array)
	seed(rng_seed)
	map_coords_array.shuffle()
#	print(map_coords_array)
	
	var num_obstacles: int = map_coords_array.size() * obstacle_density
	if num_obstacles > 0:
		for coord in map_coords_array.slice(0, num_obstacles - 1):
			
			if not map_center.equals(coord):
				create_obstacle_at(coord.x, coord.z)

func create_obstacle_at(x, z):
	var obstacle_position = Vector3(x * 2, 0, z * 2)
	obstacle_position += Vector3(-map_width + 1, 0, -map_depth + 1)
	var new_obstacle: CSGBox = ObstacleScene.instance()
	new_obstacle.height = get_obstacle_height()
	
	# New Material and set it's color
#	var new_material := SpatialMaterial.new()
#	new_material.albedo_color = get_color_at_depth(z)
#	new_obstacle.material = new_material
	
	new_obstacle.transform.origin = obstacle_position + Vector3(0, new_obstacle.height / 2, 0)
	add_child(new_obstacle) 

func get_obstacle_height():
	return rand_range(obstacle_min_height, obstacle_max_height)
	
func get_color_at_depth(z):
	return background_color.linear_interpolate(foreground_color, float(z) / map_depth)
