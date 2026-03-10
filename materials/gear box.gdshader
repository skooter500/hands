shader_type spatial;
uniform float seed_variation = 0.0;

uniform bool ambient_occlusion = true;
uniform bool shadow = true;
uniform float ao_samples : hint_range(16,256,1) = 32;
uniform float ao_spread = 0.07;
uniform float ao_strength = 2.34;
uniform float shadow_samples : hint_range(16,256,1) = 32;
uniform float shadow_mix = 0.71;
uniform float shadow_min_dist = 0;
uniform float shadow_max_dist = 8;
uniform float light_size : hint_range(0.0,1.0,0.001) = 0;
uniform vec3 light_direction = vec3(0.03,4,-0.74);

float rand(vec2 x) {
    return fract(cos(mod(dot(x, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}
vec2 rand2(vec2 x) {
    return fract(cos(mod(vec2(dot(x, vec2(13.9898, 8.141)),
						      dot(x, vec2(3.4562, 17.398))), vec2(3.14))) * 43758.5453);
}
vec3 rand3(vec2 x) {
    return fract(cos(mod(vec3(dot(x, vec2(13.9898, 8.141)),
							  dot(x, vec2(3.4562, 17.398)),
                              dot(x, vec2(13.254, 5.867))), vec3(3.14))) * 43758.5453);
}
float param_rnd(float minimum, float maximum, float seed) {
	return minimum+(maximum-minimum)*rand(vec2(seed));
}
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
	vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
const float o101606_height = 0.030000000; // {default:0.5, label:Height, max:1, min:0, name:height, step:0.01, type:named_parameter}
const float p_o101594_sha_iter = 32.000000000;
const float p_o101594_sha_mint = 0.000000000;
const float p_o101594_sha_maxt = 8.000000000;
const float p_o101594_sha_mix = 0.710000000;
const float p_o101594_ao_iter = 32.000000000;
const float p_o101594_ao_max_dist = 0.070000000;
const float p_o101594_ao_falloff = 2.340000000;
const float p_o101594_ldx = 0.030000000;
const float p_o101594_ldy = 4.000000000;
const float p_o101594_ldz = -0.740000000;
const float p_o101594_lw = 0.000000000;
vec2 o101594_input_distance(vec3 p, float _seed_variation_) {
return vec2(0.0);
}
const float p_o101652_d_in1_x = 0.000000000;
const float p_o101652_d_in1_y = 0.000000000;
const float p_o101652_d_in1_z = 0.000000000;
const float p_o101652_d_in2_x = 3.000000000;
const float p_o101652_d_in2_y = 3.000000000;
const float p_o101652_d_in2_z = 3.000000000;
varying float elapsed_time;
varying vec3 world_camera;
varying vec3 world_position;
const int MAX_STEPS = 100;
const float MAX_DIST = 100.0;
const float SURF_DIST = 1e-3;
vec2 GetDist(vec3 p) {
	float _seed_variation_ = 0.0;
	

		if (false) {
			p *= vec3(1.0, -1.0, 1.0);
		} 


	vec2 d = o101594_input_distance(p, _seed_variation_);

	return d;
}
vec2 RayMarch(vec3 ro, vec3 rd) {
	float dO = 0.0;
	float color = 0.0;
	vec2 dS;
	
	for (int i = 0; i < MAX_STEPS; i++)
	{
		vec3 p = ro + dO * rd;
		dS = GetDist(p);
		dO += dS.x;
		
		if (abs(dS.x) < SURF_DIST || dO > MAX_DIST) {
			color = dS.y;
			break;
		}
	}
	return vec2(dO, color);
}
vec3 GetNormal(vec3 p) {
	vec2 e = vec2(1e-3, 0);
	
	vec3 n = GetDist(p).x - vec3(
		GetDist(p - e.xyy).x,
		GetDist(p - e.yxy).x,
		GetDist(p - e.yyx).x
	);
	
	return normalize(n);
}
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float w, int iter )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<iter && t<maxt; i++ )
    {
        float h = GetDist(ro + t*rd).x;
        res = min( res, h/(w*t) );
        t += clamp(h, 0.005, 0.50);
        if( res<-1.0 || t>maxt ) break;
    }
    res = max(res,-1.0);
    return 0.25*(1.0+res)*(1.0+res)*(2.0-res);
}
vec3 randomSphereDir(vec2 rnd)
{
    float s = rnd.x*6.283185;
    float t = rnd.y*2.0-1.0;
    return vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
}
vec3 randomHemisphereDir(vec3 dir, float i)
{
	vec3 v = randomSphereDir(vec2(rand(vec2(i+1.0)),rand(vec2(i+2.0))));
    return v * sign(dot(v, dir));
}
float ambientOcclusion( in vec3 p, in vec3 n, in float maxDist, in float falloff, int iter )
{
   float nbIteInv = 1./float(iter);
   float rad = 1.-1.*nbIteInv; //Hemispherical factor (self occlusion correction)
   float ao = 0.0;
   for( int i=0; i<iter; i++ )
   {
	float l = rand(vec2(float(i)))*maxDist;
    vec3 rd = normalize(n+randomHemisphereDir(n, l )*rad)*l; // mix direction with the normal for self occlusion problems!
	ao += (l - max(GetDist( p + rd ),0.).x) / maxDist * falloff;
   }
	return clamp( 1.-ao*nbIteInv, 0., 1.);
}
void vertex() {
	elapsed_time = TIME;
	world_position = VERTEX;
	world_camera = (inverse(MODELVIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz; //object space
	//world_camera = ( INV_VIEW_MATRIX  * vec4(0, 0, 0, 1)).xyz; //uncomment this to raymarch in world space
}
void fragment() {
	float _seed_variation_ = 0.0;
	vec3 ro = world_camera;
	vec3 rd =  normalize(world_position - ro);
	
	vec2 rm  = RayMarch(ro, rd);
	float d = rm.x;
	if (d >= MAX_DIST)
		discard;
	else
	{
		vec3 p = ro + rd * d;
		vec3 n = GetNormal(p);
		

		float occ = ambientOcclusion(p, n, ao_spread, ao_strength, int(ao_samples));
		vec3 lig = normalize( light_direction );
		float sha = softshadow(p, lig, shadow_min_dist, shadow_max_dist, light_size, int(shadow_samples));
		if (false) {
			p *= vec3(1.0, -1.0, 1.0);
			n *= vec3(1.0, -1.0, 1.0);
		}

vec3 o101652_0_clamp_false = vec3(p_o101652_d_in1_x, p_o101652_d_in1_y, p_o101652_d_in1_z)*vec3(p_o101652_d_in2_x, p_o101652_d_in2_y, p_o101652_d_in2_z);
vec3 o101652_0_clamp_true = clamp(o101652_0_clamp_false, vec3(0.0), vec3(1.0));
vec3 o101652_0_2_tex3d = o101652_0_clamp_false;

		ALBEDO = o101652_0_2_tex3d
			* (ambient_occlusion ? occ : 1.0)
			* (shadow ? mix(1.0,sha,shadow_mix) : 1.0);
		ROUGHNESS = *error missing tex3d_gs*
{"globals":[],"defs":"","code":"","textures":{},"type":"f","f":"0.0","rgb":"vec3(0.0)","rgba":"vec4(vec3(0.0), 1.0)"};
		METALLIC = *error missing tex3d_gs*
{"globals":[],"defs":"","code":"","textures":{},"type":"f","f":"0.0","rgb":"vec3(0.0)","rgba":"vec4(vec3(0.0), 1.0)"};
		EMISSION = vec3(0.0);

		NORMAL = (VIEW_MATRIX*MODEL_MATRIX*vec4(n, 0.0)).xyz;
	}
}



