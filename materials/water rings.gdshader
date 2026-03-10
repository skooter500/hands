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
const float o236501_w = 27.000000000; // {default:0.5, label:Unnamed, max:32, min:0, name:w, step:1, type:named_parameter}
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
float pingpong(float a, float b)
{
  return (b != 0.0) ? abs(fract((a - b) / (b * 2.0)) * b * 2.0 - b) : 0.0;
}
float smin(float d1, float d2, float k) {
	float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
	return mix( d2, d1, h ) - k*h*(1.0-h);
}
float smax(float d1, float d2, float k) {
	float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
	return mix( d2, d1, h ) + k*h*(1.0-h); 
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
vec3 normal_blend(vec2 uv, vec3 n1, vec3 n2, float opacity) {
	n1.z = 1.0 - n1.z; // inverting z channel before calculations
	n2.z = 1.0 - n2.z; // inverting z channel before calculations
	vec3 t = n1*vec3( 2,  2, 2) + vec3(-1, -1,  0);
	vec3 u = n2*vec3(-2, -2, 2) + vec3( 1,  1, -1);
	vec3 r = mix(n2 * 2.0 - 1.0, t * dot(t, u) / t.z - u, opacity);
	r.z = r.z * -1.0; // inverting z channel after calculations
	return r * 0.5 + 0.5;
}
const vec4 p_o236435_albedo_color = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o236435_metallic = 0.000000000;
const float p_o236435_roughness = 0.190000000;
const float p_o236435_emission_energy = 0.000000000;
const float p_o236435_normal = 1.000000000;
const float p_o236435_ao = 1.000000000;
const float p_o236435_depth_scale = 0.500000000;
float o236435_input_depth_tex(vec2 uv, float _seed_variation_) {
return 0.0;
}
const float p_o236532_amount1 = 1.000000000;
const float p_o236532_amount2 = 1.000000000;
const float p_o236583_d_in1_x = 0.000000000;
const float p_o236583_d_in1_y = 0.000000000;
const float p_o236583_d_in1_z = 0.000000000;
const float p_o236583_d_in2_x = 0.200000000;
const float p_o236583_d_in2_y = 0.280000000;
const float p_o236583_d_in2_z = 0.550000000;
const float p_o236585_amount1 = 1.000000000;
const float p_o236584_d_in1_x = 0.000000000;
const float p_o236584_d_in1_y = 0.000000000;
const float p_o236584_d_in1_z = 0.000000000;
const float p_o236584_d_in2_x = 0.050000000;
const float p_o236584_d_in2_y = 0.520000000;
const float p_o236584_d_in2_z = 0.570000000;
const float p_o236586_d_in1_x = 0.000000000;
const float p_o236586_d_in1_y = 0.000000000;
const float p_o236586_d_in1_z = 0.000000000;
const float p_o236586_d_in2_x = 0.080000000;
const float p_o236586_d_in2_y = 0.180000000;
const float p_o236586_d_in2_z = 0.340000000;
const float p_o236533_default_in1 = 0.000000000;
const float p_o236533_default_in2 = 0.000000000;
const float p_o236531_default_in1 = 0.000000000;
const float p_o236531_default_in2 = 0.000000000;
const float p_o236524_radius = 2.000000000;
const float p_o236524_repeat = 1.000000000;
const float p_o236530_translate_x = 0.000000000;
const float seed_o236523 = 0.025586436;
const float p_o236523_scale_x = 6.000000000;
const float p_o236523_scale_y = 12.000000000;
const float p_o236523_folds = 0.000000000;
const float p_o236523_iterations = 5.000000000;
const float p_o236523_persistence = 0.350000000;
const float p_o236534_default_in1 = 0.000000000;
const float p_o236534_default_in2 = 0.000000000;
const float p_o236535_default_in1 = 0.000000000;
const float p_o236535_default_in2 = 0.000000000;
const float p_o236535_k = 0.200000000;
const float p_o236497_in_min = 0.050000000;
const float p_o236497_in_max = 0.325000000;
const float p_o236497_out_min = 0.000000000;
const float p_o236497_out_max = 1.000000000;
const float p_o236436_repeat = 1.000000000;
const float p_o236436_gradient_0_pos = 0.000000000;
const vec4 p_o236436_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o236436_gradient_1_pos = 1.000000000;
const vec4 p_o236436_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o236436_gradient_gradient_fct(float x) {
  if (x < p_o236436_gradient_0_pos) {
    return p_o236436_gradient_0_col;
  } else if (x < p_o236436_gradient_1_pos) {
    return mix(p_o236436_gradient_0_col, p_o236436_gradient_1_col, ((x-p_o236436_gradient_0_pos)/(p_o236436_gradient_1_pos-p_o236436_gradient_0_pos)));
  }
  return p_o236436_gradient_1_col;
}
const float p_o236529_color = 1.000000000;
const float p_o236528_default_in1 = 0.000000000;
const float p_o236528_default_in2 = 0.000000000;
const float p_o236525_default_in1 = 0.000000000;
const float p_o236525_default_in2 = 0.000000000;
const float p_o236582_default_in1 = 0.000000000;
const float p_o236582_default_in2 = 0.000000000;
const float p_o236526_min = 1.300000000;
const float p_o236526_max = -0.800000000;
const float p_o236526_step = 0.000000000;
const float p_o236507_radius = 2.000000000;
const float p_o236507_repeat = 1.000000000;
const float p_o236502_amount = 0.050000000;
const float p_o236502_eps = 0.100000000;
const float seed_o236506 = 0.212741271;
const float p_o236506_scale_x = 16.000000000;
const float p_o236506_scale_y = 7.000000000;
const float p_o236506_folds = 0.000000000;
const float p_o236506_iterations = 4.000000000;
const float p_o236506_persistence = 0.400000000;
float o236502_input_d(vec2 uv, float _seed_variation_) {
float o236506_0_1_f = fbm_2d_perlin((uv), vec2(p_o236506_scale_x, p_o236506_scale_y), int(p_o236506_folds), int(p_o236506_iterations), p_o236506_persistence, (elapsed_time*.3), (seed_o236506+fract(_seed_variation_)));
return o236506_0_1_f;
}
vec2 o236502_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o236502_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o236502_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o236502_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o236502_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o236522_default_in1 = 0.000000000;
const float p_o236522_default_in2 = 2.500000000;
const float p_o236499_default_in1 = 0.000000000;
const float p_o236499_default_in2 = 0.000000000;
const float p_o236500_default_in1 = 0.000000000;
const float p_o236521_default_in1 = 0.000000000;
const float p_o236508_repeat = 1.000000000;
const float p_o236508_rotate = 90.000000000;
const float p_o236508_gradient_0_pos = 0.000000000;
const vec4 p_o236508_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o236508_gradient_1_pos = 1.000000000;
const vec4 p_o236508_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o236508_gradient_gradient_fct(float x) {
  if (x < p_o236508_gradient_0_pos) {
    return p_o236508_gradient_0_col;
  } else if (x < p_o236508_gradient_1_pos) {
    return mix(p_o236508_gradient_0_col, p_o236508_gradient_1_col, ((x-p_o236508_gradient_0_pos)/(p_o236508_gradient_1_pos-p_o236508_gradient_0_pos)));
  }
  return p_o236508_gradient_1_col;
}
const float p_o236581_amount1 = 1.000000000;
const float p_o236458_amount = 0.800000000;
const float p_o236498_default_in1 = 0.000000000;
const float p_o236498_default_in2 = 0.000000000;
const float p_o236495_default_in1 = 0.000000000;
const float p_o236495_default_in2 = 0.040000000;
const float p_o236449_default_in1 = 0.000000000;
const float p_o236450_default_in1 = 0.000000000;
float o236458_input_in(vec2 uv, float _seed_variation_) {
vec4 o236436_0_1_rgba = o236436_gradient_gradient_fct(fract(p_o236436_repeat*1.41421356237*length(fract((uv))-vec2(0.5, 0.5))));
float o236450_0_clamp_false = (dot((o236436_0_1_rgba).rgb, vec3(1.0))/3.0)-(elapsed_time*.45);
float o236450_0_clamp_true = clamp(o236450_0_clamp_false, 0.0, 1.0);
float o236450_0_2_f = o236450_0_clamp_false;
float o236449_0_clamp_false = sin(o236450_0_2_f*(o236501_w));
float o236449_0_clamp_true = clamp(o236449_0_clamp_false, 0.0, 1.0);
float o236449_0_2_f = o236449_0_clamp_false;
float o236495_0_clamp_false = o236449_0_2_f*p_o236495_default_in2;
float o236495_0_clamp_true = clamp(o236495_0_clamp_false, 0.0, 1.0);
float o236495_0_2_f = o236495_0_clamp_false;
vec4 o236497_0_1_rgba = vec4(vec3(p_o236497_out_min)+(o236436_0_1_rgba.rgb-vec3(p_o236497_in_min))*vec3((p_o236497_out_max-(p_o236497_out_min))/(p_o236497_in_max-(p_o236497_in_min))), o236436_0_1_rgba.a);
float o236535_0_clamp_false = smax((dot((o236497_0_1_rgba).rgb, vec3(1.0))/3.0), p_o236535_default_in2, p_o236535_k);
float o236535_0_clamp_true = clamp(o236535_0_clamp_false, 0.0, 1.0);float o236535_0_2_f = o236535_0_clamp_false;
float o236498_0_clamp_false = o236495_0_2_f*o236535_0_2_f;
float o236498_0_clamp_true = clamp(o236498_0_clamp_false, 0.0, 1.0);
float o236498_0_1_f = o236498_0_clamp_false;
return o236498_0_1_f;
}
vec3 nm_o236458(vec2 uv, float amount, float size, float _seed_variation_) {
	vec3 e = vec3(1.0/size, -1.0/size, 0);
	vec2 rv;
	if (0 == 0) {
		rv = vec2(1.0, -1.0)*o236458_input_in(uv+e.xy, _seed_variation_);
		rv += vec2(-1.0, 1.0)*o236458_input_in(uv-e.xy, _seed_variation_);
		rv += vec2(1.0, 1.0)*o236458_input_in(uv+e.xx, _seed_variation_);
		rv += vec2(-1.0, -1.0)*o236458_input_in(uv-e.xx, _seed_variation_);
		rv += vec2(2.0, 0.0)*o236458_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(-2.0, 0.0)*o236458_input_in(uv-e.xz, _seed_variation_);
		rv += vec2(0.0, 2.0)*o236458_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(0.0, -2.0)*o236458_input_in(uv-e.zx, _seed_variation_);
		rv *= size*amount/128.0;
	} else if (0 == 1) {
		rv = vec2(3.0, -3.0)*o236458_input_in(uv+e.xy, _seed_variation_);
		rv += vec2(-3.0, 3.0)*o236458_input_in(uv-e.xy, _seed_variation_);
		rv += vec2(3.0, 3.0)*o236458_input_in(uv+e.xx, _seed_variation_);
		rv += vec2(-3.0, -3.0)*o236458_input_in(uv-e.xx, _seed_variation_);
		rv += vec2(10.0, 0.0)*o236458_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(-10.0, 0.0)*o236458_input_in(uv-e.xz, _seed_variation_);
		rv += vec2(0.0, 10.0)*o236458_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(0.0, -10.0)*o236458_input_in(uv-e.zx, _seed_variation_);
		rv *= size*amount/512.0;
	} else if (0 == 2) {
		rv = vec2(2.0, 0.0)*o236458_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(-2.0, 0.0)*o236458_input_in(uv-e.xz, _seed_variation_);
		rv += vec2(0.0, 2.0)*o236458_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(0.0, -2.0)*o236458_input_in(uv-e.zx, _seed_variation_);
		rv *= size*amount/64.0;
	} else {
		rv = vec2(1.0, 0.0)*o236458_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(0.0, 1.0)*o236458_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(-1.0, -1.0)*o236458_input_in(uv, _seed_variation_);
		rv *= size*amount/20.0;
	}
	return vec3(0.5)+0.5*normalize(vec3(rv, -1.0));
}
const float p_o236544_amount = 0.100000000;
float o236544_input_in(vec2 uv, float _seed_variation_) {
float o236523_0_1_f = fbm_2d_perlin(((vec2(fract(p_o236524_repeat*atan((uv).y-0.5, (uv).x-0.5)*0.15915494309), min(0.99999, 2.0/p_o236524_radius*length((uv)-vec2(0.5)))))-vec2(p_o236530_translate_x, (elapsed_time*.3))), vec2(p_o236523_scale_x, p_o236523_scale_y), int(p_o236523_folds), int(p_o236523_iterations), p_o236523_persistence, (elapsed_time*.8), (seed_o236523+fract(_seed_variation_)));
vec4 o236530_0_1_rgba = vec4(vec3(o236523_0_1_f), 1.0);
vec4 o236524_0_1_rgba = o236530_0_1_rgba;
float o236526_0_x = (dot((o236524_0_1_rgba).rgb, vec3(1.0))/3.0)*(p_o236526_max-p_o236526_min);float o236526_0_1_f = p_o236526_min+o236526_0_x-mod(o236526_0_x, max(p_o236526_step, 0.00000001));
float o236582_0_clamp_false = smoothstep(0.0, 1.0, o236526_0_1_f);
float o236582_0_clamp_true = clamp(o236582_0_clamp_false, 0.0, 1.0);
float o236582_0_1_f = o236582_0_clamp_false;
vec2 o236502_0_slope = o236502_slope((vec2(fract(p_o236507_repeat*atan((uv).y-0.5, (uv).x-0.5)*0.15915494309), min(0.99999, 2.0/p_o236507_radius*length((uv)-vec2(0.5))))), p_o236502_eps, _seed_variation_);
vec2 o236502_0_warp = o236502_0_slope;float o236508_0_r = 0.5+(cos(p_o236508_rotate*0.01745329251)*(((vec2(fract(p_o236507_repeat*atan((uv).y-0.5, (uv).x-0.5)*0.15915494309), min(0.99999, 2.0/p_o236507_radius*length((uv)-vec2(0.5)))))+p_o236502_amount*o236502_0_warp).x-0.5)+sin(p_o236508_rotate*0.01745329251)*(((vec2(fract(p_o236507_repeat*atan((uv).y-0.5, (uv).x-0.5)*0.15915494309), min(0.99999, 2.0/p_o236507_radius*length((uv)-vec2(0.5)))))+p_o236502_amount*o236502_0_warp).y-0.5))/(cos(abs(mod(p_o236508_rotate, 90.0)-45.0)*0.01745329251)*1.41421356237);vec4 o236508_0_1_rgba = o236508_gradient_gradient_fct(fract(o236508_0_r*p_o236508_repeat));
float o236521_0_clamp_false = (dot((o236508_0_1_rgba).rgb, vec3(1.0))/3.0)-(elapsed_time*0.3);
float o236521_0_clamp_true = clamp(o236521_0_clamp_false, 0.0, 1.0);
float o236521_0_2_f = o236521_0_clamp_false;
float o236500_0_clamp_false = o236521_0_2_f*(o236501_w*0.25);
float o236500_0_clamp_true = clamp(o236500_0_clamp_false, 0.0, 1.0);
float o236500_0_2_f = o236500_0_clamp_false;
float o236499_0_clamp_false = fract(o236500_0_2_f);
float o236499_0_clamp_true = clamp(o236499_0_clamp_false, 0.0, 1.0);
float o236499_0_1_f = o236499_0_clamp_false;
float o236522_0_clamp_false = pow(o236499_0_1_f,p_o236522_default_in2);
float o236522_0_clamp_true = clamp(o236522_0_clamp_false, 0.0, 1.0);
float o236522_0_2_f = o236522_0_clamp_false;
vec4 o236502_0_1_rgba = vec4(vec3(o236522_0_2_f), 1.0);
vec4 o236507_0_1_rgba = o236502_0_1_rgba;
float o236525_0_clamp_false = o236582_0_1_f*(dot((o236507_0_1_rgba).rgb, vec3(1.0))/3.0);
float o236525_0_clamp_true = clamp(o236525_0_clamp_false, 0.0, 1.0);
float o236525_0_1_f = o236525_0_clamp_false;
vec4 o236436_0_1_rgba = o236436_gradient_gradient_fct(fract(p_o236436_repeat*1.41421356237*length(fract((uv))-vec2(0.5, 0.5))));
vec4 o236497_0_1_rgba = vec4(vec3(p_o236497_out_min)+(o236436_0_1_rgba.rgb-vec3(p_o236497_in_min))*vec3((p_o236497_out_max-(p_o236497_out_min))/(p_o236497_in_max-(p_o236497_in_min))), o236436_0_1_rgba.a);
float o236535_0_clamp_false = smax((dot((o236497_0_1_rgba).rgb, vec3(1.0))/3.0), p_o236535_default_in2, p_o236535_k);
float o236535_0_clamp_true = clamp(o236535_0_clamp_false, 0.0, 1.0);float o236535_0_2_f = o236535_0_clamp_false;
float o236528_0_clamp_false = o236525_0_1_f*o236535_0_2_f;
float o236528_0_clamp_true = clamp(o236528_0_clamp_false, 0.0, 1.0);
float o236528_0_1_f = o236528_0_clamp_false;
return o236528_0_1_f;
}
vec3 nm_o236544(vec2 uv, float amount, float size, float _seed_variation_) {
	vec3 e = vec3(1.0/size, -1.0/size, 0);
	vec2 rv;
	if (0 == 0) {
		rv = vec2(1.0, -1.0)*o236544_input_in(uv+e.xy, _seed_variation_);
		rv += vec2(-1.0, 1.0)*o236544_input_in(uv-e.xy, _seed_variation_);
		rv += vec2(1.0, 1.0)*o236544_input_in(uv+e.xx, _seed_variation_);
		rv += vec2(-1.0, -1.0)*o236544_input_in(uv-e.xx, _seed_variation_);
		rv += vec2(2.0, 0.0)*o236544_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(-2.0, 0.0)*o236544_input_in(uv-e.xz, _seed_variation_);
		rv += vec2(0.0, 2.0)*o236544_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(0.0, -2.0)*o236544_input_in(uv-e.zx, _seed_variation_);
		rv *= size*amount/128.0;
	} else if (0 == 1) {
		rv = vec2(3.0, -3.0)*o236544_input_in(uv+e.xy, _seed_variation_);
		rv += vec2(-3.0, 3.0)*o236544_input_in(uv-e.xy, _seed_variation_);
		rv += vec2(3.0, 3.0)*o236544_input_in(uv+e.xx, _seed_variation_);
		rv += vec2(-3.0, -3.0)*o236544_input_in(uv-e.xx, _seed_variation_);
		rv += vec2(10.0, 0.0)*o236544_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(-10.0, 0.0)*o236544_input_in(uv-e.xz, _seed_variation_);
		rv += vec2(0.0, 10.0)*o236544_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(0.0, -10.0)*o236544_input_in(uv-e.zx, _seed_variation_);
		rv *= size*amount/512.0;
	} else if (0 == 2) {
		rv = vec2(2.0, 0.0)*o236544_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(-2.0, 0.0)*o236544_input_in(uv-e.xz, _seed_variation_);
		rv += vec2(0.0, 2.0)*o236544_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(0.0, -2.0)*o236544_input_in(uv-e.zx, _seed_variation_);
		rv *= size*amount/64.0;
	} else {
		rv = vec2(1.0, 0.0)*o236544_input_in(uv+e.xz, _seed_variation_);
		rv += vec2(0.0, 1.0)*o236544_input_in(uv+e.zx, _seed_variation_);
		rv += vec2(-1.0, -1.0)*o236544_input_in(uv, _seed_variation_);
		rv *= size*amount/20.0;
	}
	return vec3(0.5)+0.5*normalize(vec3(rv, -1.0));
}
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec3 o236583_0_clamp_false = vec3(p_o236583_d_in1_x, p_o236583_d_in1_y, p_o236583_d_in1_z)+vec3(p_o236583_d_in2_x, p_o236583_d_in2_y, p_o236583_d_in2_z);
vec3 o236583_0_clamp_true = clamp(o236583_0_clamp_false, vec3(0.0), vec3(1.0));
vec3 o236583_0_2_rgb = o236583_0_clamp_false;
vec3 o236584_0_clamp_false = vec3(p_o236584_d_in1_x, p_o236584_d_in1_y, p_o236584_d_in1_z)+vec3(p_o236584_d_in2_x, p_o236584_d_in2_y, p_o236584_d_in2_z);
vec3 o236584_0_clamp_true = clamp(o236584_0_clamp_false, vec3(0.0), vec3(1.0));
vec3 o236584_0_2_rgb = o236584_0_clamp_false;
vec3 o236586_0_clamp_false = vec3(p_o236586_d_in1_x, p_o236586_d_in1_y, p_o236586_d_in1_z)+vec3(p_o236586_d_in2_x, p_o236586_d_in2_y, p_o236586_d_in2_z);
vec3 o236586_0_clamp_true = clamp(o236586_0_clamp_false, vec3(0.0), vec3(1.0));
vec3 o236586_0_2_rgb = o236586_0_clamp_false;
float o236523_0_1_f = fbm_2d_perlin(((vec2(fract(p_o236524_repeat*atan((uv).y-0.5, (uv).x-0.5)*0.15915494309), min(0.99999, 2.0/p_o236524_radius*length((uv)-vec2(0.5)))))-vec2(p_o236530_translate_x, (elapsed_time*.3))), vec2(p_o236523_scale_x, p_o236523_scale_y), int(p_o236523_folds), int(p_o236523_iterations), p_o236523_persistence, (elapsed_time*.8), (seed_o236523+fract(_seed_variation_)));
vec4 o236530_0_1_rgba = vec4(vec3(o236523_0_1_f), 1.0);
vec4 o236524_0_1_rgba = o236530_0_1_rgba;
float o236531_0_clamp_false = smoothstep(0.0, 1.0, (dot((o236524_0_1_rgba).rgb, vec3(1.0))/3.0));
float o236531_0_clamp_true = clamp(o236531_0_clamp_false, 0.0, 1.0);
float o236531_0_1_f = o236531_0_clamp_false;
vec4 o236436_0_1_rgba = o236436_gradient_gradient_fct(fract(p_o236436_repeat*1.41421356237*length(fract((uv))-vec2(0.5, 0.5))));
vec4 o236497_0_1_rgba = vec4(vec3(p_o236497_out_min)+(o236436_0_1_rgba.rgb-vec3(p_o236497_in_min))*vec3((p_o236497_out_max-(p_o236497_out_min))/(p_o236497_in_max-(p_o236497_in_min))), o236436_0_1_rgba.a);
float o236535_0_clamp_false = smax((dot((o236497_0_1_rgba).rgb, vec3(1.0))/3.0), p_o236535_default_in2, p_o236535_k);
float o236535_0_clamp_true = clamp(o236535_0_clamp_false, 0.0, 1.0);float o236535_0_2_f = o236535_0_clamp_false;
float o236534_0_clamp_false = o236535_0_2_f+p_o236534_default_in2;
float o236534_0_clamp_true = clamp(o236534_0_clamp_false, 0.0, 1.0);
float o236534_0_2_f = o236534_0_clamp_true;
float o236533_0_clamp_false = o236531_0_1_f*o236534_0_2_f;
float o236533_0_clamp_true = clamp(o236533_0_clamp_false, 0.0, 1.0);
float o236533_0_1_f = o236533_0_clamp_false;
vec4 o236585_0_b = vec4(o236584_0_2_rgb, 1.0);
vec4 o236585_0_l;
float o236585_0_a;

o236585_0_l = vec4(o236586_0_2_rgb, 1.0);
o236585_0_a = p_o236585_amount1*o236533_0_1_f;
o236585_0_b = vec4(blend_normal((uv), o236585_0_l.rgb, o236585_0_b.rgb, o236585_0_a*o236585_0_l.a), min(1.0, o236585_0_b.a+o236585_0_a*o236585_0_l.a));

vec4 o236585_0_1_rgba = o236585_0_b;
float o236529_0_1_f = p_o236529_color;
float o236526_0_x = (dot((o236524_0_1_rgba).rgb, vec3(1.0))/3.0)*(p_o236526_max-p_o236526_min);float o236526_0_1_f = p_o236526_min+o236526_0_x-mod(o236526_0_x, max(p_o236526_step, 0.00000001));
float o236582_0_clamp_false = smoothstep(0.0, 1.0, o236526_0_1_f);
float o236582_0_clamp_true = clamp(o236582_0_clamp_false, 0.0, 1.0);
float o236582_0_1_f = o236582_0_clamp_false;
vec2 o236502_0_slope = o236502_slope((vec2(fract(p_o236507_repeat*atan((uv).y-0.5, (uv).x-0.5)*0.15915494309), min(0.99999, 2.0/p_o236507_radius*length((uv)-vec2(0.5))))), p_o236502_eps, _seed_variation_);
vec2 o236502_0_warp = o236502_0_slope;float o236508_0_r = 0.5+(cos(p_o236508_rotate*0.01745329251)*(((vec2(fract(p_o236507_repeat*atan((uv).y-0.5, (uv).x-0.5)*0.15915494309), min(0.99999, 2.0/p_o236507_radius*length((uv)-vec2(0.5)))))+p_o236502_amount*o236502_0_warp).x-0.5)+sin(p_o236508_rotate*0.01745329251)*(((vec2(fract(p_o236507_repeat*atan((uv).y-0.5, (uv).x-0.5)*0.15915494309), min(0.99999, 2.0/p_o236507_radius*length((uv)-vec2(0.5)))))+p_o236502_amount*o236502_0_warp).y-0.5))/(cos(abs(mod(p_o236508_rotate, 90.0)-45.0)*0.01745329251)*1.41421356237);vec4 o236508_0_1_rgba = o236508_gradient_gradient_fct(fract(o236508_0_r*p_o236508_repeat));
float o236521_0_clamp_false = (dot((o236508_0_1_rgba).rgb, vec3(1.0))/3.0)-(elapsed_time*0.3);
float o236521_0_clamp_true = clamp(o236521_0_clamp_false, 0.0, 1.0);
float o236521_0_2_f = o236521_0_clamp_false;
float o236500_0_clamp_false = o236521_0_2_f*(o236501_w*0.25);
float o236500_0_clamp_true = clamp(o236500_0_clamp_false, 0.0, 1.0);
float o236500_0_2_f = o236500_0_clamp_false;
float o236499_0_clamp_false = fract(o236500_0_2_f);
float o236499_0_clamp_true = clamp(o236499_0_clamp_false, 0.0, 1.0);
float o236499_0_1_f = o236499_0_clamp_false;
float o236522_0_clamp_false = pow(o236499_0_1_f,p_o236522_default_in2);
float o236522_0_clamp_true = clamp(o236522_0_clamp_false, 0.0, 1.0);
float o236522_0_2_f = o236522_0_clamp_false;
vec4 o236502_0_1_rgba = vec4(vec3(o236522_0_2_f), 1.0);
vec4 o236507_0_1_rgba = o236502_0_1_rgba;
float o236525_0_clamp_false = o236582_0_1_f*(dot((o236507_0_1_rgba).rgb, vec3(1.0))/3.0);
float o236525_0_clamp_true = clamp(o236525_0_clamp_false, 0.0, 1.0);
float o236525_0_1_f = o236525_0_clamp_false;
float o236528_0_clamp_false = o236525_0_1_f*o236535_0_2_f;
float o236528_0_clamp_true = clamp(o236528_0_clamp_false, 0.0, 1.0);
float o236528_0_1_f = o236528_0_clamp_false;
vec4 o236532_0_b = vec4(o236583_0_2_rgb, 1.0);
vec4 o236532_0_l;
float o236532_0_a;

o236532_0_l = o236585_0_1_rgba;
o236532_0_a = p_o236532_amount1*o236533_0_1_f;
o236532_0_b = vec4(blend_normal((uv), o236532_0_l.rgb, o236532_0_b.rgb, o236532_0_a*o236532_0_l.a), min(1.0, o236532_0_b.a+o236532_0_a*o236532_0_l.a));

o236532_0_l = vec4(vec3(o236529_0_1_f), 1.0);
o236532_0_a = p_o236532_amount2*o236528_0_1_f;
o236532_0_b = vec4(blend_normal((uv), o236532_0_l.rgb, o236532_0_b.rgb, o236532_0_a*o236532_0_l.a), min(1.0, o236532_0_b.a+o236532_0_a*o236532_0_l.a));

vec4 o236532_0_1_rgba = o236532_0_b;
vec3 o236458_0_1_rgb = nm_o236458((uv), p_o236458_amount, 1024.000000000, _seed_variation_);
vec3 o236544_0_1_rgb = nm_o236544((uv), p_o236544_amount, 1024.000000000, _seed_variation_);
vec3 o236581_0_b = o236458_0_1_rgb;
vec3 o236581_0_l;
float o236581_0_a;

o236581_0_l = o236544_0_1_rgb;
o236581_0_a = p_o236581_amount1 * 1.0;
o236581_0_b = normal_blend((uv), o236581_0_l, o236581_0_b, o236581_0_a);
vec3 o236581_0_2_rgb = o236581_0_b;

	vec3 albedo_tex = ((o236532_0_1_rgba).rgb).rgb;
	albedo_tex = mix(pow((albedo_tex + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),albedo_tex * (1.0 / 12.92),lessThan(albedo_tex,vec3(0.04045)));
	ALBEDO = albedo_tex*p_o236435_albedo_color.rgb;
	METALLIC = 1.0*p_o236435_metallic;
	ROUGHNESS = 1.0*p_o236435_roughness;
	NORMAL = o236581_0_2_rgb;
	EMISSION = vec3(0.0)*p_o236435_emission_energy;

}



