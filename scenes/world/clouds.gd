@tool

extends Node

@export_subgroup("Dependencies")
@export var world_environment : WorldEnvironment
@export var directional_light : DirectionalLight3D
@export var camera : Camera3D

@export_subgroup("Textures")
@export var cloud_base_texture : Texture3D:
	set(new_value):
		cloud_base_texture = new_value
		update_cloud_textures()
@export var cloud_detail_texture : Texture3D:
	set(new_value):
		cloud_detail_texture = new_value
		update_cloud_textures()
@export var cloud_volume_texture : Texture3D:
	set(new_value):
		cloud_volume_texture = new_value
		update_cloud_textures()

@export_subgroup("Wind")
@export var wind_vector : Vector2 = Vector2(1.0, 0.0):
	set(new_value):
		wind_vector = new_value
		update_cloud_globals()
@export var wind_uplift : float = 2.0:
	set(new_value):
		wind_uplift = new_value
		update_cloud_globals()

@export_subgroup("Cloud Shape")
@export var cloud_base_height : float = 1000.0:
	set(new_value):
		cloud_base_height = new_value
		update_cloud_globals()
@export var cloud_base_scale : float = 2000.0:
	set(new_value):
		cloud_base_scale = new_value
		update_cloud_globals()
@export var cloud_base_squeeze : float = 0.5:
	set(new_value):
		cloud_base_squeeze = new_value
		update_cloud_globals()
@export var cloud_detail_scale : float = 420.0:
	set(new_value):
		cloud_detail_scale = new_value
		update_cloud_globals()
@export var cloud_detail_amount : float = 0.5:
	set(new_value):
		cloud_detail_amount = new_value
		update_cloud_globals()
@export var cloud_detail_dist : float = 10.0:
	set(new_value):
		cloud_detail_dist = new_value
		update_cloud_globals()
@export var cloud_volume_scale : float = 150.0:
	set(new_value):
		cloud_volume_scale = new_value
		update_cloud_globals()
@export var cloud_volume_density_low : float = 4.0:
	set(new_value):
		cloud_volume_density_low = new_value
		update_cloud_globals()
@export var cloud_volume_density_high : float = 10.0:
	set(new_value):
		cloud_volume_density_high = new_value
		update_cloud_globals()

@export_subgroup("Cloud Rendering")
@export var render_normal_offset : float = 7.0:
	set(new_value):
		render_normal_offset = new_value
		update_cloud_shader()
@export var render_normal_blur : float = 10.0:
	set(new_value):
		render_normal_blur = new_value
		update_cloud_shader()
@export var render_ao_amount : float = 2.0:
	set(new_value):
		render_ao_amount = new_value
		update_cloud_shader()
@export var render_hg_base : float = 0.7:
	set(new_value):
		render_hg_base = new_value
		update_cloud_shader()
@export var render_hg_amount : float = 0.5:
	set(new_value):
		render_hg_amount = new_value
		update_cloud_shader()
@export var render_hg_mask : float = 0.05:
	set(new_value):
		render_hg_mask = new_value
		update_cloud_shader()
@export var render_hg_color_saturation : float = 1.0:
	set(new_value):
		render_hg_color_saturation = new_value
		update_cloud_shader()
@export var render_hg_color_power : float = 0.2:
	set(new_value):
		render_hg_color_power = new_value
		update_cloud_shader()
@export var render_sky_color_saturation : float = 1.0:
	set(new_value):
		render_sky_color_saturation = new_value
		update_cloud_shader()
@export var render_direct_shadow_ramp_dist : float = 1000.0:
	set(new_value):
		render_direct_shadow_ramp_dist = new_value
		update_cloud_shader()
@export var render_direct_shadow_jitter : float = 0.05:
	set(new_value):
		render_direct_shadow_jitter = new_value
		update_cloud_shader()
@export var render_short_shadow_amount : float = 0.1:
	set(new_value):
		render_short_shadow_amount = new_value
		update_cloud_shader()
@export var render_short_shadow_dist : float = 70.0:
	set(new_value):
		render_short_shadow_dist = new_value
		update_cloud_shader()
@export var render_smooth_shadow_offset : float = 150.0:
	set(new_value):
		render_smooth_shadow_offset = new_value
		update_cloud_shader()
@export var render_smooth_shadow_bias : float = 100.0:
	set(new_value):
		render_smooth_shadow_bias = new_value
		update_cloud_shader()
@export var render_smooth_shadow_amount : float = 1.0:
	set(new_value):
		render_smooth_shadow_amount = new_value
		update_cloud_shader()

func update_cloud_textures():
	# Set Global Texture Variables
	RenderingServer.global_shader_parameter_set("cloud_base_texture", cloud_base_texture)
	RenderingServer.global_shader_parameter_set("cloud_detail_texture", cloud_detail_texture)
	RenderingServer.global_shader_parameter_set("cloud_volume_texture", cloud_volume_texture)

func update_cloud_globals():
	# OUTPUT SETTINGS
	#print( ProjectSettings.get_setting("shader_globals/cloud_base_height") )
	# Set Global Variables In Editor Settings (Not Needed)
	#if Engine.is_editor_hint():
	#	ProjectSettings.set_setting("shader_globals/cloud_base_height", cloud_base_height)
	
	# Set Global Shape Variables
	RenderingServer.global_shader_parameter_set("cloud_base_height", cloud_base_height)
	RenderingServer.global_shader_parameter_set("cloud_base_scale", cloud_base_scale)
	RenderingServer.global_shader_parameter_set("cloud_base_squeeze", cloud_base_squeeze)
	RenderingServer.global_shader_parameter_set("cloud_detail_scale", cloud_detail_scale)
	RenderingServer.global_shader_parameter_set("cloud_detail_amount", cloud_detail_amount)
	RenderingServer.global_shader_parameter_set("cloud_detail_dist", cloud_detail_dist)
	RenderingServer.global_shader_parameter_set("cloud_volume_scale", cloud_volume_scale)
	RenderingServer.global_shader_parameter_set("cloud_volume_density_low", cloud_volume_density_low)
	RenderingServer.global_shader_parameter_set("cloud_volume_density_high", cloud_volume_density_high)
	# Set Global Wind Variables
	RenderingServer.global_shader_parameter_set("wind_vector", wind_vector)
	RenderingServer.global_shader_parameter_set("wind_uplift", wind_uplift)

func update_cloud_shader():
	$clouds.material_override.set_shader_parameter("render_normal_offset", render_normal_offset)
	$clouds.material_override.set_shader_parameter("render_normal_blur", render_normal_blur)
	$clouds.material_override.set_shader_parameter("render_ao_amount", render_ao_amount)
	$clouds.material_override.set_shader_parameter("render_hg_base", render_hg_base)
	$clouds.material_override.set_shader_parameter("render_hg_amount", render_hg_amount)
	$clouds.material_override.set_shader_parameter("render_hg_mask", render_hg_mask)
	$clouds.material_override.set_shader_parameter("render_hg_color_saturation", render_hg_color_saturation)
	$clouds.material_override.set_shader_parameter("render_hg_color_power", render_hg_color_power)
	$clouds.material_override.set_shader_parameter("render_sky_color_saturation", render_sky_color_saturation)
	$clouds.material_override.set_shader_parameter("render_direct_shadow_ramp_dist", render_direct_shadow_ramp_dist)
	$clouds.material_override.set_shader_parameter("render_direct_shadow_jitter", render_direct_shadow_jitter)
	$clouds.material_override.set_shader_parameter("render_short_shadow_amount", render_short_shadow_amount)
	$clouds.material_override.set_shader_parameter("render_short_shadow_dist", render_short_shadow_dist)
	$clouds.material_override.set_shader_parameter("render_smooth_shadow_offset", render_smooth_shadow_offset)
	$clouds.material_override.set_shader_parameter("render_smooth_shadow_bias", render_smooth_shadow_bias)
	$clouds.material_override.set_shader_parameter("render_smooth_shadow_amount", render_smooth_shadow_amount)

func update_world_environment():
	if !world_environment:
		printerr("Error! Clouds need to be linked to a WorldEnvironment node")
	else:
		# Get Sky-Material From WorldEnvironment Node
		var sky_material := world_environment.environment.sky.get_material()
		# Sync All Variables To Sky Buffer
		$buffer_sky/sky.material_override.set_shader_parameter("rayleigh", sky_material.rayleigh_coefficient )
		$buffer_sky/sky.material_override.set_shader_parameter("rayleigh_color", sky_material.rayleigh_color )
		$buffer_sky/sky.material_override.set_shader_parameter("mie", sky_material.mie_coefficient )
		$buffer_sky/sky.material_override.set_shader_parameter("mie_eccentricity", sky_material.mie_eccentricity )
		sky_material.mie_color = directional_light.light_color
		$buffer_sky/sky.material_override.set_shader_parameter("mie_color", sky_material.mie_color )
		$buffer_sky/sky.material_override.set_shader_parameter("turbidity", sky_material.turbidity )
		$buffer_sky/sky.material_override.set_shader_parameter("sun_disk_scale", sky_material.sun_disk_scale )
		$buffer_sky/sky.material_override.set_shader_parameter("ground_color", sky_material.ground_color )
		$buffer_sky/sky.material_override.set_shader_parameter("exposure", sky_material.energy_multiplier )

func update_directional_light():
	if !directional_light:
		printerr("Error! Clouds need to be linked to a DirectionalLight3D node")
	else:
		var light_direction : Vector3 = directional_light.transform.basis.z.normalized()
		# Update Global Shader Variables - Sun Light
		RenderingServer.global_shader_parameter_set("sun_light_direction", light_direction)
		RenderingServer.global_shader_parameter_set("sun_light_energy", directional_light.light_energy)
		RenderingServer.global_shader_parameter_set("sun_light_color", directional_light.light_color)

func _ready():
	$buffer_sky.size = $buffer_sky.size
	$clouds.show()
	update_cloud_globals()
	update_cloud_shader()
	update_cloud_textures()

func update_cloud_positions():
	if !camera:
		printerr("Error! Clouds need to be linked to a Camera3D node")
	else:
		$clouds.transform.origin = camera.transform.origin

@warning_ignore("unused_parameter")
func _process(delta):
	update_cloud_positions()
	update_directional_light()
	update_world_environment()
