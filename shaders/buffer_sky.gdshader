shader_type spatial;
render_mode unshaded, shadows_disabled;

// Global Sun Light Variables
global uniform vec3 sun_light_direction;
global uniform float sun_light_energy;
global uniform vec3 sun_light_color;

// Sky Shader
uniform float rayleigh : hint_range(0, 64) = 2.0;
uniform vec4 rayleigh_color : source_color = vec4(0.3, 0.405, 0.6, 1.0);
uniform float mie : hint_range(0, 1) = 0.005;
uniform float mie_eccentricity : hint_range(-1, 1) = 0.8;
uniform vec4 mie_color : source_color = vec4(0.69, 0.729, 0.812, 1.0);

uniform float turbidity : hint_range(0, 1000) = 10.0;
uniform float sun_disk_scale : hint_range(0, 360) = 1.0;
uniform vec4 ground_color : source_color = vec4(0.1, 0.07, 0.034, 1.0);
uniform float exposure : hint_range(0, 128) = 1.0;

// Sun constants
const float light_size = 0.00872663806;
const float SUN_ENERGY = 1000.0; //OLD 1000.0

// optical length at zenith for molecules
const float rayleigh_zenith_size = 8.4e3;
const float mie_zenith_size = 1.25e3;
const vec3 UP = vec3( 0.0, 1.0, 0.0 );

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

// cheaper than smoothstep() linear version
float linearstepc(float a, float b, float value) {
	return clamp((value - a) / (b-a),0.0,1.0);
}

float henyey_greenstein(float cos_theta, float g) {
	const float k = 0.0795774715459;
	return k * (1.0 - g * g) / (pow(1.0 + g * g - 2.0 * g * cos_theta, 1.5));
}

float cos_theta(vec3 r_dir, vec3 light_dir) {
	return dot(r_dir, normalize(light_dir));
}

vec3 atmosphere_clouds(vec3 eye_dir) {
	float zenith_angle = clamp( dot( UP, normalize(sun_light_direction)), -1.0, 1.0 );
	float sun_energy = max(0.0, 1.0 - exp(-((PI * 0.5) - acos(zenith_angle)))) * sun_light_energy;
	float sun_fade = 1.0 - clamp(1.0 - exp(normalize(sun_light_direction).y), 0.0, 1.0);

	// Rayleigh coefficients.
	float rayleigh_coefficient = rayleigh - ( 1.0 * ( 1.0 - sun_fade ) );
	vec3 rayleigh_beta = rayleigh_coefficient * rayleigh_color.rgb * 0.0001;
	// mie coefficients from Preetham
	vec3 mie_beta = turbidity * mie * mie_color.rgb * 0.000434;

	// optical length
	float zenith = acos(max(0.0, dot( UP, eye_dir)));
	float optical_mass = 1.0 / (cos(zenith) + 0.15 * pow(93.885 - degrees(zenith), -1.253));
	float rayleigh_scatter = rayleigh_zenith_size * optical_mass;
	float mie_scatter = mie_zenith_size * optical_mass;

	// light extinction based on thickness of atmosphere
	vec3 extinction = exp(-(rayleigh_beta * rayleigh_scatter + mie_beta * mie_scatter));

	// in scattering
	float cos_theta = dot(eye_dir, normalize(sun_light_direction));

	float rayleigh_phase = (3.0 / (16.0 * PI)) * (1.0 + pow(cos_theta * 0.5 + 0.5, 2.0));
	vec3 betaRTheta = rayleigh_beta * rayleigh_phase;

	float mie_phase = henyey_greenstein(cos_theta, mie_eccentricity);
	vec3 betaMTheta = mie_beta * mie_phase;

	vec3 Lin = pow(sun_energy * ((betaRTheta + betaMTheta) / (rayleigh_beta + mie_beta)) * (1.0 - extinction), vec3(1.5));
		// Hack from https://github.com/mrdoob/three.js/blob/master/examples/jsm/objects/Sky.js
		Lin *= mix(vec3(1.0), pow(sun_energy * ((betaRTheta + betaMTheta) / (rayleigh_beta + mie_beta)) * extinction, vec3(0.5)), clamp(pow(1.0 - zenith_angle, 5.0), 0.0, 1.0));
	
	vec3 color;
	// Hack in the ground color
	//Lin  *= mix(ground_color.rgb, vec3(1.0), smoothstep(-0.1, 0.1, dot(UP, EYEDIR)));
	//Lin *= mix(ground_color.rgb, vec3(1.0), linearstepc(-0.1, 0.1, dot(UP, eye_dir)));
	// Modified For Clouds
	Lin *= mix(ground_color.rgb, vec3(1.0), linearstepc(-0.9, 0.1, dot(UP, eye_dir)) * 0.9 + 0.1 );

	// Solar disk and out-scattering
	float sunAngularDiameterCos = cos(light_size * sun_disk_scale);
	float sunAngularDiameterCos2 = cos(light_size * sun_disk_scale * 0.5);
	float sundisk = smoothstep(sunAngularDiameterCos, sunAngularDiameterCos2, cos_theta);
	vec3 L0 = (sun_energy * extinction) * sundisk * sun_light_color.xyz;
	//L0 += texture(night_sky, SKY_COORDS).xyz * extinction;
	
	color = Lin + L0;
	color = pow(color, vec3(1.0 / (1.2 + (1.2 * sun_fade) ) ) );
	color *= exposure;
	
	return color;
}

void fragment() {
	vec3 sky_direction = skybox_uv_to_dir(SCREEN_UV);
	ALBEDO = atmosphere_clouds(sky_direction);
}