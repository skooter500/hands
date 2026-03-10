shader_type spatial;
render_mode blend_mix,cull_back,diffuse_burley,specular_schlick_ggx
;
uniform vec3 uv1_offset = vec3(0.0, 0.0, 0.0);
uniform vec3 uv1_scale = vec3(1.0, 1.0, 1.0);
uniform int depth_min_layers = 8;
uniform int depth_max_layers = 16;
uniform vec2 depth_flip = vec2(1.0);
uniform float variation = 0.0;
varying float elapsed_time;
void vertex() {
	elapsed_time = TIME;
	UV = UV*uv1_scale.xy+uv1_offset.xy;
}
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
float pingpong(float a, float b)
{
  return (b != 0.0) ? abs(fract((a - b) / (b * 2.0)) * b * 2.0 - b) : 0.0;
}
float shape_circle(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = max(edge, 1.0e-8);
	float distance = length(uv);
	return clamp((1.0-distance/size)/edge, 0.0, 1.0);
}
float shape_polygon(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = max(edge, 1.0e-8);
	float angle = atan(uv.x, uv.y)+3.14159265359;
	float slice = 6.28318530718/sides;
	return clamp((1.0-(cos(floor(0.5+angle/slice)*slice-angle)*length(uv))/size)/edge, 0.0, 1.0);
}
float shape_star(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = max(edge, 1.0e-8);
	float angle = atan(uv.x, uv.y);
	float slice = 6.28318530718/sides;
	return clamp((1.0-(cos(floor(angle*sides/6.28318530718-0.5+2.0*step(fract(angle*sides/6.28318530718), 0.5))*slice-angle)*length(uv))/size)/edge, 0.0, 1.0);
}
float shape_curved_star(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = max(edge, 1.0e-8);
	float angle = 2.0*(atan(uv.x, uv.y)+3.14159265359);
	float slice = 6.28318530718/sides;
	return clamp((1.0-cos(floor(0.5+0.5*angle/slice)*2.0*slice-angle)*length(uv)/size)/edge, 0.0, 1.0);
}
float shape_rays(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = 0.5*max(edge, 1.0e-8)*size;
	float slice = 6.28318530718/sides;
	float angle = mod(atan(uv.x, uv.y)+3.14159265359, slice)/slice;
	return clamp(min((size-angle)/edge, angle/edge), 0.0, 1.0);
}
vec2 get_from_tileset(float count, float seed, vec2 uv) {
	return clamp((uv+floor(rand2(vec2(seed))*count))/count, vec2(0.0), vec2(1.0));
}
vec2 custom_uv_transform(vec2 uv, vec2 cst_scale, float rnd_rotate, float rnd_scale, vec2 seed) {
	seed = rand2(seed);
	uv -= vec2(0.5);
	float angle = (seed.x * 2.0 - 1.0) * rnd_rotate;
	float ca = cos(angle);
	float sa = sin(angle);
	uv = vec2(ca*uv.x+sa*uv.y, -sa*uv.x+ca*uv.y);
	uv *= (seed.y-0.5)*2.0*rnd_scale+1.0;
	uv /= cst_scale;
	uv += vec2(0.5);
	return uv;
}
float wave_constant(float x) {
	return 1.0;
}
float wave_sine(float x) {
	return 0.5-0.5*cos(3.14159265359*2.0*x);
}
float wave_triangle(float x) {
	x = fract(x);
	return min(2.0*x, 2.0-2.0*x);
}
float wave_sawtooth(float x) {
	return fract(x);
}
float wave_square(float x) {
	return (fract(x) < 0.5) ? 0.0 : 1.0;
}
float wave_bounce(float x) {
	x = 2.0*(fract(x)-0.5);
	return sqrt(1.0-x*x);
}
float mix_mul(float x, float y) {
	return x*y;
}
float mix_add(float x, float y) {
	return min(x+y, 1.0);
}
float mix_max(float x, float y) {
	return max(x, y);
}
float mix_min(float x, float y) {
	return min(x, y);
}
float mix_xor(float x, float y) {
	return min(x+y, 2.0-x-y);
}
float mix_pow(float x, float y) {
	return pow(x, y);
}
vec2 scale(vec2 uv, vec2 center, vec2 scale) {
	uv -= center;
	uv /= scale;
	uv += center;
	return uv;
}
vec3 blend_normal(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*c1 + (1.0-opacity)*c2;
}
vec3 blend_dissolve(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	if (rand(uv) < opacity) {
		return c1;
	} else {
		return c2;
	}
}
vec3 blend_multiply(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*c1*c2 + (1.0-opacity)*c2;
}
vec3 blend_screen(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*(1.0-(1.0-c1)*(1.0-c2)) + (1.0-opacity)*c2;
}
float blend_overlay_f(float c1, float c2) {
	return (c1 < 0.5) ? (2.0*c1*c2) : (1.0-2.0*(1.0-c1)*(1.0-c2));
}
vec3 blend_overlay(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_overlay_f(c1.x, c2.x), blend_overlay_f(c1.y, c2.y), blend_overlay_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
vec3 blend_hard_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*0.5*(c1*c2+blend_overlay(uv, c1, c2, 1.0)) + (1.0-opacity)*c2;
}
float blend_soft_light_f(float c1, float c2) {
	return (c2 < 0.5) ? (2.0*c1*c2+c1*c1*(1.0-2.0*c2)) : 2.0*c1*(1.0-c2)+sqrt(c1)*(2.0*c2-1.0);
}
vec3 blend_soft_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_soft_light_f(c1.x, c2.x), blend_soft_light_f(c1.y, c2.y), blend_soft_light_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_burn_f(float c1, float c2) {
	return (c1==0.0)?c1:max((1.0-((1.0-c2)/c1)),0.0);
}
vec3 blend_burn(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_burn_f(c1.x, c2.x), blend_burn_f(c1.y, c2.y), blend_burn_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_dodge_f(float c1, float c2) {
	return (c1==1.0)?c1:min(c2/(1.0-c1),1.0);
}
vec3 blend_dodge(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_dodge_f(c1.x, c2.x), blend_dodge_f(c1.y, c2.y), blend_dodge_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
vec3 blend_lighten(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*max(c1, c2) + (1.0-opacity)*c2;
}
vec3 blend_darken(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*min(c1, c2) + (1.0-opacity)*c2;
}
vec3 blend_difference(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*clamp(c2-c1, vec3(0.0), vec3(1.0)) + (1.0-opacity)*c2;
}
vec3 blend_additive(vec2 uv, vec3 c1, vec3 c2, float oppacity) {
	return c2 + c1 * oppacity;
}
vec3 blend_addsub(vec2 uv, vec3 c1, vec3 c2, float oppacity) {
	return c2 + (c1 - .5) * 2.0 * oppacity;
}
float blend_linear_light_f(float c1, float c2) {
	return (c1 + 2.0 * c2) - 1.0;
}
vec3 blend_linear_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
return opacity*vec3(blend_linear_light_f(c1.x, c2.x), blend_linear_light_f(c1.y, c2.y), blend_linear_light_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_vivid_light_f(float c1, float c2) {
	return (c1 < 0.5) ? 1.0 - (1.0 - c2) / (2.0 * c1) : c2 / (2.0 * (1.0 - c1));
}
vec3 blend_vivid_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_vivid_light_f(c1.x, c2.x), blend_vivid_light_f(c1.y, c2.y), blend_vivid_light_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_pin_light_f( float c1, float c2) {
	return (2.0 * c1 - 1.0 > c2) ? 2.0 * c1 - 1.0 : ((c1 < 0.5 * c2) ? 2.0 * c1 : c2);
}
vec3 blend_pin_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_pin_light_f(c1.x, c2.x), blend_pin_light_f(c1.y, c2.y), blend_pin_light_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_hard_mix_f(float c1, float c2) {
	return floor(c1 + c2);
}
vec3 blend_hard_mix(vec2 uv, vec3 c1, vec3 c2, float opacity) {
		return opacity*vec3(blend_hard_mix_f(c1.x, c2.x), blend_hard_mix_f(c1.y, c2.y), blend_hard_mix_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_exclusion_f(float c1, float c2) {
	return c1 + c2 - 2.0 * c1 * c2;
}
vec3 blend_exclusion(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_exclusion_f(c1.x, c2.x), blend_exclusion_f(c1.y, c2.y), blend_exclusion_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
const vec4 p_o290182_albedo_color = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o290182_metallic = 0.000000000;
const float p_o290182_roughness = 0.110000000;
const float p_o290182_emission_energy = 0.000000000;
const float p_o290182_normal = 1.000000000;
const float p_o290182_ao = 1.000000000;
const float p_o290182_depth_scale = 1.000000000;
float o290182_input_depth_tex(vec2 uv, float _seed_variation_) {
return 0.0;
}
const float p_o290187_amount1 = 1.720000000;
const float p_o290187_amount2 = 1.000000000;
const float p_o290183_amount = 0.200000000;
const float p_o290183_eps = 0.010000000;
const float seed_o290204 = 0.389765739;
const float p_o290204_count = 25.000000000;
const float p_o290204_scale_x = 0.700000000;
const float p_o290204_scale_y = 0.700000000;
const float p_o290204_rotate = 0.000000000;
const float p_o290204_scale = 0.000000000;
const float p_o290204_value = 0.800000000;
const float p_o290209_default_in1 = 0.000000000;
const float p_o290209_default_in2 = 0.000000000;
const float p_o290211_value = 0.500000000;
const float p_o290211_width = 0.113600000;
const float p_o290211_contrast = 0.000000000;
const float p_o290202_default_in1 = 0.000000000;
const float p_o290202_default_in2 = 0.000000000;
const float seed_o290201 = 0.042548649;
const float p_o290201_default_in1 = 0.000000000;
const float p_o290188_repeat = 1.000000000;
const float p_o290188_gradient_0_pos = 0.000000000;
const vec4 p_o290188_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o290188_gradient_1_pos = 1.000000000;
const vec4 p_o290188_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o290188_gradient_gradient_fct(float x) {
  if (x < p_o290188_gradient_0_pos) {
    return p_o290188_gradient_0_col;
  } else if (x < p_o290188_gradient_1_pos) {
    return mix(p_o290188_gradient_0_col, p_o290188_gradient_1_col, ((x-p_o290188_gradient_0_pos)/(p_o290188_gradient_1_pos-p_o290188_gradient_0_pos)));
  }
  return p_o290188_gradient_1_col;
}
const float p_o290208_sides = 6.000000000;
const float p_o290208_radius = 1.000000000;
const float p_o290208_edge = 2.000000000;
float o290204_input_in(vec2 uv, float _seed_variation_) {
vec4 o290188_0_1_rgba = o290188_gradient_gradient_fct(fract(p_o290188_repeat*1.41421356237*length(fract((uv))-vec2(0.5, 0.5))));
float o290201_0_clamp_false = (dot((o290188_0_1_rgba).rgb, vec3(1.0))/3.0)-(elapsed_time*.6-param_rnd(0,1, (seed_o290201+fract(_seed_variation_))+16.455979));
float o290201_0_clamp_true = clamp(o290201_0_clamp_false, 0.0, 1.0);
float o290201_0_2_f = o290201_0_clamp_false;
float o290202_0_clamp_false = fract(o290201_0_2_f);
float o290202_0_clamp_true = clamp(o290202_0_clamp_false, 0.0, 1.0);
float o290202_0_1_f = o290202_0_clamp_false;
float o290211_0_step = clamp((o290202_0_1_f - (p_o290211_value))/max(0.0001, p_o290211_width)+0.5, 0.0, 1.0);
float o290211_0_false = clamp((min(o290211_0_step, 1.0-o290211_0_step) * 2.0) / (1.0 - p_o290211_contrast), 0.0, 1.0);
float o290211_0_true = 1.0-o290211_0_false;float o290211_0_1_f = o290211_0_false;
float o290208_0_1_f = shape_circle((uv), p_o290208_sides, p_o290208_radius*1.0, p_o290208_edge*1.0);
float o290209_0_clamp_false = o290211_0_1_f*o290208_0_1_f;
float o290209_0_clamp_true = clamp(o290209_0_clamp_false, 0.0, 1.0);
float o290209_0_1_f = o290209_0_clamp_false;
return o290209_0_1_f;
}
float o290204_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 splatter_o290204(vec2 uv, int count, inout vec3 instance_uv, vec2 seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	for (int i = 0; i < count; ++i) {
		seed = rand2(seed);
		rc1 = rand3(seed);
		float mask = o290204_input_mask(fract(seed+vec2(0.5)), _seed_variation_);
		if (mask > 0.01) {
			vec2 pv = fract(uv - seed)-vec2(0.5);
			seed = rand2(seed);
			float angle = (seed.x * 2.0 - 1.0) * p_o290204_rotate * 0.01745329251;
			float ca = cos(angle);
			float sa = sin(angle);
			pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
			pv *= (seed.y-0.5)*2.0*p_o290204_scale+1.0;
			pv /= vec2(p_o290204_scale_x, p_o290204_scale_y);
			pv += vec2(0.5);
			seed = rand2(seed);
			vec2 clamped_pv = clamp(pv, vec2(0.0), vec2(1.0));
			if (pv.x != clamped_pv.x || pv.y != clamped_pv.y) {
				continue;
			}
			vec2 full_uv = pv;
			pv = get_from_tileset( 1.0, seed.x, pv);
			float c1 = o290204_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o290204_value*seed.x);
			c = max(c, c1);
			rc = mix(rc, rc1, step(c, c1));
			instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
		}
	}
	return vec4(rc, c);
}
float o290183_input_d(vec2 uv, float _seed_variation_) {
vec3 o290204_0_instance_uv = vec3(0.0);
vec4 o290204_0_rch = splatter_o290204((uv), int(p_o290204_count), o290204_0_instance_uv, vec2(float((seed_o290204+fract(_seed_variation_)))), _seed_variation_);float o290204_0_1_f = o290204_0_rch.a;
return o290204_0_1_f;
}
vec2 o290183_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o290183_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o290183_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o290183_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o290183_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o290212_cx = 0.000000000;
const float p_o290212_cy = 0.000000000;
const float p_o290212_scale_x = 1.000000000;
const float p_o290212_scale_y = 1.000000000;
const float p_o290258_gradient_0_pos = 0.000000000;
const vec4 p_o290258_gradient_0_col = vec4(0.546875000, 0.546875000, 0.546875000, 1.000000000);
const float p_o290258_gradient_1_pos = 1.000000000;
const vec4 p_o290258_gradient_1_col = vec4(0.375000000, 0.375000000, 0.375000000, 1.000000000);
vec4 o290258_gradient_gradient_fct(float x) {
  if (x < p_o290258_gradient_0_pos) {
    return p_o290258_gradient_0_col;
  } else if (x < p_o290258_gradient_1_pos) {
    return mix(p_o290258_gradient_0_col, p_o290258_gradient_1_col, ((x-p_o290258_gradient_0_pos)/(p_o290258_gradient_1_pos-p_o290258_gradient_0_pos)));
  }
  return p_o290258_gradient_1_col;
}
const float p_o290257_x_scale = 8.000000000;
const float p_o290257_y_scale = 8.000000000;
const float p_o290203_color = 0.160000000;
const float p_o290210_sides = 6.000000000;
const float p_o290210_radius = 2.340000000;
const float p_o290210_edge = 0.720000000;
const float p_o290220_amount = 1.000000000;
float o290220_input_in(vec2 uv, float _seed_variation_) {
vec3 o290204_0_instance_uv = vec3(0.0);
vec4 o290204_0_rch = splatter_o290204((uv), int(p_o290204_count), o290204_0_instance_uv, vec2(float((seed_o290204+fract(_seed_variation_)))), _seed_variation_);float o290204_0_1_f = o290204_0_rch.a;
return o290204_0_1_f;
}
vec3 nm_o290220(vec2 uv, float amount, float size, float _seed_variation_) {
	vec3 e = vec3(1.0/size, -1.0/size, 0);
	vec2 rv;
	if (2 == 0) {
		rv = vec2(1.0, -1.0)*o290220_input_in(uv+e.xy, _seed_variation_);
		rv += vec2(-1.0, 1.0)*o290220_input_in(uv-e.xy, _seed_variation_);
		rv += vec2(1.0, 1.0)*o290220_input_in(uv+e.xx, _seed_variation_);
		rv += vec2(-1.0, -1.0)*o290220_input_in(uv-e.xx, _seed_variation_);
		rv += vec2(2.0, 0.0)*o290220_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(-2.0, 0.0)*o290220_input_in(uv-e.xz, _seed_variation_);
		rv += vec2(0.0, 2.0)*o290220_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(0.0, -2.0)*o290220_input_in(uv-e.zx, _seed_variation_);
		rv *= size*amount/128.0;
	} else if (2 == 1) {
		rv = vec2(3.0, -3.0)*o290220_input_in(uv+e.xy, _seed_variation_);
		rv += vec2(-3.0, 3.0)*o290220_input_in(uv-e.xy, _seed_variation_);
		rv += vec2(3.0, 3.0)*o290220_input_in(uv+e.xx, _seed_variation_);
		rv += vec2(-3.0, -3.0)*o290220_input_in(uv-e.xx, _seed_variation_);
		rv += vec2(10.0, 0.0)*o290220_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(-10.0, 0.0)*o290220_input_in(uv-e.xz, _seed_variation_);
		rv += vec2(0.0, 10.0)*o290220_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(0.0, -10.0)*o290220_input_in(uv-e.zx, _seed_variation_);
		rv *= size*amount/512.0;
	} else if (2 == 2) {
		rv = vec2(2.0, 0.0)*o290220_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(-2.0, 0.0)*o290220_input_in(uv-e.xz, _seed_variation_);
		rv += vec2(0.0, 2.0)*o290220_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(0.0, -2.0)*o290220_input_in(uv-e.zx, _seed_variation_);
		rv *= size*amount/64.0;
	} else {
		rv = vec2(1.0, 0.0)*o290220_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(0.0, 1.0)*o290220_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(-1.0, -1.0)*o290220_input_in(uv, _seed_variation_);
		rv *= size*amount/20.0;
	}
	return vec3(0.5)+0.5*normalize(vec3(rv, -1.0));
}
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec2 o290183_0_slope = o290183_slope((uv), p_o290183_eps, _seed_variation_);
vec2 o290183_0_warp = o290183_0_slope;float o290257_0_1_f = mix_xor(wave_square(p_o290257_x_scale*(scale(((uv)+p_o290183_amount*o290183_0_warp), vec2(0.5+p_o290212_cx, 0.5+p_o290212_cy), vec2(p_o290212_scale_x, p_o290212_scale_y))).x), wave_square(p_o290257_y_scale*(scale(((uv)+p_o290183_amount*o290183_0_warp), vec2(0.5+p_o290212_cx, 0.5+p_o290212_cy), vec2(p_o290212_scale_x, p_o290212_scale_y))).y));
vec4 o290258_0_1_rgba = o290258_gradient_gradient_fct(o290257_0_1_f);
vec4 o290212_0_1_rgba = o290258_0_1_rgba;
vec4 o290183_0_1_rgba = o290212_0_1_rgba;
float o290203_0_1_f = p_o290203_color;
vec3 o290204_0_instance_uv = vec3(0.0);
vec4 o290204_0_rch = splatter_o290204((uv), int(p_o290204_count), o290204_0_instance_uv, vec2(float((seed_o290204+fract(_seed_variation_)))), _seed_variation_);float o290204_0_1_f = o290204_0_rch.a;
float o290210_0_1_f = shape_circle((uv), p_o290210_sides, p_o290210_radius*1.0, p_o290210_edge*1.0);
vec4 o290187_0_b = o290183_0_1_rgba;
vec4 o290187_0_l;
float o290187_0_a;

o290187_0_l = vec4(vec3(o290203_0_1_f), 1.0);
o290187_0_a = p_o290187_amount1*o290204_0_1_f;
o290187_0_b = vec4(blend_normal((uv), o290187_0_l.rgb, o290187_0_b.rgb, o290187_0_a*o290187_0_l.a), min(1.0, o290187_0_b.a+o290187_0_a*o290187_0_l.a));

o290187_0_l = vec4(vec3(o290210_0_1_f), 1.0);
o290187_0_a = p_o290187_amount2*1.0;
o290187_0_b = vec4(blend_multiply((uv), o290187_0_l.rgb, o290187_0_b.rgb, o290187_0_a*o290187_0_l.a), min(1.0, o290187_0_b.a+o290187_0_a*o290187_0_l.a));

vec4 o290187_0_2_rgba = o290187_0_b;
vec3 o290220_0_1_rgb = nm_o290220((uv), p_o290220_amount, 32.000000000, _seed_variation_);

	vec3 albedo_tex = ((o290187_0_2_rgba).rgb).rgb;
	albedo_tex = mix(pow((albedo_tex + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),albedo_tex * (1.0 / 12.92),lessThan(albedo_tex,vec3(0.04045)));
	ALBEDO = albedo_tex*p_o290182_albedo_color.rgb;
	METALLIC = 1.0*p_o290182_metallic;
	ROUGHNESS = 1.0*p_o290182_roughness;
	NORMAL = o290220_0_1_rgb;
	EMISSION = vec3(0.0)*p_o290182_emission_energy;

}



