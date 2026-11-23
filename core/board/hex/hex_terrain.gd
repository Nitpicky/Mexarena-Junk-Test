class_name HexTerrain
extends Resource
## What a painted hex tile means for movement. Matched by atlas coordinates of
## the tile in the hex TileSet. Add a tile to the atlas + a HexTerrain entry on
## the HexMap to create a new terrain.

@export var display_name: String = "Plain"
@export var atlas_coords: Vector2i = Vector2i.ZERO
## Movement points spent to enter this tile.
@export var move_cost: int = 1
## Nobody can enter or summon on it.
@export var blocked: bool = false
