#define CAMERA_CLIP 20000.0
#define R_STEP_MAX 200
#define R_DIST_MIN 1.0
#define R_DIST_MAX 40000.0
#define R_DIST_START_OFFSET 16.0
#define V_STEP_SIZE 10.0
#define V_STEP_SIZE_DIST_MULTIPLIER 10.0
#define L_STEP_MAX 15.0
#define L_STEP_MIN 2.0
#define L_STEP_MIN_DIST 40000.0

shader_type spatial;
render_mode unshaded, shadows_disabled;

#include "res://shaders/cloud_functions.gdshaderinc"

uniform sampler2D buffer_sky : source_color, filter_linear, repeat_disable;

uniform float render_normal_offset = 7.0;
uniform float render_normal_blur = 7.0;
uniform float render_ao_amount = 2.0;
uniform float render_hg_base = 0.7;
uniform float render_hg_amount = 0.5;
uniform float render_hg_mask = 0.05;
uniform float render_hg_color_saturation = 1.0;
uniform float render_hg_color_power = 0.2;
uniform float render_sky_color_saturation = 1.0;

uniform float render_direct_shadow_ramp_dist = 1000.0;
uniform float render_direct_shadow_jitter = 0.05;
uniform float render_short_shadow_amount = 0.1;
uniform float render_short_shadow_dist = 70.0;

uniform float render_smooth_shadow_offset = 150.0;
uniform float render_smooth_shadow_bias = 100.0;
uniform float render_smooth_shadow_amount = 1.0;

void raymarch_cloud(in vec4 r_ori, in vec4 r_dir, in vec4 cloud_transform, inout vec3 cloud_out ) {
		// Buffer Vars
		float density = 0.0;
		float ao = 1.0;
		// Screen Noise
		float noise = hash14(vec4(r_dir.xyz * 1000.0, r_ori.w)) - 0.5;
		// Calculate Back Distance of BBox
		float r_back_height = max( abs(r_ori.y - cloud_base_height) + cloud_base_scale * 0.5, 0.0);
		float r_dist_back = r_back_height / abs(r_dir.y);
		// Start Distance
		float dist_ori = r_dir.w;
		
		// Inside Clip
		for(int r_step = 0; r_step < R_STEP_MAX; r_step++) {
			float dist = get_cloud_base(r_ori, vec4(r_dir.xyz, dist_ori), cloud_transform);
			
			if(dist <= cloud_detail_dist) {
				dist = mix(dist, get_cloud_detail(r_ori, vec4(r_dir.xyz, dist_ori), vec4(cloud_transform.xyz, cloud_detail_scale) ), cloud_detail_amount );
			}
			
			// Cloud SDF Shape Min Reached
			if(dist <= R_DIST_MIN) {
				// Volume March Stop Condition
				bool v_stop = false;
				
				// Volume Marching
				while(v_stop == false) {
					// Get Dist From SDF Texture To Calculate Density
					float v_dist = get_cloud_base(r_ori, vec4(r_dir.xyz, dist_ori), cloud_transform);
					v_dist = mix(v_dist, get_cloud_detail(r_ori, vec4(r_dir.xyz, dist_ori), vec4(cloud_transform.xyz, cloud_detail_scale) ), cloud_detail_amount );
					// Leave While-Loop When Not Inside Cloud Volume Shape (SDF < 0.0)
					if(v_dist > R_DIST_MIN) {
						v_stop = true;
					}
					// Inside Cloud Density
					float v_density = max(-v_dist, 0.0);
					// Adding Complexity as AO
					ao *= (1.0 - v_density * render_ao_amount * 0.001);
					// Current Density Of Volume
					float v_tex_density = linearstepc( cloud_volume_density_low, cloud_volume_density_high, get_cloud_volume(r_ori, vec4(r_dir.xyz, dist_ori), vec4(cloud_transform.xyz, cloud_volume_scale) ) * v_density );
					// Volume Step Size Adding To Distance To Origin
					float dist_step_size = 1.0 + (dist_ori / R_DIST_MAX) * V_STEP_SIZE_DIST_MULTIPLIER;
					// Add Current Density To Density Buffer (Use Hash for Correct Sorting)
					//density += v_tex_density;
					density += step( hash13( vec3(r_ori.xyz + r_dir.xyz * dist_ori) ), v_tex_density); // Noise For Pixel Perfect Mask
					// Add Raymarched Distance To Distance To Origin
					dist_ori += (V_STEP_SIZE + noise * V_STEP_SIZE) * dist_step_size;
					//dist_ori += V_STEP_SIZE * dist_step_size;
					
					if(density >= 1.0 || dist_ori > R_DIST_MAX) {
						if(density >= 1.0) {
							// Inside Clip ( Cloud SDF + Cloud Volume )
							cloud_out = vec3(ao, dist_ori, 1.0);
						}
						else {
							cloud_out = vec3(ao, R_DIST_MAX, density);
						}
						return;
					}
				}
			}
			else {
				dist_ori += dist;
			}
			
			if( dist_ori > R_DIST_MAX || dist_ori > r_dist_back ) {
				// Inside Clip (When Going Outside of BBox Or Further Than Max Ray-Dist)
				cloud_out = vec3(ao, R_DIST_MAX, density);
				return;
			}
		}
	
		// Inside Clip (Max Ray-Steps Is Reached)
		cloud_out = vec3(ao, dist_ori, density);
		return;
}

void lightmarch_cloud(in vec4 r_ori, in vec4 r_dir, in vec4 cloud_transform, inout vec3 color_out ) {
	float ao = color_out.x;
	float dist_ori = color_out.y;
	// Get World Position Based On Distance
	vec3 world_pos = r_ori.xyz + r_dir.xyz * dist_ori;
	// Cos-Theta Used for Scattering
	float cos_theta = cos_theta(r_dir.xyz, sun_light_direction);
	// Cloud Density At World Position
	float cloud_density = get_cloud_base(r_ori, vec4(r_dir.xyz, dist_ori), cloud_transform);
	cloud_density = mix(cloud_density, get_cloud_detail(r_ori, vec4(r_dir.xyz, dist_ori), vec4(cloud_transform.xyz, cloud_detail_scale) ), cloud_detail_amount );
	// Cloud Density At Normal Offset (No Detail Pass)
	float cloud_density_offset_forward = get_cloud_base(vec4(world_pos, r_ori.w), vec4(vec3(0.0, 0.0, render_normal_offset), render_normal_offset), cloud_transform);
	float cloud_density_offset_up = get_cloud_base(vec4(world_pos, r_ori.w), vec4(vec3(0.0, render_normal_offset, 0.0), render_normal_offset), cloud_transform);
	float cloud_density_offset_right = get_cloud_base(vec4(world_pos, r_ori.w), vec4(vec3(render_normal_offset, 0.0, 0.0), render_normal_offset), cloud_transform);
	// Cloud Normal
	vec3 cloud_normal;
	cloud_normal.x = (cloud_density_offset_right - cloud_density);
	cloud_normal.y = (cloud_density_offset_up - cloud_density);
	cloud_normal.z = (cloud_density_offset_forward - cloud_density);
	cloud_normal /= render_normal_offset;
	cloud_normal = normalize(cloud_normal);
	// Cloud Density At Upper Offset For Smooth Shadow
	float cloud_density_smooth = get_cloud_base(vec4(world_pos, r_ori.w), vec4( vec3(0.0, 1.0, 0.0), render_smooth_shadow_offset), cloud_transform);
	cloud_density_smooth = exp( max(-cloud_density_smooth + render_smooth_shadow_bias, 0.0) * -render_smooth_shadow_amount * 0.001);
	// Cloud Density At Screen Space Offset (Used For Henyey Greenstein To Determine Density)
	float cloud_density_offset_sss = get_cloud_base(vec4(world_pos, r_ori.w), vec4(r_dir.xyz, 50.0), cloud_transform);
	cloud_density_offset_sss = mix(cloud_density_offset_sss, get_cloud_detail(vec4(world_pos, r_ori.w), vec4(r_dir.xyz, 50.0), vec4(cloud_transform.xyz, cloud_detail_scale) ), cloud_detail_amount );
	// Cloud Inner Density
	float cloud_inner_density = cloud_density;
	cloud_inner_density = min(cloud_inner_density, cloud_density_offset_sss);
	// Henhey Greenstein Function
	float hg_mask = 1.0 - exp( cloud_inner_density * render_hg_mask );
	float hg_luminance = henyey_greenstein(cos_theta, clamp(render_hg_base - hg_mask, -1.0, 1.0) ) * render_hg_amount;
	// Color Lighting
	vec3 hg_color = mix(vec3(hg_luminance), hg_luminance * sun_light_color, pow(cos_theta * 0.5 + 0.5, render_hg_color_power) * render_hg_color_saturation );
	
	// Sky Sample Ray
	// Maybe this can be optimized with less normalizations or less samples (but currently this gives best scattering quality)
	vec3 noise_vector_c = normalize(hash33(world_pos) - 0.5);
	vec3 noise_vector_1 = normalize(hash33(world_pos * 1.067) - 0.5);
	vec3 noise_vector_2 = cross(noise_vector_1, noise_vector_c);
	vec3 noise_vector_3 = cross(noise_vector_1, noise_vector_2);
	vec3 noise_vector_4 = normalize(hash33(world_pos * 0.971) - 0.5);
	vec3 noise_vector_5 = cross(noise_vector_4, noise_vector_c);
	vec3 noise_vector_6 = cross(noise_vector_4, noise_vector_5);
	
	noise_vector_1 *= render_normal_blur;
	noise_vector_2 *= render_normal_blur;
	noise_vector_3 *= render_normal_blur;
	noise_vector_4 *= render_normal_blur;
	noise_vector_5 *= render_normal_blur;
	noise_vector_6 *= render_normal_blur;
	
	vec3 sky_ray1 = normalize(cloud_normal + noise_vector_1);
	vec3 sky_ray2 = normalize(cloud_normal - noise_vector_1);
	vec3 sky_ray3 = normalize(cloud_normal + noise_vector_2);
	vec3 sky_ray4 = normalize(cloud_normal - noise_vector_2);
	vec3 sky_ray5 = normalize(cloud_normal + noise_vector_3);
	vec3 sky_ray6 = normalize(cloud_normal - noise_vector_3);
	vec3 sky_ray7 = normalize(cloud_normal + noise_vector_4);
	vec3 sky_ray8 = normalize(cloud_normal - noise_vector_4);
	vec3 sky_ray9 = normalize(cloud_normal + noise_vector_5);
	vec3 sky_ray10 = normalize(cloud_normal - noise_vector_5);
	vec3 sky_ray11 = normalize(cloud_normal + noise_vector_6);
	vec3 sky_ray12 = normalize(cloud_normal - noise_vector_6);
	
	vec3 sky_tex = texture(buffer_sky, dir_to_skybox_uv(sky_ray1) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray2) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray3) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray4) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray5) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray6) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray7) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray8) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray9) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray10) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray11) ).xyz;
	sky_tex += texture(buffer_sky, dir_to_skybox_uv(sky_ray12) ).xyz;
	
	sky_tex *= 0.08333333333333333333333333333; // 1.0 / 12.0 - 12 samples
	sky_tex = saturation(sky_tex, render_sky_color_saturation);
	
	// Calculate Back Distance of BBox For Light Ray Start Point
	float light_back_height = max( abs(world_pos.y - cloud_base_height - cloud_base_scale * 0.5) , 0.0);
	float light_dist_back = light_back_height / abs(sun_light_direction.y);
	// Light March Stop Condition
	float dist_light = 0.0;
	// Light Iterations Based On Distance
	int l_step_max = int(L_STEP_MIN + pow4(1.0 - dist_ori / L_STEP_MIN_DIST) * L_STEP_MAX);
	
	for(int l_step = 0; l_step < l_step_max; l_step++) {
		vec3 l_step_pos = world_pos + sun_light_direction * light_dist_back;
		vec3 l_step_noise = (hash33(l_step_pos) - 0.5) * render_direct_shadow_jitter;
		float l_dist = get_cloud_base(vec4(l_step_pos, r_ori.w), vec4(-sun_light_direction.xyz + l_step_noise, dist_light), cloud_transform);
		
		if(l_dist < cloud_detail_dist) {
			l_dist = mix(l_dist, get_cloud_detail(vec4(l_step_pos, r_ori.w), vec4(-sun_light_direction.xyz + l_step_noise, dist_light), cloud_transform), cloud_detail_amount );
			if(l_dist < 1.0) {
				break;
			}
		}
		
		dist_light += l_dist;
	}
	
	// Short Distance Shadow
	float short_shadow_mask = get_cloud_base(vec4(world_pos, r_ori.w), vec4(sun_light_direction, render_short_shadow_dist), cloud_transform);
	short_shadow_mask = mix(short_shadow_mask, get_cloud_detail(vec4(world_pos, r_ori.w), vec4(sun_light_direction, render_short_shadow_dist), vec4(cloud_transform.xyz, cloud_detail_scale) ), cloud_detail_amount );
	short_shadow_mask = exp( max(-short_shadow_mask, 0.0) * -render_short_shadow_amount);
	// Directional Shadow Mask Based On Distance To Raymarched Light Ray Hit
	float dir_shadow_mask = min( pow4( linearstepc(render_direct_shadow_ramp_dist, 0.0, light_dist_back - dist_light) ), short_shadow_mask);
	// Combined Color Output (Shadow as Mask)
	color_out = vec3( mix(sky_tex * ao * cloud_density_smooth, sky_tex + hg_color, dir_shadow_mask) );
}

void fragment() {
	// Ray Direction & Ray Origin by Engine
	vec3 r_dir = normalize(-VIEW * mat3(VIEW_MATRIX));
	vec3 r_ori = CAMERA_POSITION_WORLD;
	
	// Start Distance For Ray Marcher To Save Performance (Calculating BBox)
	float r_start_height = max( abs(r_ori.y - cloud_base_height) - cloud_base_scale * 0.5 + R_DIST_START_OFFSET, 0.0);
	float r_dist_start = r_start_height / abs(r_dir.y);
	
	// Getting Cloud Values Via Raymarch Loop
	if(r_dist_start < R_DIST_MAX) {
		// Cloud Transform + Wind (vec4 = X,Y,Z,Scale)
		vec4 cloud_transform = get_cloud_transform();
		
		// Buffer Vars (cloud_out, color_out)
		vec3 cloud_out; // vec3(ao, dist, alpha)
		raymarch_cloud(vec4(r_ori, TIME), vec4(r_dir, r_dist_start), cloud_transform, cloud_out );
		//cloud_out.z = step(hash13(r_dir * 1370.0), cloud_out.z);
		
		// Defer Lights To Get More Performance (its not physically correct but significiantly reduces alus)
		if(cloud_out.z > 0.0) {
			vec3 color_out = cloud_out;
			lightmarch_cloud(vec4(r_ori, TIME), vec4(r_dir, r_dist_start), cloud_transform, color_out );
			
			ALBEDO = max(color_out, 0.0);
			ALPHA = cloud_out.z * pow3(linearstepc(R_DIST_MAX, 3000.0, cloud_out.y));
			// This Clamp Is Due To Max Depth Being Reached By The Current Camera, But Are Still Supposed To Be Rendered In The Background (this clamps the depth-range)
			vec3 depth_pos = r_ori + r_dir * clamp(cloud_out.y, -CAMERA_CLIP, CAMERA_CLIP);
			// Converting Z-Depth Back To Depth (Thanks to Zylann & Detox for helping out)
			vec4 sdf_ndc = PROJECTION_MATRIX * VIEW_MATRIX * vec4(depth_pos, 1.0);
			DEPTH = sdf_ndc.z / sdf_ndc.w;
		}
		else {
			discard;
		}
	}
	else {
		discard;
	}
}
