@tool
extends Node

enum ColorID {
	RED,     # 1,0,0
	GREEN,   # 0,1,0
	BLUE,    # 0,0,1
	YELLOW,  # 1,1,0
	CYAN,    # 0,1,1
	MAGENTA, # 1,0,1
	WHITE,   # 1,1,1
}

const bright = 0.8
const dim = 0.4

const COLOR_VALUES_MAX: Dictionary = {
	ColorID.RED:     Color(1, 0.0, 0.0),
	ColorID.GREEN:   Color(0.0, 1, 0.0),
	ColorID.BLUE:    Color(0.0, 0.0, 1),
	ColorID.YELLOW:  Color(1, 1, 0.0),
	ColorID.CYAN:    Color(0.0, 1, 1),
	ColorID.MAGENTA: Color(1, 0.0, 1),
	ColorID.WHITE:   Color(1, 1, 1),
}

const COLOR_VALUES: Dictionary = {
	ColorID.RED:     Color(bright, 0.0, 0.0),
	ColorID.GREEN:   Color(0.0, bright, 0.0),
	ColorID.BLUE:    Color(0.0, 0.0, bright),
	ColorID.YELLOW:  Color(bright, bright, 0.0),
	ColorID.CYAN:    Color(0.0, bright, bright),
	ColorID.MAGENTA: Color(bright, 0.0, bright),
	ColorID.WHITE:   Color(bright, bright, bright),
}

const COLOR_VALUES_DARKER: Dictionary = {
	ColorID.RED:     Color(dim, 0.0, 0.0),
	ColorID.GREEN:   Color(0.0, dim, 0.0),
	ColorID.BLUE:    Color(0.0, 0.0, dim),
	ColorID.YELLOW:  Color(dim, dim, 0.0),
	ColorID.CYAN:    Color(0.0, dim, dim),
	ColorID.MAGENTA: Color(dim, 0.0, dim),
	ColorID.WHITE:   Color(dim, dim, dim),
}


## Each color tracks which light sources are currently activating it.
## A color is enabled when it has at least one source (or is WHITE).
var _color_sources: Dictionary = {
	ColorID.RED:     {},
	ColorID.GREEN:   {},
	ColorID.BLUE:    {},
	ColorID.YELLOW:  {},
	ColorID.CYAN:    {},
	ColorID.MAGENTA: {},
	ColorID.WHITE:   {},
}


func get_color(id: ColorID) -> Color:
	if is_enabled(id):
		return COLOR_VALUES[id]
	return COLOR_VALUES_DARKER[id]
	
func get_bright_color(id: ColorID) -> Color:
	return COLOR_VALUES[id]

func get_dark_color(id: ColorID) -> Color:
	return COLOR_VALUES_DARKER[id]

## Register a light source for a color. Pass the light node (or any unique key).
func add_source(id: ColorID, source: Object) -> void:
	_color_sources[id][source] = true


## Unregister a light source for a color.
func remove_source(id: ColorID, source: Object) -> void:
	_color_sources[id].erase(source)


## White is always enabled. Others are enabled when at least one source exists.
func is_enabled(id: ColorID) -> bool:
	if id == ColorID.WHITE:
		return true
	return _color_sources[id].size() > 0


func get_color_name(id: ColorID) -> String:
	return ColorID.keys()[id]


func get_all() -> Array:
	return COLOR_VALUES.values()
