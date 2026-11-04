extends Node3D
class_name ShipWorld3D

const PLAYER_TEXTURE: Texture2D = preload("res://assets/art/characters/astronaut_4dir.svg")

@onready var camera: Camera3D = $Camera3D
@onready var player_avatar: Node3D = $PlayerAvatar
@onready var player_sprite: Sprite3D = $PlayerAvatar/Sprite3D
@onready var player_shadow: MeshInstance3D = $PlayerAvatar/Shadow

var _materials: Dictionary = {}
var _box_transforms: Dictionary = {}
var _unit_box: BoxMesh
var _shadow_mesh: CylinderMesh


func _ready() -> void:
	_create_materials()
	_create_world()
	_build_floor()
	_build_walls()
	_build_cryo_room()
	_build_corridor()
	_build_engineering_room()
	_flush_box_batches()
	player_sprite.texture = PLAYER_TEXTURE
	player_sprite.hframes = 4
	player_sprite.vframes = 4
	player_sprite.pixel_size = 1.0
	player_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	player_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	player_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	player_sprite.position = Vector3(0, 10, 0)
	player_shadow.position = Vector3(0, 0.025, 0)
	player_shadow.mesh = _shadow_mesh
	player_shadow.material_override = _materials["shadow"]


func sync_view(camera_center: Vector2, player_position: Vector2, frame: Vector2i) -> void:
	var target := Vector3(camera_center.x, 0, camera_center.y)
	camera.global_position = target + Vector3(0, 350, 155)
	camera.look_at(target, Vector3.UP)
	player_avatar.position = Vector3(player_position.x, 0.18, player_position.y)
	player_sprite.frame_coords = frame


func _create_materials() -> void:
	_unit_box = BoxMesh.new()
	_unit_box.size = Vector3.ONE
	_shadow_mesh = CylinderMesh.new()
	_shadow_mesh.top_radius = 8.0
	_shadow_mesh.bottom_radius = 8.0
	_shadow_mesh.height = 0.04
	_shadow_mesh.radial_segments = 16

	_material("floor_base", Color("#172a34"), 0.52, 0.74)
	_material("cryo_floor", Color("#3d5960"), 0.58, 0.64)
	_material("corridor_floor", Color("#485b61"), 0.5, 0.7)
	_material("engineering_floor", Color("#3b5158"), 0.58, 0.64)
	_material("tile_light", Color("#526b70"), 0.58, 0.6)
	_material("tile_mid", Color("#40585f"), 0.56, 0.66)
	_material("tile_dark", Color("#2b424b"), 0.52, 0.7)
	_material("seam", Color("#101d25"), 0.24, 0.86)
	_material("steel", Color("#344c54"), 0.7, 0.48)
	_material("steel_light", Color("#81938a"), 0.74, 0.4)
	_material("steel_dark", Color("#1b2c35"), 0.62, 0.58)
	_material("side_face", Color("#14232c"), 0.56, 0.64)
	_material("glass_frame", Color("#19343e"), 0.66, 0.32)
	_material("glass", Color("#14556a"), 0.32, 0.24, true)
	_material("glass_hi", Color("#45b5c3"), 0.28, 0.3, true)
	_material("cyan", Color("#43cbd2"), 0.22, 0.34, true)
	_material("cyan_soft", Color("#287e8a"), 0.3, 0.4, true)
	_material("amber", Color("#d39343"), 0.18, 0.48, true)
	_material("red", Color("#a83e3d"), 0.16, 0.5, true)
	_material("black", Color("#0b171f"), 0.18, 0.72)
	_material("shadow", Color("#0a141b"), 0.0, 1.0)


func _material(
	key: String,
	color: Color,
	metallic: float = 0.0,
	roughness: float = 0.8,
	emissive: bool = false
) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.55
	_materials[key] = material


func _flush_box_batches() -> void:
	for material_key: String in _box_transforms:
		var transforms: Array = _box_transforms[material_key]
		var multi_mesh := MultiMesh.new()
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.mesh = _unit_box
		multi_mesh.instance_count = transforms.size()
		for index in range(transforms.size()):
			multi_mesh.set_instance_transform(index, transforms[index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "StaticGeometry_%s" % material_key
		instance.multimesh = multi_mesh
		instance.material_override = _materials[material_key]
		add_child(instance)


func _create_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#07121b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#7697a4")
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-54, -24, 0)
	key_light.light_color = Color("#b9d8e2")
	key_light.light_energy = 0.78
	key_light.shadow_enabled = true
	add_child(key_light)

	var camera_light := OmniLight3D.new()
	camera_light.position = Vector3(0, 54, 18)
	camera_light.light_color = Color("#317a9d")
	camera_light.light_energy = 1.25
	camera_light.omni_range = 320.0
	add_child(camera_light)

	var emergency_light := OmniLight3D.new()
	emergency_light.position = Vector3(160, 42, -80)
	emergency_light.light_color = Color("#b94b3f")
	emergency_light.light_energy = 0.55
	emergency_light.omni_range = 120.0
	add_child(emergency_light)

	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 180.0
	camera.current = true


func _build_floor() -> void:
	_box("HullSubfloor", Vector3(80, -1.6, 0), Vector3(800, 3, 240), "floor_base")
	_floor_tiles("CryoDeck", -200, 0, 224, 224, "cryo_floor")
	_floor_tiles("CorridorDeck", 40, 0, 224, 112, "corridor_floor")
	_floor_tiles("EngineeringDeck", 320, 0, 304, 224, "engineering_floor")

	_batch_boxes(
		"CryoRecessedGrates",
		Vector3(14, 0.35, 38),
		"seam",
		[
			Vector3(-302, 0.15, -72), Vector3(-98, 0.15, -72),
			Vector3(-302, 0.15, 72), Vector3(-98, 0.15, 72)
		]
	)
	_batch_boxes(
		"EngineeringRecessedGrates",
		Vector3(16, 0.35, 42),
		"seam",
		[
			Vector3(184, 0.15, -74), Vector3(456, 0.15, -74),
			Vector3(184, 0.15, 74), Vector3(456, 0.15, 74)
		]
	)
	_batch_boxes(
		"CorridorThresholdRails",
		Vector3(4, 0.8, 104),
		"steel_light",
		[Vector3(-74, 0.2, 0), Vector3(154, 0.2, 0)]
	)


func _floor_tiles(
	label: String,
	center_x: float,
	center_z: float,
	width: float,
	depth: float,
	base_material: String
) -> void:
	_box(
		label + "Foundation",
		Vector3(center_x, -0.3, center_z),
		Vector3(width, 0.8, depth),
		base_material
	)
	var light_tiles: Array[Vector3] = []
	var mid_tiles: Array[Vector3] = []
	var dark_tiles: Array[Vector3] = []
	var x_count := int(width / 40.0)
	var z_count := int(depth / 40.0)
	for x_index in range(x_count):
		for z_index in range(z_count):
			var position := Vector3(
				center_x - width * 0.5 + 20.0 + x_index * 40.0,
				0.14,
				center_z - depth * 0.5 + 20.0 + z_index * 40.0
			)
			var variation := (x_index * 3 + z_index * 5) % 7
			if variation == 0:
				dark_tiles.append(position)
			elif variation == 1 or variation == 4:
				light_tiles.append(position)
			else:
				mid_tiles.append(position)
	_batch_boxes(label + "TilesLight", Vector3(37, 0.08, 37), "tile_light", light_tiles)
	_batch_boxes(label + "TilesMid", Vector3(37, 0.08, 37), "tile_mid", mid_tiles)
	_batch_boxes(label + "TilesDark", Vector3(37, 0.08, 37), "tile_dark", dark_tiles)
	var inserts: Array[Vector3] = []
	for x_index in range(0, x_count, 2):
		for z_index in range(0, z_count, 2):
			inserts.append(Vector3(
				center_x - width * 0.5 + 20.0 + x_index * 40.0,
				0.34,
				center_z - depth * 0.5 + 20.0 + z_index * 40.0
			))
	_batch_boxes(label + "RaisedInserts", Vector3(10, 0.32, 10), "steel_dark", inserts)
	_box(
		label + "NorthTrim",
		Vector3(center_x, 0.2, center_z - depth * 0.5 + 2.0),
		Vector3(width - 8.0, 0.5, 2.0),
		"steel_light"
	)
	_box(
		label + "SouthTrim",
		Vector3(center_x, 0.2, center_z + depth * 0.5 - 2.0),
		Vector3(width - 8.0, 0.5, 2.0),
		"steel_dark"
	)


func _build_walls() -> void:
	_box("RearBulkhead", Vector3(80, 18, -116), Vector3(800, 36, 8), "steel_dark")
	_box("RearBulkheadCap", Vector3(80, 37, -116), Vector3(800, 2, 10), "steel_light")
	_box("OuterWestBulkhead", Vector3(-316, 17, 0), Vector3(8, 34, 240), "steel_dark")
	_box("OuterEastBulkhead", Vector3(476, 17, 0), Vector3(8, 34, 240), "steel_dark")
	_box("OuterWestCap", Vector3(-316, 35, 0), Vector3(10, 2, 240), "steel_light")
	_box("OuterEastCap", Vector3(476, 35, 0), Vector3(10, 2, 240), "steel_light")

	for divider_x in [-80.0, 160.0]:
		_box("DividerNorth_%d" % int(divider_x), Vector3(divider_x, 15, -68), Vector3(8, 30, 88), "steel_dark")
		_box("DividerSouth_%d" % int(divider_x), Vector3(divider_x, 15, 68), Vector3(8, 30, 88), "steel_dark")
		_box("DoorJambNear_%d" % int(divider_x), Vector3(divider_x, 16, -25), Vector3(12, 32, 6), "steel_light")
		_box("DoorJambFar_%d" % int(divider_x), Vector3(divider_x, 16, 25), Vector3(12, 32, 6), "steel_light")
		_box("DoorHeader_%d" % int(divider_x), Vector3(divider_x, 34, 0), Vector3(12, 4, 52), "steel")
		_box("DoorLight_%d" % int(divider_x), Vector3(divider_x, 28, 0), Vector3(2, 2, 32), "cyan")
		for door_side in [-1.0, 1.0]:
			var leaf_z: float = door_side * 32.0
			var side_name := "Near" if door_side < 0.0 else "Far"
			_box("DoorLeaf_%s_%d" % [side_name, int(divider_x)], Vector3(divider_x, 15, leaf_z), Vector3(9, 28, 13), "steel_dark")
			_box("DoorFace_%s_%d" % [side_name, int(divider_x)], Vector3(divider_x, 15, leaf_z + 6.8), Vector3(6, 22, 0.6), "steel")
			_box("DoorStatus_%s_%d" % [side_name, int(divider_x)], Vector3(divider_x, 15, leaf_z + 7.2), Vector3(2, 10, 0.3), "cyan_soft")

	_box("CorridorNorthRail", Vector3(40, 12, -68), Vector3(224, 24, 7), "steel_dark")
	_box("CorridorSouthRail", Vector3(40, 12, 68), Vector3(224, 24, 7), "steel_dark")
	_box("CorridorNorthCap", Vector3(40, 25, -68), Vector3(224, 2, 10), "steel_light")
	_box("CorridorSouthCap", Vector3(40, 25, 68), Vector3(224, 2, 10), "steel_light")

	for x in [-288.0, -184.0, -16.0, 88.0, 216.0, 304.0, 416.0]:
		_box("RearWallRib_%d" % int(x), Vector3(x, 21, -110), Vector3(3, 22, 3), "steel_light")
	_box("RearWallPipe", Vector3(80, 30, -106), Vector3(780, 4, 4), "steel")
	_box("RearPipeHighlight", Vector3(80, 32.5, -106), Vector3(780, 1, 1), "steel_light")


func _build_cryo_room() -> void:
	_cryo_pod("PrimaryCryoPod", Vector3(-264, 0, -38), 68.0)
	_cryo_pod("CompactCryoPod", Vector3(-264, 0, 42), 60.0)

	_terminal("CryoDiagnosticTerminal", Vector3(-136, 0, -102), 0.9)
	_terminal("CryoWallTerminal", Vector3(-296, 0, -102), 0.75)
	_panel("CryoOverheadPanel", Vector3(-196, 24, -108), Vector3(96, 14, 7))
	_box("CryoOverheadCyan", Vector3(-196, 31, -103), Vector3(56, 1.5, 1), "cyan_soft")
	_box("CryoOverheadAmber", Vector3(-232, 31, -103), Vector3(8, 1.5, 1), "amber")
	_vent("CryoNorthVent", Vector3(-112, 8, -102), Vector3(18, 8, 6))
	_vent("CryoSouthVent", Vector3(-112, 8, 102), Vector3(18, 8, 6))

	for offset in [0.0, 8.0, 16.0]:
		_box("CryoCoolantLine_%d" % int(offset), Vector3(-200, 19 + offset * 0.2, -105), Vector3(198, 2, 3), "steel")
	_box("CryoConduitDrop", Vector3(-104, 13, -91), Vector3(3, 26, 3), "steel_light")
	_box("CryoAlertBeacon", Vector3(-104, 27, -91), Vector3(5, 4, 5), "red")


func _cryo_pod(label: String, base: Vector3, height: float) -> void:
	var x := base.x
	var z := base.z
	_box(label + "FootShadow", Vector3(x, 0.22, z), Vector3(48, 0.08, 58), "shadow")
	_box(label + "LowerSkirt", Vector3(x, 5, z), Vector3(38, 9, 48), "black")
	_box(label + "LowerArmor", Vector3(x, 9, z), Vector3(36, 7, 46), "steel_dark")
	_box(label + "PodBody", Vector3(x, height * 0.52, z), Vector3(34, height - 12, 42), "steel")
	_box(label + "LeftFrame", Vector3(x - 18, height * 0.52, z + 21), Vector3(5, height - 10, 5), "steel_light")
	_box(label + "RightFrame", Vector3(x + 18, height * 0.52, z + 21), Vector3(5, height - 10, 5), "steel_light")
	_box(label + "TopCap", Vector3(x, height - 4, z), Vector3(40, 7, 48), "steel_light")
	_box(label + "GlassBacking", Vector3(x, height * 0.55, z + 21.5), Vector3(23, height * 0.56, 1.5), "glass_frame")
	_box(label + "IlluminatedGlass", Vector3(x, height * 0.55, z + 22.5), Vector3(17, height * 0.48, 0.7), "glass")
	_box(label + "GlassHighlight", Vector3(x - 6, height * 0.58, z + 23), Vector3(2, height * 0.28, 0.35), "glass_hi")
	_box(label + "GlassGlint", Vector3(x - 2, height * 0.38, z + 23), Vector3(1, height * 0.12, 0.35), "cyan")
	_box(label + "PodControlHousing", Vector3(x + 21, height * 0.5, z + 12), Vector3(7, 22, 10), "steel_dark")
	_box(label + "PodControlScreen", Vector3(x + 21, height * 0.58, z + 17.4), Vector3(4, 8, 0.6), "cyan")
	_box(label + "PodControlAlert", Vector3(x + 21, height * 0.39, z + 17.4), Vector3(3, 2, 0.6), "amber")
	_box(label + "LowerStatus", Vector3(x, 7, z + 24), Vector3(14, 2, 1), "cyan_soft")


func _build_corridor() -> void:
	for x in [-56.0, 8.0, 72.0, 136.0]:
		_box("CorridorConduit_%d" % int(x), Vector3(x, 23, -61), Vector3(3, 5, 3), "steel")
		_box("CorridorConduitClamp_%d" % int(x), Vector3(x, 26, -61), Vector3(5, 1, 5), "steel_light")
	_box("CorridorCableTray", Vector3(40, 31, -62), Vector3(196, 3, 8), "steel_dark")
	_box("CorridorCableHighlight", Vector3(40, 33, -61), Vector3(188, 1, 2), "steel_light")
	_terminal("CorridorWallTerminal", Vector3(32, 0, -58), 0.85)
	_terminal("CorridorSignalPanel", Vector3(-56, 0, -58), 0.6)
	_box("CorridorEmergencyStrip", Vector3(120, 27, -62), Vector3(12, 2, 1), "red")
	_box("CorridorAmberStrip", Vector3(-48, 27, -62), Vector3(8, 2, 1), "amber")
	_vent("CorridorNorthVent", Vector3(-64, 10, -63), Vector3(22, 8, 5))
	_vent("CorridorSouthVent", Vector3(144, 10, -63), Vector3(22, 8, 5))

	for x in [-48.0, 32.0, 112.0]:
		_box("CorridorFloorInset_%d" % int(x), Vector3(x, 0.55, 0), Vector3(28, 0.25, 4), "steel_dark")
		_box("CorridorInsetRidge_%d" % int(x), Vector3(x, 0.75, 0), Vector3(22, 0.2, 1), "steel_light")


func _build_engineering_room() -> void:
	_reactor("AuxiliaryReactor", Vector3(220, 0, -76), 1.0)
	_reactor("CoolantGenerator", Vector3(420, 0, -76), 0.88)
	_reactor("PowerTransferUnit", Vector3(220, 0, 76), 0.85)
	_terminal("EngineeringWallConsole", Vector3(264, 0, -102), 1.05)
	_terminal("EngineeringDiagnostic", Vector3(448, 0, -102), 0.9)
	_panel("EngineeringWallRack", Vector3(362, 23, -108), Vector3(76, 24, 8))
	_box("RackDisplayPrimary", Vector3(350, 31, -102), Vector3(22, 8, 1), "cyan_soft")
	_box("RackDisplaySecondary", Vector3(378, 31, -102), Vector3(18, 8, 1), "glass")
	_status_lights(Vector3(350, 21, -102), 8)

	_bench("MechanicalBench", Vector3(408, 0, -58))
	_box("ConsoleCableTrunk", Vector3(318, 4, 56), Vector3(5, 4, 100), "steel_dark")
	_box("ConsoleCableHighlight", Vector3(318, 6.5, 56), Vector3(2, 1, 96), "cyan_soft")
	_power_console("AuxiliaryPowerConsole", Vector3(320, 0, 8))
	_vent("EngineeringWestVent", Vector3(184, 10, 0), Vector3(7, 12, 48))
	_vent("EngineeringEastVent", Vector3(456, 10, 0), Vector3(7, 12, 48))
	_box("EngineeringWarningRed", Vector3(160, 27, -44), Vector3(2, 9, 3), "red")
	_box("EngineeringWarningAmber", Vector3(160, 27, 44), Vector3(2, 9, 3), "amber")


func _reactor(label: String, base: Vector3, scale: float) -> void:
	var x := base.x
	var z := base.z
	_box(label + "FloorShadow", Vector3(x, 0.22, z), Vector3(66 * scale, 0.08, 54 * scale), "shadow")
	_box(label + "Base", Vector3(x, 4 * scale, z), Vector3(52 * scale, 8 * scale, 42 * scale), "black")
	_box(label + "LowerSide", Vector3(x, 12 * scale, z), Vector3(46 * scale, 10 * scale, 38 * scale), "steel_dark")
	_box(label + "MainHousing", Vector3(x, 29 * scale, z), Vector3(40 * scale, 28 * scale, 34 * scale), "steel")
	_box(label + "TopPlate", Vector3(x, 44 * scale, z), Vector3(48 * scale, 4 * scale, 42 * scale), "steel_light")
	_box(label + "CoreFront", Vector3(x, 29 * scale, z + 17.5 * scale), Vector3(22 * scale, 22 * scale, 1.4 * scale), "glass_frame")
	_box(label + "CoreGlow", Vector3(x, 29 * scale, z + 18.5 * scale), Vector3(14 * scale, 16 * scale, 0.8 * scale), "glass")
	_box(label + "CoreHighlight", Vector3(x - 4 * scale, 30 * scale, z + 19 * scale), Vector3(2 * scale, 12 * scale, 0.4 * scale), "cyan")
	_box(label + "SideCoolingLeft", Vector3(x - 22 * scale, 22 * scale, z + 7 * scale), Vector3(4 * scale, 16 * scale, 18 * scale), "steel_dark")
	_box(label + "SideCoolingRight", Vector3(x + 22 * scale, 22 * scale, z + 7 * scale), Vector3(4 * scale, 16 * scale, 18 * scale), "steel_dark")
	_box(label + "TopVent", Vector3(x, 47 * scale, z - 7 * scale), Vector3(26 * scale, 1 * scale, 14 * scale), "seam")
	_box(label + "StatusCyan", Vector3(x - 15 * scale, 16 * scale, z + 20 * scale), Vector3(4 * scale, 2 * scale, 1), "cyan")
	_box(label + "StatusAmber", Vector3(x + 15 * scale, 16 * scale, z + 20 * scale), Vector3(4 * scale, 2 * scale, 1), "amber")
	_box(label + "PowerPipe", Vector3(x, 50 * scale, z - 19 * scale), Vector3(4 * scale, 10 * scale, 4 * scale), "steel_light")


func _bench(label: String, base: Vector3) -> void:
	var x := base.x
	var z := base.z
	_box(label + "Shadow", Vector3(x, 0.22, z), Vector3(70, 0.08, 30), "shadow")
	_box(label + "Cabinet", Vector3(x, 9, z), Vector3(60, 16, 20), "steel_dark")
	_box(label + "SideFace", Vector3(x, 12, z + 11), Vector3(60, 10, 2), "side_face")
	_box(label + "Top", Vector3(x, 18, z), Vector3(64, 4, 24), "steel_light")
	_box(label + "WorkSurface", Vector3(x, 20.3, z), Vector3(58, 1, 18), "steel")
	_box(label + "ScreenBezel", Vector3(x, 26, z - 5), Vector3(34, 8, 3), "black")
	_box(label + "Screen", Vector3(x, 26, z - 3.2), Vector3(28, 4, 0.6), "glass")
	_box(label + "ScreenGraph", Vector3(x - 5, 26, z - 2.8), Vector3(8, 1, 0.3), "cyan")
	_box(label + "Keyboard", Vector3(x, 21.4, z + 8), Vector3(20, 0.8, 5), "steel_dark")


func _power_console(label: String, base: Vector3) -> void:
	var x := base.x
	var z := base.z
	_box(label + "FootShadow", Vector3(x, 0.22, z), Vector3(24, 0.08, 24), "shadow")
	_box(label + "Pedestal", Vector3(x, 6, z), Vector3(16, 12, 16), "steel_dark")
	_box(label + "SideFace", Vector3(x, 7, z + 8.5), Vector3(16, 8, 1), "side_face")
	_box(label + "ConsoleBody", Vector3(x, 13, z), Vector3(18, 4, 18), "steel_light")
	_box(label + "WorkSurface", Vector3(x, 15.4, z), Vector3(16, 1, 14), "steel")
	_box(label + "DisplayHousing", Vector3(x, 23, z - 3), Vector3(20, 14, 4), "black")
	_box(label + "DisplayBezel", Vector3(x, 23, z - 0.7), Vector3(17, 10, 1), "steel_light")
	_box(label + "Display", Vector3(x, 23, z), Vector3(14, 7, 0.5), "glass")
	_box(label + "DisplayLine", Vector3(x - 3, 24, z + 0.3), Vector3(6, 1, 0.2), "cyan")
	_box(label + "EmergencyIndicator", Vector3(x + 6, 17, z + 7), Vector3(3, 1, 1), "red")
	_box(label + "ReadyIndicator", Vector3(x - 6, 17, z + 7), Vector3(3, 1, 1), "cyan")


func _terminal(label: String, base: Vector3, scale: float) -> void:
	var x := base.x
	var z := base.z
	_box(label + "Mount", Vector3(x, 15 * scale, z), Vector3(34 * scale, 28 * scale, 5), "steel_dark")
	_box(label + "Bezel", Vector3(x, 20 * scale, z + 3 * scale), Vector3(28 * scale, 17 * scale, 2), "steel_light")
	_box(label + "ScreenFrame", Vector3(x, 20 * scale, z + 4.2 * scale), Vector3(23 * scale, 12 * scale, 0.8), "black")
	_box(label + "Screen", Vector3(x, 20 * scale, z + 4.8 * scale), Vector3(19 * scale, 9 * scale, 0.4), "glass")
	_box(label + "ScreenLineOne", Vector3(x - 4 * scale, 21 * scale, z + 5.1 * scale), Vector3(8 * scale, 0.7 * scale, 0.2), "cyan")
	_box(label + "ScreenLineTwo", Vector3(x + 2 * scale, 18.5 * scale, z + 5.1 * scale), Vector3(6 * scale, 0.7 * scale, 0.2), "cyan_soft")
	_box(label + "ControlDeck", Vector3(x, 8 * scale, z + 4 * scale), Vector3(30 * scale, 5 * scale, 10 * scale), "steel")
	_box(label + "KeyboardGlow", Vector3(x, 10.8 * scale, z + 8 * scale), Vector3(18 * scale, 0.6 * scale, 2 * scale), "cyan_soft")
	_status_lights(Vector3(x, 6 * scale, z + 9 * scale), 4, scale)


func _panel(label: String, position: Vector3, size: Vector3) -> void:
	_box(label + "Housing", position, size, "steel_dark")
	_box(
		label + "Face",
		position + Vector3(0, 0, size.z * 0.5 + 0.4),
		Vector3(size.x - 4, size.y - 4, 0.6),
		"steel"
	)


func _status_lights(position: Vector3, count: int, scale: float = 1.0) -> void:
	var spacing := 3.0 * scale
	for index in range(count):
		var material := "cyan" if index % 4 != 3 else "amber"
		_box(
			"StatusLight_%d_%d" % [int(position.x), index],
			position + Vector3((index - (count - 1) * 0.5) * spacing, 0, 0),
			Vector3(scale, scale, 0.5),
			material
		)


func _vent(label: String, position: Vector3, size: Vector3) -> void:
	_box(label + "Bezel", position, size, "steel_dark")
	var count := 4
	for index in range(count):
		if size.x >= size.z:
			_box(
				label + "Fin_%d" % index,
				position + Vector3((index - 1.5) * 3.0, 0, size.z * 0.5 + 0.5),
				Vector3(1, size.y * 0.55, size.z * 0.12),
				"steel_light"
			)
		else:
			_box(
				label + "Fin_%d" % index,
				position + Vector3(size.x * 0.5 + 0.5, 0, (index - 1.5) * 3.0),
				Vector3(size.x * 0.12, size.y * 0.55, 1),
				"steel_light"
			)


func _batch_boxes(
	label: String,
	size: Vector3,
	material_key: String,
	positions: Array[Vector3]
) -> void:
	if positions.is_empty():
		return
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = _unit_box
	multi_mesh.instance_count = positions.size()
	var transform_basis := Basis.from_scale(size)
	for index in range(positions.size()):
		multi_mesh.set_instance_transform(index, Transform3D(transform_basis, positions[index]))
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = multi_mesh
	instance.material_override = _materials[material_key]
	add_child(instance)


func _box(
	_label: String,
	position: Vector3,
	size: Vector3,
	material_key: String
) -> void:
	if not _box_transforms.has(material_key):
		_box_transforms[material_key] = []
	var transforms: Array = _box_transforms[material_key]
	transforms.append(Transform3D(Basis.from_scale(size), position))
