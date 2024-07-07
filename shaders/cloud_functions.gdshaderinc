// Global Wind Vector
global uniform vec2 wind_vector;
global uniform float wind_uplift;

// Global Cloud Textures
global uniform sampler3D cloud_base_texture : hint_anisotropy, filter_linear, repeat_enable;
global uniform sampler3D cloud_detail_texture : hint_anisotropy, filter_linear, repeat_enable;
global uniform sampler3D cloud_volume_texture : hint_anisotropy, filter_linear, repeat_enable;

// Global Sun Light Variables
global uniform vec3 sun_light_direction;
global uniform float sun_light_energy;
global uniform vec3 sun_light_color;

// Global Cloud Variables
// Base
global uniform float cloud_base_height;
global uniform float cloud_base_scale;
global uniform float cloud_base_squeeze;
// Detail
global uniform float cloud_detail_scale;
global uniform float cloud_detail_amount;
global uniform float cloud_detail_dist;
// Volume
global uniform float cloud_volume_scale;
global uniform float cloud_volume_density_low;
global uniform float cloud_volume_density_high;

float pow2(float x){
    return x*x;
}

float pow3(float x){
    return x*x*x;
}

float pow4(float x){
    return pow2(pow2(x));
}

float hash13(vec3 p3) {
	p3  = fract(p3 * .1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

float hash14(vec4 p4) {
	p4 = fract(p4  * vec4(.1031, .1030, .0973, .1099));
	p4 += dot(p4, p4.wzxy+33.33);
	return fract((p4.x + p4.y) * (p4.z + p4.w));
}

vec3 hash33(vec3 p3) {
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yxz+33.33);
	return fract((p3.xxy + p3.yxx)*p3.zyx);
}

// linear version of smoothstep
float linearstepc(float a, float b, float value) {
	return clamp((value - a) / (b-a),0.0,1.0);
}

vec3 saturation(vec3 rgb, float adjustment) {
	const vec3 v = vec3(0.2125, 0.7154, 0.0721);
	vec3 intensity = vec3(dot(rgb, v));
	return mix(intensity, rgb, adjustment);
}

float lum(vec3 rgb) {
	const vec3 w = vec3(0.2125, 0.7154, 0.0721);
	return dot(rgb, w);
}

vec4 get_cloud_transform() {
	vec4 cloud_transform = vec4(0.0, cloud_base_height, 0.0, cloud_base_scale);
	cloud_transform.xz += vec2(TIME * wind_vector.x, TIME * wind_vector.y);
	return cloud_transform;
}

/*
float get_cloud_density(in vec3 r_pos) {
	vec2 tiling = 0.00002 * r_pos.xz;
	return texture(cloud_density_texture, tiling * 1.37).x * texture(cloud_density_texture, tiling * 0.57).y;
}

float get_cloud_base(in vec4 r_ori, in vec4 r_dir, in vec4 transform) {
	// Ray Position With Added Offset
	vec3 r_pos = (r_ori.xyz - transform.xyz) + (r_dir.xyz * r_dir.w);
	r_pos *= vec3(cloud_base_squeeze, 1.0, cloud_base_squeeze);
	// Avoid Bleeding From Upper and Lower Texture Tile
	//r_pos.y = clamp(r_pos.y, -0.5 * transform.w, 0.5 * transform.w);
	float clamp_height = clamp( (0.5 * transform.w - abs(r_pos.y)), -1000.0, 0.0);
	// Get Current Signed Distance At Position (Add Scaling)
	//return texture(cloud_base_texture, (r_pos.xyz / transform.w + vec3(0.5, 0.5, 0.5) ) ) * transform.w - clamp_height;
	vec2 dist_all = texture(cloud_base_texture, (r_pos.xyz / transform.w + vec3(0.5, 0.5, 0.5) ) ).xz * transform.w - clamp_height;
	
	float dist_mask = get_cloud_density(r_pos);
	float dist_out = mix( dist_all.x, dist_all.y, linearstepc(0.3, 0.6, dist_mask) );
	return dist_out;
}
*/

float get_cloud_base(in vec4 r_ori, in vec4 r_dir, in vec4 transform) {
	// Ray Position With Added Offset
	vec3 r_pos = (r_ori.xyz - transform.xyz) + (r_dir.xyz * r_dir.w);
	r_pos *= vec3(cloud_base_squeeze, 1.0, cloud_base_squeeze);
	// Avoid Bleeding From Upper and Lower Texture Tile
	//r_pos.y = clamp(r_pos.y, -0.5 * transform.w, 0.5 * transform.w);
	float clamp_height = clamp( (0.5 * transform.w - abs(r_pos.y)), -1000.0, 0.0);
	// Get Current Signed Distance At Position (Add Scaling)
	//return texture(cloud_base_texture, (r_pos.xyz / transform.w + vec3(0.5, 0.5, 0.5) ) ) * transform.w - clamp_height;
	float dist = texture(cloud_base_texture, (r_pos.xyz / transform.w + vec3(0.5, 0.5, 0.5) ) ).z * transform.w - clamp_height;
	return dist;
}

float get_cloud_detail(in vec4 r_ori, in vec4 r_dir, in vec4 transform) {
	// Ray Position With Added Offset
	vec3 detail_transform = transform.xyz;
	detail_transform.y += wind_uplift * r_ori.w;
	vec3 r_pos = (r_ori.xyz - detail_transform) + (r_dir.xyz * r_dir.w);
	// Get Current Signed Distance At Position (Add Scaling)E
	return texture(cloud_detail_texture, (r_pos.xyz / transform.w ) ).x * transform.w;
}

float get_cloud_volume(in vec4 r_ori, in vec4 r_dir, in vec4 transform) {
	// Ray Position With Added Offset
	vec3 volume_transform = transform.xyz;
	volume_transform.y += wind_uplift * r_ori.w * 2.0;
	vec3 r_pos = (r_ori.xyz - volume_transform) + (r_dir.xyz * r_dir.w);
	// Get Current Volume Texture At Position (Add Scaling)
	return texture(cloud_volume_texture, r_pos.xyz / transform.w ).x;
}

vec2 dir_to_skybox_uv(vec3 dir) {
	vec2 uv = vec2(atan(dir.x, -dir.z), acos(dir.y));
	if (uv.x < 0.0) {
		uv.x += PI * 2.0;
	}
	return (uv / vec2(PI * 2.0, PI));
}

vec3 skybox_uv_to_dir(vec2 uv) {
	uv = (uv - 0.5) * vec2(-2.0, -1.0) * PI;
	vec3 r_dir = normalize( vec3( sin(uv.x), tan(uv.y), cos(uv.x) ) * cos(uv.y) );
	return r_dir;
}

float henyey_greenstein(float cos_theta, float g) {
	const float k = 0.0795774715459;
	return k * (1.0 - g * g) / (pow(1.0 + g * g - 2.0 * g * cos_theta, 1.5));
}

float cos_theta(vec3 r_dir, vec3 light_dir) {
	return dot(r_dir, light_dir);
}
