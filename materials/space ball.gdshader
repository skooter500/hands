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
uniform sampler2D texture_1;
const float texture_1_size = 512.0;
uniform sampler2D texture_2;
const float texture_2_size = 512.0;
float safe_divide(float a, float b)
{
  return (b != 0.0) ? a / b : 0.0;
}
float smootherstep(float edge0, float edge1, float x)
{
  x = clamp(safe_divide((x - edge0), (edge1 - edge0)), 0.0, 1.0);
  return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}
float smoothstep_map_range(float value, float fromMin, float fromMax, float toMin, float toMax){
	float result;  
	if (fromMax != fromMin) {
	    float factor = (fromMin > fromMax) ? 1.0 - smoothstep(fromMax, fromMin, value) :
	                                         smoothstep(fromMin, fromMax, value);
	    result = toMin + factor * (toMax - toMin);
	 }
	 else {
	    result = 0.0;
	 }
		return result;
}
float smootherstep_map_range(float value, float fromMin, float fromMax, float toMin, float toMax){
	float result;
	if (fromMax != fromMin) {
		float factor = (fromMin > fromMax) ? 1.0 - smootherstep(fromMax, fromMin, value) :
	                    smootherstep(fromMin, fromMax, value);
						result = toMin + factor * (toMax - toMin);
	}
	else {
		result = 0.0;
	}
	return result;
}
float linear_map_range(float value, float fromMin, float fromMax, float toMin, float toMax){
	float result;
	if (fromMax != fromMin) {
    	result = toMin + ((value - fromMin) / (fromMax - fromMin)) * (toMax - toMin);
  	}
	else
	{
		result = 0.0;
	}
	return result;
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
float sdMoon(vec2 p, float d, float ra, float rb )
{
    p.y = abs(p.y);
    float a = (ra*ra - rb*rb + d*d)/(2.0*d);
    float b = sqrt(max(ra*ra-a*a,0.0));
    if( d*(p.x*b-p.y*a) > d*d*max(b-p.y,0.0) )
          return length(p-vec2(a,b));
    return max( (length(p          )-ra),
               -(length(p-vec2(d,0))-rb));
}
vec2 sdf2d_rotate(vec2 uv, float a) {
	vec2 rv;
	float c = cos(a);
	float s = sin(a);
	uv -= vec2(0.5);
	rv.x = uv.x*c+uv.y*s;
	rv.y = -uv.x*s+uv.y*c;
	return rv+vec2(0.5);
}
vec2 scale(vec2 uv, vec2 center, vec2 scale) {
	uv -= center;
	uv /= scale;
	uv += center;
	return uv;
}
const float p_o116780_translate_x = 0.000000000;
const float p_o116780_translate_y = 0.000000000;
const float p_o116780_rotate = 0.000000000;
const float p_o116780_scale_x = 0.900000000;
const float p_o116780_scale_y = 0.900000000;
const float p_o116550_amount1 = 1.000000000;
const float p_o116550_amount2 = 1.000000000;
const float p_o116550_amount3 = 0.310000000;
const float p_o116550_amount4 = 0.140000000;
const float p_o116549_translate_x = 0.000000000;
const float p_o116549_translate_y = 0.000000000;
const float p_o116549_rotate = 0.000000000;
const float p_o116549_scale_x = 0.800000000;
const float p_o116549_scale_y = 0.800000000;
const float p_o116516_amount1 = 1.000000000;
const float p_o116516_amount2 = 1.000000000;
const float p_o116478_r = 0.640000000;
const float p_o116478_a = 0.820000000;
const float p_o116478_cx = 0.000000000;
const float p_o116478_cy = 0.000000000;
const float p_o116463_amount1 = 1.000000000;
const float p_o116463_amount2 = 1.000000000;
const float p_o116463_amount3 = 1.000000000;
const vec4 p_o116667_color = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o116461_translate_y = 0.000000000;
const float p_o116515_amount1 = 1.000000000;
const float seed_o116479 = 0.291292071;
const float p_o116479_tx = 8.000000000;
const float p_o116479_ty = 8.000000000;
const float p_o116479_overlap = 3.000000000;
const float p_o116479_scale_x = 0.150000000;
const float p_o116479_scale_y = 0.150000000;
const float p_o116479_fixed_offset = 0.000000000;
const float p_o116479_offset = 1.000000000;
const float p_o116479_rotate = 0.000000000;
const float p_o116479_scale = 0.530000000;
const float p_o116479_value = 0.000000000;
const float p_o116458_default_in1 = 0.000000000;
const float p_o116458_default_in2 = 0.000000000;
const float p_o116455_sides = 6.000000000;
const float p_o116455_radius = 1.000000000;
const float p_o116455_edge = 0.025000000;
const float p_o116460_value = 1.000000000;
const float p_o116460_fromMin = 0.000000000;
const float p_o116460_fromMax = 1.000000000;
const float p_o116460_toMin = 0.000000000;
const float p_o116460_toMax = 0.720000000;
const float seed_o116456 = 0.000000000;
const float p_o116457_sides = 6.000000000;
const float p_o116457_radius = 1.000000000;
const float p_o116457_edge = 0.025000000;
const float p_o116459_value = 1.000000000;
const float p_o116459_fromMin = 0.000000000;
const float p_o116459_fromMax = 1.600000000;
const float p_o116459_toMin = 0.000000000;
const float p_o116459_toMax = 1.000000000;
float o116479_input_in(vec2 uv, float _seed_variation_) {
float o116456_0_1_f = (fract(elapsed_time*0.3+param_rnd(0,1, (seed_o116456+fract(_seed_variation_))+-0.961397)));
float o116460_0_clamp_false = linear_map_range(p_o116460_value*o116456_0_1_f,p_o116460_fromMin*1.0,p_o116460_fromMax*1.0,p_o116460_toMin*1.0,p_o116460_toMax*1.0);
float o116460_0_clamp_true = clamp(o116460_0_clamp_false,p_o116460_toMin,p_o116460_toMax);float o116460_0_2_f = o116460_0_clamp_false;
float o116455_0_1_f = shape_circle((uv), p_o116455_sides, p_o116455_radius*o116460_0_2_f, p_o116455_edge*1.0);
float o116459_0_clamp_false = smootherstep_map_range(p_o116459_value*o116456_0_1_f,p_o116459_fromMin*1.0,p_o116459_fromMax*1.0,p_o116459_toMin*1.0,p_o116459_toMax*1.0);
float o116459_0_clamp_true = clamp(o116459_0_clamp_false,p_o116459_toMin,p_o116459_toMax);float o116459_0_2_f = o116459_0_clamp_false;
float o116457_0_1_f = shape_circle((uv), p_o116457_sides, p_o116457_radius*o116459_0_2_f, p_o116457_edge*1.0);
float o116458_0_clamp_false = o116455_0_1_f-o116457_0_1_f;
float o116458_0_clamp_true = clamp(o116458_0_clamp_false, 0.0, 1.0);
float o116458_0_1_f = o116458_0_clamp_false;
return o116458_0_1_f;
}
float o116479_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 tiler_o116479(vec2 uv, vec2 tile, int overlap, inout vec3 instance_uv, vec2 _seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	for (int dx = -overlap; dx <= overlap; ++dx) {
		for (int dy = -overlap; dy <= overlap; ++dy) {
			vec2 pos = uv*tile+vec2(float(dx), float(dy)); pos = fract((floor(mod(pos, tile))+vec2(0.5))/tile)-vec2(0.5);
			vec2 seed = rand2(pos+_seed);
			rc1 = rand3(seed);
			pos = fract(pos+vec2(p_o116479_fixed_offset/tile.x, 0.0)*floor(mod(pos.y*tile.y, 2.0))+p_o116479_offset*seed/tile);
			float mask = o116479_input_mask(fract(pos+vec2(0.5)), _seed_variation_);
			if (mask > 0.01) {
				vec2 pv = fract(uv - pos)-vec2(0.5);
				seed = rand2(seed);
				float angle = (seed.x * 2.0 - 1.0) * p_o116479_rotate * 0.01745329251;
				float ca = cos(angle);
				float sa = sin(angle);
				pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
				pv *= (seed.y-0.5)*2.0*p_o116479_scale+1.0;
				pv /= vec2(p_o116479_scale_x, p_o116479_scale_y);
				pv += vec2(0.5);
				seed = rand2(seed);
				vec2 clamped_pv = clamp(pv, vec2(0.0), vec2(1.0));
				if (pv.x != clamped_pv.x || pv.y != clamped_pv.y) {
					continue;
				}
				vec2 full_uv = pv;
				pv = get_from_tileset( 1.0, seed.x, pv);
				float c1 = o116479_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o116479_value*seed.x);
				c = max(c, c1);
				rc = mix(rc, rc1, step(c, c1));
				instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
			}
		}
	}
	return vec4(rc, c);
}const float p_o116501_gradient_0_pos = 0.000000000;
const vec4 p_o116501_gradient_0_col = vec4(0.037170000, 0.394403011, 0.792968988, 1.000000000);
const float p_o116501_gradient_1_pos = 0.514235000;
const vec4 p_o116501_gradient_1_col = vec4(0.037170000, 0.394403011, 0.792968988, 1.000000000);
const float p_o116501_gradient_2_pos = 0.514255000;
const vec4 p_o116501_gradient_2_col = vec4(0.099030003, 0.593811989, 0.921875000, 1.000000000);
vec4 o116501_gradient_gradient_fct(float x) {
  if (x < 0.5*(p_o116501_gradient_0_pos+p_o116501_gradient_1_pos)) {
    return p_o116501_gradient_0_col;
  } else if (x < 0.5*(p_o116501_gradient_1_pos+p_o116501_gradient_2_pos)) {
    return p_o116501_gradient_1_col;
  }
  return p_o116501_gradient_2_col;
}
const float p_o116488_gradient_0_pos = 0.000000000;
const vec4 p_o116488_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o116488_gradient_1_pos = 1.000000000;
const vec4 p_o116488_gradient_1_col = vec4(0.929687977, 0.963744998, 1.000000000, 1.000000000);
vec4 o116488_gradient_gradient_fct(float x) {
  if (x < p_o116488_gradient_0_pos) {
    return p_o116488_gradient_0_col;
  } else if (x < p_o116488_gradient_1_pos) {
    return mix(p_o116488_gradient_0_col, p_o116488_gradient_1_col, ((x-p_o116488_gradient_0_pos)/(p_o116488_gradient_1_pos-p_o116488_gradient_0_pos)));
  }
  return p_o116488_gradient_1_col;
}
const float p_o116462_translate_y = 0.000000000;
const float seed_o116487 = 0.540782392;
const float p_o116487_v1 = 0.000000000;
const float p_o116487_v2 = 0.100000000;
const float p_o116487_v3 = 0.200000000;
const float p_o116487_v4 = 0.300000000;
const float p_o116487_v5 = 0.400000000;
const float seed_o116483 = 0.390599340;
const float p_o116483_tx = 10.000000000;
const float p_o116483_ty = 10.000000000;
const float p_o116483_overlap = 2.000000000;
const float p_o116483_scale_x = 0.100000000;
const float p_o116483_scale_y = 0.100000000;
const float p_o116483_fixed_offset = 0.000000000;
const float p_o116483_offset = 1.000000000;
const float p_o116483_rotate = 0.000000000;
const float p_o116483_scale = 0.800000000;
const float p_o116483_value = 0.000000000;
float o116483_input_in(vec2 uv, float _seed_variation_) {
float o116456_0_1_f = (fract(elapsed_time*0.3+param_rnd(0,1, (seed_o116456+fract(_seed_variation_))+-0.961397)));
float o116460_0_clamp_false = linear_map_range(p_o116460_value*o116456_0_1_f,p_o116460_fromMin*1.0,p_o116460_fromMax*1.0,p_o116460_toMin*1.0,p_o116460_toMax*1.0);
float o116460_0_clamp_true = clamp(o116460_0_clamp_false,p_o116460_toMin,p_o116460_toMax);float o116460_0_2_f = o116460_0_clamp_false;
float o116455_0_1_f = shape_circle((uv), p_o116455_sides, p_o116455_radius*o116460_0_2_f, p_o116455_edge*1.0);
float o116459_0_clamp_false = smootherstep_map_range(p_o116459_value*o116456_0_1_f,p_o116459_fromMin*1.0,p_o116459_fromMax*1.0,p_o116459_toMin*1.0,p_o116459_toMax*1.0);
float o116459_0_clamp_true = clamp(o116459_0_clamp_false,p_o116459_toMin,p_o116459_toMax);float o116459_0_2_f = o116459_0_clamp_false;
float o116457_0_1_f = shape_circle((uv), p_o116457_sides, p_o116457_radius*o116459_0_2_f, p_o116457_edge*1.0);
float o116458_0_clamp_false = o116455_0_1_f-o116457_0_1_f;
float o116458_0_clamp_true = clamp(o116458_0_clamp_false, 0.0, 1.0);
float o116458_0_1_f = o116458_0_clamp_false;
return o116458_0_1_f;
}
float o116483_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 tiler_o116483(vec2 uv, vec2 tile, int overlap, inout vec3 instance_uv, vec2 _seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	for (int dx = -overlap; dx <= overlap; ++dx) {
		for (int dy = -overlap; dy <= overlap; ++dy) {
			vec2 pos = uv*tile+vec2(float(dx), float(dy)); pos = fract((floor(mod(pos, tile))+vec2(0.5))/tile)-vec2(0.5);
			vec2 seed = rand2(pos+_seed);
			rc1 = rand3(seed);
			pos = fract(pos+vec2(p_o116483_fixed_offset/tile.x, 0.0)*floor(mod(pos.y*tile.y, 2.0))+p_o116483_offset*seed/tile);
			float mask = o116483_input_mask(fract(pos+vec2(0.5)), _seed_variation_);
			if (mask > 0.01) {
				vec2 pv = fract(uv - pos)-vec2(0.5);
				seed = rand2(seed);
				float angle = (seed.x * 2.0 - 1.0) * p_o116483_rotate * 0.01745329251;
				float ca = cos(angle);
				float sa = sin(angle);
				pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
				pv *= (seed.y-0.5)*2.0*p_o116483_scale+1.0;
				pv /= vec2(p_o116483_scale_x, p_o116483_scale_y);
				pv += vec2(0.5);
				seed = rand2(seed);
				vec2 clamped_pv = clamp(pv, vec2(0.0), vec2(1.0));
				if (pv.x != clamped_pv.x || pv.y != clamped_pv.y) {
					continue;
				}
				vec2 full_uv = pv;
				pv = get_from_tileset( 1.0, seed.x, pv);
				float c1 = o116483_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o116483_value*seed.x);
				c = max(c, c1);
				rc = mix(rc, rc1, step(c, c1));
				instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
			}
		}
	}
	return vec4(rc, c);
}float o116487_input_in(vec2 uv, float _seed_variation_) {
vec3 o116483_0_instance_uv = vec3(0.0);
vec4 o116483_0_rch = tiler_o116483((uv), vec2(p_o116483_tx, p_o116483_ty), int(p_o116483_overlap), o116483_0_instance_uv, vec2(float((seed_o116483+fract(_seed_variation_)))), _seed_variation_);float o116483_0_1_f = o116483_0_rch.a;
return o116483_0_1_f;
}
const float p_o116465_gradient_0_pos = 0.000000000;
const vec4 p_o116465_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o116465_gradient_1_pos = 1.000000000;
const vec4 p_o116465_gradient_1_col = vec4(0.492188007, 0.721706986, 1.000000000, 1.000000000);
vec4 o116465_gradient_gradient_fct(float x) {
  if (x < p_o116465_gradient_0_pos) {
    return p_o116465_gradient_0_col;
  } else if (x < p_o116465_gradient_1_pos) {
    return mix(p_o116465_gradient_0_col, p_o116465_gradient_1_col, ((x-p_o116465_gradient_0_pos)/(p_o116465_gradient_1_pos-p_o116465_gradient_0_pos)));
  }
  return p_o116465_gradient_1_col;
}
const float p_o116464_translate_y = 0.000000000;
const vec4 p_o116518_color = vec4(0.051383998, 0.538340986, 0.876953006, 1.000000000);
const float p_o116520_default_in1 = 0.000000000;
const float p_o116520_default_in2 = 0.000000000;
const float p_o116517_sides = 6.000000000;
const float p_o116517_radius = 0.940000000;
const float p_o116517_edge = 0.000000000;
const float p_o116764_default_in1 = 0.000000000;
const float p_o116764_default_in2 = 0.750000000;
const float p_o116521_default_in1 = 0.000000000;
const float p_o116521_default_in2 = 0.000000000;
const float p_o116519_sides = 6.000000000;
const float p_o116519_radius = 0.833100000;
const float p_o116519_edge = 0.579400000;
const float p_o116545_sides = 6.000000000;
const float p_o116545_radius = 0.920000000;
const float p_o116545_edge = 0.000000000;
const float p_o116528_amount1 = 1.000000000;
const float p_o116528_amount2 = 1.000000000;
const float p_o116528_amount3 = 1.000000000;
const float seed_o116523 = 0.556229651;
const float p_o116523_count = 90.000000000;
const float p_o116523_rings = 1.000000000;
const float p_o116523_scale_x = 0.900000000;
const float p_o116523_scale_y = 0.900000000;
const float p_o116523_radius = 0.293600000;
const float p_o116523_spiral = 0.000000000;
const float p_o116523_i_rotate = 1.000000000;
const float p_o116523_i_scale = 0.000000000;
const float p_o116523_rotate = 0.000000000;
const float p_o116523_scale = 0.000000000;
const float p_o116523_value = 0.000000000;
const float p_o116548_translate_x = 0.000000000;
const float p_o116548_translate_y = -0.030350000;
const float seed_o116527 = 0.000000000;
const float seed_o116522 = 0.052988488;
const float p_o116522_sides = 6.000000000;
const float p_o116522_edge = 0.000000000;
float o116523_input_in(vec2 uv, float _seed_variation_) {
float o116522_0_1_f = shape_circle((((uv)-vec2(p_o116548_translate_x, p_o116548_translate_y))-vec2((param_rnd(-.1,.1, (seed_o116527+fract(_seed_variation_))+0.841471)), ((sin((elapsed_time*1.5+param_rnd(-10.0,10.0, (seed_o116527+fract(_seed_variation_))+16.038603)))*2.0-1.0)*0.005))), p_o116522_sides, (param_rnd(.09,.02, (seed_o116522+fract(_seed_variation_))+17.841471))*1.0, p_o116522_edge*1.0);
vec4 o116527_0_1_rgba = vec4(vec3(o116522_0_1_f), 1.0);
vec4 o116548_0_1_rgba = o116527_0_1_rgba;
return (dot((o116548_0_1_rgba).rgb, vec3(1.0))/3.0);
}
float o116523_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 splatter_o116523(vec2 uv, int count, int rings, inout vec3 instance_uv, vec2 seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	seed = rand2(seed);
	for (int i = 0; i < count; ++i) {
		float a = -1.57079632679+6.28318530718*float(i)*p_o116523_rings/float(count);
		float rings_distance = ceil(float(i+1)*float(rings)/float(count))/float(rings);
		float spiral_distance = float(i+1)/float(count);
		vec2 pos = p_o116523_radius*mix(rings_distance, spiral_distance, p_o116523_spiral)*vec2(cos(a), sin(a));
		float mask = o116523_input_mask(fract(pos-vec2(0.5)), _seed_variation_);
		if (mask > 0.01) {
			vec2 pv = uv-0.5-pos;
			rc1 = rand3(seed);
			seed = rand2(seed);
			float angle = (seed.x * 2.0 - 1.0) * p_o116523_rotate * 0.01745329251 + (a+1.57079632679) * p_o116523_i_rotate;
			float ca = cos(angle);
			float sa = sin(angle);
			pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
			pv /= mix(1.0, float(i+1)/float(count+1), p_o116523_i_scale);
			pv /= vec2(p_o116523_scale_x, p_o116523_scale_y);
			pv *= (seed.y-0.5)*2.0*p_o116523_scale+1.0;
			pv += vec2(0.5);
			seed = rand2(seed);
			if (pv != clamp(pv, vec2(0.0), vec2(1.0))) {
				continue;
			}
			vec2 full_uv = pv;
			pv = get_from_tileset( 1.0, seed.x, pv);
			float c1 = o116523_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o116523_value*seed.x);
			c = max(c, c1);
			rc = mix(rc, rc1, step(c, c1));
			instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
		}
	}
	return vec4(rc, c);
}
const float p_o116529_gradient_0_pos = 0.000000000;
const vec4 p_o116529_gradient_0_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o116529_gradient_1_pos = 0.332831000;
const vec4 p_o116529_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o116529_gradient_2_pos = 0.332851000;
const vec4 p_o116529_gradient_2_col = vec4(0.121569000, 0.270588011, 0.541176021, 1.000000000);
const float p_o116529_gradient_3_pos = 0.401533000;
const vec4 p_o116529_gradient_3_col = vec4(0.121569000, 0.270588011, 0.541176021, 1.000000000);
const float p_o116529_gradient_4_pos = 0.401553000;
const vec4 p_o116529_gradient_4_col = vec4(0.051383998, 0.538340986, 0.876953006, 1.000000000);
vec4 o116529_gradient_gradient_fct(float x) {
  if (x < 0.5*(p_o116529_gradient_0_pos+p_o116529_gradient_1_pos)) {
    return p_o116529_gradient_0_col;
  } else if (x < 0.5*(p_o116529_gradient_1_pos+p_o116529_gradient_2_pos)) {
    return p_o116529_gradient_1_col;
  } else if (x < 0.5*(p_o116529_gradient_2_pos+p_o116529_gradient_3_pos)) {
    return p_o116529_gradient_2_col;
  } else if (x < 0.5*(p_o116529_gradient_3_pos+p_o116529_gradient_4_pos)) {
    return p_o116529_gradient_3_col;
  }
  return p_o116529_gradient_4_col;
}
const float p_o116552_translate_x = 0.000000000;
const float p_o116552_translate_y = -0.005000000;
const float p_o116551_sides = 6.000000000;
const float p_o116551_radius = 0.705700000;
const float p_o116551_edge = 0.005900000;
const float p_o116570_translate_x = 0.000000000;
const float p_o116570_translate_y = 0.000000000;
const float p_o116570_rotate = 0.000000000;
const float p_o116570_scale_x = 1.077250000;
const float p_o116779_amount1 = 1.000000000;
const float seed_o116565 = 0.000496532;
const float p_o116565_count = 50.000000000;
const float p_o116565_rings = 1.000000000;
const float p_o116565_scale_x = 0.500000000;
const float p_o116565_scale_y = 0.500000000;
const float p_o116565_radius = 0.405300000;
const float p_o116565_spiral = 0.000000000;
const float p_o116565_i_rotate = 1.000000000;
const float p_o116565_i_scale = 0.000000000;
const float p_o116565_rotate = 0.000000000;
const float p_o116565_scale = 0.000000000;
const float p_o116565_value = 0.000000000;
const float seed_o116564 = 0.000000000;
const float p_o116564_translate_y = 0.165000000;
const float p_o116564_rotate = 0.000000000;
const float p_o116564_scale_x = 0.500000000;
const float p_o116564_scale_y = 0.500000000;
const float seed_o116562 = 0.000000000;
const float p_o116562_translate_x = 0.000000000;
const float p_o116562_rotate = 0.000000000;
const float p_o116562_scale_x = 0.500000000;
const float p_o116562_scale_y = 0.500000000;
const float p_o116563_default_in1 = 0.000000000;
const float p_o116563_default_in2 = 1.730000000;
const float seed_o116553 = 0.499502510;
const float seed_o116569 = 0.000000000;
const float p_o116569_cx = 0.000000000;
const float p_o116569_cy = 0.000000000;
const float p_o116559_bevel = 0.000000000;
const float p_o116559_base = 0.000000000;
const float p_o116556_a = 90.000000000;
const float p_o116554_ra = 0.220000000;
const float p_o116554_rb = 0.290000000;
const float p_o116554_d = 1.000000000;
const float p_o116554_cx = 0.000000000;
const float p_o116554_cy = 0.000000000;
const float p_o116560_value = 1.000000000;
const float p_o116560_fromMin = 0.000000000;
const float p_o116560_fromMax = 0.498000000;
const float p_o116560_toMin = 0.229000000;
const float p_o116560_toMax = 0.754000000;
const float p_o116557_value = 1.000000000;
const float p_o116557_fromMin = 0.000000000;
const float p_o116557_fromMax = 1.000000000;
const float p_o116557_toMin = 0.335000000;
const float p_o116557_toMax = 1.000000000;
float o116565_input_in(vec2 uv, float _seed_variation_) {
float o116553_0_1_f = (fract(elapsed_time*0.4+param_rnd(0,1, (seed_o116553+fract(_seed_variation_))+-0.961397)));
float o116563_0_clamp_false = o116553_0_1_f*p_o116563_default_in2;
float o116563_0_clamp_true = clamp(o116563_0_clamp_false, 0.0, 1.0);
float o116563_0_2_f = o116563_0_clamp_false;
vec4 o116561_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o116563_0_2_f), 1.0).rgb, vec4(vec3(o116563_0_2_f), 1.0).a);
float o116553_0_3_f = (fract(elapsed_time*0.4+param_rnd(0,1, (seed_o116553+fract(_seed_variation_))+-0.961397)));
float o116560_0_clamp_false = linear_map_range(p_o116560_value*o116553_0_3_f,p_o116560_fromMin*1.0,p_o116560_fromMax*1.0,p_o116560_toMin*1.0,p_o116560_toMax*1.0);
float o116560_0_clamp_true = clamp(o116560_0_clamp_false,p_o116560_toMin,p_o116560_toMax);float o116560_0_2_f = o116560_0_clamp_false;
float o116557_0_clamp_false = linear_map_range(p_o116557_value*o116553_0_3_f,p_o116557_fromMin*1.0,p_o116557_fromMax*1.0,p_o116557_toMin*1.0,p_o116557_toMax*1.0);
float o116557_0_clamp_true = clamp(o116557_0_clamp_false,p_o116557_toMin,p_o116557_toMax);float o116557_0_2_f = o116557_0_clamp_true;
vec4 o116558_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o116557_0_2_f), 1.0).rgb, vec4(vec3(o116557_0_2_f), 1.0).a);
float o116554_0_1_sdf2d = sdMoon((sdf2d_rotate((scale((transform2_clamp(transform2((transform2((uv), vec2((param_rnd(-.1,.1, (seed_o116564+fract(_seed_variation_))+0.841471))*(2.0*1.0-1.0), p_o116564_translate_y*(2.0*1.0-1.0)), p_o116564_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116564_scale_x*(2.0*1.0-1.0), p_o116564_scale_y*(2.0*1.0-1.0)))), vec2(p_o116562_translate_x*(2.0*1.0-1.0), (param_rnd(.05,.1, (seed_o116562+fract(_seed_variation_))+17.841471))*(2.0*(dot((o116561_0_1_rgba).rgb, vec3(1.0))/3.0)-1.0)), p_o116562_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116562_scale_x*(2.0*1.0-1.0), p_o116562_scale_y*(2.0*1.0-1.0))))), vec2(0.5+p_o116569_cx, 0.5+p_o116569_cy), vec2((param_rnd(0,1, (seed_o116569+fract(_seed_variation_))+34.841471)), ((param_rnd(0,1, (seed_o116569+fract(_seed_variation_))+34.841471)))))), p_o116556_a*0.01745329251)) - 0.5 - vec2(p_o116554_cx, p_o116554_cy), p_o116554_d*(dot((o116558_0_1_rgba).rgb, vec3(1.0))/3.0), p_o116554_ra, p_o116554_rb*o116560_0_2_f);
float o116556_0_1_sdf2d = o116554_0_1_sdf2d;
float o116559_0_1_f = clamp(p_o116559_base-o116556_0_1_sdf2d/max(p_o116559_bevel, 0.00001), 0.0, 1.0);
vec4 o116569_0_1_rgba = vec4(vec3(o116559_0_1_f), 1.0);
vec4 o116562_0_1_rgba = o116569_0_1_rgba;
vec4 o116564_0_1_rgba = o116562_0_1_rgba;
return (dot((o116564_0_1_rgba).rgb, vec3(1.0))/3.0);
}
float o116565_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 splatter_o116565(vec2 uv, int count, int rings, inout vec3 instance_uv, vec2 seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	seed = rand2(seed);
	for (int i = 0; i < count; ++i) {
		float a = -1.57079632679+6.28318530718*float(i)*p_o116565_rings/float(count);
		float rings_distance = ceil(float(i+1)*float(rings)/float(count))/float(rings);
		float spiral_distance = float(i+1)/float(count);
		vec2 pos = p_o116565_radius*mix(rings_distance, spiral_distance, p_o116565_spiral)*vec2(cos(a), sin(a));
		float mask = o116565_input_mask(fract(pos-vec2(0.5)), _seed_variation_);
		if (mask > 0.01) {
			vec2 pv = uv-0.5-pos;
			rc1 = rand3(seed);
			seed = rand2(seed);
			float angle = (seed.x * 2.0 - 1.0) * p_o116565_rotate * 0.01745329251 + (a+1.57079632679) * p_o116565_i_rotate;
			float ca = cos(angle);
			float sa = sin(angle);
			pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
			pv /= mix(1.0, float(i+1)/float(count+1), p_o116565_i_scale);
			pv /= vec2(p_o116565_scale_x, p_o116565_scale_y);
			pv *= (seed.y-0.5)*2.0*p_o116565_scale+1.0;
			pv += vec2(0.5);
			seed = rand2(seed);
			if (pv != clamp(pv, vec2(0.0), vec2(1.0))) {
				continue;
			}
			vec2 full_uv = pv;
			pv = get_from_tileset( 1.0, seed.x, pv);
			float c1 = o116565_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o116565_value*seed.x);
			c = max(c, c1);
			rc = mix(rc, rc1, step(c, c1));
			instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
		}
	}
	return vec4(rc, c);
}
const float p_o116765_gradient_0_pos = 0.000000000;
const vec4 p_o116765_gradient_0_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o116765_gradient_1_pos = 0.601911000;
const vec4 p_o116765_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o116765_gradient_2_pos = 0.601931000;
const vec4 p_o116765_gradient_2_col = vec4(0.744140983, 0.895057976, 1.000000000, 1.000000000);
vec4 o116765_gradient_gradient_fct(float x) {
  if (x < 0.5*(p_o116765_gradient_0_pos+p_o116765_gradient_1_pos)) {
    return p_o116765_gradient_0_col;
  } else if (x < 0.5*(p_o116765_gradient_1_pos+p_o116765_gradient_2_pos)) {
    return p_o116765_gradient_1_col;
  }
  return p_o116765_gradient_2_col;
}
const float p_o116546_sides = 6.000000000;
const float p_o116546_radius = 0.695200000;
const float p_o116546_edge = 0.000100000;
const vec4 p_o116571_color = vec4(0.038757000, 0.057116002, 0.156250000, 1.000000000);
const vec4 p_o116666_color = vec4(0.218750000, 0.533080995, 1.000000000, 1.000000000);
const vec4 p_o116763_color = vec4(0.648688972, 0.760960996, 0.927734017, 1.000000000);
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec2 o116478_0_co = vec2(p_o116478_cx+0.5,p_o116478_cy+0.5);
float o116478_0_f = dot(2.0*((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))) - o116478_0_co),2.0*((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))) - o116478_0_co));vec4 o116667_0_1_rgba = p_o116667_color;
vec3 o116479_0_instance_uv = vec3(0.0);
vec4 o116479_0_rch = tiler_o116479(((o116478_0_co-(o116478_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116478_r-o116478_0_f)*max(p_o116478_a,0.0)+1.0))-vec2((-elapsed_time*.1), p_o116461_translate_y)), vec2(p_o116479_tx, p_o116479_ty), int(p_o116479_overlap), o116479_0_instance_uv, vec2(float((seed_o116479+fract(_seed_variation_)))), _seed_variation_);float o116479_0_1_f = o116479_0_rch.a;
vec3 o116479_1_2_rgb = o116479_0_rch.rgb;
vec4 o116501_0_1_rgba = o116501_gradient_gradient_fct((dot(o116479_1_2_rgb, vec3(1.0))/3.0));
vec4 o116515_0_b = vec4(vec3(o116479_0_1_f), 1.0);
vec4 o116515_0_l;
float o116515_0_a;

o116515_0_l = o116501_0_1_rgba;
o116515_0_a = p_o116515_amount1*1.0;
o116515_0_b = vec4(blend_multiply(((o116478_0_co-(o116478_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116478_r-o116478_0_f)*max(p_o116478_a,0.0)+1.0))-vec2((-elapsed_time*.1), p_o116461_translate_y)), o116515_0_l.rgb, o116515_0_b.rgb, o116515_0_a*o116515_0_l.a), min(1.0, o116515_0_b.a+o116515_0_a*o116515_0_l.a));

vec4 o116515_0_2_rgba = o116515_0_b;
vec4 o116461_0_1_rgba = o116515_0_2_rgba;
vec3 o116479_3_instance_uv = vec3(0.0);
vec4 o116479_3_rch = tiler_o116479(((o116478_0_co-(o116478_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116478_r-o116478_0_f)*max(p_o116478_a,0.0)+1.0))-vec2((-elapsed_time*.1), p_o116461_translate_y)), vec2(p_o116479_tx, p_o116479_ty), int(p_o116479_overlap), o116479_3_instance_uv, vec2(float((seed_o116479+fract(_seed_variation_)))), _seed_variation_);float o116479_0_4_f = o116479_3_rch.a;
vec4 o116461_1_2_rgba = vec4(vec3(o116479_0_4_f), 1.0);
float o116487_0_1_f = o116487_input_in(((o116478_0_co-(o116478_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116478_r-o116478_0_f)*max(p_o116478_a,0.0)+1.0))-vec2((-elapsed_time*.04), p_o116462_translate_y)), (seed_o116487+fract(_seed_variation_))+p_o116487_v1);
vec4 o116462_0_1_rgba = vec4(vec3(o116487_0_1_f), 1.0);
vec4 o116488_0_1_rgba = o116488_gradient_gradient_fct((dot((o116462_0_1_rgba).rgb, vec3(1.0))/3.0));
float o116487_1_3_f = o116487_input_in(((o116478_0_co-(o116478_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116478_r-o116478_0_f)*max(p_o116478_a,0.0)+1.0))-vec2((-elapsed_time*.09), p_o116464_translate_y)), (seed_o116487+fract(_seed_variation_))+p_o116487_v2);
vec4 o116464_0_1_rgba = vec4(vec3(o116487_1_3_f), 1.0);
vec4 o116465_0_1_rgba = o116465_gradient_gradient_fct((dot((o116464_0_1_rgba).rgb, vec3(1.0))/3.0));
vec4 o116463_0_b = o116667_0_1_rgba;
vec4 o116463_0_l;
float o116463_0_a;

o116463_0_l = o116461_0_1_rgba;
o116463_0_a = p_o116463_amount1*(dot((o116461_1_2_rgba).rgb, vec3(1.0))/3.0);
o116463_0_b = vec4(blend_lighten((o116478_0_co-(o116478_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116478_r-o116478_0_f)*max(p_o116478_a,0.0)+1.0)), o116463_0_l.rgb, o116463_0_b.rgb, o116463_0_a*o116463_0_l.a), min(1.0, o116463_0_b.a+o116463_0_a*o116463_0_l.a));

o116463_0_l = o116488_0_1_rgba;
o116463_0_a = p_o116463_amount2*1.0;
o116463_0_b = vec4(blend_lighten((o116478_0_co-(o116478_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116478_r-o116478_0_f)*max(p_o116478_a,0.0)+1.0)), o116463_0_l.rgb, o116463_0_b.rgb, o116463_0_a*o116463_0_l.a), min(1.0, o116463_0_b.a+o116463_0_a*o116463_0_l.a));

o116463_0_l = o116465_0_1_rgba;
o116463_0_a = p_o116463_amount3*1.0;
o116463_0_b = vec4(blend_lighten((o116478_0_co-(o116478_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116478_r-o116478_0_f)*max(p_o116478_a,0.0)+1.0)), o116463_0_l.rgb, o116463_0_b.rgb, o116463_0_a*o116463_0_l.a), min(1.0, o116463_0_b.a+o116463_0_a*o116463_0_l.a));

vec4 o116463_0_2_rgba = o116463_0_b;
vec4 o116667_0_3_rgba = p_o116667_color;
vec3 o116479_5_instance_uv = vec3(0.0);
vec4 o116479_5_rch = tiler_o116479(((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.1), p_o116461_translate_y)), vec2(p_o116479_tx, p_o116479_ty), int(p_o116479_overlap), o116479_5_instance_uv, vec2(float((seed_o116479+fract(_seed_variation_)))), _seed_variation_);float o116479_0_6_f = o116479_5_rch.a;
vec3 o116479_1_7_rgb = o116479_5_rch.rgb;
vec4 o116501_0_3_rgba = o116501_gradient_gradient_fct((dot(o116479_1_7_rgb, vec3(1.0))/3.0));
vec4 o116515_3_b = vec4(vec3(o116479_0_6_f), 1.0);
vec4 o116515_3_l;
float o116515_3_a;

o116515_3_l = o116501_0_3_rgba;
o116515_3_a = p_o116515_amount1*1.0;
o116515_3_b = vec4(blend_multiply(((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.1), p_o116461_translate_y)), o116515_3_l.rgb, o116515_3_b.rgb, o116515_3_a*o116515_3_l.a), min(1.0, o116515_3_b.a+o116515_3_a*o116515_3_l.a));

vec4 o116515_0_5_rgba = o116515_3_b;
vec4 o116461_0_4_rgba = o116515_0_5_rgba;
vec3 o116479_8_instance_uv = vec3(0.0);
vec4 o116479_8_rch = tiler_o116479(((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.1), p_o116461_translate_y)), vec2(p_o116479_tx, p_o116479_ty), int(p_o116479_overlap), o116479_8_instance_uv, vec2(float((seed_o116479+fract(_seed_variation_)))), _seed_variation_);float o116479_0_9_f = o116479_8_rch.a;
vec4 o116461_1_5_rgba = vec4(vec3(o116479_0_9_f), 1.0);
float o116487_0_5_f = o116487_input_in(((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.04), p_o116462_translate_y)), (seed_o116487+fract(_seed_variation_))+p_o116487_v1);
vec4 o116462_0_3_rgba = vec4(vec3(o116487_0_5_f), 1.0);
vec4 o116488_0_3_rgba = o116488_gradient_gradient_fct((dot((o116462_0_3_rgba).rgb, vec3(1.0))/3.0));
float o116487_1_7_f = o116487_input_in(((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.09), p_o116464_translate_y)), (seed_o116487+fract(_seed_variation_))+p_o116487_v2);
vec4 o116464_0_3_rgba = vec4(vec3(o116487_1_7_f), 1.0);
vec4 o116465_0_3_rgba = o116465_gradient_gradient_fct((dot((o116464_0_3_rgba).rgb, vec3(1.0))/3.0));
vec4 o116463_3_b = o116667_0_3_rgba;
vec4 o116463_3_l;
float o116463_3_a;

o116463_3_l = o116461_0_4_rgba;
o116463_3_a = p_o116463_amount1*(dot((o116461_1_5_rgba).rgb, vec3(1.0))/3.0);
o116463_3_b = vec4(blend_lighten((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))), o116463_3_l.rgb, o116463_3_b.rgb, o116463_3_a*o116463_3_l.a), min(1.0, o116463_3_b.a+o116463_3_a*o116463_3_l.a));

o116463_3_l = o116488_0_3_rgba;
o116463_3_a = p_o116463_amount2*1.0;
o116463_3_b = vec4(blend_lighten((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))), o116463_3_l.rgb, o116463_3_b.rgb, o116463_3_a*o116463_3_l.a), min(1.0, o116463_3_b.a+o116463_3_a*o116463_3_l.a));

o116463_3_l = o116465_0_3_rgba;
o116463_3_a = p_o116463_amount3*1.0;
o116463_3_b = vec4(blend_lighten((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))), o116463_3_l.rgb, o116463_3_b.rgb, o116463_3_a*o116463_3_l.a), min(1.0, o116463_3_b.a+o116463_3_a*o116463_3_l.a));

vec4 o116463_0_5_rgba = o116463_3_b;
vec4 o116478_0_1_rgba = clamp(mix(o116463_0_2_rgba,o116463_0_5_rgba,step(p_o116478_r,o116478_0_f)),0.0,1.0);
vec4 o116518_0_1_rgba = p_o116518_color;
float o116517_0_1_f = shape_circle((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))), p_o116517_sides, p_o116517_radius*1.0, p_o116517_edge*1.0);
float o116519_0_1_f = shape_circle((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))), p_o116519_sides, p_o116519_radius*1.0, p_o116519_edge*1.0);
float o116521_0_clamp_false = smoothstep(0.0, 1.0, o116519_0_1_f);
float o116521_0_clamp_true = clamp(o116521_0_clamp_false, 0.0, 1.0);
float o116521_0_1_f = o116521_0_clamp_false;
float o116764_0_clamp_false = o116521_0_1_f*p_o116764_default_in2;
float o116764_0_clamp_true = clamp(o116764_0_clamp_false, 0.0, 1.0);
float o116764_0_2_f = o116764_0_clamp_false;
float o116520_0_clamp_false = o116517_0_1_f-o116764_0_2_f;
float o116520_0_clamp_true = clamp(o116520_0_clamp_false, 0.0, 1.0);
float o116520_0_1_f = o116520_0_clamp_false;
float o116545_0_1_f = shape_circle((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))), p_o116545_sides, p_o116545_radius*1.0, p_o116545_edge*1.0);
vec4 o116516_0_b = o116478_0_1_rgba;
vec4 o116516_0_l;
float o116516_0_a;

o116516_0_l = o116518_0_1_rgba;
o116516_0_a = p_o116516_amount1*o116520_0_1_f;
o116516_0_b = vec4(blend_normal((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))), o116516_0_l.rgb, o116516_0_b.rgb, o116516_0_a*o116516_0_l.a), min(1.0, o116516_0_b.a+o116516_0_a*o116516_0_l.a));

o116516_0_l = vec4(vec3(o116545_0_1_f), 1.0);
o116516_0_a = p_o116516_amount2*1.0;
o116516_0_b = vec4(blend_multiply((transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116549_translate_x*(2.0*1.0-1.0), p_o116549_translate_y*(2.0*1.0-1.0)), p_o116549_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116549_scale_x*(2.0*1.0-1.0), p_o116549_scale_y*(2.0*1.0-1.0)))), o116516_0_l.rgb, o116516_0_b.rgb, o116516_0_a*o116516_0_l.a), min(1.0, o116516_0_b.a+o116516_0_a*o116516_0_l.a));

vec4 o116516_0_2_rgba = o116516_0_b;
vec4 o116549_0_1_rgba = o116516_0_2_rgba;
vec3 o116523_0_instance_uv = vec3(0.0);
vec4 o116523_0_rch = splatter_o116523((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), int(p_o116523_count), int(p_o116523_rings), o116523_0_instance_uv, vec2(float((seed_o116523+fract(_seed_variation_)))), _seed_variation_);float o116523_0_1_f = o116523_0_rch.a;
vec3 o116523_1_2_rgb = o116523_0_rch.rgb;
vec4 o116529_0_1_rgba = o116529_gradient_gradient_fct((dot(o116523_1_2_rgb, vec3(1.0))/3.0));
float o116551_0_1_f = shape_circle(((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0)))))-vec2(p_o116552_translate_x, p_o116552_translate_y)), p_o116551_sides, p_o116551_radius*1.0, p_o116551_edge*1.0);
vec4 o116552_0_1_rgba = vec4(vec3(o116551_0_1_f), 1.0);
vec3 o116565_0_instance_uv = vec3(0.0);
vec4 o116565_0_rch = splatter_o116565((transform2_clamp(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116570_translate_x*(2.0*1.0-1.0), p_o116570_translate_y*(2.0*1.0-1.0)), p_o116570_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116570_scale_x*(2.0*1.0-1.0), (p_o116570_scale_x)*(2.0*1.0-1.0))))), int(p_o116565_count), int(p_o116565_rings), o116565_0_instance_uv, vec2(float((seed_o116565+fract(_seed_variation_)))), _seed_variation_);float o116565_0_1_f = o116565_0_rch.a;
vec3 o116565_1_2_rgb = o116565_0_rch.rgb;
vec4 o116765_0_1_rgba = o116765_gradient_gradient_fct((dot(o116565_1_2_rgb, vec3(1.0))/3.0));
vec4 o116779_0_b = vec4(vec3(o116565_0_1_f), 1.0);
vec4 o116779_0_l;
float o116779_0_a;

o116779_0_l = o116765_0_1_rgba;
o116779_0_a = p_o116779_amount1*1.0;
o116779_0_b = vec4(blend_multiply((transform2_clamp(transform2((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), vec2(p_o116570_translate_x*(2.0*1.0-1.0), p_o116570_translate_y*(2.0*1.0-1.0)), p_o116570_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116570_scale_x*(2.0*1.0-1.0), (p_o116570_scale_x)*(2.0*1.0-1.0))))), o116779_0_l.rgb, o116779_0_b.rgb, o116779_0_a*o116779_0_l.a), min(1.0, o116779_0_b.a+o116779_0_a*o116779_0_l.a));

vec4 o116779_0_2_rgba = o116779_0_b;
vec4 o116570_0_1_rgba = o116779_0_2_rgba;
vec4 o116528_0_b = vec4(vec3(o116523_0_1_f), 1.0);
vec4 o116528_0_l;
float o116528_0_a;

o116528_0_l = o116529_0_1_rgba;
o116528_0_a = p_o116528_amount1*1.0;
o116528_0_b = vec4(blend_multiply((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), o116528_0_l.rgb, o116528_0_b.rgb, o116528_0_a*o116528_0_l.a), min(1.0, o116528_0_b.a+o116528_0_a*o116528_0_l.a));

o116528_0_l = o116552_0_1_rgba;
o116528_0_a = p_o116528_amount2*1.0;
o116528_0_b = vec4(blend_lighten((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), o116528_0_l.rgb, o116528_0_b.rgb, o116528_0_a*o116528_0_l.a), min(1.0, o116528_0_b.a+o116528_0_a*o116528_0_l.a));

o116528_0_l = o116570_0_1_rgba;
o116528_0_a = p_o116528_amount3*1.0;
o116528_0_b = vec4(blend_lighten((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), o116528_0_l.rgb, o116528_0_b.rgb, o116528_0_a*o116528_0_l.a), min(1.0, o116528_0_b.a+o116528_0_a*o116528_0_l.a));

vec4 o116528_0_2_rgba = o116528_0_b;
float o116546_0_1_f = shape_circle((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), p_o116546_sides, p_o116546_radius*1.0, p_o116546_edge*1.0);
vec4 o116547_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o116546_0_1_f), 1.0).rgb, vec4(vec3(o116546_0_1_f), 1.0).a);
vec4 o116571_0_1_rgba = p_o116571_color;
vec4 o116666_0_1_rgba = p_o116666_color;
vec4 o116591_0 = textureLod(texture_1, (transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), 0.0);
vec4 o116763_0_1_rgba = p_o116763_color;
vec4 o116688_0 = textureLod(texture_2, (transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), 0.0);
vec4 o116550_0_b = o116549_0_1_rgba;
vec4 o116550_0_l;
float o116550_0_a;

o116550_0_l = o116528_0_2_rgba;
o116550_0_a = p_o116550_amount1*(dot((o116547_0_1_rgba).rgb, vec3(1.0))/3.0);
o116550_0_b = vec4(blend_normal((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), o116550_0_l.rgb, o116550_0_b.rgb, o116550_0_a*o116550_0_l.a), min(1.0, o116550_0_b.a+o116550_0_a*o116550_0_l.a));

o116550_0_l = o116571_0_1_rgba;
o116550_0_a = p_o116550_amount2*1.0;
o116550_0_b = vec4(blend_lighten((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), o116550_0_l.rgb, o116550_0_b.rgb, o116550_0_a*o116550_0_l.a), min(1.0, o116550_0_b.a+o116550_0_a*o116550_0_l.a));

o116550_0_l = o116666_0_1_rgba;
o116550_0_a = p_o116550_amount3*(dot((o116591_0).rgb, vec3(1.0))/3.0);
o116550_0_b = vec4(blend_additive((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), o116550_0_l.rgb, o116550_0_b.rgb, o116550_0_a*o116550_0_l.a), min(1.0, o116550_0_b.a+o116550_0_a*o116550_0_l.a));

o116550_0_l = o116763_0_1_rgba;
o116550_0_a = p_o116550_amount4*(dot((o116688_0).rgb, vec3(1.0))/3.0);
o116550_0_b = vec4(blend_lighten((transform2_clamp(transform2((uv), vec2(p_o116780_translate_x*(2.0*1.0-1.0), p_o116780_translate_y*(2.0*1.0-1.0)), p_o116780_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116780_scale_x*(2.0*1.0-1.0), p_o116780_scale_y*(2.0*1.0-1.0))))), o116550_0_l.rgb, o116550_0_b.rgb, o116550_0_a*o116550_0_l.a), min(1.0, o116550_0_b.a+o116550_0_a*o116550_0_l.a));

vec4 o116550_0_2_rgba = o116550_0_b;
vec4 o116780_0_1_rgba = o116550_0_2_rgba;

	vec4 color_tex = o116780_0_1_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	ALBEDO = color_tex.rgb;
	ALPHA = color_tex.a;

}



