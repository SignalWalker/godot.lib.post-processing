@tool
class_name ViewportShader extends TextureRect

@export var input: Viewport:
	get:
		return input
	set(value):
		self.texture = null
		input = value
		if input != null:
			self.texture = input.get_texture()
		self.input_changed.emit()

## Emitted after this ViewportShader's input is changed
signal input_changed()

static func with(vp: Viewport, mat: ShaderMaterial) -> ViewportShader:
	var res: ViewportShader = ViewportShader.new()
	res.material = mat
	res.input = vp
	return res

func _validate_property(property: Dictionary) -> void:
	match property.name:
		&"texture":
			property.usage = PROPERTY_USAGE_READ_ONLY
		&"expand_mode":
			property.usage = PROPERTY_USAGE_READ_ONLY
		&"use_parent_material":
			property.usage = PROPERTY_USAGE_READ_ONLY

func _init() -> void:
	self.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
