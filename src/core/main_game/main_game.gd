class_name MainGame
extends Node2D
## Main entry pont for the game
## Responsible for setting up the World layers and coordinating high-level systems

const TEST_LEVEL_GRASSLAND 	= "uid://db0g8rvnkq2ej"
const PLAYER_SCENE_UID		= "uid://c57jnrgvc8rp0"

var player: Player = null

var _current_level : BaseLevel = null

# Game World Root Nodes
@onready var level_root: 	Node2D = $World/LevelRoot
@onready var item_root: 	Node2D = $World/ItemRoot
@onready var entity_root: 	Node2D = $World/EntityRoot
@onready var effect_root: 	Node2D = $World/EffectRoot

# UI Root Nodes
@onready var hud_layer: 		CanvasLayer = $HudLayer
@onready var pause_layer: 		CanvasLayer = $PauseLayer
@onready var transition_layer: 	CanvasLayer = $TransitionLayer
@onready var debug_layer: 		CanvasLayer = $DebugLayer

func _ready() -> void:
	_init_player()
	load_level(TEST_LEVEL_GRASSLAND)
	
## Called for loading a level scene.
## NOTE: The input level_scnee must extend BaseLevel
func load_level(level_scene : String) -> void:
		# Make sure this is called during idle time
		_deferred_load_level.call_deferred(level_scene)

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build(): return # Nur im DebugModus - außerhalb von shipping
	
	if event.is_action_pressed(&"debug_quit"):
		quit_game()

func quit_game() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _init_player() -> void:
	var player_scene : PackedScene = ResourceLoader.load(PLAYER_SCENE_UID) as PackedScene
	if not player_scene:
		push_error("Could not load player scene: " + PLAYER_SCENE_UID)
		return
	
	player = player_scene.instantiate() as Player
	if not player:
		# push_error("Loaded player scene does not extend player or does not exist: " + PLAYER_SCENE_UID)
		return
	entity_root.add_child(player)
	

func _deferred_load_level(level_scene_uid: String) -> void:
	var new_level: BaseLevel = null
	
	
	var new_level_packed : PackedScene =\
		ResourceLoader.load(level_scene_uid, "PackedScene") as PackedScene
	new_level = new_level_packed.instantiate() as BaseLevel
		
	if not new_level:
		# push_error(("Loaded level is not of type level or does not exist"))
		return
		# FUTURE (main menu) Should have a fall back scene
	
	if _current_level:
		_current_level.queue_free()
		_current_level = null
		# Allow the old level to finish freeing before adding the new one
		await get_tree().process_frame
	level_root.add_child(new_level)
	
	# Allow level to fully process before accessing it 
	await get_tree().process_frame
	_place_player_at_level_spawn()
	_setup_level_camera()
	
## Finds the default spawn location in currently loaded level, and places
## the player at that position
func _place_player_at_level_spawn() -> void:
	if not player:
		push_error("Cannot place player into level because player is null")
		return
	if not _current_level:
		push_error("Cannot place player into level because level is null")

	player.global_position = _current_level.get_default_player_spawn()
	
## Attaches player to the current camera as the target
func _setup_level_camera() -> void:
	if not player or not _current_level: return
	
	var level_camera: Camera2D = _current_level.get_player_camera()
	if not level_camera: 
		push_error("No camera found in current_level")
		return
		
	# FUTURE (camera): Temporary hookup
	# Will become: camera_system_set_target(player)
	level_camera.target = player
