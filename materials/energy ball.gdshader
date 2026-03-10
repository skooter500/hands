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
uniform sampler2D texture_1;
const float texture_1_size = 512.0;
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
float sdRipples(float d, float w, int r) {
	for (int i = 0; i < r; ++i) {
		d = abs(d)-w;
	}
	return d;
}
vec2 scale(vec2 uv, vec2 center, vec2 scale) {
	uv -= center;
	uv /= scale;
	uv += center;
	return uv;
}
float value_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float p00 = rand(mod(o, size));
	float p01 = rand(mod(o + vec2(0.0, 1.0), size));
	float p10 = rand(mod(o + vec2(1.0, 0.0), size));
	float p11 = rand(mod(o + vec2(1.0, 1.0), size));
	p00 = sin(p00 * 6.28318530718 + offset * 6.28318530718) / 2.0 + 0.5;
	p01 = sin(p01 * 6.28318530718 + offset * 6.28318530718) / 2.0 + 0.5;
	p10 = sin(p10 * 6.28318530718 + offset * 6.28318530718) / 2.0 + 0.5;
	p11 = sin(p11 * 6.28318530718 + offset * 6.28318530718) / 2.0 + 0.5;
	vec2 t =  f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(p00, p10, t.x), mix(p01, p11, t.x), t.y);
}
float fbm_2d_value(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = value_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float perlin_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float a00 = rand(mod(o, size)) * 6.28318530718 + offset * 6.28318530718;
	float a01 = rand(mod(o + vec2(0.0, 1.0), size)) * 6.28318530718 + offset * 6.28318530718;
	float a10 = rand(mod(o + vec2(1.0, 0.0), size)) * 6.28318530718 + offset * 6.28318530718;
	float a11 = rand(mod(o + vec2(1.0, 1.0), size)) * 6.28318530718 + offset * 6.28318530718;
	vec2 v00 = vec2(cos(a00), sin(a00));
	vec2 v01 = vec2(cos(a01), sin(a01));
	vec2 v10 = vec2(cos(a10), sin(a10));
	vec2 v11 = vec2(cos(a11), sin(a11));
	float p00 = dot(v00, f);
	float p01 = dot(v01, f - vec2(0.0, 1.0));
	float p10 = dot(v10, f - vec2(1.0, 0.0));
	float p11 = dot(v11, f - vec2(1.0, 1.0));
	vec2 t =  f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return 0.5 + mix(mix(p00, p10, t.x), mix(p01, p11, t.x), t.y);
}
float fbm_2d_perlin(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = perlin_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float perlinabs_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	return abs(2.0*perlin_noise_2d(coord, size, offset, seed)-1.0);
}
float fbm_2d_perlinabs(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = perlinabs_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float fbm_2d_mod289(float x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}
float fbm_2d_permute(float x) {
	return fbm_2d_mod289(((x * 34.0) + 1.0) * x);
}
vec2 fbm_2d_rgrad2(vec2 p, float rot, float seed) {
	float u = fbm_2d_permute(fbm_2d_permute(p.x) + p.y) * 0.0243902439 + rot; // Rotate by shift
	u = fract(u) * 6.28318530718; // 2*pi
	return vec2(cos(u), sin(u));
}
float simplex_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	coord *= 2.0; // needed for it to tile
	coord += rand2(vec2(seed, 1.0-seed)) + size;
	size *= 2.0; // needed for it to tile
	coord.y += 0.001;
	vec2 uv = vec2(coord.x + coord.y*0.5, coord.y);
	vec2 i0 = floor(uv);
	vec2 f0 = fract(uv);
	vec2 i1 = (f0.x > f0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 p0 = vec2(i0.x - i0.y * 0.5, i0.y);
	vec2 p1 = vec2(p0.x + i1.x - i1.y * 0.5, p0.y + i1.y);
	vec2 p2 = vec2(p0.x + 0.5, p0.y + 1.0);
	i1 = i0 + i1;
	vec2 i2 = i0 + vec2(1.0, 1.0);
	vec2 d0 = coord - p0;
	vec2 d1 = coord - p1;
	vec2 d2 = coord - p2;
	vec3 xw = mod(vec3(p0.x, p1.x, p2.x), size.x);
	vec3 yw = mod(vec3(p0.y, p1.y, p2.y), size.y);
	vec3 iuw = xw + 0.5 * yw;
	vec3 ivw = yw;
	vec2 g0 = fbm_2d_rgrad2(vec2(iuw.x, ivw.x), offset, seed);
	vec2 g1 = fbm_2d_rgrad2(vec2(iuw.y, ivw.y), offset, seed);
	vec2 g2 = fbm_2d_rgrad2(vec2(iuw.z, ivw.z), offset, seed);
	vec3 w = vec3(dot(g0, d0), dot(g1, d1), dot(g2, d2));
	vec3 t = 0.8 - vec3(dot(d0, d0), dot(d1, d1), dot(d2, d2));
	t = max(t, vec3(0.0));
	vec3 t2 = t * t;
	vec3 t4 = t2 * t2;
	float n = dot(t4, w);
	return 0.5 + 5.5 * n;
}
float fbm_2d_simplex(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = simplex_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node =  0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718 * node);
			vec2 diff = neighbor + node - f;
			float dist = length(diff);
			min_dist = min(min_dist, dist);
		}
	}
	return min_dist;
}
float fbm_2d_cellular(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular2_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist1 = 2.0;
	float min_dist2 = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = length(diff);
			if (min_dist1 > dist) {
				min_dist2 = min_dist1;
				min_dist1 = dist;
			} else if (min_dist2 > dist) {
				min_dist2 = dist;
			}
		}
	}
	return min_dist2-min_dist1;
}
float fbm_2d_cellular2(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular2_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular3_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = abs((diff).x) + abs((diff).y);
			min_dist = min(min_dist, dist);
		}
	}
	return min_dist;
}
float fbm_2d_cellular3(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular3_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular4_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist1 = 2.0;
	float min_dist2 = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = abs((diff).x) + abs((diff).y);
			if (min_dist1 > dist) {
				min_dist2 = min_dist1;
				min_dist1 = dist;
			} else if (min_dist2 > dist) {
				min_dist2 = dist;
			}
		}
	}
	return min_dist2-min_dist1;
}
float fbm_2d_cellular4(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular4_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular5_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.5 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = max(abs((diff).x), abs((diff).y));
			min_dist = min(min_dist, dist);
		}
	}
	return min_dist;
}
float fbm_2d_cellular5(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular5_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular6_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist1 = 2.0;
	float min_dist2 = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = max(abs((diff).x), abs((diff).y));
			if (min_dist1 > dist) {
				min_dist2 = min_dist1;
				min_dist1 = dist;
			} else if (min_dist2 > dist) {
				min_dist2 = dist;
			}
		}
	}
	return min_dist2-min_dist1;
}
float fbm_2d_cellular6(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular6_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
// MIT License Inigo Quilez - https://www.shadertoy.com/view/Xd23Dh
float voronoise_noise_2d( vec2 coord, vec2 size, float offset, float seed) {
	vec2 i = floor(coord) + rand2(vec2(seed, 1.0-seed)) + size;
	vec2 f = fract(coord);

	vec2 a = vec2(0.0);

	for( int y=-2; y<=2; y++ ) {
		for( int x=-2; x<=2; x++ ) {
			vec2  g = vec2( float(x), float(y) );
			vec3  o = rand3( mod(i + g, size) + vec2(seed) );
			o.xy += 0.25 * sin(offset * 6.28318530718 + 6.28318530718*o.xy);
			vec2  d = g - f + o.xy;
			float w = pow( 1.0-smoothstep(0.0, 1.414, length(d)), 1.0 );
			a += vec2(o.z*w,w);
		}
	}

	return a.x/a.y;
}
float fbm_2d_voronoise(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = voronoise_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
const float p_o86021_cx = 0.000000000;
const float p_o86021_cy = 0.000000000;
const float p_o86021_scale_x = 1.200000000;
const float p_o86021_scale_y = 1.200000000;
const float p_o86020_amount1 = 1.000000000;
const float p_o86006_cx = 0.000000000;
const float p_o86006_cy = 0.000000000;
const float p_o86006_scale_x = 0.450000000;
const float p_o86006_scale_y = 0.450000000;
const float p_o86005_amount1 = 0.700000000;
const float p_o86008_amount1 = 2.000000000;
const float p_o86008_amount2 = 1.000000000;
const float p_o86008_amount3 = 1.000000000;
const float p_o85963_min = 0.000000000;
const float p_o85963_max = 0.150700000;
const float p_o85963_step = 0.000000000;
const float p_o85967_default_in1 = 0.000000000;
const float p_o85967_default_in2 = 0.000000000;
const float p_o86000_sides = 6.000000000;
const float p_o86000_radius = 3.820000000;
const float p_o86000_edge = 0.670500000;
const float p_o86007_amount1 = 1.000000000;
const float p_o85990_amount1 = 1.000000000;
const float p_o85973_gradient_0_pos = 0.000000000;
const vec4 p_o85973_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o85973_gradient_1_pos = 0.344356000;
const vec4 p_o85973_gradient_1_col = vec4(0.129913002, 0.503906012, 0.188350007, 1.000000000);
const float p_o85973_gradient_2_pos = 1.000000000;
const vec4 p_o85973_gradient_2_col = vec4(0.216796994, 0.750000000, 0.725005984, 1.000000000);
vec4 o85973_gradient_gradient_fct(float x) {
  if (x < p_o85973_gradient_0_pos) {
    return p_o85973_gradient_0_col;
  } else if (x < p_o85973_gradient_1_pos) {
    return mix(mix(p_o85973_gradient_1_col, p_o85973_gradient_2_col, (x-p_o85973_gradient_1_pos)/(p_o85973_gradient_2_pos-p_o85973_gradient_1_pos)), mix(p_o85973_gradient_0_col, p_o85973_gradient_1_col, (x-p_o85973_gradient_0_pos)/(p_o85973_gradient_1_pos-p_o85973_gradient_0_pos)), 1.0-0.5*(x-p_o85973_gradient_0_pos)/(p_o85973_gradient_1_pos-p_o85973_gradient_0_pos));
  } else if (x < p_o85973_gradient_2_pos) {
    return mix(mix(p_o85973_gradient_0_col, p_o85973_gradient_1_col, (x-p_o85973_gradient_0_pos)/(p_o85973_gradient_1_pos-p_o85973_gradient_0_pos)), mix(p_o85973_gradient_1_col, p_o85973_gradient_2_col, (x-p_o85973_gradient_1_pos)/(p_o85973_gradient_2_pos-p_o85973_gradient_1_pos)), 0.5+0.5*(x-p_o85973_gradient_1_pos)/(p_o85973_gradient_2_pos-p_o85973_gradient_1_pos));
  }
  return p_o85973_gradient_2_col;
}
const float p_o85987_r = 1.000000000;
const float p_o85987_a = 4.000000000;
const float p_o85987_cx = 0.000000000;
const float p_o85987_cy = 0.000000000;
const float p_o85992_translate_x = 0.000000000;
const float p_o85992_rotate = 0.000000000;
const float p_o85992_scale_x = 1.000000000;
const float p_o85992_scale_y = 2.000000000;
const float p_o85969_value = 0.240000000;
const float p_o85969_width = 0.320000000;
const float p_o85968_default_in1 = 0.000000000;
const float p_o85968_default_in2 = 0.000000000;
const vec4 p_o85964_color = vec4(0.108612999, 0.753323019, 0.362708002, 1.000000000);
const float p_o86018_default_in1 = 0.000000000;
const float p_o86018_default_in2 = 8.000000000;
const float p_o86004_bevel = 1.000000000;
const float p_o86004_base = 1.050000000;
const float p_o86003_r = 0.000000000;
const float p_o86003_ripples = 1.000000000;
const float p_o86002_r = 0.444100000;
const float p_o86002_cx = 0.000000000;
const float p_o86002_cy = 0.000000000;
const vec4 p_o85965_color = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o85966_cx = 0.000000000;
const float p_o85966_cy = 0.000000000;
const float p_o85966_scale_x = 0.800000000;
const float p_o85966_scale_y = 0.800000000;
const float p_o85970_amount1 = 1.000000000;
const float p_o85988_r = 3.000000000;
const float p_o85988_a = 10.000000000;
const float p_o85988_cx = 0.000000000;
const float p_o85988_cy = 0.000000000;
const float p_o85971_value = 0.220900000;
const float p_o85971_width = 0.106400000;
const float p_o86014_sigma = 15.000000000;
const float p_o86014_center_x = 0.000000000;
const float p_o86014_center_y = 0.000000000;
const float p_o86014_iter = 35.000000000;
vec4 o86014_input_in(vec2 uv, float _seed_variation_) {
float o86000_0_1_f = shape_circle((uv), p_o86000_sides, p_o86000_radius*1.0, p_o86000_edge*1.0);
float o85967_0_clamp_false = smoothstep(0.0, 1.0, o86000_0_1_f);
float o85967_0_clamp_true = clamp(o85967_0_clamp_false, 0.0, 1.0);
float o85967_0_1_f = o85967_0_clamp_false;
float o85963_0_x = o85967_0_1_f*(p_o85963_max-p_o85963_min);float o85963_0_1_f = p_o85963_min+o85963_0_x-mod(o85963_0_x, max(p_o85963_step, 0.00000001));
vec2 o85987_0_co = vec2(p_o85987_cx+0.5,p_o85987_cy+0.5);
float o85987_0_f = dot(2.0*((uv) - o85987_0_co),2.0*((uv) - o85987_0_co));vec4 o85993_0 = textureLod(texture_1, (transform2((o85987_0_co-(o85987_0_co-(uv))/(sqrt(p_o85987_r-o85987_0_f)*max(p_o85987_a,0.0)+1.0)), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_1_rgba = o85993_0;
float o85991_0_1_f = o85992_0_1_rgba.r;
vec4 o85993_1 = textureLod(texture_1, (transform2((uv), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_4_rgba = o85993_1;
float o85991_0_3_f = o85992_0_4_rgba.r;
vec4 o85987_0_1_rgba = clamp(mix(vec4(vec3(o85991_0_1_f), 1.0),vec4(vec3(o85991_0_3_f), 1.0),step(p_o85987_r,o85987_0_f)),0.0,1.0);
vec4 o85973_0_1_rgba = o85973_gradient_gradient_fct((dot((o85987_0_1_rgba).rgb, vec3(1.0))/3.0));
float o85987_2_2_f = clamp(p_o85987_r-o85987_0_f,0.0,1.0);
vec3 o85969_0_false = clamp((vec4(vec3(o85987_2_2_f), 1.0).rgb-vec3(p_o85969_value))/max(0.0001, p_o85969_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o85969_0_true = vec3(1.0)-o85969_0_false;vec4 o85969_0_1_rgba = vec4(o85969_0_false, vec4(vec3(o85987_2_2_f), 1.0).a);
vec4 o85990_0_b = o85973_0_1_rgba;
vec4 o85990_0_l;
float o85990_0_a;
o85990_0_l = o85969_0_1_rgba;
o85990_0_a = p_o85990_amount1*1.0;
o85990_0_b = vec4(blend_multiply((uv), o85990_0_l.rgb, o85990_0_b.rgb, o85990_0_a*o85990_0_l.a), min(1.0, o85990_0_b.a+o85990_0_a*o85990_0_l.a));
vec4 o85990_0_2_rgba = o85990_0_b;
vec4 o86007_0_b = o85990_0_2_rgba;
vec4 o86007_0_l;
float o86007_0_a;
o86007_0_l = o85990_0_2_rgba;
o86007_0_a = p_o86007_amount1*1.0;
o86007_0_b = vec4(blend_additive((uv), o86007_0_l.rgb, o86007_0_b.rgb, o86007_0_a*o86007_0_l.a), min(1.0, o86007_0_b.a+o86007_0_a*o86007_0_l.a));
vec4 o86007_0_2_rgba = o86007_0_b;
float o85968_0_clamp_false = (dot((o85969_0_1_rgba).rgb, vec3(1.0))/3.0)*(dot((o85987_0_1_rgba).rgb, vec3(1.0))/3.0);
float o85968_0_clamp_true = clamp(o85968_0_clamp_false, 0.0, 1.0);
float o85968_0_1_f = o85968_0_clamp_false;
vec4 o85964_0_1_rgba = p_o85964_color;
float o86002_0_1_sdf2d = length((uv)-vec2(p_o86002_cx+0.5, p_o86002_cy+0.5))-p_o86002_r;
float o86003_0_1_sdf2d = sdRipples(o86002_0_1_sdf2d, p_o86003_r, int(p_o86003_ripples));
float o86004_0_1_f = clamp(p_o86004_base-o86003_0_1_sdf2d/max(p_o86004_bevel, 0.00001), 0.0, 1.0);
float o86018_0_clamp_false = pow(o86004_0_1_f,p_o86018_default_in2);
float o86018_0_clamp_true = clamp(o86018_0_clamp_false, 0.0, 1.0);
float o86018_0_2_f = o86018_0_clamp_false;
vec4 o85965_0_1_rgba = p_o85965_color;
vec2 o85988_0_co = vec2(p_o85988_cx+0.5,p_o85988_cy+0.5);
float o85988_0_f = dot(2.0*((scale((uv), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))) - o85988_0_co),2.0*((scale((uv), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))) - o85988_0_co));vec4 o85993_2 = textureLod(texture_1, (transform2((o85988_0_co-(o85988_0_co-(scale((uv), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))))/(sqrt(p_o85988_r-o85988_0_f)*max(p_o85988_a,0.0)+1.0)), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_7_rgba = o85993_2;
float o85991_1_5_f = o85992_0_7_rgba.g;
vec4 o85993_3 = textureLod(texture_1, (transform2((scale((uv), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_10_rgba = o85993_3;
float o85991_1_7_f = o85992_0_10_rgba.g;
vec4 o85988_0_1_rgba = clamp(mix(vec4(vec3(o85991_1_5_f), 1.0),vec4(vec3(o85991_1_7_f), 1.0),step(p_o85988_r,o85988_0_f)),0.0,1.0);
float o85988_2_2_f = clamp(p_o85988_r-o85988_0_f,0.0,1.0);
vec3 o85971_0_false = clamp((vec4(vec3(o85988_2_2_f), 1.0).rgb-vec3(p_o85971_value))/max(0.0001, p_o85971_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o85971_0_true = vec3(1.0)-o85971_0_false;vec4 o85971_0_1_rgba = vec4(o85971_0_false, vec4(vec3(o85988_2_2_f), 1.0).a);
vec4 o85970_0_b = o85988_0_1_rgba;
vec4 o85970_0_l;
float o85970_0_a;
o85970_0_l = o85971_0_1_rgba;
o85970_0_a = p_o85970_amount1*1.0;
o85970_0_b = vec4(blend_multiply((scale((uv), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))), o85970_0_l.rgb, o85970_0_b.rgb, o85970_0_a*o85970_0_l.a), min(1.0, o85970_0_b.a+o85970_0_a*o85970_0_l.a));
vec4 o85970_0_2_rgba = o85970_0_b;
vec4 o85966_0_1_rgba = o85970_0_2_rgba;
vec4 o86008_0_b = vec4(vec3(o85963_0_1_f), 1.0);
vec4 o86008_0_l;
float o86008_0_a;
o86008_0_l = o86007_0_2_rgba;
o86008_0_a = p_o86008_amount1*o85968_0_1_f;
o86008_0_b = vec4(blend_normal((uv), o86008_0_l.rgb, o86008_0_b.rgb, o86008_0_a*o86008_0_l.a), min(1.0, o86008_0_b.a+o86008_0_a*o86008_0_l.a));
o86008_0_l = o85964_0_1_rgba;
o86008_0_a = p_o86008_amount2*o86018_0_2_f;
o86008_0_b = vec4(blend_additive((uv), o86008_0_l.rgb, o86008_0_b.rgb, o86008_0_a*o86008_0_l.a), min(1.0, o86008_0_b.a+o86008_0_a*o86008_0_l.a));
o86008_0_l = o85965_0_1_rgba;
o86008_0_a = p_o86008_amount3*(dot((o85966_0_1_rgba).rgb, vec3(1.0))/3.0);
o86008_0_b = vec4(blend_normal((uv), o86008_0_l.rgb, o86008_0_b.rgb, o86008_0_a*o86008_0_l.a), min(1.0, o86008_0_b.a+o86008_0_a*o86008_0_l.a));
vec4 o86008_0_1_rgba = o86008_0_b;
return o86008_0_1_rgba;
}
const float p_o85972_sides = 6.000000000;
const float p_o85972_radius = 0.700000000;
const float p_o85972_edge = 1.000000000;
float o86014_input_amount(vec2 uv, float _seed_variation_) {
float o85972_0_1_f = shape_circle((uv), p_o85972_sides, p_o85972_radius*1.0, p_o85972_edge*1.0);
vec4 o86009_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o85972_0_1_f), 1.0).rgb, vec4(vec3(o85972_0_1_f), 1.0).a);
return (dot((o86009_0_1_rgba).rgb, vec3(1.0))/3.0);
}
vec4 o86014_fct(vec2 uv, vec2 center, float _seed_variation_) {
	vec2 e = -sign(p_o86014_sigma)*normalize(uv-center)/64.000000000;
	vec4 rv = vec4(0.0);
	float sum = 0.0;
	float sigma = max(0.0000001f, abs(p_o86014_sigma))*o86014_input_amount(uv, _seed_variation_);
	for (float i = 0.0; i <= p_o86014_iter; i += 1.0) {
		float coef = exp(-0.5*(pow(i/sigma, 2.0)))/(6.28318530718*sigma*sigma);
		rv += o86014_input_in(uv+i*e, _seed_variation_)*coef;
		sum += coef;
	}
	return rv/sum;
}const float p_o86010_amount = 0.034200000;
const float p_o86010_eps = 0.100000000;
const float p_o86001_translate_x = 0.000000000;
const float seed_o85999 = 0.865040421;
const float p_o85999_scale_x = 4.000000000;
const float p_o85999_scale_y = 2.000000000;
const float p_o85999_folds = 0.000000000;
const float p_o85999_iterations = 6.000000000;
const float p_o85999_persistence = 0.450000000;
const float p_o85999_offset = 0.000000000;
float o86010_input_d(vec2 uv, float _seed_variation_) {
float o85999_0_1_f = fbm_2d_perlin(((uv)-vec2(p_o86001_translate_x, (-elapsed_time*4.5))), vec2(p_o85999_scale_x, p_o85999_scale_y), int(p_o85999_folds), int(p_o85999_iterations), p_o85999_persistence, p_o85999_offset, (seed_o85999+fract(_seed_variation_)));
vec4 o86001_0_1_rgba = vec4(vec3(o85999_0_1_f), 1.0);
return (dot((o86001_0_1_rgba).rgb, vec3(1.0))/3.0);
}
vec2 o86010_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o86010_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o86010_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o86010_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o86010_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o85989_sides = 6.000000000;
const float p_o85989_radius = 1.100000000;
const float p_o85989_edge = 0.220000000;
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
float o86000_0_1_f = shape_circle((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), p_o86000_sides, p_o86000_radius*1.0, p_o86000_edge*1.0);
float o85967_0_clamp_false = smoothstep(0.0, 1.0, o86000_0_1_f);
float o85967_0_clamp_true = clamp(o85967_0_clamp_false, 0.0, 1.0);
float o85967_0_1_f = o85967_0_clamp_false;
float o85963_0_x = o85967_0_1_f*(p_o85963_max-p_o85963_min);float o85963_0_1_f = p_o85963_min+o85963_0_x-mod(o85963_0_x, max(p_o85963_step, 0.00000001));
vec2 o85987_0_co = vec2(p_o85987_cx+0.5,p_o85987_cy+0.5);
float o85987_0_f = dot(2.0*((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))) - o85987_0_co),2.0*((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))) - o85987_0_co));vec4 o85993_0 = textureLod(texture_1, (transform2((o85987_0_co-(o85987_0_co-(scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))))/(sqrt(p_o85987_r-o85987_0_f)*max(p_o85987_a,0.0)+1.0)), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_1_rgba = o85993_0;
float o85991_0_1_f = o85992_0_1_rgba.r;
vec4 o85993_1 = textureLod(texture_1, (transform2((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_4_rgba = o85993_1;
float o85991_0_3_f = o85992_0_4_rgba.r;
vec4 o85987_0_1_rgba = clamp(mix(vec4(vec3(o85991_0_1_f), 1.0),vec4(vec3(o85991_0_3_f), 1.0),step(p_o85987_r,o85987_0_f)),0.0,1.0);
vec4 o85973_0_1_rgba = o85973_gradient_gradient_fct((dot((o85987_0_1_rgba).rgb, vec3(1.0))/3.0));
float o85987_2_2_f = clamp(p_o85987_r-o85987_0_f,0.0,1.0);
vec3 o85969_0_false = clamp((vec4(vec3(o85987_2_2_f), 1.0).rgb-vec3(p_o85969_value))/max(0.0001, p_o85969_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o85969_0_true = vec3(1.0)-o85969_0_false;vec4 o85969_0_1_rgba = vec4(o85969_0_false, vec4(vec3(o85987_2_2_f), 1.0).a);
vec4 o85990_0_b = o85973_0_1_rgba;
vec4 o85990_0_l;
float o85990_0_a;

o85990_0_l = o85969_0_1_rgba;
o85990_0_a = p_o85990_amount1*1.0;
o85990_0_b = vec4(blend_multiply((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o85990_0_l.rgb, o85990_0_b.rgb, o85990_0_a*o85990_0_l.a), min(1.0, o85990_0_b.a+o85990_0_a*o85990_0_l.a));

vec4 o85990_0_2_rgba = o85990_0_b;
vec4 o86007_0_b = o85990_0_2_rgba;
vec4 o86007_0_l;
float o86007_0_a;

o86007_0_l = o85990_0_2_rgba;
o86007_0_a = p_o86007_amount1*1.0;
o86007_0_b = vec4(blend_additive((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86007_0_l.rgb, o86007_0_b.rgb, o86007_0_a*o86007_0_l.a), min(1.0, o86007_0_b.a+o86007_0_a*o86007_0_l.a));

vec4 o86007_0_2_rgba = o86007_0_b;
float o85968_0_clamp_false = (dot((o85969_0_1_rgba).rgb, vec3(1.0))/3.0)*(dot((o85987_0_1_rgba).rgb, vec3(1.0))/3.0);
float o85968_0_clamp_true = clamp(o85968_0_clamp_false, 0.0, 1.0);
float o85968_0_1_f = o85968_0_clamp_false;
vec4 o85964_0_1_rgba = p_o85964_color;
float o86002_0_1_sdf2d = length((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y)))-vec2(p_o86002_cx+0.5, p_o86002_cy+0.5))-p_o86002_r;
float o86003_0_1_sdf2d = sdRipples(o86002_0_1_sdf2d, p_o86003_r, int(p_o86003_ripples));
float o86004_0_1_f = clamp(p_o86004_base-o86003_0_1_sdf2d/max(p_o86004_bevel, 0.00001), 0.0, 1.0);
float o86018_0_clamp_false = pow(o86004_0_1_f,p_o86018_default_in2);
float o86018_0_clamp_true = clamp(o86018_0_clamp_false, 0.0, 1.0);
float o86018_0_2_f = o86018_0_clamp_false;
vec4 o85965_0_1_rgba = p_o85965_color;
vec2 o85988_0_co = vec2(p_o85988_cx+0.5,p_o85988_cy+0.5);
float o85988_0_f = dot(2.0*((scale((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))) - o85988_0_co),2.0*((scale((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))) - o85988_0_co));vec4 o85993_2 = textureLod(texture_1, (transform2((o85988_0_co-(o85988_0_co-(scale((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))))/(sqrt(p_o85988_r-o85988_0_f)*max(p_o85988_a,0.0)+1.0)), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_7_rgba = o85993_2;
float o85991_1_5_f = o85992_0_7_rgba.g;
vec4 o85993_3 = textureLod(texture_1, (transform2((scale((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_10_rgba = o85993_3;
float o85991_1_7_f = o85992_0_10_rgba.g;
vec4 o85988_0_1_rgba = clamp(mix(vec4(vec3(o85991_1_5_f), 1.0),vec4(vec3(o85991_1_7_f), 1.0),step(p_o85988_r,o85988_0_f)),0.0,1.0);
float o85988_2_2_f = clamp(p_o85988_r-o85988_0_f,0.0,1.0);
vec3 o85971_0_false = clamp((vec4(vec3(o85988_2_2_f), 1.0).rgb-vec3(p_o85971_value))/max(0.0001, p_o85971_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o85971_0_true = vec3(1.0)-o85971_0_false;vec4 o85971_0_1_rgba = vec4(o85971_0_false, vec4(vec3(o85988_2_2_f), 1.0).a);
vec4 o85970_0_b = o85988_0_1_rgba;
vec4 o85970_0_l;
float o85970_0_a;

o85970_0_l = o85971_0_1_rgba;
o85970_0_a = p_o85970_amount1*1.0;
o85970_0_b = vec4(blend_multiply((scale((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))), o85970_0_l.rgb, o85970_0_b.rgb, o85970_0_a*o85970_0_l.a), min(1.0, o85970_0_b.a+o85970_0_a*o85970_0_l.a));

vec4 o85970_0_2_rgba = o85970_0_b;
vec4 o85966_0_1_rgba = o85970_0_2_rgba;
vec4 o86008_0_b = vec4(vec3(o85963_0_1_f), 1.0);
vec4 o86008_0_l;
float o86008_0_a;

o86008_0_l = o86007_0_2_rgba;
o86008_0_a = p_o86008_amount1*o85968_0_1_f;
o86008_0_b = vec4(blend_normal((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86008_0_l.rgb, o86008_0_b.rgb, o86008_0_a*o86008_0_l.a), min(1.0, o86008_0_b.a+o86008_0_a*o86008_0_l.a));

o86008_0_l = o85964_0_1_rgba;
o86008_0_a = p_o86008_amount2*o86018_0_2_f;
o86008_0_b = vec4(blend_additive((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86008_0_l.rgb, o86008_0_b.rgb, o86008_0_a*o86008_0_l.a), min(1.0, o86008_0_b.a+o86008_0_a*o86008_0_l.a));

o86008_0_l = o85965_0_1_rgba;
o86008_0_a = p_o86008_amount3*(dot((o85966_0_1_rgba).rgb, vec3(1.0))/3.0);
o86008_0_b = vec4(blend_normal((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86008_0_l.rgb, o86008_0_b.rgb, o86008_0_a*o86008_0_l.a), min(1.0, o86008_0_b.a+o86008_0_a*o86008_0_l.a));

vec4 o86008_0_1_rgba = o86008_0_b;
vec4 o86014_0_1_rgba = o86014_fct((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(p_o86014_center_x, p_o86014_center_y)+vec2(0.5), _seed_variation_);
vec4 o86005_0_b = o86008_0_1_rgba;
vec4 o86005_0_l;
float o86005_0_a;

o86005_0_l = o86014_0_1_rgba;
o86005_0_a = p_o86005_amount1*1.0;
o86005_0_b = vec4(blend_additive((scale((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86005_0_l.rgb, o86005_0_b.rgb, o86005_0_a*o86005_0_l.a), min(1.0, o86005_0_b.a+o86005_0_a*o86005_0_l.a));

vec4 o86005_0_2_rgba = o86005_0_b;
vec4 o86006_0_1_rgba = o86005_0_2_rgba;
vec2 o86010_0_slope = o86010_slope((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), p_o86010_eps, _seed_variation_);
vec2 o86010_0_warp = o86010_0_slope;float o86000_0_4_f = shape_circle((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), p_o86000_sides, p_o86000_radius*1.0, p_o86000_edge*1.0);
float o85967_2_clamp_false = smoothstep(0.0, 1.0, o86000_0_4_f);
float o85967_2_clamp_true = clamp(o85967_2_clamp_false, 0.0, 1.0);
float o85967_0_3_f = o85967_2_clamp_false;
float o85963_2_x = o85967_0_3_f*(p_o85963_max-p_o85963_min);float o85963_0_3_f = p_o85963_min+o85963_2_x-mod(o85963_2_x, max(p_o85963_step, 0.00000001));
vec2 o85987_3_co = vec2(p_o85987_cx+0.5,p_o85987_cy+0.5);
float o85987_3_f = dot(2.0*((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))) - o85987_3_co),2.0*((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))) - o85987_3_co));vec4 o85993_4 = textureLod(texture_1, (transform2((o85987_3_co-(o85987_3_co-(scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))))/(sqrt(p_o85987_r-o85987_3_f)*max(p_o85987_a,0.0)+1.0)), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_13_rgba = o85993_4;
float o85991_0_9_f = o85992_0_13_rgba.r;
vec4 o85993_5 = textureLod(texture_1, (transform2((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_16_rgba = o85993_5;
float o85991_0_11_f = o85992_0_16_rgba.r;
vec4 o85987_0_4_rgba = clamp(mix(vec4(vec3(o85991_0_9_f), 1.0),vec4(vec3(o85991_0_11_f), 1.0),step(p_o85987_r,o85987_3_f)),0.0,1.0);
vec4 o85973_0_3_rgba = o85973_gradient_gradient_fct((dot((o85987_0_4_rgba).rgb, vec3(1.0))/3.0));
float o85987_2_5_f = clamp(p_o85987_r-o85987_3_f,0.0,1.0);
vec3 o85969_2_false = clamp((vec4(vec3(o85987_2_5_f), 1.0).rgb-vec3(p_o85969_value))/max(0.0001, p_o85969_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o85969_2_true = vec3(1.0)-o85969_2_false;vec4 o85969_0_3_rgba = vec4(o85969_2_false, vec4(vec3(o85987_2_5_f), 1.0).a);
vec4 o85990_3_b = o85973_0_3_rgba;
vec4 o85990_3_l;
float o85990_3_a;

o85990_3_l = o85969_0_3_rgba;
o85990_3_a = p_o85990_amount1*1.0;
o85990_3_b = vec4(blend_multiply((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o85990_3_l.rgb, o85990_3_b.rgb, o85990_3_a*o85990_3_l.a), min(1.0, o85990_3_b.a+o85990_3_a*o85990_3_l.a));

vec4 o85990_0_5_rgba = o85990_3_b;
vec4 o86007_3_b = o85990_0_5_rgba;
vec4 o86007_3_l;
float o86007_3_a;

o86007_3_l = o85990_0_5_rgba;
o86007_3_a = p_o86007_amount1*1.0;
o86007_3_b = vec4(blend_additive((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86007_3_l.rgb, o86007_3_b.rgb, o86007_3_a*o86007_3_l.a), min(1.0, o86007_3_b.a+o86007_3_a*o86007_3_l.a));

vec4 o86007_0_5_rgba = o86007_3_b;
float o85968_2_clamp_false = (dot((o85969_0_3_rgba).rgb, vec3(1.0))/3.0)*(dot((o85987_0_4_rgba).rgb, vec3(1.0))/3.0);
float o85968_2_clamp_true = clamp(o85968_2_clamp_false, 0.0, 1.0);
float o85968_0_3_f = o85968_2_clamp_false;
vec4 o85964_0_3_rgba = p_o85964_color;
float o86002_0_3_sdf2d = length((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y)))-vec2(p_o86002_cx+0.5, p_o86002_cy+0.5))-p_o86002_r;
float o86003_0_3_sdf2d = sdRipples(o86002_0_3_sdf2d, p_o86003_r, int(p_o86003_ripples));
float o86004_0_3_f = clamp(p_o86004_base-o86003_0_3_sdf2d/max(p_o86004_bevel, 0.00001), 0.0, 1.0);
float o86018_3_clamp_false = pow(o86004_0_3_f,p_o86018_default_in2);
float o86018_3_clamp_true = clamp(o86018_3_clamp_false, 0.0, 1.0);
float o86018_0_5_f = o86018_3_clamp_false;
vec4 o85965_0_3_rgba = p_o85965_color;
vec2 o85988_3_co = vec2(p_o85988_cx+0.5,p_o85988_cy+0.5);
float o85988_3_f = dot(2.0*((scale((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))) - o85988_3_co),2.0*((scale((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))) - o85988_3_co));vec4 o85993_6 = textureLod(texture_1, (transform2((o85988_3_co-(o85988_3_co-(scale((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))))/(sqrt(p_o85988_r-o85988_3_f)*max(p_o85988_a,0.0)+1.0)), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_19_rgba = o85993_6;
float o85991_1_13_f = o85992_0_19_rgba.g;
vec4 o85993_7 = textureLod(texture_1, (transform2((scale((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))), vec2(p_o85992_translate_x*(2.0*1.0-1.0), (-elapsed_time)*(2.0*1.0-1.0)), p_o85992_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o85992_scale_x*(2.0*1.0-1.0), p_o85992_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o85992_0_22_rgba = o85993_7;
float o85991_1_15_f = o85992_0_22_rgba.g;
vec4 o85988_0_4_rgba = clamp(mix(vec4(vec3(o85991_1_13_f), 1.0),vec4(vec3(o85991_1_15_f), 1.0),step(p_o85988_r,o85988_3_f)),0.0,1.0);
float o85988_2_5_f = clamp(p_o85988_r-o85988_3_f,0.0,1.0);
vec3 o85971_2_false = clamp((vec4(vec3(o85988_2_5_f), 1.0).rgb-vec3(p_o85971_value))/max(0.0001, p_o85971_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o85971_2_true = vec3(1.0)-o85971_2_false;vec4 o85971_0_3_rgba = vec4(o85971_2_false, vec4(vec3(o85988_2_5_f), 1.0).a);
vec4 o85970_3_b = o85988_0_4_rgba;
vec4 o85970_3_l;
float o85970_3_a;

o85970_3_l = o85971_0_3_rgba;
o85970_3_a = p_o85970_amount1*1.0;
o85970_3_b = vec4(blend_multiply((scale((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(0.5+p_o85966_cx, 0.5+p_o85966_cy), vec2(p_o85966_scale_x, p_o85966_scale_y))), o85970_3_l.rgb, o85970_3_b.rgb, o85970_3_a*o85970_3_l.a), min(1.0, o85970_3_b.a+o85970_3_a*o85970_3_l.a));

vec4 o85970_0_5_rgba = o85970_3_b;
vec4 o85966_0_3_rgba = o85970_0_5_rgba;
vec4 o86008_2_b = vec4(vec3(o85963_0_3_f), 1.0);
vec4 o86008_2_l;
float o86008_2_a;

o86008_2_l = o86007_0_5_rgba;
o86008_2_a = p_o86008_amount1*o85968_0_3_f;
o86008_2_b = vec4(blend_normal((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86008_2_l.rgb, o86008_2_b.rgb, o86008_2_a*o86008_2_l.a), min(1.0, o86008_2_b.a+o86008_2_a*o86008_2_l.a));

o86008_2_l = o85964_0_3_rgba;
o86008_2_a = p_o86008_amount2*o86018_0_5_f;
o86008_2_b = vec4(blend_additive((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86008_2_l.rgb, o86008_2_b.rgb, o86008_2_a*o86008_2_l.a), min(1.0, o86008_2_b.a+o86008_2_a*o86008_2_l.a));

o86008_2_l = o85965_0_3_rgba;
o86008_2_a = p_o86008_amount3*(dot((o85966_0_3_rgba).rgb, vec3(1.0))/3.0);
o86008_2_b = vec4(blend_normal((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86008_2_l.rgb, o86008_2_b.rgb, o86008_2_a*o86008_2_l.a), min(1.0, o86008_2_b.a+o86008_2_a*o86008_2_l.a));

vec4 o86008_0_3_rgba = o86008_2_b;
vec4 o86014_0_3_rgba = o86014_fct((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), vec2(p_o86014_center_x, p_o86014_center_y)+vec2(0.5), _seed_variation_);
vec4 o86005_3_b = o86008_0_3_rgba;
vec4 o86005_3_l;
float o86005_3_a;

o86005_3_l = o86014_0_3_rgba;
o86005_3_a = p_o86005_amount1*1.0;
o86005_3_b = vec4(blend_additive((scale(((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y)))+p_o86010_amount*o86010_0_warp), vec2(0.5+p_o86006_cx, 0.5+p_o86006_cy), vec2(p_o86006_scale_x, p_o86006_scale_y))), o86005_3_l.rgb, o86005_3_b.rgb, o86005_3_a*o86005_3_l.a), min(1.0, o86005_3_b.a+o86005_3_a*o86005_3_l.a));

vec4 o86005_0_5_rgba = o86005_3_b;
vec4 o86006_0_3_rgba = o86005_0_5_rgba;
vec4 o86010_0_1_rgba = o86006_0_3_rgba;
float o85989_0_1_f = shape_circle((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), p_o85989_sides, p_o85989_radius*1.0, p_o85989_edge*1.0);
vec4 o86020_0_b = o86006_0_1_rgba;
vec4 o86020_0_l;
float o86020_0_a;

o86020_0_l = o86010_0_1_rgba;
o86020_0_a = p_o86020_amount1*o85989_0_1_f;
o86020_0_b = vec4(blend_normal((scale((uv), vec2(0.5+p_o86021_cx, 0.5+p_o86021_cy), vec2(p_o86021_scale_x, p_o86021_scale_y))), o86020_0_l.rgb, o86020_0_b.rgb, o86020_0_a*o86020_0_l.a), min(1.0, o86020_0_b.a+o86020_0_a*o86020_0_l.a));

vec4 o86020_0_1_rgba = o86020_0_b;
vec4 o86021_0_1_rgba = o86020_0_1_rgba;

	vec4 color_tex = o86021_0_1_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	ALBEDO = color_tex.rgb;
	ALPHA = color_tex.a;

}
