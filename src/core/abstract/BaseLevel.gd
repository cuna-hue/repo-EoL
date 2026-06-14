@abstract
class_name BaseLevel
extends Node
## Abstract class for levels

## Provides a player spawn location
@abstract func get_default_player_spawn() -> Vector2

## Provides the camera used in the level
@abstract func get_player_camera() -> Camera2D
