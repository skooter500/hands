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
const float p_o116921_translate_x = 0.000000000;
const float p_o116921_translate_y = 0.000000000;
const float p_o116921_rotate = 0.000000000;
const float p_o116921_scale_x = 0.900000000;
const float p_o116921_scale_y = 0.900000000;
const float p_o116691_amount1 = 1.000000000;
const float p_o116691_amount2 = 1.000000000;
const float p_o116691_amount3 = 0.310000000;
const float p_o116691_amount4 = 0.140000000;
const float p_o116690_translate_x = 0.000000000;
const float p_o116690_translate_y = 0.000000000;
const float p_o116690_rotate = 0.000000000;
const float p_o116690_scale_x = 0.800000000;
const float p_o116690_scale_y = 0.800000000;
const float p_o116657_amount1 = 1.000000000;
const float p_o116657_amount2 = 1.000000000;
const float p_o116619_r = 0.640000000;
const float p_o116619_a = 0.820000000;
const float p_o116619_cx = 0.000000000;
const float p_o116619_cy = 0.000000000;
const float p_o116604_amount1 = 1.000000000;
const float p_o116604_amount2 = 1.000000000;
const float p_o116604_amount3 = 1.000000000;
const vec4 p_o116808_color = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o116602_translate_y = 0.000000000;
const float p_o116656_amount1 = 1.000000000;
const float seed_o116620 = 0.291292071;
const float p_o116620_tx = 8.000000000;
const float p_o116620_ty = 8.000000000;
const float p_o116620_overlap = 3.000000000;
const float p_o116620_scale_x = 0.150000000;
const float p_o116620_scale_y = 0.150000000;
const float p_o116620_fixed_offset = 0.000000000;
const float p_o116620_offset = 1.000000000;
const float p_o116620_rotate = 0.000000000;
const float p_o116620_scale = 0.530000000;
const float p_o116620_value = 0.000000000;
const float p_o116599_default_in1 = 0.000000000;
const float p_o116599_default_in2 = 0.000000000;
const float p_o116596_sides = 6.000000000;
const float p_o116596_radius = 1.000000000;
const float p_o116596_edge = 0.025000000;
const float p_o116601_value = 1.000000000;
const float p_o116601_fromMin = 0.000000000;
const float p_o116601_fromMax = 1.000000000;
const float p_o116601_toMin = 0.000000000;
const float p_o116601_toMax = 0.720000000;
const float seed_o116597 = 0.000000000;
const float p_o116598_sides = 6.000000000;
const float p_o116598_radius = 1.000000000;
const float p_o116598_edge = 0.025000000;
const float p_o116600_value = 1.000000000;
const float p_o116600_fromMin = 0.000000000;
const float p_o116600_fromMax = 1.600000000;
const float p_o116600_toMin = 0.000000000;
const float p_o116600_toMax = 1.000000000;
float o116620_input_in(vec2 uv, float _seed_variation_) {
float o116597_0_1_f = (fract(elapsed_time*0.3+param_rnd(0,1, (seed_o116597+fract(_seed_variation_))+-0.961397)));
float o116601_0_clamp_false = linear_map_range(p_o116601_value*o116597_0_1_f,p_o116601_fromMin*1.0,p_o116601_fromMax*1.0,p_o116601_toMin*1.0,p_o116601_toMax*1.0);
float o116601_0_clamp_true = clamp(o116601_0_clamp_false,p_o116601_toMin,p_o116601_toMax);float o116601_0_2_f = o116601_0_clamp_false;
float o116596_0_1_f = shape_circle((uv), p_o116596_sides, p_o116596_radius*o116601_0_2_f, p_o116596_edge*1.0);
float o116600_0_clamp_false = smootherstep_map_range(p_o116600_value*o116597_0_1_f,p_o116600_fromMin*1.0,p_o116600_fromMax*1.0,p_o116600_toMin*1.0,p_o116600_toMax*1.0);
float o116600_0_clamp_true = clamp(o116600_0_clamp_false,p_o116600_toMin,p_o116600_toMax);float o116600_0_2_f = o116600_0_clamp_false;
float o116598_0_1_f = shape_circle((uv), p_o116598_sides, p_o116598_radius*o116600_0_2_f, p_o116598_edge*1.0);
float o116599_0_clamp_false = o116596_0_1_f-o116598_0_1_f;
float o116599_0_clamp_true = clamp(o116599_0_clamp_false, 0.0, 1.0);
float o116599_0_1_f = o116599_0_clamp_false;
return o116599_0_1_f;
}
float o116620_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 tiler_o116620(vec2 uv, vec2 tile, int overlap, inout vec3 instance_uv, vec2 _seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	for (int dx = -overlap; dx <= overlap; ++dx) {
		for (int dy = -overlap; dy <= overlap; ++dy) {
			vec2 pos = uv*tile+vec2(float(dx), float(dy)); pos = fract((floor(mod(pos, tile))+vec2(0.5))/tile)-vec2(0.5);
			vec2 seed = rand2(pos+_seed);
			rc1 = rand3(seed);
			pos = fract(pos+vec2(p_o116620_fixed_offset/tile.x, 0.0)*floor(mod(pos.y*tile.y, 2.0))+p_o116620_offset*seed/tile);
			float mask = o116620_input_mask(fract(pos+vec2(0.5)), _seed_variation_);
			if (mask > 0.01) {
				vec2 pv = fract(uv - pos)-vec2(0.5);
				seed = rand2(seed);
				float angle = (seed.x * 2.0 - 1.0) * p_o116620_rotate * 0.01745329251;
				float ca = cos(angle);
				float sa = sin(angle);
				pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
				pv *= (seed.y-0.5)*2.0*p_o116620_scale+1.0;
				pv /= vec2(p_o116620_scale_x, p_o116620_scale_y);
				pv += vec2(0.5);
				seed = rand2(seed);
				vec2 clamped_pv = clamp(pv, vec2(0.0), vec2(1.0));
				if (pv.x != clamped_pv.x || pv.y != clamped_pv.y) {
					continue;
				}
				vec2 full_uv = pv;
				pv = get_from_tileset( 1.0, seed.x, pv);
				float c1 = o116620_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o116620_value*seed.x);
				c = max(c, c1);
				rc = mix(rc, rc1, step(c, c1));
				instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
			}
		}
	}
	return vec4(rc, c);
}const float p_o116642_gradient_0_pos = 0.000000000;
const vec4 p_o116642_gradient_0_col = vec4(0.037170000, 0.394403011, 0.792968988, 1.000000000);
const float p_o116642_gradient_1_pos = 0.514235000;
const vec4 p_o116642_gradient_1_col = vec4(0.037170000, 0.394403011, 0.792968988, 1.000000000);
const float p_o116642_gradient_2_pos = 0.514255000;
const vec4 p_o116642_gradient_2_col = vec4(0.099030003, 0.593811989, 0.921875000, 1.000000000);
vec4 o116642_gradient_gradient_fct(float x) {
  if (x < 0.5*(p_o116642_gradient_0_pos+p_o116642_gradient_1_pos)) {
    return p_o116642_gradient_0_col;
  } else if (x < 0.5*(p_o116642_gradient_1_pos+p_o116642_gradient_2_pos)) {
    return p_o116642_gradient_1_col;
  }
  return p_o116642_gradient_2_col;
}
const float p_o116629_gradient_0_pos = 0.000000000;
const vec4 p_o116629_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o116629_gradient_1_pos = 1.000000000;
const vec4 p_o116629_gradient_1_col = vec4(0.929687977, 0.963744998, 1.000000000, 1.000000000);
vec4 o116629_gradient_gradient_fct(float x) {
  if (x < p_o116629_gradient_0_pos) {
    return p_o116629_gradient_0_col;
  } else if (x < p_o116629_gradient_1_pos) {
    return mix(p_o116629_gradient_0_col, p_o116629_gradient_1_col, ((x-p_o116629_gradient_0_pos)/(p_o116629_gradient_1_pos-p_o116629_gradient_0_pos)));
  }
  return p_o116629_gradient_1_col;
}
const float p_o116603_translate_y = 0.000000000;
const float seed_o116628 = 0.540782392;
const float p_o116628_v1 = 0.000000000;
const float p_o116628_v2 = 0.100000000;
const float p_o116628_v3 = 0.200000000;
const float p_o116628_v4 = 0.300000000;
const float p_o116628_v5 = 0.400000000;
const float seed_o116624 = 0.390599340;
const float p_o116624_tx = 10.000000000;
const float p_o116624_ty = 10.000000000;
const float p_o116624_overlap = 2.000000000;
const float p_o116624_scale_x = 0.100000000;
const float p_o116624_scale_y = 0.100000000;
const float p_o116624_fixed_offset = 0.000000000;
const float p_o116624_offset = 1.000000000;
const float p_o116624_rotate = 0.000000000;
const float p_o116624_scale = 0.800000000;
const float p_o116624_value = 0.000000000;
float o116624_input_in(vec2 uv, float _seed_variation_) {
float o116597_0_1_f = (fract(elapsed_time*0.3+param_rnd(0,1, (seed_o116597+fract(_seed_variation_))+-0.961397)));
float o116601_0_clamp_false = linear_map_range(p_o116601_value*o116597_0_1_f,p_o116601_fromMin*1.0,p_o116601_fromMax*1.0,p_o116601_toMin*1.0,p_o116601_toMax*1.0);
float o116601_0_clamp_true = clamp(o116601_0_clamp_false,p_o116601_toMin,p_o116601_toMax);float o116601_0_2_f = o116601_0_clamp_false;
float o116596_0_1_f = shape_circle((uv), p_o116596_sides, p_o116596_radius*o116601_0_2_f, p_o116596_edge*1.0);
float o116600_0_clamp_false = smootherstep_map_range(p_o116600_value*o116597_0_1_f,p_o116600_fromMin*1.0,p_o116600_fromMax*1.0,p_o116600_toMin*1.0,p_o116600_toMax*1.0);
float o116600_0_clamp_true = clamp(o116600_0_clamp_false,p_o116600_toMin,p_o116600_toMax);float o116600_0_2_f = o116600_0_clamp_false;
float o116598_0_1_f = shape_circle((uv), p_o116598_sides, p_o116598_radius*o116600_0_2_f, p_o116598_edge*1.0);
float o116599_0_clamp_false = o116596_0_1_f-o116598_0_1_f;
float o116599_0_clamp_true = clamp(o116599_0_clamp_false, 0.0, 1.0);
float o116599_0_1_f = o116599_0_clamp_false;
return o116599_0_1_f;
}
float o116624_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 tiler_o116624(vec2 uv, vec2 tile, int overlap, inout vec3 instance_uv, vec2 _seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	for (int dx = -overlap; dx <= overlap; ++dx) {
		for (int dy = -overlap; dy <= overlap; ++dy) {
			vec2 pos = uv*tile+vec2(float(dx), float(dy)); pos = fract((floor(mod(pos, tile))+vec2(0.5))/tile)-vec2(0.5);
			vec2 seed = rand2(pos+_seed);
			rc1 = rand3(seed);
			pos = fract(pos+vec2(p_o116624_fixed_offset/tile.x, 0.0)*floor(mod(pos.y*tile.y, 2.0))+p_o116624_offset*seed/tile);
			float mask = o116624_input_mask(fract(pos+vec2(0.5)), _seed_variation_);
			if (mask > 0.01) {
				vec2 pv = fract(uv - pos)-vec2(0.5);
				seed = rand2(seed);
				float angle = (seed.x * 2.0 - 1.0) * p_o116624_rotate * 0.01745329251;
				float ca = cos(angle);
				float sa = sin(angle);
				pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
				pv *= (seed.y-0.5)*2.0*p_o116624_scale+1.0;
				pv /= vec2(p_o116624_scale_x, p_o116624_scale_y);
				pv += vec2(0.5);
				seed = rand2(seed);
				vec2 clamped_pv = clamp(pv, vec2(0.0), vec2(1.0));
				if (pv.x != clamped_pv.x || pv.y != clamped_pv.y) {
					continue;
				}
				vec2 full_uv = pv;
				pv = get_from_tileset( 1.0, seed.x, pv);
				float c1 = o116624_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o116624_value*seed.x);
				c = max(c, c1);
				rc = mix(rc, rc1, step(c, c1));
				instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
			}
		}
	}
	return vec4(rc, c);
}float o116628_input_in(vec2 uv, float _seed_variation_) {
vec3 o116624_0_instance_uv = vec3(0.0);
vec4 o116624_0_rch = tiler_o116624((uv), vec2(p_o116624_tx, p_o116624_ty), int(p_o116624_overlap), o116624_0_instance_uv, vec2(float((seed_o116624+fract(_seed_variation_)))), _seed_variation_);float o116624_0_1_f = o116624_0_rch.a;
return o116624_0_1_f;
}
const float p_o116606_gradient_0_pos = 0.000000000;
const vec4 p_o116606_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o116606_gradient_1_pos = 1.000000000;
const vec4 p_o116606_gradient_1_col = vec4(0.492188007, 0.721706986, 1.000000000, 1.000000000);
vec4 o116606_gradient_gradient_fct(float x) {
  if (x < p_o116606_gradient_0_pos) {
    return p_o116606_gradient_0_col;
  } else if (x < p_o116606_gradient_1_pos) {
    return mix(p_o116606_gradient_0_col, p_o116606_gradient_1_col, ((x-p_o116606_gradient_0_pos)/(p_o116606_gradient_1_pos-p_o116606_gradient_0_pos)));
  }
  return p_o116606_gradient_1_col;
}
const float p_o116605_translate_y = 0.000000000;
const vec4 p_o116659_color = vec4(0.051383998, 0.538340986, 0.876953006, 1.000000000);
const float p_o116661_default_in1 = 0.000000000;
const float p_o116661_default_in2 = 0.000000000;
const float p_o116658_sides = 6.000000000;
const float p_o116658_radius = 0.940000000;
const float p_o116658_edge = 0.000000000;
const float p_o116905_default_in1 = 0.000000000;
const float p_o116905_default_in2 = 0.750000000;
const float p_o116662_default_in1 = 0.000000000;
const float p_o116662_default_in2 = 0.000000000;
const float p_o116660_sides = 6.000000000;
const float p_o116660_radius = 0.833100000;
const float p_o116660_edge = 0.579400000;
const float p_o116686_sides = 6.000000000;
const float p_o116686_radius = 0.920000000;
const float p_o116686_edge = 0.000000000;
const float p_o116669_amount1 = 1.000000000;
const float p_o116669_amount2 = 1.000000000;
const float p_o116669_amount3 = 1.000000000;
const float seed_o116664 = 0.556229651;
const float p_o116664_count = 90.000000000;
const float p_o116664_rings = 1.000000000;
const float p_o116664_scale_x = 0.900000000;
const float p_o116664_scale_y = 0.900000000;
const float p_o116664_radius = 0.293600000;
const float p_o116664_spiral = 0.000000000;
const float p_o116664_i_rotate = 1.000000000;
const float p_o116664_i_scale = 0.000000000;
const float p_o116664_rotate = 0.000000000;
const float p_o116664_scale = 0.000000000;
const float p_o116664_value = 0.000000000;
const float p_o116689_translate_x = 0.000000000;
const float p_o116689_translate_y = -0.030350000;
const float seed_o116668 = 0.000000000;
const float seed_o116663 = 0.052988488;
const float p_o116663_sides = 6.000000000;
const float p_o116663_edge = 0.000000000;
float o116664_input_in(vec2 uv, float _seed_variation_) {
float o116663_0_1_f = shape_circle((((uv)-vec2(p_o116689_translate_x, p_o116689_translate_y))-vec2((param_rnd(-.1,.1, (seed_o116668+fract(_seed_variation_))+0.841471)), ((sin((elapsed_time*1.5+param_rnd(-10.0,10.0, (seed_o116668+fract(_seed_variation_))+16.038603)))*2.0-1.0)*0.005))), p_o116663_sides, (param_rnd(.09,.02, (seed_o116663+fract(_seed_variation_))+17.841471))*1.0, p_o116663_edge*1.0);
vec4 o116668_0_1_rgba = vec4(vec3(o116663_0_1_f), 1.0);
vec4 o116689_0_1_rgba = o116668_0_1_rgba;
return (dot((o116689_0_1_rgba).rgb, vec3(1.0))/3.0);
}
float o116664_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 splatter_o116664(vec2 uv, int count, int rings, inout vec3 instance_uv, vec2 seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	seed = rand2(seed);
	for (int i = 0; i < count; ++i) {
		float a = -1.57079632679+6.28318530718*float(i)*p_o116664_rings/float(count);
		float rings_distance = ceil(float(i+1)*float(rings)/float(count))/float(rings);
		float spiral_distance = float(i+1)/float(count);
		vec2 pos = p_o116664_radius*mix(rings_distance, spiral_distance, p_o116664_spiral)*vec2(cos(a), sin(a));
		float mask = o116664_input_mask(fract(pos-vec2(0.5)), _seed_variation_);
		if (mask > 0.01) {
			vec2 pv = uv-0.5-pos;
			rc1 = rand3(seed);
			seed = rand2(seed);
			float angle = (seed.x * 2.0 - 1.0) * p_o116664_rotate * 0.01745329251 + (a+1.57079632679) * p_o116664_i_rotate;
			float ca = cos(angle);
			float sa = sin(angle);
			pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
			pv /= mix(1.0, float(i+1)/float(count+1), p_o116664_i_scale);
			pv /= vec2(p_o116664_scale_x, p_o116664_scale_y);
			pv *= (seed.y-0.5)*2.0*p_o116664_scale+1.0;
			pv += vec2(0.5);
			seed = rand2(seed);
			if (pv != clamp(pv, vec2(0.0), vec2(1.0))) {
				continue;
			}
			vec2 full_uv = pv;
			pv = get_from_tileset( 1.0, seed.x, pv);
			float c1 = o116664_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o116664_value*seed.x);
			c = max(c, c1);
			rc = mix(rc, rc1, step(c, c1));
			instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
		}
	}
	return vec4(rc, c);
}
const float p_o116670_gradient_0_pos = 0.000000000;
const vec4 p_o116670_gradient_0_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o116670_gradient_1_pos = 0.332831000;
const vec4 p_o116670_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o116670_gradient_2_pos = 0.332851000;
const vec4 p_o116670_gradient_2_col = vec4(0.121569000, 0.270588011, 0.541176021, 1.000000000);
const float p_o116670_gradient_3_pos = 0.401533000;
const vec4 p_o116670_gradient_3_col = vec4(0.121569000, 0.270588011, 0.541176021, 1.000000000);
const float p_o116670_gradient_4_pos = 0.401553000;
const vec4 p_o116670_gradient_4_col = vec4(0.051383998, 0.538340986, 0.876953006, 1.000000000);
vec4 o116670_gradient_gradient_fct(float x) {
  if (x < 0.5*(p_o116670_gradient_0_pos+p_o116670_gradient_1_pos)) {
    return p_o116670_gradient_0_col;
  } else if (x < 0.5*(p_o116670_gradient_1_pos+p_o116670_gradient_2_pos)) {
    return p_o116670_gradient_1_col;
  } else if (x < 0.5*(p_o116670_gradient_2_pos+p_o116670_gradient_3_pos)) {
    return p_o116670_gradient_2_col;
  } else if (x < 0.5*(p_o116670_gradient_3_pos+p_o116670_gradient_4_pos)) {
    return p_o116670_gradient_3_col;
  }
  return p_o116670_gradient_4_col;
}
const float p_o116693_translate_x = 0.000000000;
const float p_o116693_translate_y = -0.005000000;
const float p_o116692_sides = 6.000000000;
const float p_o116692_radius = 0.705700000;
const float p_o116692_edge = 0.005900000;
const float p_o116711_translate_x = 0.000000000;
const float p_o116711_translate_y = 0.000000000;
const float p_o116711_rotate = 0.000000000;
const float p_o116711_scale_x = 1.077250000;
const float p_o116920_amount1 = 1.000000000;
const float seed_o116706 = 0.000496532;
const float p_o116706_count = 50.000000000;
const float p_o116706_rings = 1.000000000;
const float p_o116706_scale_x = 0.500000000;
const float p_o116706_scale_y = 0.500000000;
const float p_o116706_radius = 0.405300000;
const float p_o116706_spiral = 0.000000000;
const float p_o116706_i_rotate = 1.000000000;
const float p_o116706_i_scale = 0.000000000;
const float p_o116706_rotate = 0.000000000;
const float p_o116706_scale = 0.000000000;
const float p_o116706_value = 0.000000000;
const float seed_o116705 = 0.000000000;
const float p_o116705_translate_y = 0.165000000;
const float p_o116705_rotate = 0.000000000;
const float p_o116705_scale_x = 0.500000000;
const float p_o116705_scale_y = 0.500000000;
const float seed_o116703 = 0.000000000;
const float p_o116703_translate_x = 0.000000000;
const float p_o116703_rotate = 0.000000000;
const float p_o116703_scale_x = 0.500000000;
const float p_o116703_scale_y = 0.500000000;
const float p_o116704_default_in1 = 0.000000000;
const float p_o116704_default_in2 = 1.730000000;
const float seed_o116694 = 0.499502510;
const float seed_o116710 = 0.000000000;
const float p_o116710_cx = 0.000000000;
const float p_o116710_cy = 0.000000000;
const float p_o116700_bevel = 0.000000000;
const float p_o116700_base = 0.000000000;
const float p_o116697_a = 90.000000000;
const float p_o116695_ra = 0.220000000;
const float p_o116695_rb = 0.290000000;
const float p_o116695_d = 1.000000000;
const float p_o116695_cx = 0.000000000;
const float p_o116695_cy = 0.000000000;
const float p_o116701_value = 1.000000000;
const float p_o116701_fromMin = 0.000000000;
const float p_o116701_fromMax = 0.498000000;
const float p_o116701_toMin = 0.229000000;
const float p_o116701_toMax = 0.754000000;
const float p_o116698_value = 1.000000000;
const float p_o116698_fromMin = 0.000000000;
const float p_o116698_fromMax = 1.000000000;
const float p_o116698_toMin = 0.335000000;
const float p_o116698_toMax = 1.000000000;
float o116706_input_in(vec2 uv, float _seed_variation_) {
float o116694_0_1_f = (fract(elapsed_time*0.4+param_rnd(0,1, (seed_o116694+fract(_seed_variation_))+-0.961397)));
float o116704_0_clamp_false = o116694_0_1_f*p_o116704_default_in2;
float o116704_0_clamp_true = clamp(o116704_0_clamp_false, 0.0, 1.0);
float o116704_0_2_f = o116704_0_clamp_false;
vec4 o116702_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o116704_0_2_f), 1.0).rgb, vec4(vec3(o116704_0_2_f), 1.0).a);
float o116694_0_3_f = (fract(elapsed_time*0.4+param_rnd(0,1, (seed_o116694+fract(_seed_variation_))+-0.961397)));
float o116701_0_clamp_false = linear_map_range(p_o116701_value*o116694_0_3_f,p_o116701_fromMin*1.0,p_o116701_fromMax*1.0,p_o116701_toMin*1.0,p_o116701_toMax*1.0);
float o116701_0_clamp_true = clamp(o116701_0_clamp_false,p_o116701_toMin,p_o116701_toMax);float o116701_0_2_f = o116701_0_clamp_false;
float o116698_0_clamp_false = linear_map_range(p_o116698_value*o116694_0_3_f,p_o116698_fromMin*1.0,p_o116698_fromMax*1.0,p_o116698_toMin*1.0,p_o116698_toMax*1.0);
float o116698_0_clamp_true = clamp(o116698_0_clamp_false,p_o116698_toMin,p_o116698_toMax);float o116698_0_2_f = o116698_0_clamp_true;
vec4 o116699_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o116698_0_2_f), 1.0).rgb, vec4(vec3(o116698_0_2_f), 1.0).a);
float o116695_0_1_sdf2d = sdMoon((sdf2d_rotate((scale((transform2_clamp(transform2((transform2((uv), vec2((param_rnd(-.1,.1, (seed_o116705+fract(_seed_variation_))+0.841471))*(2.0*1.0-1.0), p_o116705_translate_y*(2.0*1.0-1.0)), p_o116705_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116705_scale_x*(2.0*1.0-1.0), p_o116705_scale_y*(2.0*1.0-1.0)))), vec2(p_o116703_translate_x*(2.0*1.0-1.0), (param_rnd(.05,.1, (seed_o116703+fract(_seed_variation_))+17.841471))*(2.0*(dot((o116702_0_1_rgba).rgb, vec3(1.0))/3.0)-1.0)), p_o116703_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116703_scale_x*(2.0*1.0-1.0), p_o116703_scale_y*(2.0*1.0-1.0))))), vec2(0.5+p_o116710_cx, 0.5+p_o116710_cy), vec2((param_rnd(0,1, (seed_o116710+fract(_seed_variation_))+34.841471)), ((param_rnd(0,1, (seed_o116710+fract(_seed_variation_))+34.841471)))))), p_o116697_a*0.01745329251)) - 0.5 - vec2(p_o116695_cx, p_o116695_cy), p_o116695_d*(dot((o116699_0_1_rgba).rgb, vec3(1.0))/3.0), p_o116695_ra, p_o116695_rb*o116701_0_2_f);
float o116697_0_1_sdf2d = o116695_0_1_sdf2d;
float o116700_0_1_f = clamp(p_o116700_base-o116697_0_1_sdf2d/max(p_o116700_bevel, 0.00001), 0.0, 1.0);
vec4 o116710_0_1_rgba = vec4(vec3(o116700_0_1_f), 1.0);
vec4 o116703_0_1_rgba = o116710_0_1_rgba;
vec4 o116705_0_1_rgba = o116703_0_1_rgba;
return (dot((o116705_0_1_rgba).rgb, vec3(1.0))/3.0);
}
float o116706_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 splatter_o116706(vec2 uv, int count, int rings, inout vec3 instance_uv, vec2 seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	seed = rand2(seed);
	for (int i = 0; i < count; ++i) {
		float a = -1.57079632679+6.28318530718*float(i)*p_o116706_rings/float(count);
		float rings_distance = ceil(float(i+1)*float(rings)/float(count))/float(rings);
		float spiral_distance = float(i+1)/float(count);
		vec2 pos = p_o116706_radius*mix(rings_distance, spiral_distance, p_o116706_spiral)*vec2(cos(a), sin(a));
		float mask = o116706_input_mask(fract(pos-vec2(0.5)), _seed_variation_);
		if (mask > 0.01) {
			vec2 pv = uv-0.5-pos;
			rc1 = rand3(seed);
			seed = rand2(seed);
			float angle = (seed.x * 2.0 - 1.0) * p_o116706_rotate * 0.01745329251 + (a+1.57079632679) * p_o116706_i_rotate;
			float ca = cos(angle);
			float sa = sin(angle);
			pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
			pv /= mix(1.0, float(i+1)/float(count+1), p_o116706_i_scale);
			pv /= vec2(p_o116706_scale_x, p_o116706_scale_y);
			pv *= (seed.y-0.5)*2.0*p_o116706_scale+1.0;
			pv += vec2(0.5);
			seed = rand2(seed);
			if (pv != clamp(pv, vec2(0.0), vec2(1.0))) {
				continue;
			}
			vec2 full_uv = pv;
			pv = get_from_tileset( 1.0, seed.x, pv);
			float c1 = o116706_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o116706_value*seed.x);
			c = max(c, c1);
			rc = mix(rc, rc1, step(c, c1));
			instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
		}
	}
	return vec4(rc, c);
}
const float p_o116906_gradient_0_pos = 0.000000000;
const vec4 p_o116906_gradient_0_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o116906_gradient_1_pos = 0.601911000;
const vec4 p_o116906_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o116906_gradient_2_pos = 0.601931000;
const vec4 p_o116906_gradient_2_col = vec4(0.744140983, 0.895057976, 1.000000000, 1.000000000);
vec4 o116906_gradient_gradient_fct(float x) {
  if (x < 0.5*(p_o116906_gradient_0_pos+p_o116906_gradient_1_pos)) {
    return p_o116906_gradient_0_col;
  } else if (x < 0.5*(p_o116906_gradient_1_pos+p_o116906_gradient_2_pos)) {
    return p_o116906_gradient_1_col;
  }
  return p_o116906_gradient_2_col;
}
const float p_o116687_sides = 6.000000000;
const float p_o116687_radius = 0.695200000;
const float p_o116687_edge = 0.000100000;
const vec4 p_o116712_color = vec4(0.038757000, 0.057116002, 0.156250000, 1.000000000);
const vec4 p_o116807_color = vec4(0.218750000, 0.533080995, 1.000000000, 1.000000000);
const vec4 p_o116904_color = vec4(0.648688972, 0.760960996, 0.927734017, 1.000000000);
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec2 o116619_0_co = vec2(p_o116619_cx+0.5,p_o116619_cy+0.5);
float o116619_0_f = dot(2.0*((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))) - o116619_0_co),2.0*((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))) - o116619_0_co));vec4 o116808_0_1_rgba = p_o116808_color;
vec3 o116620_0_instance_uv = vec3(0.0);
vec4 o116620_0_rch = tiler_o116620(((o116619_0_co-(o116619_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116619_r-o116619_0_f)*max(p_o116619_a,0.0)+1.0))-vec2((-elapsed_time*.1), p_o116602_translate_y)), vec2(p_o116620_tx, p_o116620_ty), int(p_o116620_overlap), o116620_0_instance_uv, vec2(float((seed_o116620+fract(_seed_variation_)))), _seed_variation_);float o116620_0_1_f = o116620_0_rch.a;
vec3 o116620_1_2_rgb = o116620_0_rch.rgb;
vec4 o116642_0_1_rgba = o116642_gradient_gradient_fct((dot(o116620_1_2_rgb, vec3(1.0))/3.0));
vec4 o116656_0_b = vec4(vec3(o116620_0_1_f), 1.0);
vec4 o116656_0_l;
float o116656_0_a;

o116656_0_l = o116642_0_1_rgba;
o116656_0_a = p_o116656_amount1*1.0;
o116656_0_b = vec4(blend_multiply(((o116619_0_co-(o116619_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116619_r-o116619_0_f)*max(p_o116619_a,0.0)+1.0))-vec2((-elapsed_time*.1), p_o116602_translate_y)), o116656_0_l.rgb, o116656_0_b.rgb, o116656_0_a*o116656_0_l.a), min(1.0, o116656_0_b.a+o116656_0_a*o116656_0_l.a));

vec4 o116656_0_2_rgba = o116656_0_b;
vec4 o116602_0_1_rgba = o116656_0_2_rgba;
vec3 o116620_3_instance_uv = vec3(0.0);
vec4 o116620_3_rch = tiler_o116620(((o116619_0_co-(o116619_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116619_r-o116619_0_f)*max(p_o116619_a,0.0)+1.0))-vec2((-elapsed_time*.1), p_o116602_translate_y)), vec2(p_o116620_tx, p_o116620_ty), int(p_o116620_overlap), o116620_3_instance_uv, vec2(float((seed_o116620+fract(_seed_variation_)))), _seed_variation_);float o116620_0_4_f = o116620_3_rch.a;
vec4 o116602_1_2_rgba = vec4(vec3(o116620_0_4_f), 1.0);
float o116628_0_1_f = o116628_input_in(((o116619_0_co-(o116619_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116619_r-o116619_0_f)*max(p_o116619_a,0.0)+1.0))-vec2((-elapsed_time*.04), p_o116603_translate_y)), (seed_o116628+fract(_seed_variation_))+p_o116628_v1);
vec4 o116603_0_1_rgba = vec4(vec3(o116628_0_1_f), 1.0);
vec4 o116629_0_1_rgba = o116629_gradient_gradient_fct((dot((o116603_0_1_rgba).rgb, vec3(1.0))/3.0));
float o116628_1_3_f = o116628_input_in(((o116619_0_co-(o116619_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116619_r-o116619_0_f)*max(p_o116619_a,0.0)+1.0))-vec2((-elapsed_time*.09), p_o116605_translate_y)), (seed_o116628+fract(_seed_variation_))+p_o116628_v2);
vec4 o116605_0_1_rgba = vec4(vec3(o116628_1_3_f), 1.0);
vec4 o116606_0_1_rgba = o116606_gradient_gradient_fct((dot((o116605_0_1_rgba).rgb, vec3(1.0))/3.0));
vec4 o116604_0_b = o116808_0_1_rgba;
vec4 o116604_0_l;
float o116604_0_a;

o116604_0_l = o116602_0_1_rgba;
o116604_0_a = p_o116604_amount1*(dot((o116602_1_2_rgba).rgb, vec3(1.0))/3.0);
o116604_0_b = vec4(blend_lighten((o116619_0_co-(o116619_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116619_r-o116619_0_f)*max(p_o116619_a,0.0)+1.0)), o116604_0_l.rgb, o116604_0_b.rgb, o116604_0_a*o116604_0_l.a), min(1.0, o116604_0_b.a+o116604_0_a*o116604_0_l.a));

o116604_0_l = o116629_0_1_rgba;
o116604_0_a = p_o116604_amount2*1.0;
o116604_0_b = vec4(blend_lighten((o116619_0_co-(o116619_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116619_r-o116619_0_f)*max(p_o116619_a,0.0)+1.0)), o116604_0_l.rgb, o116604_0_b.rgb, o116604_0_a*o116604_0_l.a), min(1.0, o116604_0_b.a+o116604_0_a*o116604_0_l.a));

o116604_0_l = o116606_0_1_rgba;
o116604_0_a = p_o116604_amount3*1.0;
o116604_0_b = vec4(blend_lighten((o116619_0_co-(o116619_0_co-(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))))/(sqrt(p_o116619_r-o116619_0_f)*max(p_o116619_a,0.0)+1.0)), o116604_0_l.rgb, o116604_0_b.rgb, o116604_0_a*o116604_0_l.a), min(1.0, o116604_0_b.a+o116604_0_a*o116604_0_l.a));

vec4 o116604_0_2_rgba = o116604_0_b;
vec4 o116808_0_3_rgba = p_o116808_color;
vec3 o116620_5_instance_uv = vec3(0.0);
vec4 o116620_5_rch = tiler_o116620(((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.1), p_o116602_translate_y)), vec2(p_o116620_tx, p_o116620_ty), int(p_o116620_overlap), o116620_5_instance_uv, vec2(float((seed_o116620+fract(_seed_variation_)))), _seed_variation_);float o116620_0_6_f = o116620_5_rch.a;
vec3 o116620_1_7_rgb = o116620_5_rch.rgb;
vec4 o116642_0_3_rgba = o116642_gradient_gradient_fct((dot(o116620_1_7_rgb, vec3(1.0))/3.0));
vec4 o116656_3_b = vec4(vec3(o116620_0_6_f), 1.0);
vec4 o116656_3_l;
float o116656_3_a;

o116656_3_l = o116642_0_3_rgba;
o116656_3_a = p_o116656_amount1*1.0;
o116656_3_b = vec4(blend_multiply(((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.1), p_o116602_translate_y)), o116656_3_l.rgb, o116656_3_b.rgb, o116656_3_a*o116656_3_l.a), min(1.0, o116656_3_b.a+o116656_3_a*o116656_3_l.a));

vec4 o116656_0_5_rgba = o116656_3_b;
vec4 o116602_0_4_rgba = o116656_0_5_rgba;
vec3 o116620_8_instance_uv = vec3(0.0);
vec4 o116620_8_rch = tiler_o116620(((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.1), p_o116602_translate_y)), vec2(p_o116620_tx, p_o116620_ty), int(p_o116620_overlap), o116620_8_instance_uv, vec2(float((seed_o116620+fract(_seed_variation_)))), _seed_variation_);float o116620_0_9_f = o116620_8_rch.a;
vec4 o116602_1_5_rgba = vec4(vec3(o116620_0_9_f), 1.0);
float o116628_0_5_f = o116628_input_in(((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.04), p_o116603_translate_y)), (seed_o116628+fract(_seed_variation_))+p_o116628_v1);
vec4 o116603_0_3_rgba = vec4(vec3(o116628_0_5_f), 1.0);
vec4 o116629_0_3_rgba = o116629_gradient_gradient_fct((dot((o116603_0_3_rgba).rgb, vec3(1.0))/3.0));
float o116628_1_7_f = o116628_input_in(((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0))))-vec2((-elapsed_time*.09), p_o116605_translate_y)), (seed_o116628+fract(_seed_variation_))+p_o116628_v2);
vec4 o116605_0_3_rgba = vec4(vec3(o116628_1_7_f), 1.0);
vec4 o116606_0_3_rgba = o116606_gradient_gradient_fct((dot((o116605_0_3_rgba).rgb, vec3(1.0))/3.0));
vec4 o116604_3_b = o116808_0_3_rgba;
vec4 o116604_3_l;
float o116604_3_a;

o116604_3_l = o116602_0_4_rgba;
o116604_3_a = p_o116604_amount1*(dot((o116602_1_5_rgba).rgb, vec3(1.0))/3.0);
o116604_3_b = vec4(blend_lighten((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))), o116604_3_l.rgb, o116604_3_b.rgb, o116604_3_a*o116604_3_l.a), min(1.0, o116604_3_b.a+o116604_3_a*o116604_3_l.a));

o116604_3_l = o116629_0_3_rgba;
o116604_3_a = p_o116604_amount2*1.0;
o116604_3_b = vec4(blend_lighten((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))), o116604_3_l.rgb, o116604_3_b.rgb, o116604_3_a*o116604_3_l.a), min(1.0, o116604_3_b.a+o116604_3_a*o116604_3_l.a));

o116604_3_l = o116606_0_3_rgba;
o116604_3_a = p_o116604_amount3*1.0;
o116604_3_b = vec4(blend_lighten((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))), o116604_3_l.rgb, o116604_3_b.rgb, o116604_3_a*o116604_3_l.a), min(1.0, o116604_3_b.a+o116604_3_a*o116604_3_l.a));

vec4 o116604_0_5_rgba = o116604_3_b;
vec4 o116619_0_1_rgba = clamp(mix(o116604_0_2_rgba,o116604_0_5_rgba,step(p_o116619_r,o116619_0_f)),0.0,1.0);
vec4 o116659_0_1_rgba = p_o116659_color;
float o116658_0_1_f = shape_circle((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))), p_o116658_sides, p_o116658_radius*1.0, p_o116658_edge*1.0);
float o116660_0_1_f = shape_circle((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))), p_o116660_sides, p_o116660_radius*1.0, p_o116660_edge*1.0);
float o116662_0_clamp_false = smoothstep(0.0, 1.0, o116660_0_1_f);
float o116662_0_clamp_true = clamp(o116662_0_clamp_false, 0.0, 1.0);
float o116662_0_1_f = o116662_0_clamp_false;
float o116905_0_clamp_false = o116662_0_1_f*p_o116905_default_in2;
float o116905_0_clamp_true = clamp(o116905_0_clamp_false, 0.0, 1.0);
float o116905_0_2_f = o116905_0_clamp_false;
float o116661_0_clamp_false = o116658_0_1_f-o116905_0_2_f;
float o116661_0_clamp_true = clamp(o116661_0_clamp_false, 0.0, 1.0);
float o116661_0_1_f = o116661_0_clamp_false;
float o116686_0_1_f = shape_circle((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))), p_o116686_sides, p_o116686_radius*1.0, p_o116686_edge*1.0);
vec4 o116657_0_b = o116619_0_1_rgba;
vec4 o116657_0_l;
float o116657_0_a;

o116657_0_l = o116659_0_1_rgba;
o116657_0_a = p_o116657_amount1*o116661_0_1_f;
o116657_0_b = vec4(blend_normal((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))), o116657_0_l.rgb, o116657_0_b.rgb, o116657_0_a*o116657_0_l.a), min(1.0, o116657_0_b.a+o116657_0_a*o116657_0_l.a));

o116657_0_l = vec4(vec3(o116686_0_1_f), 1.0);
o116657_0_a = p_o116657_amount2*1.0;
o116657_0_b = vec4(blend_multiply((transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116690_translate_x*(2.0*1.0-1.0), p_o116690_translate_y*(2.0*1.0-1.0)), p_o116690_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116690_scale_x*(2.0*1.0-1.0), p_o116690_scale_y*(2.0*1.0-1.0)))), o116657_0_l.rgb, o116657_0_b.rgb, o116657_0_a*o116657_0_l.a), min(1.0, o116657_0_b.a+o116657_0_a*o116657_0_l.a));

vec4 o116657_0_2_rgba = o116657_0_b;
vec4 o116690_0_1_rgba = o116657_0_2_rgba;
vec3 o116664_0_instance_uv = vec3(0.0);
vec4 o116664_0_rch = splatter_o116664((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), int(p_o116664_count), int(p_o116664_rings), o116664_0_instance_uv, vec2(float((seed_o116664+fract(_seed_variation_)))), _seed_variation_);float o116664_0_1_f = o116664_0_rch.a;
vec3 o116664_1_2_rgb = o116664_0_rch.rgb;
vec4 o116670_0_1_rgba = o116670_gradient_gradient_fct((dot(o116664_1_2_rgb, vec3(1.0))/3.0));
float o116692_0_1_f = shape_circle(((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0)))))-vec2(p_o116693_translate_x, p_o116693_translate_y)), p_o116692_sides, p_o116692_radius*1.0, p_o116692_edge*1.0);
vec4 o116693_0_1_rgba = vec4(vec3(o116692_0_1_f), 1.0);
vec3 o116706_0_instance_uv = vec3(0.0);
vec4 o116706_0_rch = splatter_o116706((transform2_clamp(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116711_translate_x*(2.0*1.0-1.0), p_o116711_translate_y*(2.0*1.0-1.0)), p_o116711_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116711_scale_x*(2.0*1.0-1.0), (p_o116711_scale_x)*(2.0*1.0-1.0))))), int(p_o116706_count), int(p_o116706_rings), o116706_0_instance_uv, vec2(float((seed_o116706+fract(_seed_variation_)))), _seed_variation_);float o116706_0_1_f = o116706_0_rch.a;
vec3 o116706_1_2_rgb = o116706_0_rch.rgb;
vec4 o116906_0_1_rgba = o116906_gradient_gradient_fct((dot(o116706_1_2_rgb, vec3(1.0))/3.0));
vec4 o116920_0_b = vec4(vec3(o116706_0_1_f), 1.0);
vec4 o116920_0_l;
float o116920_0_a;

o116920_0_l = o116906_0_1_rgba;
o116920_0_a = p_o116920_amount1*1.0;
o116920_0_b = vec4(blend_multiply((transform2_clamp(transform2((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), vec2(p_o116711_translate_x*(2.0*1.0-1.0), p_o116711_translate_y*(2.0*1.0-1.0)), p_o116711_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116711_scale_x*(2.0*1.0-1.0), (p_o116711_scale_x)*(2.0*1.0-1.0))))), o116920_0_l.rgb, o116920_0_b.rgb, o116920_0_a*o116920_0_l.a), min(1.0, o116920_0_b.a+o116920_0_a*o116920_0_l.a));

vec4 o116920_0_2_rgba = o116920_0_b;
vec4 o116711_0_1_rgba = o116920_0_2_rgba;
vec4 o116669_0_b = vec4(vec3(o116664_0_1_f), 1.0);
vec4 o116669_0_l;
float o116669_0_a;

o116669_0_l = o116670_0_1_rgba;
o116669_0_a = p_o116669_amount1*1.0;
o116669_0_b = vec4(blend_multiply((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), o116669_0_l.rgb, o116669_0_b.rgb, o116669_0_a*o116669_0_l.a), min(1.0, o116669_0_b.a+o116669_0_a*o116669_0_l.a));

o116669_0_l = o116693_0_1_rgba;
o116669_0_a = p_o116669_amount2*1.0;
o116669_0_b = vec4(blend_lighten((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), o116669_0_l.rgb, o116669_0_b.rgb, o116669_0_a*o116669_0_l.a), min(1.0, o116669_0_b.a+o116669_0_a*o116669_0_l.a));

o116669_0_l = o116711_0_1_rgba;
o116669_0_a = p_o116669_amount3*1.0;
o116669_0_b = vec4(blend_lighten((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), o116669_0_l.rgb, o116669_0_b.rgb, o116669_0_a*o116669_0_l.a), min(1.0, o116669_0_b.a+o116669_0_a*o116669_0_l.a));

vec4 o116669_0_2_rgba = o116669_0_b;
float o116687_0_1_f = shape_circle((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), p_o116687_sides, p_o116687_radius*1.0, p_o116687_edge*1.0);
vec4 o116688_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o116687_0_1_f), 1.0).rgb, vec4(vec3(o116687_0_1_f), 1.0).a);
vec4 o116712_0_1_rgba = p_o116712_color;
vec4 o116807_0_1_rgba = p_o116807_color;
vec4 o116732_0 = textureLod(texture_1, (transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), 0.0);
vec4 o116904_0_1_rgba = p_o116904_color;
vec4 o116829_0 = textureLod(texture_2, (transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), 0.0);
vec4 o116691_0_b = o116690_0_1_rgba;
vec4 o116691_0_l;
float o116691_0_a;

o116691_0_l = o116669_0_2_rgba;
o116691_0_a = p_o116691_amount1*(dot((o116688_0_1_rgba).rgb, vec3(1.0))/3.0);
o116691_0_b = vec4(blend_normal((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), o116691_0_l.rgb, o116691_0_b.rgb, o116691_0_a*o116691_0_l.a), min(1.0, o116691_0_b.a+o116691_0_a*o116691_0_l.a));

o116691_0_l = o116712_0_1_rgba;
o116691_0_a = p_o116691_amount2*1.0;
o116691_0_b = vec4(blend_lighten((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), o116691_0_l.rgb, o116691_0_b.rgb, o116691_0_a*o116691_0_l.a), min(1.0, o116691_0_b.a+o116691_0_a*o116691_0_l.a));

o116691_0_l = o116807_0_1_rgba;
o116691_0_a = p_o116691_amount3*(dot((o116732_0).rgb, vec3(1.0))/3.0);
o116691_0_b = vec4(blend_additive((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), o116691_0_l.rgb, o116691_0_b.rgb, o116691_0_a*o116691_0_l.a), min(1.0, o116691_0_b.a+o116691_0_a*o116691_0_l.a));

o116691_0_l = o116904_0_1_rgba;
o116691_0_a = p_o116691_amount4*(dot((o116829_0).rgb, vec3(1.0))/3.0);
o116691_0_b = vec4(blend_lighten((transform2_clamp(transform2((uv), vec2(p_o116921_translate_x*(2.0*1.0-1.0), p_o116921_translate_y*(2.0*1.0-1.0)), p_o116921_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o116921_scale_x*(2.0*1.0-1.0), p_o116921_scale_y*(2.0*1.0-1.0))))), o116691_0_l.rgb, o116691_0_b.rgb, o116691_0_a*o116691_0_l.a), min(1.0, o116691_0_b.a+o116691_0_a*o116691_0_l.a));

vec4 o116691_0_2_rgba = o116691_0_b;
vec4 o116921_0_1_rgba = o116691_0_2_rgba;

	vec4 color_tex = o116921_0_1_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	ALBEDO = color_tex.rgb;
	ALPHA = color_tex.a;

}



