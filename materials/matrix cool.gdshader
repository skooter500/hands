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
vec4 brick(vec2 uv, vec2 bmin, vec2 bmax, float mortar, float round, float bevel, float brick_height) {
	float color;
	vec2 size = bmax - bmin;
	float min_size = min(size.x, size.y);
	mortar *= brick_height;
	bevel *= brick_height;
	round *= brick_height;
	vec2 center = 0.5*(bmin+bmax);
	vec2 d = abs(uv-center)-0.5*(size)+vec2(round+mortar);
	color = length(max(d,vec2(0))) + min(max(d.x,d.y),0.0)-round;
	color = clamp(-color/bevel, 0.0, 1.0);
	vec2 tiled_brick_pos = mod(bmin, vec2(1.0, 1.0));
	return vec4(color, center, tiled_brick_pos.x+7.0*tiled_brick_pos.y);
}
vec4 brick_corner_bb(vec2 uv, vec2 bmin, vec2 bmax, float mortar, float corner, float brick_height) {
	vec2 center = 0.5*(bmin + bmax);
	vec2 size = bmax - bmin;
	float max_size = max(size.x, size.y);
	float min_size = min(size.x, size.y);
	mortar *= brick_height;
	corner *= brick_height;
	
	vec2 corner1 = vec2(bmin + mortar);
	vec2 corner2 = vec2(bmax.x - mortar - corner, bmin.y + mortar);
	vec2 corner3 = vec2(bmin.x + mortar, bmax.y - mortar - corner);
	vec2 corner4 = vec2(bmax - mortar - corner);
	vec2 top = uv.x < center.x ? corner1 : corner2;
	vec2 bottom = uv.x < center.x ? corner3 : corner4;
	vec2 positions = uv.y < center.y ? top : bottom;
	return vec4(round(fract(positions)*4096.0)/4096.0, corner, corner);
}
vec4 bricks_rb(vec2 uv, vec2 count, float repeat, float offset) {
	count *= repeat;
	float x_offset = offset*step(0.5, fract(uv.y*count.y*0.5));
	vec2 bmin = floor(vec2(uv.x*count.x-x_offset, uv.y*count.y));
	bmin.x += x_offset;
	bmin /= count;
	return vec4(bmin, bmin+vec2(1.0)/count);
}
vec4 bricks_rb2(vec2 uv, vec2 count, float repeat, float offset) {
	count *= repeat;
	float x_offset = offset*step(0.5, fract(uv.y*count.y*0.5));
	count.x = count.x*(1.0+step(0.5, fract(uv.y*count.y*0.5)));
	vec2 bmin = floor(vec2(uv.x*count.x-x_offset, uv.y*count.y));
	bmin.x += x_offset;
	bmin /= count;
	return vec4(bmin, bmin+vec2(1.0)/count);
}
vec4 bricks_rb3(vec2 uv, vec2 count, float repeat, float offset) {
	vec4 bb = bricks_rb(uv, count, repeat, offset);
	
	if ( (uv.x - bb.x) / (bb.z - bb.x) < 1.0/3.0) {
		bb.z = bb.x + (bb.z - bb.x) / 3.0;
	} else {
		bb.x = bb.x + (bb.z - bb.x) / 3.0;
	}
	return bb;
}
vec4 bricks_hb(vec2 uv, vec2 count, float repeat, float offset) {
	float pc = count.x+count.y;
	float c = pc*repeat;
	vec2 corner = floor(uv*c);
	float cdiff = mod(corner.x-corner.y, pc);
	if (cdiff < count.x) {
		return vec4((corner-vec2(cdiff, 0.0))/c, (corner-vec2(cdiff, 0.0)+vec2(count.x, 1.0))/c);
	} else {
		return vec4((corner-vec2(0.0, pc-cdiff-1.0))/c, (corner-vec2(0.0, pc-cdiff-1.0)+vec2(1.0, count.y))/c);
	}
}
vec4 bricks_bw(vec2 uv, vec2 count, float repeat, float offset) {
	vec2 c = 2.0*count*repeat;
	float mc = max(c.x, c.y);
	vec2 corner1 = floor(uv*c);
	vec2 corner2 = count*floor(repeat*2.0*uv);
	float cdiff = mod(dot(floor(repeat*2.0*uv), vec2(1.0)), 2.0);
	vec2 corner;
	vec2 size;
	if (cdiff == 0.0) {
		corner = vec2(corner1.x, corner2.y);
		size = vec2(1.0, count.y);
	} else {
		corner = vec2(corner2.x, corner1.y);
		size = vec2(count.x, 1.0);
	}
	return vec4(corner/c, (corner+size)/c);
}
vec4 bricks_sb(vec2 uv, vec2 count, float repeat, float offset) {
	vec2 c = (count+vec2(1.0)) * repeat;
	float mc = max(c.x, c.y);
	vec2 corner1 = floor(uv*c);
	vec2 corner2 = (count+vec2(1.0))*floor(repeat*uv);
	vec2 rcorner = corner1 - corner2;
	vec2 corner;
	vec2 size;
	if (rcorner.x == 0.0 && rcorner.y < count.y) {
		corner = corner2;
		size = vec2(1.0, count.y);
	} else if (rcorner.y == 0.0) {
		corner = corner2+vec2(1.0, 0.0);
		size = vec2(count.x, 1.0);
	} else if (rcorner.x == count.x) {
		corner = corner2+vec2(count.x, 1.0);
		size = vec2(1.0, count.y);
	} else if (rcorner.y == count.y) {
		corner = corner2+vec2(0.0, count.y);
		size = vec2(count.x, 1.0);
	} else {
		corner = corner2+vec2(1.0);
		size = vec2(count.x-1.0, count.y-1.0);
	}
	return vec4(corner/c, (corner+size)/c);
}
float pingpong(float a, float b)
{
  return (b != 0.0) ? abs(fract((a - b) / (b * 2.0)) * b * 2.0 - b) : 0.0;
}
uniform sampler2D texture_1;
const float texture_1_size = 512.0;
vec3 fill_to_uv_stretch(vec2 coord, vec4 bb, float seed) {
	vec2 uv_islands = fract(coord-bb.xy)/bb.zw;
	float random_value = rand(vec2(seed)+bb.xy+bb.zw);
	return vec3(uv_islands, random_value);
}
vec3 fill_to_uv_square(vec2 coord, vec4 bb, float seed) {
	vec2 uv_islands;
	if (bb.z > bb.w) {
		vec2 adjusted_coord = coord + vec2(0.0, (bb.z - bb.w) / 2.0);
		uv_islands = fract(adjusted_coord-bb.xy)/bb.zz;
	} else {
		vec2 adjusted_coord = coord + vec2((bb.w - bb.z) / 2.0, 0.0);
		uv_islands = fract(adjusted_coord-bb.xy)/bb.ww;
	}
	float random_value = rand(vec2(seed)+bb.xy+bb.zw);
	return vec3(uv_islands, random_value);
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
const float p_o64211_amount1 = 1.000000000;
const float seed_o64159 = 0.000000000;
const float p_o64159_sx = 1.000000000;
const float p_o64159_sy = -1.000000000;
const float p_o64159_rotate = 0.000000000;
const float p_o64159_scale = 0.000000000;
const float p_o64212_translate_x = 0.000000000;
const float p_o64212_rotate = 0.000000000;
const float p_o64212_scale_x = 1.000000000;
const float p_o64212_scale_y = 1.000000000;
const float p_o64177_amount1 = 0.850000000;
const float p_o64195_amount1 = 1.000000000;
const float p_o64196_value = 0.500000000;
const float p_o64196_width = 0.290000000;
const float p_o64197_default_in1 = 0.000000000;
const float p_o64197_default_in2 = 0.000000000;
const float p_o64201_default_in1 = 0.000000000;
const float p_o64201_default_in2 = 0.000000000;
const float p_o64202_default_in1 = 0.000000000;
const float p_o64202_default_in2 = 0.000000000;
const float p_o64209_repeat = 1.000000000;
const float p_o64209_rows = 24.000000000;
const float p_o64209_columns = 24.000000000;
const float p_o64209_row_offset = 0.000000000;
const float p_o64209_mortar = 0.050000000;
const float p_o64209_bevel = 0.050000000;
const float p_o64209_round = 0.000000000;
const float p_o64209_corner = 0.300000000;
const float p_o64203_default_in1 = 0.000000000;
const float seed_o64205 = 0.107369378;
const float seed_o64207 = 0.904198766;
const float p_o64207_sx = -1.000000000;
const float p_o64207_sy = 1.000000000;
const float p_o64207_rotate = 0.000000000;
const float p_o64207_scale = 0.000000000;
vec4 o64207_input_in(vec2 uv, float _seed_variation_) {
vec4 o64173_0 = textureLod(texture_1, uv, 0.0);
return o64173_0;
}
const float p_o64200_d_in1_x = 0.000000000;
const float p_o64200_d_in1_y = 0.000000000;
const float p_o64200_d_in1_z = 0.000000000;
const float p_o64200_d_in2_x = 0.000000000;
const float p_o64200_d_in2_y = 0.000000000;
const float p_o64200_d_in2_z = 0.000000000;
const float seed_o64208 = 0.000000000;
const float p_o64198_value = 0.950000000;
const float p_o64198_width = 0.143300000;
const float p_o64182_gradient_0_pos = 0.547273000;
const vec4 p_o64182_gradient_0_col = vec4(0.593690991, 0.937500000, 0.216064006, 1.000000000);
const float p_o64182_gradient_1_pos = 0.874546000;
const vec4 p_o64182_gradient_1_col = vec4(0.537508011, 0.945312023, 0.524353027, 1.000000000);
vec4 o64182_gradient_gradient_fct(float x) {
  if (x < p_o64182_gradient_0_pos) {
    return p_o64182_gradient_0_col;
  } else if (x < p_o64182_gradient_1_pos) {
    return mix(p_o64182_gradient_0_col, p_o64182_gradient_1_col, ((x-p_o64182_gradient_0_pos)/(p_o64182_gradient_1_pos-p_o64182_gradient_0_pos)));
  }
  return p_o64182_gradient_1_col;
}
const float p_o64176_translate_x = 0.008350000;
const float p_o64176_translate_y = 0.011750000;
const float p_o64178_count = 10.000000000;
const float p_o64178_width = 5.000000000;
vec4 o64178_input_in(vec2 uv, float _seed_variation_) {
vec4 o64209_0_rect = bricks_rb((uv), vec2(p_o64209_columns, p_o64209_rows), p_o64209_repeat, p_o64209_row_offset);
vec4 o64209_0 = brick((uv), o64209_0_rect.xy, o64209_0_rect.zw, p_o64209_mortar*1.0, p_o64209_round*1.0, max(0.001, p_o64209_bevel*1.0), 1.0 / p_o64209_rows);vec4 o64209_1_2_fill = round(vec4(fract(o64209_0_rect.xy), o64209_0_rect.zw - o64209_0_rect.xy)*4096.0)/4096.0;
vec2 o64204_0_c = fract(o64209_1_2_fill.xy+0.5*o64209_1_2_fill.zw);float o64204_0_1_f = o64204_0_c.y;
vec2 o64206_0_c = fract(o64209_1_2_fill.xy+0.5*o64209_1_2_fill.zw);float o64206_0_1_f = o64206_0_c.x;
vec3 o64205_0_rand = vec3(o64206_0_1_f);vec3 o64205_0_1_rgb = rand3( vec2( float((seed_o64205+fract(_seed_variation_))) + o64205_0_rand.x, rand( o64205_0_rand.yz ) ) );
float o64203_0_clamp_false = (dot(o64205_0_1_rgb, vec3(1.0))/3.0)*(elapsed_time*2.);
float o64203_0_clamp_true = clamp(o64203_0_clamp_false, 0.0, 1.0);
float o64203_0_2_f = o64203_0_clamp_false;
float o64202_0_clamp_false = o64204_0_1_f-o64203_0_2_f;
float o64202_0_clamp_true = clamp(o64202_0_clamp_false, 0.0, 1.0);
float o64202_0_1_f = o64202_0_clamp_false;
float o64201_0_clamp_false = fract(o64202_0_1_f);
float o64201_0_clamp_true = clamp(o64201_0_clamp_false, 0.0, 1.0);
float o64201_0_1_f = o64201_0_clamp_false;
vec4 o64208_0_bb = o64209_1_2_fill;vec3 o64208_0_1_rgb = fill_to_uv_square((uv), o64208_0_bb, float((seed_o64208+fract(_seed_variation_))));
vec3 o64198_0_false = clamp((vec4(vec3(o64201_0_1_f), 1.0).rgb-vec3(p_o64198_value))/max(0.0001, p_o64198_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o64198_0_true = vec3(1.0)-o64198_0_false;vec4 o64198_0_1_rgba = vec4(o64198_0_false, vec4(vec3(o64201_0_1_f), 1.0).a);
vec4 o64199_0_1_rgba = vec4(0.0, 0.0, (dot((o64198_0_1_rgba).rgb, vec3(1.0))/3.0), 1.0);
vec3 o64200_0_clamp_false = o64208_0_1_rgb-((o64199_0_1_rgba).rgb);
vec3 o64200_0_clamp_true = clamp(o64200_0_clamp_false, vec3(0.0), vec3(1.0));
vec3 o64200_0_1_rgb = o64200_0_clamp_false;
vec3 o64207_0_map = o64200_0_1_rgb;
float o64207_0_rnd =  float((seed_o64207+fract(_seed_variation_)))+o64207_0_map.z;
vec4 o64207_0_1_rgba = o64207_input_in(get_from_tileset(4.0, o64207_0_rnd, custom_uv_transform(o64207_0_map.xy, vec2(p_o64207_sx, p_o64207_sy), p_o64207_rotate*0.01745329251, p_o64207_scale, vec2(o64207_0_map.z, float((seed_o64207+fract(_seed_variation_)))))), false ? o64207_0_rnd : 0.0);
float o64197_0_clamp_false = o64201_0_1_f*(dot((o64207_0_1_rgba).rgb, vec3(1.0))/3.0);
float o64197_0_clamp_true = clamp(o64197_0_clamp_false, 0.0, 1.0);
float o64197_0_1_f = o64197_0_clamp_false;
vec3 o64196_0_false = clamp((vec4(vec3(o64197_0_1_f), 1.0).rgb-vec3(p_o64196_value))/max(0.0001, p_o64196_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o64196_0_true = vec3(1.0)-o64196_0_false;vec4 o64196_0_1_rgba = vec4(o64196_0_false, vec4(vec3(o64197_0_1_f), 1.0).a);
vec4 o64182_0_1_rgba = o64182_gradient_gradient_fct(o64201_0_1_f);
vec4 o64195_0_b = o64196_0_1_rgba;
vec4 o64195_0_l;
float o64195_0_a;
o64195_0_l = o64182_0_1_rgba;
o64195_0_a = p_o64195_amount1*1.0;
o64195_0_b = vec4(blend_multiply((uv), o64195_0_l.rgb, o64195_0_b.rgb, o64195_0_a*o64195_0_l.a), min(1.0, o64195_0_b.a+o64195_0_a*o64195_0_l.a));
vec4 o64195_0_2_rgba = o64195_0_b;
return o64195_0_2_rgba;
}
vec4 supersample_o64178(vec2 uv, float size, int count, float width, float _seed_variation_) {
	vec4 rv = vec4(0.0);
	vec2 step_size = vec2(width)/size/float(count);
	uv -= vec2(0.5)/size;
	for (int x = 0; x < count; ++x) {
		for (int y = 0; y < count; ++y) {
			rv += o64178_input_in(uv+(vec2(float(x), float(y))+vec2(0.5))*step_size, _seed_variation_);
		}
	}
	return rv/float(count*count);
}vec4 o64159_input_in(vec2 uv, float _seed_variation_) {
vec4 o64209_0_rect = bricks_rb((fract(transform2((uv), vec2(p_o64212_translate_x*(2.0*1.0-1.0), (elapsed_time*.1)*(2.0*1.0-1.0)), p_o64212_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o64212_scale_x*(2.0*1.0-1.0), p_o64212_scale_y*(2.0*1.0-1.0))))), vec2(p_o64209_columns, p_o64209_rows), p_o64209_repeat, p_o64209_row_offset);
vec4 o64209_0 = brick((fract(transform2((uv), vec2(p_o64212_translate_x*(2.0*1.0-1.0), (elapsed_time*.1)*(2.0*1.0-1.0)), p_o64212_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o64212_scale_x*(2.0*1.0-1.0), p_o64212_scale_y*(2.0*1.0-1.0))))), o64209_0_rect.xy, o64209_0_rect.zw, p_o64209_mortar*1.0, p_o64209_round*1.0, max(0.001, p_o64209_bevel*1.0), 1.0 / p_o64209_rows);vec4 o64209_1_2_fill = round(vec4(fract(o64209_0_rect.xy), o64209_0_rect.zw - o64209_0_rect.xy)*4096.0)/4096.0;
vec2 o64204_0_c = fract(o64209_1_2_fill.xy+0.5*o64209_1_2_fill.zw);float o64204_0_1_f = o64204_0_c.y;
vec2 o64206_0_c = fract(o64209_1_2_fill.xy+0.5*o64209_1_2_fill.zw);float o64206_0_1_f = o64206_0_c.x;
vec3 o64205_0_rand = vec3(o64206_0_1_f);vec3 o64205_0_1_rgb = rand3( vec2( float((seed_o64205+fract(_seed_variation_))) + o64205_0_rand.x, rand( o64205_0_rand.yz ) ) );
float o64203_0_clamp_false = (dot(o64205_0_1_rgb, vec3(1.0))/3.0)*(elapsed_time*2.);
float o64203_0_clamp_true = clamp(o64203_0_clamp_false, 0.0, 1.0);
float o64203_0_2_f = o64203_0_clamp_false;
float o64202_0_clamp_false = o64204_0_1_f-o64203_0_2_f;
float o64202_0_clamp_true = clamp(o64202_0_clamp_false, 0.0, 1.0);
float o64202_0_1_f = o64202_0_clamp_false;
float o64201_0_clamp_false = fract(o64202_0_1_f);
float o64201_0_clamp_true = clamp(o64201_0_clamp_false, 0.0, 1.0);
float o64201_0_1_f = o64201_0_clamp_false;
vec4 o64208_0_bb = o64209_1_2_fill;vec3 o64208_0_1_rgb = fill_to_uv_square((fract(transform2((uv), vec2(p_o64212_translate_x*(2.0*1.0-1.0), (elapsed_time*.1)*(2.0*1.0-1.0)), p_o64212_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o64212_scale_x*(2.0*1.0-1.0), p_o64212_scale_y*(2.0*1.0-1.0))))), o64208_0_bb, float((seed_o64208+fract(_seed_variation_))));
vec3 o64198_0_false = clamp((vec4(vec3(o64201_0_1_f), 1.0).rgb-vec3(p_o64198_value))/max(0.0001, p_o64198_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o64198_0_true = vec3(1.0)-o64198_0_false;vec4 o64198_0_1_rgba = vec4(o64198_0_false, vec4(vec3(o64201_0_1_f), 1.0).a);
vec4 o64199_0_1_rgba = vec4(0.0, 0.0, (dot((o64198_0_1_rgba).rgb, vec3(1.0))/3.0), 1.0);
vec3 o64200_0_clamp_false = o64208_0_1_rgb-((o64199_0_1_rgba).rgb);
vec3 o64200_0_clamp_true = clamp(o64200_0_clamp_false, vec3(0.0), vec3(1.0));
vec3 o64200_0_1_rgb = o64200_0_clamp_false;
vec3 o64207_0_map = o64200_0_1_rgb;
float o64207_0_rnd =  float((seed_o64207+fract(_seed_variation_)))+o64207_0_map.z;
vec4 o64207_0_1_rgba = o64207_input_in(get_from_tileset(4.0, o64207_0_rnd, custom_uv_transform(o64207_0_map.xy, vec2(p_o64207_sx, p_o64207_sy), p_o64207_rotate*0.01745329251, p_o64207_scale, vec2(o64207_0_map.z, float((seed_o64207+fract(_seed_variation_)))))), false ? o64207_0_rnd : 0.0);
float o64197_0_clamp_false = o64201_0_1_f*(dot((o64207_0_1_rgba).rgb, vec3(1.0))/3.0);
float o64197_0_clamp_true = clamp(o64197_0_clamp_false, 0.0, 1.0);
float o64197_0_1_f = o64197_0_clamp_false;
vec3 o64196_0_false = clamp((vec4(vec3(o64197_0_1_f), 1.0).rgb-vec3(p_o64196_value))/max(0.0001, p_o64196_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o64196_0_true = vec3(1.0)-o64196_0_false;vec4 o64196_0_1_rgba = vec4(o64196_0_false, vec4(vec3(o64197_0_1_f), 1.0).a);
vec4 o64182_0_1_rgba = o64182_gradient_gradient_fct(o64201_0_1_f);
vec4 o64195_0_b = o64196_0_1_rgba;
vec4 o64195_0_l;
float o64195_0_a;
o64195_0_l = o64182_0_1_rgba;
o64195_0_a = p_o64195_amount1*1.0;
o64195_0_b = vec4(blend_multiply((fract(transform2((uv), vec2(p_o64212_translate_x*(2.0*1.0-1.0), (elapsed_time*.1)*(2.0*1.0-1.0)), p_o64212_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o64212_scale_x*(2.0*1.0-1.0), p_o64212_scale_y*(2.0*1.0-1.0))))), o64195_0_l.rgb, o64195_0_b.rgb, o64195_0_a*o64195_0_l.a), min(1.0, o64195_0_b.a+o64195_0_a*o64195_0_l.a));
vec4 o64195_0_2_rgba = o64195_0_b;
vec4 o64178_0_1_rgba = supersample_o64178(((fract(transform2((uv), vec2(p_o64212_translate_x*(2.0*1.0-1.0), (elapsed_time*.1)*(2.0*1.0-1.0)), p_o64212_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o64212_scale_x*(2.0*1.0-1.0), p_o64212_scale_y*(2.0*1.0-1.0)))))-vec2(p_o64176_translate_x, p_o64176_translate_y)), 256.000000000, int(p_o64178_count), p_o64178_width, _seed_variation_);
vec4 o64176_0_1_rgba = o64178_0_1_rgba;
vec4 o64177_0_b = o64195_0_2_rgba;
vec4 o64177_0_l;
float o64177_0_a;
o64177_0_l = o64176_0_1_rgba;
o64177_0_a = p_o64177_amount1*1.0;
o64177_0_b = vec4(blend_additive((fract(transform2((uv), vec2(p_o64212_translate_x*(2.0*1.0-1.0), (elapsed_time*.1)*(2.0*1.0-1.0)), p_o64212_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o64212_scale_x*(2.0*1.0-1.0), p_o64212_scale_y*(2.0*1.0-1.0))))), o64177_0_l.rgb, o64177_0_b.rgb, o64177_0_a*o64177_0_l.a), min(1.0, o64177_0_b.a+o64177_0_a*o64177_0_l.a));
vec4 o64177_0_2_rgba = o64177_0_b;
vec4 o64212_0_1_rgba = o64177_0_2_rgba;
return o64212_0_1_rgba;
}
const float p_o64156_d_in1_x = 0.000000000;
const float p_o64156_d_in1_y = 0.000000000;
const float p_o64156_d_in1_z = 0.000000000;
const float p_o64156_d_in2_x = 0.000000000;
const float p_o64156_d_in2_y = 0.000000000;
const float p_o64156_d_in2_z = 0.000000000;
const float p_o64130_repeat = 1.000000000;
const float p_o64130_gradient_0_pos = 0.000000000;
const vec4 p_o64130_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o64130_gradient_1_pos = 1.000000000;
const vec4 p_o64130_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o64130_gradient_gradient_fct(float x) {
  if (x < p_o64130_gradient_0_pos) {
    return p_o64130_gradient_0_col;
  } else if (x < p_o64130_gradient_1_pos) {
    return mix(p_o64130_gradient_0_col, p_o64130_gradient_1_col, ((x-p_o64130_gradient_0_pos)/(p_o64130_gradient_1_pos-p_o64130_gradient_0_pos)));
  }
  return p_o64130_gradient_1_col;
}
const float p_o64158_default_in1 = 0.126200000;
const float p_o64158_default_in2 = 0.000000000;
const float p_o64143_repeat = 1.000000000;
const float p_o64143_gradient_0_pos = 0.000000000;
const vec4 p_o64143_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o64143_gradient_1_pos = 1.000000000;
const vec4 p_o64143_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o64143_gradient_gradient_fct(float x) {
  if (x < p_o64143_gradient_0_pos) {
    return p_o64143_gradient_0_col;
  } else if (x < p_o64143_gradient_1_pos) {
    return mix(p_o64143_gradient_0_col, p_o64143_gradient_1_col, ((x-p_o64143_gradient_0_pos)/(p_o64143_gradient_1_pos-p_o64143_gradient_0_pos)));
  }
  return p_o64143_gradient_1_col;
}
const float p_o64160_gradient_0_pos = 0.049527000;
const vec4 p_o64160_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o64160_gradient_1_pos = 0.376800000;
const vec4 p_o64160_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o64160_gradient_gradient_fct(float x) {
  if (x < p_o64160_gradient_0_pos) {
    return p_o64160_gradient_0_col;
  } else if (x < p_o64160_gradient_1_pos) {
    return mix(p_o64160_gradient_0_col, p_o64160_gradient_1_col, (x-p_o64160_gradient_0_pos)/(p_o64160_gradient_1_pos-p_o64160_gradient_0_pos));
  }
  return p_o64160_gradient_1_col;
}
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec4 o64130_0_1_rgba = o64130_gradient_gradient_fct(fract(p_o64130_repeat*0.15915494309*atan((uv).y-0.5, (uv).x-0.5)));
vec4 o64143_0_1_rgba = o64143_gradient_gradient_fct(fract(p_o64143_repeat*1.41421356237*length(fract((uv))-vec2(0.5, 0.5))));
float o64158_0_clamp_false = p_o64158_default_in1/(dot((o64143_0_1_rgba).rgb, vec3(1.0))/3.0);
float o64158_0_clamp_true = clamp(o64158_0_clamp_false, 0.0, 1.0);
float o64158_0_2_f = o64158_0_clamp_false;
vec4 o64157_0_1_rgba = vec4((dot((o64130_0_1_rgba).rgb, vec3(1.0))/3.0), o64158_0_2_f, 0.0, 1.0);
vec3 o64156_0_clamp_false = fract(((o64157_0_1_rgba).rgb));
vec3 o64156_0_clamp_true = clamp(o64156_0_clamp_false, vec3(0.0), vec3(1.0));
vec3 o64156_0_1_rgb = o64156_0_clamp_false;
vec3 o64159_0_map = o64156_0_1_rgb;
float o64159_0_rnd =  float((seed_o64159+fract(_seed_variation_)))+o64159_0_map.z;
vec4 o64159_0_1_rgba = o64159_input_in(get_from_tileset(1.0, o64159_0_rnd, custom_uv_transform(o64159_0_map.xy, vec2(p_o64159_sx, p_o64159_sy), p_o64159_rotate*0.01745329251, p_o64159_scale, vec2(o64159_0_map.z, float((seed_o64159+fract(_seed_variation_)))))), false ? o64159_0_rnd : 0.0);
vec4 o64160_0_1_rgba = o64160_gradient_gradient_fct((dot((o64143_0_1_rgba).rgb, vec3(1.0))/3.0));
vec4 o64211_0_b = o64159_0_1_rgba;
vec4 o64211_0_l;
float o64211_0_a;

o64211_0_l = o64160_0_1_rgba;
o64211_0_a = p_o64211_amount1*1.0;
o64211_0_b = vec4(blend_multiply((uv), o64211_0_l.rgb, o64211_0_b.rgb, o64211_0_a*o64211_0_l.a), min(1.0, o64211_0_b.a+o64211_0_a*o64211_0_l.a));

vec4 o64211_0_2_rgba = o64211_0_b;

	vec4 color_tex = o64211_0_2_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	ALBEDO = color_tex.rgb;
	ALPHA = color_tex.a;

}



