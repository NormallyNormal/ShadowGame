@tool
extends SpotLight3D

@export var color: Colors.ColorID = Colors.ColorID.WHITE:
	set(value):
		color = value
		light_color = Colors.COLOR_VALUES_MAX[color]

func _ready() -> void:
	if not Engine.is_editor_hint():
		%Screen.projecting_lights.append(self)
