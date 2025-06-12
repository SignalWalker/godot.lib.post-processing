@tool
class_name ScreenShader extends CanvasLayer

const REGION_UNIFORM: StringName = &"texture_region"

var material: ShaderMaterial:
	get:
		return material
	set(value):
		if value == null:
			material = value
			self.material_changed.emit()
			return
		var shader: Shader = value.shader;
		if shader.get_mode() != Shader.MODE_CANVAS_ITEM:
			printerr("[PostProcessing] expected CanvasItem shader")
			return
		material = value
		self.material_changed.emit()

var input: BackBufferCopy
var output: ColorRect

signal material_changed()

func _init(mat: ShaderMaterial = null) -> void:
	self.material = mat

	self.input = BackBufferCopy.new()
	input.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT

	self.output = ColorRect.new()
	self.output.material = mat
	self.output.set_anchors_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	self.add_child(self.input, false, Node.INTERNAL_MODE_BACK)
	self.add_child(self.output, false, Node.INTERNAL_MODE_BACK)

func set_shader_parameter(param: StringName, value: Variant) -> void:
	if self.material == null:
		return
	self.material.set_shader_parameter(param, value)
