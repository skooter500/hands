shader_type spatial;

render_mode unshaded, blend_mix;

uniform vec3 uv1_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 uv1_offset = vec3(0.0, 0.0, 0.0);
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
// Based on https://www.shadertoy.com/view/ldl3W8
// The MIT License
// Copyright © 2013 Inigo Quilez
vec3 iq_voronoi(vec2 x, vec2 size, vec2 stretch, float randomness, vec2 seed) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	vec2 mg, mr, mc;
	float md = 8.0;
	for (int j=-1; j<=1; j++)
	for (int i=-1; i<=1; i++) {
		vec2 g = vec2(float(i),float(j));
		vec2 o = randomness*rand2(seed + mod(n + g + size, size));
		vec2 c = g + o;
		vec2 r = c - f;
		vec2 rr = r*stretch;
		float d = dot(rr,rr);
		if (d<md) {
			mc = c;
			md = d;
			mr = r;
			mg = g;
		}
	}
	md = 8.0;
	for (int j=-2; j<=2; j++)
	for (int i=-2; i<=2; i++) {
		vec2 g = mg + vec2(float(i),float(j));
		vec2 o = randomness*rand2(seed + mod(n + g + size, size));
		vec2 r = g + o - f;
		vec2 rr = (mr-r)*stretch;
		if (dot(rr,rr)>0.00001)
	   		md = min(md, dot(0.5*(mr+r)*stretch, normalize((r-mr)*stretch)));
	}
	return vec3(md, mc+n);
}
vec4 voronoi(vec2 uv, vec2 size, vec2 stretch, float intensity, float randomness, float seed) {
	uv *= size;
	vec3 v = iq_voronoi(uv, size, stretch, randomness, rand2(vec2(seed, 1.0-seed)));
	return vec4(v.yz, intensity*length((uv-v.yz)*stretch), v.x);
}
vec2 transform2_clamp(vec2 uv) {
	return clamp(uv, vec2(0.0), vec2(1.0));
}
vec2 transform2(vec2 uv, vec2 translate, float rotate, vec2 scale) {
 	vec2 rv;
	uv -= translate;
	uv -= vec2(0.5);
	rv.x = cos(rotate)*uv.x + sin(rotate)*uv.y;
	rv.y = -sin(rotate)*uv.x + cos(rotate)*uv.y;
	rv /= scale;
	rv += vec2(0.5);
	return rv;	
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
float pingpong(float a, float b)
{
  return (b != 0.0) ? abs(fract((a - b) / (b * 2.0)) * b * 2.0 - b) : 0.0;
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
vec2 rotate(vec2 uv, float rotate) {
 	vec2 rv;
	rv.x = cos(rotate)*uv.x + sin(rotate)*uv.y;
	rv.y = -sin(rotate)*uv.x + cos(rotate)*uv.y;
	return rv;	
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
uniform sampler2D texture_1;
const float texture_1_size = 2048.0;
const float p_o147879_amount1 = 1.000000000;
const float p_o147879_amount2 = 0.500000000;
const float seed_o147869 = 0.000000000;
const float p_o147869_sx = 1.000000000;
const float p_o147869_sy = 1.000000000;
const float p_o147869_rotate = 0.000000000;
const float p_o147869_scale = 0.000000000;
const float seed_o147878 = 0.000000000;
const vec4 p_o147878_edgecolor = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float seed_o147877 = 0.395433307;
const float p_o147877_scale_x = 4.000000000;
const float p_o147877_scale_y = 4.000000000;
const float p_o147877_stretch_x = 1.000000000;
const float p_o147877_stretch_y = 1.000000000;
const float p_o147877_intensity = 0.000000000;
const float p_o147877_randomness = 1.000000000;
vec4 o147869_input_in(vec2 uv, float _seed_variation_) {
vec4 o147877_0_xyzw = voronoi((uv), vec2(p_o147877_scale_x, p_o147877_scale_y), vec2(p_o147877_stretch_y, p_o147877_stretch_x), p_o147877_intensity, p_o147877_randomness, (seed_o147877+fract(_seed_variation_)));vec4 o147877_2_1_fill = round(vec4(fract((o147877_0_xyzw.xy-1.0)/vec2(p_o147877_scale_x, p_o147877_scale_y)), vec2(2.0)/vec2(p_o147877_scale_x, p_o147877_scale_y))*4096.0)/4096.0;
vec4 o147878_0_bb = o147877_2_1_fill;vec3 o147878_0_1_rgb = mix(p_o147878_edgecolor.rgb, rand3(vec2(float((seed_o147878+fract(_seed_variation_))), rand(vec2(rand(o147878_0_bb.xy), rand(o147878_0_bb.zw))))), step(0.0000001, dot(o147878_0_bb.zw, vec2(1.0))));
return vec4(o147878_0_1_rgb, 1.0);
}
const float p_o147871_d_in1_x = 0.000000000;
const float p_o147871_d_in1_y = 0.000000000;
const float p_o147871_d_in1_z = 0.000000000;
const float p_o147871_d_in2_x = 0.000000000;
const float p_o147871_d_in2_y = 0.000000000;
const float p_o147871_d_in2_z = 0.000000000;
const float p_o147876_amount1 = 1.000000000;
const float p_o147872_amount1 = 1.000000000;
const float p_o147868_amount1 = 1.000000000;
const float p_o147868_amount2 = 1.000000000;
const float p_o147867_translate_x = 0.500000000;
const float p_o147867_translate_y = 0.500000000;
const float p_o147867_rotate = 0.000000000;
const float p_o147867_scale_x = 1.000000000;
const float p_o147867_scale_y = 1.000000000;
const float p_o147866_default_in1 = 1.000000000;
const float p_o147866_default_in2 = 0.000000000;
const float p_o147864_sides = 4.000000000;
const float p_o147864_radius = 1.000000000;
const float p_o147864_edge = 1.000000000;
const float p_o147870_default_in1 = 0.000000000;
const float p_o147873_amount1 = 1.000000000;
const float p_o147875_cx = 0.353200000;
const float p_o147875_cy = 0.852500000;
const float p_o147875_rotate = 45.000000000;
const float p_o147874_x_scale = 0.500000000;
const float p_o147874_y_scale = 0.500000000;
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec4 o147867_0_1_rgba = vec4(((transform2((uv), vec2(p_o147867_translate_x*(2.0*1.0-1.0), p_o147867_translate_y*(2.0*1.0-1.0)), p_o147867_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o147867_scale_x*(2.0*1.0-1.0), p_o147867_scale_y*(2.0*1.0-1.0))))), 0.0, 1.0);
float o147864_0_1_f = shape_polygon((uv), p_o147864_sides, p_o147864_radius*1.0, p_o147864_edge*1.0);
vec4 o147865_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o147864_0_1_f), 1.0).rgb, vec4(vec3(o147864_0_1_f), 1.0).a);
float o147866_0_clamp_false = p_o147866_default_in1/(dot((o147865_0_1_rgba).rgb, vec3(1.0))/3.0);
float o147866_0_clamp_true = clamp(o147866_0_clamp_false, 0.0, 1.0);
float o147866_0_2_f = o147866_0_clamp_false;
vec4 o147868_0_b = o147867_0_1_rgba;
vec4 o147868_0_l;
float o147868_0_a;

o147868_0_l = o147867_0_1_rgba;
o147868_0_a = p_o147868_amount1*1.0;
o147868_0_b = vec4(blend_additive((uv), o147868_0_l.rgb, o147868_0_b.rgb, o147868_0_a*o147868_0_l.a), min(1.0, o147868_0_b.a+o147868_0_a*o147868_0_l.a));

o147868_0_l = vec4(vec3(o147866_0_2_f), 1.0);
o147868_0_a = p_o147868_amount2*1.0;
o147868_0_b = vec4(blend_multiply((uv), o147868_0_l.rgb, o147868_0_b.rgb, o147868_0_a*o147868_0_l.a), min(1.0, o147868_0_b.a+o147868_0_a*o147868_0_l.a));

vec4 o147868_0_2_rgba = o147868_0_b;
float o147870_0_clamp_false = o147866_0_2_f+(elapsed_time);
float o147870_0_clamp_true = clamp(o147870_0_clamp_false, 0.0, 1.0);
float o147870_0_2_f = o147870_0_clamp_false;
vec4 o147960_0_1_rgba = vec4(o147870_0_2_f, 0.0, 0.0, 1.0);
vec4 o147872_0_b = o147868_0_2_rgba;
vec4 o147872_0_l;
float o147872_0_a;

o147872_0_l = o147960_0_1_rgba;
o147872_0_a = p_o147872_amount1*1.0;
o147872_0_b = vec4(blend_additive((uv), o147872_0_l.rgb, o147872_0_b.rgb, o147872_0_a*o147872_0_l.a), min(1.0, o147872_0_b.a+o147872_0_a*o147872_0_l.a));

vec4 o147872_0_2_rgba = o147872_0_b;
vec4 o147959_0_1_rgba = vec4(0.0, o147870_0_2_f, 0.0, 1.0);
vec4 o147873_0_b = o147868_0_2_rgba;
vec4 o147873_0_l;
float o147873_0_a;

o147873_0_l = o147959_0_1_rgba;
o147873_0_a = p_o147873_amount1*1.0;
o147873_0_b = vec4(blend_additive((uv), o147873_0_l.rgb, o147873_0_b.rgb, o147873_0_a*o147873_0_l.a), min(1.0, o147873_0_b.a+o147873_0_a*o147873_0_l.a));

vec4 o147873_0_2_rgba = o147873_0_b;
vec2 o147875_0_c = vec2(0.5+p_o147875_cx, 0.5+p_o147875_cy);float o147874_0_1_f = mix_xor(wave_square(p_o147874_x_scale*(rotate((uv)-o147875_0_c, p_o147875_rotate*0.01745329251)+o147875_0_c).x), wave_square(p_o147874_y_scale*(rotate((uv)-o147875_0_c, p_o147875_rotate*0.01745329251)+o147875_0_c).y));
vec4 o147875_0_1_rgba = vec4(vec3(o147874_0_1_f), 1.0);
vec4 o147876_0_b = o147872_0_2_rgba;
vec4 o147876_0_l;
float o147876_0_a;

o147876_0_l = o147873_0_2_rgba;
o147876_0_a = p_o147876_amount1*(dot((o147875_0_1_rgba).rgb, vec3(1.0))/3.0);
o147876_0_b = vec4(blend_normal((uv), o147876_0_l.rgb, o147876_0_b.rgb, o147876_0_a*o147876_0_l.a), min(1.0, o147876_0_b.a+o147876_0_a*o147876_0_l.a));

vec4 o147876_0_1_rgba = o147876_0_b;
vec3 o147871_0_clamp_false = fract(((o147876_0_1_rgba).rgb));
vec3 o147871_0_clamp_true = clamp(o147871_0_clamp_false, vec3(0.0), vec3(1.0));
vec3 o147871_0_1_rgb = o147871_0_clamp_false;
vec3 o147869_0_map = o147871_0_1_rgb;
float o147869_0_rnd =  float((seed_o147869+fract(_seed_variation_)))+o147869_0_map.z;
vec4 o147869_0_1_rgba = o147869_input_in(get_from_tileset(1.0, o147869_0_rnd, custom_uv_transform(o147869_0_map.xy, vec2(p_o147869_sx, p_o147869_sy), p_o147869_rotate*0.01745329251, p_o147869_scale, vec2(o147869_0_map.z, float((seed_o147869+fract(_seed_variation_)))))), false ? o147869_0_rnd : 0.0);
vec4 o147902_0 = textureLod(texture_1, (uv), 0.0);
vec4 o147958_0_1_rgba = vec4(vec3(1.0)-o147902_0.rgb, o147902_0.a);
vec4 o147879_0_b = o147869_0_1_rgba;
vec4 o147879_0_l;
float o147879_0_a;

o147879_0_l = o147865_0_1_rgba;
o147879_0_a = p_o147879_amount1*1.0;
o147879_0_b = vec4(blend_multiply((uv), o147879_0_l.rgb, o147879_0_b.rgb, o147879_0_a*o147879_0_l.a), min(1.0, o147879_0_b.a+o147879_0_a*o147879_0_l.a));

o147879_0_l = o147958_0_1_rgba;
o147879_0_a = p_o147879_amount2*1.0;
o147879_0_b = vec4(blend_multiply((uv), o147879_0_l.rgb, o147879_0_b.rgb, o147879_0_a*o147879_0_l.a), min(1.0, o147879_0_b.a+o147879_0_a*o147879_0_l.a));

vec4 o147879_0_2_rgba = o147879_0_b;

	vec4 color_tex = o147879_0_2_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	ALBEDO = color_tex.rgb;
	ALPHA = color_tex.a;

}



