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
float anisotropic(vec2 uv, vec2 size, float seed, float smoothness, float interpolation) {
	vec2 seed2 = rand2(vec2(seed, 1.0-seed));
	
	vec2 xy = floor(uv*size);
	vec2 offset = vec2(rand(seed2 + xy.y), 0.0);
	vec2 xy_offset = floor(uv * size + offset );
	float f0 = rand(seed2+mod(xy_offset, size));
	float f1 = rand(seed2+mod(xy_offset+vec2(1.0, 0.0), size));
	float mixer = clamp( (fract(uv.x*size.x+offset.x) -.5) / smoothness + 0.5, 0.0, 1.0 );
	float smooth_mix = smoothstep(0.0, 1.0, mixer);
	float linear = mix(f0, f1, mixer);
	float smoothed = mix(f0, f1, smooth_mix);
	
	return mix(linear, smoothed, interpolation);
}
// Display modes
const bool ASCII_DISPLAY = true;
const bool CUSTOM_DISPLAY = false;
// ASCII Character configurations (31-125)
// 31 reserved to display all segments
const float CHARS[] = {
	float(0xFFFF), float(0x0000), float(0x0202), float(0x0022),
	float(0xE722), float(0xE774), float(0xCF71), float(0xB1E8),
	float(0x0020), float(0x0081), float(0x0808), float(0xCCA9),
	float(0xC420), float(0x0800), float(0x8400), float(0x0000),
	float(0x0801), float(0x3B57), float(0x0203), float(0xB546),
	float(0x2746), float(0x8612), float(0xA1D4), float(0xB754),
	float(0x0246), float(0xB756), float(0xA756), float(0x4020),
	float(0x0820), float(0x8081), float(0xA500), float(0x0C08),
	float(0x4446), float(0x3576), float(0x9656), float(0x6766),
	float(0x3154), float(0x6366), float(0xB154), float(0x9054),
	float(0x3754), float(0x9612), float(0x6164), float(0x3302),
	float(0x9091), float(0x3110), float(0x121B), float(0x129A),
	float(0x3356), float(0x9456), float(0x33D6), float(0x94D6),
	float(0xA754), float(0x4064), float(0x3312), float(0x1811),
	float(0x1A92), float(0x0889), float(0xA712), float(0x2945),
	float(0x4124), float(0x0088), float(0x6060), float(0x0880),
	float(0x2100), float(0x0008), float(0xF100), float(0xF010),
	float(0xB000), float(0x4702), float(0xB800), float(0xC424),
	float(0xE070), float(0xD010), float(0x4000), float(0x7020),
	float(0x40A1), float(0x1010), float(0xD600), float(0xD000),
	float(0xF000), float(0x9070), float(0x0626), float(0x9000),
	float(0xE050), float(0xB010), float(0x7000), float(0x1800),
	float(0x1A80), float(0x0889), float(0x0722), float(0xA800),
	float(0xC124), float(0x4020), float(0x6460)
};
/*
 bit position mapping:
  _10__ __14__
 | \   |   /  |
 12 13 11 16  15
 |	\|/	 |
  __1__ __6___
 |	/|\	 |
 4  5  2  9   7
 | /   |   \  |
  __3__|__8___
 1  4	8   12	16
 |  |	|	|	|		
 0000 0000 0000 0000
 e.g. M = 0001 0010 0001 1011 (binary) = 4635 (dec) = 0x121B (hex) 
*/
float m(vec4 d) { return max(max(d.x,d.y),max(d.z,d.w)); }
float fs(vec2 p, float st, float sl, vec4 s14, float s5, bool sf, float da)
{
	const vec2 h = vec2(1,-1);
	da *= 0.017453;
	
	sl *= 0.1;
	st *= 0.5;
	sl = clamp(sl, 0,1);
	p = 2.0 * (p - 0.5);
	vec2 p1 = p;
	vec2 p2 = p;
	vec2 _p = p;
	
	p = abs(p) - vec2(0.25,0.4);
	
	float f = -max(p.x, p.y);
	float ism = f - st - (sl*1.625);
	float isg = min(ism, st-abs(dot(normalize(vec2(sin(da),cos(da))),_p*vec2(sf ? 1.0:-1.0 ,1.0))));
	
	float d = min(st - abs(f), min(-dot(p, normalize(h.xx)), abs(dot(p, normalize(h)))) - sl);
	p1.x = abs(p1.x); p2.y = abs(p2.y);
	p1 += vec2(0.15, 0.0); p2 -= vec2(0.0, 0.15);
	float q1 = -dot(p1,h.xx);
	float q2 = min(p2.x, -dot(p2,h.yx));
	float q3 = dot(p1, h.yx);
	float q4 = min(-p2.x, -dot(p2,h.xx));
	
	vec4 qv4 = vec4(q1,q2,q3,q4);
	qv4 = min(qv4,s14);
	
	return max(m(min(vec4(d),qv4)), min(isg,s5));
}
float i(float n, int b) { b = 16 - b; return float(mod(floor(n / exp2(floor(float(b)))), 2.0) != 0.0); }
float xvisd(vec2 uv, float st, float sl, float bevel, float a, float dps, vec2 dpo, float da, bool is_ascii, bool dp)
{
	float d;
	const vec2 b = vec2(1,0);
	int n = int(clamp(a, 31.0, 125.0) - 31.0);
	float ch = is_ascii ? CHARS[n] : a;
	float dpt = is_ascii ? (( n == 0 || n == 15 || n == 32 ) ? 1.0 : 0.0) : float(dp);
	
	st = clamp(st, 0, 1) * 0.5;
	float d1 = fs(uv+vec2(0.125, -0.2), st, sl, vec4(i(ch,1), i(ch,2), i(ch,3), i(ch,4)), i(ch,5) ,true, da );
	float d2 = fs(uv-vec2(0.125,  0.2), st, sl, vec4(i(ch,6), i(ch,7), i(ch,8), 0), i(ch,9) ,false, da);
	float d3 = fs(uv+vec2(0.125,  0.2), st, sl, vec4(i(ch,10), i(ch,11),0, i(ch,12)), i(ch,13) ,false, da);
	float d4 = fs(uv-vec2(0.125, -0.2), st, sl, vec4(i(ch,14), i(ch,15),0,0), i(ch,16), true, da);
	
	d = m(vec4(d1,d2,d3,d4));
	d = max(d,(-distance(uv-0.5,dpo)*3.0)+0.1*dps*dpt);
	return clamp(d/max(bevel, 1e-4), 0, 1);
}
float xvisd_custom(vec2 uv, float st, float sl, float bevel, float a, float dps, vec2 dpo, float da, bool dp)
{
	return xvisd(uv, st, sl, bevel, a, dps, dpo, da, CUSTOM_DISPLAY, dp);
}
float xvisd_ascii(vec2 uv, float st, float sl, float bevel, float a, float dps, vec2 dpo, float da, bool dp)
{
	return xvisd(uv, st, sl, bevel, a, dps, dpo, da, ASCII_DISPLAY, dp);
}
float all_seg(vec2 uv, float st, float sl, float dps, vec2 dpo, float da)
{
	return xvisd(uv, st, sl, 0, 31.0, dps, dpo, da, ASCII_DISPLAY, false);
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
float pingpong(float a, float b)
{
  return (b != 0.0) ? abs(fract((a - b) / (b * 2.0)) * b * 2.0 - b) : 0.0;
}
vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
	vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
const float p_o79171_hue = 1.000000000;
const float p_o79171_value = 1.000000000;
const float p_o79171_saturation = 1.000000000;
const float p_o79156_gradient_0_pos = 0.000000000;
const vec4 p_o79156_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o79156_gradient_1_pos = 0.108276134;
const vec4 p_o79156_gradient_1_col = vec4(0.964843750, 0.203521729, 0.000000000, 1.000000000);
const float p_o79156_gradient_2_pos = 0.533848653;
const vec4 p_o79156_gradient_2_col = vec4(1.000000000, 0.632812500, 0.000000000, 1.000000000);
const float p_o79156_gradient_3_pos = 1.000000000;
const vec4 p_o79156_gradient_3_col = vec4(1.000000000, 0.773437500, 0.000000000, 1.000000000);
vec4 o79156_gradient_gradient_fct(float x) {
  if (x < p_o79156_gradient_0_pos) {
    return p_o79156_gradient_0_col;
  } else if (x < p_o79156_gradient_1_pos) {
    return mix(mix(p_o79156_gradient_1_col, p_o79156_gradient_2_col, (x-p_o79156_gradient_1_pos)/(p_o79156_gradient_2_pos-p_o79156_gradient_1_pos)), mix(p_o79156_gradient_0_col, p_o79156_gradient_1_col, (x-p_o79156_gradient_0_pos)/(p_o79156_gradient_1_pos-p_o79156_gradient_0_pos)), 1.0-0.5*(x-p_o79156_gradient_0_pos)/(p_o79156_gradient_1_pos-p_o79156_gradient_0_pos));
  } else if (x < p_o79156_gradient_2_pos) {
    return 0.5*(mix(p_o79156_gradient_1_col, p_o79156_gradient_2_col, (x-p_o79156_gradient_1_pos)/(p_o79156_gradient_2_pos-p_o79156_gradient_1_pos)) + mix(mix(p_o79156_gradient_0_col, p_o79156_gradient_1_col, (x-p_o79156_gradient_0_pos)/(p_o79156_gradient_1_pos-p_o79156_gradient_0_pos)), mix(p_o79156_gradient_2_col, p_o79156_gradient_3_col, (x-p_o79156_gradient_2_pos)/(p_o79156_gradient_3_pos-p_o79156_gradient_2_pos)), 0.5-0.5*cos(3.14159265359*(x-p_o79156_gradient_1_pos)/(p_o79156_gradient_2_pos-p_o79156_gradient_1_pos))));
  } else if (x < p_o79156_gradient_3_pos) {
    return mix(mix(p_o79156_gradient_1_col, p_o79156_gradient_2_col, (x-p_o79156_gradient_1_pos)/(p_o79156_gradient_2_pos-p_o79156_gradient_1_pos)), mix(p_o79156_gradient_2_col, p_o79156_gradient_3_col, (x-p_o79156_gradient_2_pos)/(p_o79156_gradient_3_pos-p_o79156_gradient_2_pos)), 0.5+0.5*(x-p_o79156_gradient_2_pos)/(p_o79156_gradient_3_pos-p_o79156_gradient_2_pos));
  }
  return p_o79156_gradient_3_col;
}
const float p_o79154_translate_y = 0.000000000;
const float p_o79154_rotate = 0.000000000;
const float p_o79154_scale_x = 1.000000000;
const float p_o79154_scale_y = 1.000000000;
const float p_o79192_min = 0.750000000;
const float p_o79192_max = 1.000000000;
const float p_o79192_step = 0.000000000;
const float seed_o79172 = 0.000000000;
const float p_o79172_v1 = 0.000000000;
const float p_o79172_v2 = 0.100000000;
const float p_o79172_v3 = 0.200000000;
const float p_o79172_v4 = 0.300000000;
const float p_o79172_v5 = 0.400000000;
const float seed_o79155 = 0.000000000;
const float p_o79155_scale_x = 1.000000000;
const float p_o79155_scale_y = 24.000000000;
const float p_o79155_smoothness = 1.000000000;
const float p_o79155_interpolation = 1.000000000;
float o79172_input_in(vec2 uv, float _seed_variation_) {
float o79155_0_1_f = anisotropic((uv), vec2(p_o79155_scale_x, p_o79155_scale_y), (seed_o79155+fract(_seed_variation_)), p_o79155_smoothness, p_o79155_interpolation);
return o79155_0_1_f;
}
const float seed_o79150 = 0.000000000;
const float p_o79150_tx = 24.000000000;
const float p_o79150_ty = 24.000000000;
const float p_o79150_overlap = 1.000000000;
const float p_o79150_scale_x = 0.045000000;
const float p_o79150_scale_y = 0.045000000;
const float p_o79150_fixed_offset = 0.500000000;
const float p_o79150_offset = 0.000000000;
const float p_o79150_rotate = 0.000000000;
const float p_o79150_scale = 0.000000000;
const float p_o79150_value = 1.000000000;
const float p_o79149_translate_x = 0.130000000;
const float p_o79149_translate_y = 0.005000000;
const float p_o79149_rotate = 0.000000000;
const float p_o79149_scale_x = 1.000000000;
const float p_o79149_scale_y = 1.000000000;
const float p_o79146_amount = 0.250000000;
const float p_o79146_center = 0.000000000;
const float seed_o79145 = 0.284392774;
const float p_o79145_sl = 0.170000000;
const float p_o79145_st = 0.410000000;
const float p_o79145_dps = 1.000000000;
const float p_o79145_dpx = 0.335628390;
const float p_o79145_dpy = 0.420309842;
const float p_o79145_da = 50.000000000;
const float p_o79145_b = 0.130000000;
float o79150_input_in(vec2 uv, float _seed_variation_) {
float o79145_0_1_f = xvisd_custom(((transform2((uv), vec2(p_o79149_translate_x*(2.0*1.0-1.0), p_o79149_translate_y*(2.0*1.0-1.0)), p_o79149_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o79149_scale_x*(2.0*1.0-1.0), p_o79149_scale_y*(2.0*1.0-1.0))))+p_o79146_amount*((transform2((uv), vec2(p_o79149_translate_x*(2.0*1.0-1.0), p_o79149_translate_y*(2.0*1.0-1.0)), p_o79149_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o79149_scale_x*(2.0*1.0-1.0), p_o79149_scale_y*(2.0*1.0-1.0)))).yx-vec2(p_o79146_center))*vec2(1.0, 0.0)), p_o79145_st, p_o79145_sl, p_o79145_b*1.0, (mod(param_rndi(0,65535, (seed_o79145+fract(_seed_variation_))+-0.958924) + round(elapsed_time * (seed_o79145+fract(_seed_variation_))), 65535)), p_o79145_dps, vec2(p_o79145_dpx, p_o79145_dpy), p_o79145_da, false);
vec4 o79146_0_1_rgba = vec4(vec3(o79145_0_1_f), 1.0);
vec4 o79149_0_1_rgba = o79146_0_1_rgba;
return (dot((o79149_0_1_rgba).rgb, vec3(1.0))/3.0);
}
float o79150_input_mask(vec2 uv, float _seed_variation_) {
return 1.0;
}
vec4 tiler_o79150(vec2 uv, vec2 tile, int overlap, inout vec3 instance_uv, vec2 _seed, float _seed_variation_) {
	float c = 0.0;
	vec3 rc = vec3(0.0);
	vec3 rc1;
	for (int dx = -overlap; dx <= overlap; ++dx) {
		for (int dy = -overlap; dy <= overlap; ++dy) {
			vec2 pos = uv*tile+vec2(float(dx), float(dy)); pos = fract((floor(mod(pos, tile))+vec2(0.5))/tile)-vec2(0.5);
			vec2 seed = rand2(pos+_seed);
			rc1 = rand3(seed);
			pos = fract(pos+vec2(p_o79150_fixed_offset/tile.x, 0.0)*floor(mod(pos.y*tile.y, 2.0))+p_o79150_offset*seed/tile);
			float mask = o79150_input_mask(fract(pos+vec2(0.5)), _seed_variation_);
			if (mask > 0.01) {
				vec2 pv = fract(uv - pos)-vec2(0.5);
				seed = rand2(seed);
				float angle = (seed.x * 2.0 - 1.0) * p_o79150_rotate * 0.01745329251;
				float ca = cos(angle);
				float sa = sin(angle);
				pv = vec2(ca*pv.x+sa*pv.y, -sa*pv.x+ca*pv.y);
				pv *= (seed.y-0.5)*2.0*p_o79150_scale+1.0;
				pv /= vec2(p_o79150_scale_x, p_o79150_scale_y);
				pv += vec2(0.5);
				seed = rand2(seed);
				vec2 clamped_pv = clamp(pv, vec2(0.0), vec2(1.0));
				if (pv.x != clamped_pv.x || pv.y != clamped_pv.y) {
					continue;
				}
				vec2 full_uv = pv;
				pv = get_from_tileset( 1.0, seed.x, pv);
				float c1 = o79150_input_in(pv, true ? seed.x : 0.0)*mask*(1.0-p_o79150_value*seed.x);
				c = max(c, c1);
				rc = mix(rc, rc1, step(c, c1));
				instance_uv = mix(instance_uv, vec3(full_uv, seed.x), step(c, c1));
			}
		}
	}
	return vec4(rc, c);
}const float p_o79189_x = 1.000000000;
const float p_o79189_y = 24.000000000;
const float p_o79189_c = 13.000000000;
const float p_o79189_d = 1.000000000;
const float p_o79186_default_in1 = 0.000000000;
const float p_o79186_default_in2 = 0.000000000;
const float p_o79191_default_in1 = 0.000000000;
const float p_o79191_default_in2 = 1.450000000;
const float p_o79190_translate_x = 0.000000000;
const float p_o79190_rotate = 0.000000000;
const float p_o79190_scale_x = 1.000000000;
const float p_o79190_scale_y = 9.000000000;
const float p_o79173_repeat = 1.000000000;
const float p_o79173_rotate = 90.000000000;
const float p_o79173_gradient_0_pos = 0.000000000;
const vec4 p_o79173_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o79173_gradient_1_pos = 1.000000000;
const vec4 p_o79173_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o79173_gradient_gradient_fct(float x) {
  if (x < p_o79173_gradient_0_pos) {
    return p_o79173_gradient_0_col;
  } else if (x < p_o79173_gradient_1_pos) {
    return mix(p_o79173_gradient_0_col, p_o79173_gradient_1_col, ((x-p_o79173_gradient_0_pos)/(p_o79173_gradient_1_pos-p_o79173_gradient_0_pos)));
  }
  return p_o79173_gradient_1_col;
}
const float p_o79194_default_in1 = 0.000000000;
const float p_o79195_default_in1 = 0.000000000;
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
float o79172_1_1_f = o79172_input_in((uv), (seed_o79172+fract(_seed_variation_))+p_o79172_v2);
float o79192_0_x = o79172_1_1_f*(p_o79192_max-p_o79192_min);float o79192_0_1_f = p_o79192_min+o79192_0_x-mod(o79192_0_x, max(p_o79192_step, 0.00000001));
vec3 o79150_0_instance_uv = vec3(0.0);
vec4 o79150_0_rch = tiler_o79150((fract(transform2((uv), vec2((elapsed_time / 4.0)*(2.0*o79192_0_1_f-1.0), p_o79154_translate_y*(2.0*1.0-1.0)), p_o79154_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o79154_scale_x*(2.0*1.0-1.0), p_o79154_scale_y*(2.0*1.0-1.0))))), vec2(p_o79150_tx, p_o79150_ty), int(p_o79150_overlap), o79150_0_instance_uv, vec2(float((seed_o79150+fract(_seed_variation_)))), _seed_variation_);float o79150_0_1_f = o79150_0_rch.a;
vec4 o79154_0_1_rgba = vec4(vec3(o79150_0_1_f), 1.0);
vec4 o79156_0_1_rgba = o79156_gradient_gradient_fct((dot((o79154_0_1_rgba).rgb, vec3(1.0))/3.0));
vec2 o79189_0_uv = floor(((uv)*vec2(p_o79189_x, p_o79189_y)))+vec2(0.5);
vec3 o79189_0_dither = fract(vec3(dot(vec2(171.0, 231.0), o79189_0_uv))/vec3(103.0, 71.0, 97.0));
float o79173_0_r = 0.5+(cos(p_o79173_rotate*0.01745329251)*((fract(transform2((o79189_0_uv/vec2(p_o79189_x, p_o79189_y)), vec2(p_o79190_translate_x*(2.0*1.0-1.0), (elapsed_time)*(2.0*1.0-1.0)), p_o79190_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o79190_scale_x*(2.0*1.0-1.0), p_o79190_scale_y*(2.0*1.0-1.0))))).x-0.5)+sin(p_o79173_rotate*0.01745329251)*((fract(transform2((o79189_0_uv/vec2(p_o79189_x, p_o79189_y)), vec2(p_o79190_translate_x*(2.0*1.0-1.0), (elapsed_time)*(2.0*1.0-1.0)), p_o79190_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o79190_scale_x*(2.0*1.0-1.0), p_o79190_scale_y*(2.0*1.0-1.0))))).y-0.5))/(cos(abs(mod(p_o79173_rotate, 90.0)-45.0)*0.01745329251)*1.41421356237);vec4 o79173_0_1_rgba = o79173_gradient_gradient_fct(fract(o79173_0_r*p_o79173_repeat));
vec4 o79190_0_1_rgba = o79173_0_1_rgba;
float o79191_0_clamp_false = (dot((o79190_0_1_rgba).rgb, vec3(1.0))/3.0)*p_o79191_default_in2;
float o79191_0_clamp_true = clamp(o79191_0_clamp_false, 0.0, 1.0);
float o79191_0_2_f = o79191_0_clamp_false;
float o79172_0_3_f = o79172_input_in((o79189_0_uv/vec2(p_o79189_x, p_o79189_y)), (seed_o79172+fract(_seed_variation_))+p_o79172_v1);
float o79186_0_clamp_false = o79191_0_2_f+o79172_0_3_f;
float o79186_0_clamp_true = clamp(o79186_0_clamp_false, 0.0, 1.0);
float o79186_0_1_f = o79186_0_clamp_false;
vec3 o79189_0_1_rgb = floor(vec3(o79186_0_1_f)*p_o79189_c+p_o79189_d*(o79189_0_dither-vec3(0.5)))/p_o79189_c;
float o79193_0_1_f = vec4(o79189_0_1_rgb, 1.0).r;
float o79193_1_2_f = vec4(o79189_0_1_rgb, 1.0).g;
float o79194_0_clamp_false = sin(o79193_1_2_f*(elapsed_time * 0.02));
float o79194_0_clamp_true = clamp(o79194_0_clamp_false, 0.0, 1.0);
float o79194_0_2_f = o79194_0_clamp_false;
float o79193_3_3_f = vec4(o79189_0_1_rgb, 1.0).a;
float o79195_0_clamp_false = sin(o79193_3_3_f*(elapsed_time * 0.03 - 18.4));
float o79195_0_clamp_true = clamp(o79195_0_clamp_false, 0.0, 1.0);
float o79195_0_2_f = o79195_0_clamp_false;
vec4 o79171_0_rbga = o79156_0_1_rgba;
vec3 o79171_0_hsv = rgb_to_hsv(o79171_0_rbga.rgb);
o79171_0_hsv.x = fract(o79171_0_hsv.x+p_o79171_hue*((sin(65.87 + elapsed_time)) / 3.0)*(o79193_0_1_f-0.5));
o79171_0_hsv.y = clamp(o79171_0_hsv.y+p_o79171_saturation*((sin(65.87 + elapsed_time)) / 3.0)*(o79195_0_2_f-0.5), 0.0, 1.0);
o79171_0_hsv.z = clamp(o79171_0_hsv.z+p_o79171_value*((sin(65.87 + elapsed_time)) / 3.0)*(o79194_0_2_f-0.5), 0.0, 1.0);
	vec4 o79171_0_1_rgba = vec4(hsv_to_rgb(o79171_0_hsv), o79171_0_rbga.a);

	vec4 color_tex = o79171_0_1_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	ALBEDO = color_tex.rgb;
	ALPHA = color_tex.a;

}



