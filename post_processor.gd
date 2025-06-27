@tool
class_name PostProcessor extends ViewportShader

## Emitted after this PostProcessor chain is reset
signal was_reset()

var first_in_chain: WeakRef = weakref(self)
var chain_root: Node = null

## Input to the first shader in the chain
@export var initial: Viewport:
	get:
		return initial
	set(value):
		initial = value
		var first: ViewportShader = self.first_in_chain.get_ref()
		assert(first != null, "first_in_chain not found")
		first.input = initial

@export var chain: PostProcessingChain:
	get:
		return chain
	set(value):
		if chain != null:
			chain.changed.disconnect(self._on_chain_changed)
		chain = value
		if chain != null:
			chain.changed.connect(self._on_chain_changed)
		self.reset.call_deferred()

## Whether to enable HDR on internal subviewports
@export var use_hdr: bool:
	get:
		return use_hdr
	set(value):
		use_hdr = value
		for child: Node in self.get_children():
			if child is Viewport:
				(child as Viewport).use_hdr_2d = use_hdr

func _validate_property(property: Dictionary) -> void:
	super(property)
	match property.name:
		&"input":
			property.usage = PROPERTY_USAGE_READ_ONLY

func _init() -> void:
	super()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			if self.chain_root != null:
				for child: Node in self.chain_root.get_children():
					assert(child is SubViewport)
					(child as SubViewport).size = self.size

func is_rendering() -> bool:
	return self.material != null && self.input != null

func reset() -> void:
	# free old chain
	if self.chain_root != null:
		self.chain_root.free()
		self.chain_root = null

	# reset first_in_chain
	self.first_in_chain = weakref(self)

	# reset input & material
	self.material = null
	self.input = self.initial

	if self.chain == null:
		# no shaders to add, so just quit
		self.was_reset.emit()
		return

	# add new chain shaders...

	# update chain root
	self.chain_root = Node.new()
	self.chain_root.name = &"__PostProcessorChainRoot"
	self.add_child(self.chain_root, false, INTERNAL_MODE_BACK)

	var prev_vp: Viewport = self.initial

	# for all shaders in chain...
	for index: int in range(0, self.chain.chain.size()):
		var mat: ShaderMaterial = self.chain.chain[index]

		if index == self.chain.chain.size() - 1:
			# last shader, which is rendered to self
			self.input = prev_vp
			self.material = mat
		else:
			# make shader node...
			var shader: ViewportShader
			if mat.has_method(&"make_viewport_shader"):
				shader = mat.call(&"make_viewport_shader", prev_vp)
			else:
				shader = ViewportShader.with(prev_vp, mat)
			shader.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
			# if it's the first one, update first_in_chain
			if index == 0:
				self.first_in_chain = weakref(shader)

			# make viewport...
			var vp: SubViewport = SubViewport.new()

			vp.size = self.size

			# # ensure this renders even if it isn't visible (which it won't be)
			# vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

			# rendering settings...
			vp.anisotropic_filtering_level = Viewport.ANISOTROPY_DISABLED
			vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
			vp.disable_3d = true
			vp.gui_disable_input = true
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			vp.snap_2d_transforms_to_pixel = true
			vp.snap_2d_vertices_to_pixel = true
			vp.use_debanding = false
			vp.use_hdr_2d = self.use_hdr

			# add to tree...
			vp.add_child(shader)
			self.chain_root.add_child(vp)

			# update prev_vp
			prev_vp = vp

	self.was_reset.emit()

func _on_chain_changed() -> void:
	self.reset.call_deferred()
