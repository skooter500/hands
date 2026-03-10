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
float cross2( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }
// signed distance to a quadratic bezier
vec2 sdBezier( in vec2 pos, in vec2 A, in vec2 B, in vec2 C ) {	
	vec2 a = B - A;
	vec2 b = A - 2.0*B + C;
	vec2 c = a * 2.0;
	vec2 d = A - pos;
	float kk = 1.0/dot(b,b);
	float kx = kk * dot(a,b);
	float ky = kk * (2.0*dot(a,a)+dot(d,b))/3.0;
	float kz = kk * dot(d,a);	  
	float res = 0.0;
	float sgn = 0.0;
	float p = ky - kx*kx;
	float p3 = p*p*p;
	float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
	float h = q*q + 4.0*p3;
	float rvx;
	if( h>=0.0 ) { // 1 root
		h = sqrt(h);
		vec2 x = (vec2(h,-h)-q)/2.0;
		vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
		rvx = uv.x+uv.y-kx;
		float t = clamp(rvx, 0.0, 1.0);
		vec2 q2 = d+(c+b*t)*t;
		res = dot(q2, q2);
		sgn = cross2(c+2.0*b*t, q2);
	} else {   // 3 roots
		float z = sqrt(-p);
		float v = acos(q/(p*z*2.0))/3.0;
		float m = cos(v);
		float n = sin(v)*1.732050808;
		vec3  t = clamp(vec3(m+m,-n-m,n-m)*z-kx, 0.0, 1.0);
		vec2  qx=d+(c+b*t.x)*t.x; float dx=dot(qx, qx), sx = cross2(c+2.0*b*t.x,qx);
		vec2  qy=d+(c+b*t.y)*t.y; float dy=dot(qy, qy), sy = cross2(c+2.0*b*t.y,qy);
		if( dx<dy ) { res=dx; sgn=sx; rvx = t.x; } else { res=dy; sgn=sy; rvx = t.y; }
	}
	
	return vec2(rvx, sqrt(res)*sign(sgn));
}
vec2 sdLine(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p-a, ba = b-a;
	float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
	return vec2(length(pa-ba*h), h);
}
float sd_box(vec2 uv, vec2 size) {
	vec2 d = abs(uv)-size;
	return length(max(d, vec2(0)))+min(max(d.x, d.y), 0.0);
}
float s(vec2 uv, vec2 A, vec2 B, vec2 C) { return abs(sdBezier(uv, A, B, C).y); }
float l(vec2 uv, vec2 A, vec2 B) { return sdLine(uv, A, B).x; }
float box(vec2 p, float r) { p = abs(p) - r; return step(max(p.x,p.y),0.0);}
vec3 grid(vec2 p, int gs) {
	float g = float(gs);
	p += 0.5;
	vec2 a = floor(p*g)/vec2(g);
	p = fract(p*g) - 0.5;
	float c = g*(a.x+floor(1.0/g)) + a.y*g*g;
	return vec3(p,c);
}
// Katakana
float k1(vec2 uv) { // a
	float d = s(uv, vec2(0.084, -0.004), vec2(0.399, -0.195),vec2(0.26, -0.28));
	d = min(d, s(uv, vec2(-0.278, 0.318), vec2(-0.009, 0.227),vec2(-0.021, -0.133)));
	return min(d, l(uv, vec2(-0.31, -0.28), vec2(0.26, -0.28)));
}
float k2(vec2 uv) { // i
	float d = s(uv, vec2(0.264, -0.319), vec2(0, -0.051),vec2(-0.309, 0.045));
	return min(d, l(uv, vec2(0.0385, 0.3155), vec2(0.0385, -0.1088)));
}
float k3(vec2 uv) { // u
	float d = s(uv, vec2(0.289, -0.194), vec2(0.297, 0.234),vec2(-0.117, 0.324));
	d = min(d, l(uv, vec2(0, -0.21), vec2(0, -0.3281)));
	d = min(d, l(uv, vec2(-0.27, -0.21), vec2(0.2878, -0.21)));
	return min(d, l(uv, vec2(-0.28, 0), vec2(-0.28, -0.2066)));
}
float k4(vec2 uv) { // e
	float d = l(uv, vec2(0.28, -0.25), vec2(-0.28, -0.25));
	d = min(d, l(uv, vec2(0, -0.25), vec2(0, 0.25)));
	return min(d, l(uv, vec2(0.34, 0.25), vec2(-0.34, 0.25)));
}
float k5(vec2 uv) { // o
	float d = s(uv, vec2(0.09, -0.183), vec2(-0.013, 0.065),vec2(-0.325, 0.228));
	d = min(d, l(uv, vec2(0.12, -0.33), vec2(0.12, 0.33)));
	return min(d, l(uv, vec2(-0.31, -0.19), vec2(0.31, -0.19)));
}
float k6(vec2 uv) { // ka
	float d = s(uv, vec2(-0.039, -0.334136), vec2(0.006, 0.105),vec2(-0.319, 0.302));
	d = min(d, l(uv, vec2(-0.29, -0.19), vec2(0.28, -0.19)));
	d = min(d, s(uv, vec2(0.246, 0.217), vec2(0.231, 0.325),vec2(0.054, 0.28)));
	return min(d, l(uv, vec2(0.2469, 0.2153), vec2(0.28, -0.19)));
}
float k7(vec2 uv) { // ki
	float d = l(uv, vec2(0.07, 0.33), vec2(-0.07, -0.33));
	d = min(d, l(uv, vec2(0.25, -0.23), vec2(-0.31, -0.14)));
	return min(d, l(uv, vec2(0.31, 0), vec2(-0.33, 0.1)));
}
float k8(vec2 uv) { // ku
	float d = s(uv, vec2(-0.212, 0.319), vec2(0.281, 0.158),vec2(0.259, -0.21));
	d = min(d, s(uv, vec2(-0.053, -0.328), vec2(-0.141, -0.11),vec2(-0.295, -0.023)));
	return min(d, l(uv, vec2(0.2565, -0.22), vec2(-0.0918, -0.2193)));
}
float k9(vec2 uv) // ke
{
	float d = s(uv, vec2(-0.192, 0.319), vec2(0.136, 0.167),vec2(0.128, -0.181));
	d = min(d, s(uv, vec2(-0.124, -0.332), vec2(-0.198, -0.131),vec2(-0.336, -0.01)));
	return min(d, l(uv, vec2(0.3279, -0.19), vec2(-0.19, -0.19)));
}
float k10(vec2 uv) // ko
{
	float d = l(uv, vec2(0.25, -0.24), vec2(-0.27, -0.24));
	d = min(d, l(uv, vec2(0.25, -0.24), vec2(0.25, 0.25)));
	return min(d, l(uv, vec2(-0.28, 0.25), vec2(0.25, 0.25)));
}
float k11(vec2 uv) // sa
{
	float d = l(uv, vec2(-0.342, -0.1604), vec2(0.34, -0.16));
	d = min(d, l(uv, vec2(-0.17, -0.33), vec2(-0.17, 0.0844)));
	d = min(d, s(uv, vec2(0.17, -0.068), vec2(0.176, 0.287),vec2(-0.11, 0.315)));
	return min(d, l(uv, vec2(0.17, -0.33), vec2(0.17, -0.03)));
}
float k12(vec2 uv) // shi
{
	float d = s(uv, vec2(-0.22, -0.306), vec2(-0.117, -0.267),vec2(-0.03, -0.204));
	d = min(d, s(uv, vec2(0.313, -0.153), vec2(0.177, 0.267),vec2(-0.273, 0.299)));
	return min(d, s(uv, vec2(-0.289, -0.098), vec2(-0.154, -0.05),vec2(-0.087, 0.013)));
}
float k13(vec2 uv) // su
{
	float d = s(uv, vec2(0.057, 0.044), vec2(0.195, 0.126),vec2(0.314, 0.286));
	d = min(d, s(uv, vec2(0.221, -0.269), vec2(0.1, 0.14),vec2(-0.316, 0.288)));
	return min(d, l(uv, vec2(-0.27, -0.27), vec2(0.22, -0.27)));
}
float k14(vec2 uv) // se
{
	float d = s(uv, vec2(0.252, -0.182), vec2(0.41, -0.176),vec2(0.119, 0.078));
	d = min(d, s(uv, vec2(-0.137, 0.15), vec2(-0.142, 0.352),vec2(0.278, 0.269)));
	d = min(d, l(uv, vec2(-0.1353, -0.3247), vec2(-0.1373, 0.1509)));
	return min(d, l(uv, vec2(-0.3301, -0.0978), vec2(0.2521, -0.1818)));
}
float k15(vec2 uv) // so
{
	float d = s(uv, vec2(0.265, -0.28), vec2(0.257, 0.135),vec2(-0.194, 0.309));
	return min(d, s(uv, vec2(-0.276, -0.285), vec2(-0.199, -0.188),vec2(-0.148, -0.033)));
}
float k16(vec2 uv) // ta
{
	float d = s(uv, vec2(-0.212, 0.319), vec2(0.281, 0.158),vec2(0.259, -0.21));
	d = min(d, s(uv, vec2(-0.053, -0.328), vec2(-0.141, -0.11),vec2(-0.295, -0.023)));
	d = min(d, l(uv, vec2(0.2565, -0.22), vec2(-0.0918, -0.2193)));
	return min(d, s(uv, vec2(-0.102, -0.058), vec2(0.028, 0.025),vec2(0.126, 0.122)));
}
float k17(vec2 uv) // chi
{
	float d = s(uv, vec2(-0.269, -0.23), vec2(0.044, -0.237),vec2(0.265, -0.316));
	d = min(d, l(uv, vec2(0.338, -0.04), vec2(-0.3238, -0.04)));
	d = min(d, s(uv, vec2(-0.213, 0.324), vec2(0.044, 0.229),vec2(0.04, -0.038)));
	return min(d, l(uv, vec2(0.04, -0.249), vec2(0.04, -0.0363)));
}
float k18(vec2 uv) // tsu
{
	float d = s(uv, vec2(-0.175, 0.296), vec2(0.228, 0.222),vec2(0.292, -0.271));	
	d = min(d, s(uv, vec2(-0.071, -0.297), vec2(0, -0.144),vec2(0.013, -0.068)));
	return min(d, s(uv, vec2(-0.29, -0.253), vec2(-0.222, -0.11),vec2(-0.204, -0.032)));
}
float k19(vec2 uv) // te
{
	float d = l(uv, vec2(-0.25, -0.29), vec2(0.25, -0.29));
	d = min(d, l(uv, vec2(-0.33, -0.0704), vec2(0.33, -0.07)));
	return min(d, s(uv, vec2(-0.225, 0.32), vec2(0.029, 0.261),vec2(0.03, -0.068)));
}
float k20(vec2 uv) { // to
	float d = s (uv, vec2(-0.159, -0.093), vec2(0.104, -0.02),vec2(0.294, 0.08));
	return min(d, l(uv, vec2(-0.16, -0.3254), vec2(-0.16, 0.32)));
}
float k21(vec2 uv) { // na
	float d = s(uv, vec2(-0.252, 0.32), vec2(0.045, 0.253),vec2(0.039, -0.118));
	d = min(d, l(uv, vec2(0.039, -0.1141), vec2(0.0393, -0.33)));
	d = min(d, l(uv, vec2(-0.32, -0.12), vec2(0.33, -0.12)));
	return d;
}
float k22(vec2 uv) { // ni
	float d = l(uv, vec2(-0.24, -0.23), vec2(0.25, -0.23));
	d = min(d, l(uv, vec2(-0.33, 0.24), vec2(0.33, 0.24)));
	return d;
}
float k23(vec2 uv) { // nu
	float d = s(uv, vec2(-0.268, 0.311), vec2(0.178, 0.145),vec2(0.266, -0.28));
	d = min(d, s(uv, vec2(-0.143, -0.092), vec2(0.125, 0.079),vec2(0.253, 0.23)));
	return min(d, l(uv, vec2(-0.2553, -0.28), vec2(0.2661, -0.28)));
}
float k24(vec2 uv) { // ne
	float d = l(uv, vec2(0, -0.2201), vec2(0, -0.35));
	d = min(d, l(uv, vec2(0, 0.0031), vec2(0, 0.34)));
	d = min(d, s(uv, vec2(-0.327, 0.144), vec2(0.134, -0.013),vec2(0.25, -0.219)));
	d = min(d, s(uv, vec2(0.333, 0.161), vec2(0.125, 0.041),vec2(0, 0.005)));
	return min(d, l(uv, vec2(-0.27, -0.22), vec2(0.25, -0.22)));
}
float k25(vec2 uv) { // no
	return s(uv, vec2(-0.284, 0.284), vec2(0.19, 0.094),vec2(0.24, -0.294));
}
float k26(vec2 uv) { // ha
	uv.x = -abs(uv.x);
	return s(uv, vec2(-0.329, 0.271), vec2(-0.178, 0.12946),vec2(-0.148, -0.283));
}
float k27(vec2 uv) { // hi
	float d = s(uv, vec2(0.269, 0.262), vec2(-0.208, 0.326),vec2(-0.21, 0.18));
	d = min(d, s(uv, vec2(-0.212, -0.049), vec2(0.057, -0.09),vec2(0.235, -0.186)));
	return min(d, l(uv, vec2(-0.2159, -0.3062), vec2(-0.21, 0.18)));
}
float k28(vec2 uv) { // fu
	float d = s(uv, vec2(-0.193, 0.302), vec2(0.298, 0.141),vec2(0.28, -0.27));
	return min(d, l(uv, vec2(-0.28, -0.27), vec2(0.28, -0.27)));
}
float k29(vec2 uv) { // he
	float d = l(uv, vec2(-0.0793, -0.222), vec2(0.3384, 0.2195));
	return min(d, l(uv, vec2(-0.0793, -0.222), vec2(-0.3366, 0.0766)));
}
float k30(vec2 uv) { // ho
	float d = l(uv, vec2(0, -0.33), vec2(0, 0.32));
	d = min(d, l(uv, vec2(-0.33, -0.21), vec2(0.33, -0.21)));
	uv.x = -abs(uv.x);
	return min(d, s(uv, vec2(-0.328, 0.249), vec2(-0.215, 0.059),vec2(-0.208, -0.047)));
}
float k31(vec2 uv) { // ma
	float d = s(uv, vec2(0.31, -0.25), vec2(0.311, -0.135),vec2(-0.024, 0.136));
	d = min(d, s(uv, vec2(0.115, 0.314), vec2(-0.009, 0.136),vec2(-0.208, -0.047)));
	return min(d, l(uv, vec2(-0.32, -0.25), vec2(0.31, -0.25)));
}
float k32(vec2 uv) { // mi
	float d = s(uv, vec2(-0.211, -0.303), vec2(0.055, -0.276),vec2(0.249, -0.215));
	d = min(d, s(uv, vec2(0.219, 0.019), vec2(-0.017, -0.05),vec2(-0.228, -0.072)));
	return min(d, s(uv, vec2(0.27, 0.309), vec2(-0.017, 0.211),vec2(-0.288, 0.174)));
}
float k33(vec2 uv) { // mu
	float d = s(uv, vec2(-0.335, 0.265), vec2(0.068, 0.262),vec2(0.287, 0.198));
	d = min(d, s(uv, vec2(-0.244, 0.264), vec2(-0.139, 0.064),vec2(-0.021, -0.331)));
	return min(d, s(uv, vec2(0.33, 0.304), vec2(0.253, 0.09),vec2(0.128, -0.094)));
}
float k34(vec2 uv) { // me
	float d = s(uv, vec2(-0.283, 0.293), vec2(0.069, 0.165),vec2(0.219, -0.315));
	return min(d, s(uv, vec2(-0.19, -0.191), vec2(0.076, -0.021),vec2(0.258, 0.211)));
}
float k35(vec2 uv) { // mo
	float d = l(uv, vec2(-0.28, -0.28), vec2(0.28, -0.28));
	d = min(d, s(uv, vec2(-0.07, 0.171), vec2(-0.077, 0.351),vec2(0.32, 0.267)));
	d = min(d, l(uv, vec2(-0.07, -0.28), vec2(-0.07, 0.17)));
	return min(d, l(uv, vec2(-0.32, -0.04), vec2(0.33, -0.04)));
}
float k36(vec2 uv) { // ya
	float d = l(uv, vec2(-0.1546, -0.3368), vec2(-0.0156, 0.3389));
	d = min(d, s(uv, vec2(0.107, 0.07), vec2(0.41, -0.144),vec2(0.265, -0.222)));
	return min(d,l(uv, vec2(-0.325, -0.1285), vec2(0.2631, -0.2219)));
}
float k37(vec2 uv) { // yu
	float d = s(uv, vec2(0.103, 0.239), vec2(0.216, -0.251),vec2(0.143, -0.248));
	d = min(d, l(uv, vec2(-0.26, -0.25), vec2(0.1425, -0.248)));
	return min(d, l(uv, vec2(-0.33, 0.24), vec2(0.34, 0.24)));
}
float k38(vec2 p) { // yo
	const vec2 a = vec2(0);
	const float b = 0.25;
	float c = abs(p.y)-0.25;
	float d = length(max(vec2(abs(c),p.x-b),a));
	float d1 = min(d, length(max(vec2(abs(p.y),p.x-b),a)));
	d = min(d, length(max(vec2(abs(p.x-b),c),a)));
	d = length(max(vec2(d,-p.x-0.25),a));
	return min(d,length(max(vec2(d1,-p.x-0.22),a)));
}
float k39(vec2 uv) { // ra
	float d = s(uv, vec2(0.27, -0.1), vec2(0.264, 0.221),vec2(-0.159, 0.319));
	d = min(d, l(uv, vec2(-0.3, -0.1), vec2(0.27, -0.1)));
	return min(d, l(uv, vec2(-0.23, -0.3), vec2(0.23, -0.3)));
}
float k40(vec2 uv) { // ri
	float d = l(uv, vec2(-0.21, -0.31), vec2(-0.21, 0.06));
	d = min(d, s(uv, vec2(0.21, -0.07), vec2(0.218, 0.254),vec2(-0.148, 0.317)));
	return min(d, l(uv, vec2(0.21, -0.31), vec2(0.21, -0.07)));
}
float k41(vec2 uv) { // ru
	float d = s(uv, vec2(0.05, 0.237), vec2(0.109, 0.416),vec2(0.354, 0.052));
	d = min(d, s(uv, vec2(-0.169, -0.301), vec2(-0.144, 0.2),vec2(-0.322, 0.317)));
	return min(d, l(uv, vec2(0.05, -0.31), vec2(0.05, 0.2371)));
}
float k42(vec2 uv) { // re
	float d = s(uv, vec2(-0.21, 0.237), vec2(-0.216, 0.348),vec2(0.003, 0.26));
	d = min(d, s(uv, vec2(0, 0.261), vec2(0.171, 0.192),vec2(0.322, -0.021)));
	return min(d, l(uv, vec2(-0.21, -0.31), vec2(-0.21, 0.2371)));
}
float k43(vec2 uv) { // ro
	return abs(sd_box(uv ,vec2(0.25,0.25)));
}
float k44(vec2 uv) { // wa
	float d = l(uv, vec2(-0.271, -0.28), vec2(-0.271, -0.04));
	d = min(d, s(uv, vec2(0.28, -0.28), vec2(0.303, 0.193),vec2(-0.115, 0.313)));
	return min(d, l(uv, vec2(-0.271, -0.28), vec2(0.28, -0.28)));
}
float k45(vec2 uv) { // wo
	return min(l(uv, vec2(-0.255, -0.058), vec2(0.25, -0.058)),k28(uv));
}
float k46(vec2 uv) { // n
	float d = s(uv, vec2(0.313, -0.196), vec2(0.221, 0.217),vec2(-0.267, 0.279));
	return min(d, s(uv, vec2(-0.078, -0.099), vec2(-0.14, -0.181),vec2(-0.273, -0.268)));
}
// Hiragana
float h1(vec2 uv) { // a
	float d = s(uv, vec2(-0.175, 0.287), vec2(-0.318, 0.318),vec2(-0.306, 0.19));
	d = min(d, s(uv, vec2(-0.306, 0.189), vec2(-0.266, -0.062),vec2(0.044, -0.082)));
	d = min(d, s(uv, vec2(0.044, -0.082), vec2(0.264, -0.083),vec2(0.297, 0.071)));
	d = min(d, s(uv, vec2(-0.175, 0.287), vec2(0.013, 0.225),vec2(0.105, -0.135)));
	d = min(d, s(uv, vec2(-0.292, -0.237), vec2(0.022, -0.228),vec2(0.243, -0.266)));
	d = min(d, s(uv, vec2(-0.097, -0.348), vec2(-0.131, 0.113),vec2(-0.035, 0.28)));
	return min(d, s(uv, vec2(0.033, 0.333), vec2(0.313, 0.299),vec2(0.297, 0.073)));
}
float h2(vec2 uv) { // i
	float d = s(uv, vec2(-0.121, 0.271), vec2(-0.309, 0.317),vec2(-0.292, -0.274));
	d = min(d, s(uv, vec2(0.319, 0.198), vec2(0.304, -0.062),vec2(0.175, -0.231)));
	return min(d, s(uv, vec2(-0.121, 0.271), vec2(-0.037, 0.246),vec2(-0.028, 0.084)));
}
float h3(vec2 uv) { // u
	float d = s(uv, vec2(0.217, 0.143), vec2(0.12, 0.291),vec2(-0.129, 0.314));
	d = min(d, s(uv, vec2(0.198, -0.084), vec2(0.306, -0.01),vec2(0.218, 0.141)));
	d = min(d, s(uv, vec2(-0.195, -0.327), vec2(-0.037, -0.298),vec2(0.175, -0.283)));
	return min(d, s(uv, vec2(0.197, -0.085), vec2(0.072, -0.162),vec2(-0.274, -0.065)));
}
float h4(vec2 uv) { // e
	float d = s(uv, vec2(0.093, 0.171), vec2(0.101, 0.386),vec2(0.345, 0.277));
	d = min(d, s(uv, vec2(0.093, 0.17), vec2(0.081, -0.032),vec2(-0.311, 0.298)));
	d = min(d, s(uv, vec2(-0.173, -0.337), vec2(-0.037, -0.298),vec2(0.175, -0.283)));
	d = min(d, s(uv, vec2(0.165, -0.151), vec2(0.065, -0.14),vec2(-0.253, -0.119)));
	return min(d, l(uv, vec2(0.1651, -0.1503), vec2(-0.3101, 0.2973)));
}
float h5(vec2 uv) { // o
	float d = s(uv, vec2(-0.103, 0.022), vec2(0.111, -0.047),vec2(0.23, 0.027));
	d = min(d, s(uv, vec2(0.23, 0.027), vec2(0.357, 0.119),vec2(0.263, 0.249)));
	d = min(d, s(uv, vec2(-0.286, 0.265), vec2(-0.414, 0.155),vec2(-0.104, 0.022)));
	d = min(d, s(uv, vec2(-0.12, 0.192), vec2(-0.121, 0.383),vec2(-0.286, 0.265)));
	d = min(d, s(uv, vec2(0.262, 0.25), vec2(0.158, 0.376),vec2(0.033, 0.244)));
	d = min(d,s(uv, vec2(-0.305, -0.181), vec2(-0.074, -0.182),vec2(0.073, -0.214)));
	d = min(d, s(uv, vec2(0.337, -0.131), vec2(0.27, -0.219),vec2(0.169, -0.277)));
	return min(d, l(uv, vec2(-0.12, -0.3504), vec2(-0.12, 0.19)));
}
float h6(vec2 uv) { // ka
	float d = s(uv, vec2(-0.342, -0.13), vec2(-0.206, -0.147),vec2(-0.112, -0.156));
	d = min(d, s(uv, vec2(0.094, -0.046), vec2(0.082, -0.181),vec2(-0.11, -0.156)));
	d = min(d, s(uv, vec2(0.06, 0.239), vec2(0.107, 0.114),vec2(0.094, -0.045)));
	d = min(d, s(uv, vec2(0.06, 0.239), vec2(0.02, 0.345),vec2(-0.145, 0.271)));
	d = min(d, s(uv, vec2(0.34, 0.083), vec2(0.274, -0.103),vec2(0.176, -0.235)));
	return min(d, s(uv, vec2(-0.104, -0.341), vec2(-0.184, 0.092),vec2(-0.326, 0.304)));
}
float h7(vec2 uv) { // ki
	float d = s(uv, vec2(-0.048, -0.349), vec2(0.091, -0.023),vec2(0.239, 0.124));
	d = min(d, s(uv, vec2(-0.149, 0.087), vec2(0.033, 0.036),vec2(0.239, 0.124)));
	d = min(d, s(uv, vec2(-0.241, 0.176), vec2(-0.237, 0.116),vec2(-0.149, 0.087)));
	d = min(d, s(uv, vec2(-0.291, -0.051), vec2(-0.031, -0.05),vec2(0.294, -0.127)));
	d = min(d, s(uv, vec2(-0.29, -0.209), vec2(0.027, -0.217),vec2(0.239, -0.278)));
	return min(d, s(uv, vec2(0.201, 0.288), vec2(-0.252, 0.38),vec2(-0.241, 0.176)));
}
float h8(vec2 uv) { // ku
	float d = s(uv, vec2(0.147, -0.329), vec2(0.018, -0.207),vec2(-0.186, -0.07));
	d = min(d, s(uv, vec2(-0.186, -0.07), vec2(-0.254, -0.02),vec2(-0.191, 0.025)));
	return min(d, s(uv, vec2(-0.19, 0.026), vec2(0.028947, 0.168335),vec2(0.183612, 0.325139)));
}
float h9(vec2 uv) // ke
{
	float d = s(uv, vec2(0.183, -0.332), vec2(0.265, 0.268),vec2(-0.009, 0.328));
	d = min(d, s(uv, vec2(-0.099, -0.136), vec2(0.076, -0.12),vec2(0.332, -0.158)));
	return min(d, s(uv, vec2(-0.229, -0.323), vec2(-0.309, 0.089),vec2(-0.235, 0.298)));
}
float h10(vec2 uv) // ko
{
	float d = s(uv, vec2(-0.225, -0.272), vec2(0.00429, -0.252796),vec2(0.208268, -0.268477));
	d = min(d, s(uv, vec2(-0.002435, -0.145273), vec2(0.093951, -0.205755),vec2(0.208268, -0.266237)));
	return min(d, s(uv, vec2(0.266548, 0.255698), vec2(-0.452981, 0.36098),vec2(-0.195206, 0.009291)));
}
float h11(vec2 uv) // sa
{
	float d = s(uv, vec2(-0.048, -0.349), vec2(0.091, -0.023),vec2(0.239, 0.124));
	d = min(d, s(uv, vec2(-0.149, 0.087), vec2(0.033, 0.036),vec2(0.239, 0.124)));
	d = min(d, s(uv, vec2(-0.241, 0.176), vec2(-0.237, 0.116),vec2(-0.149, 0.087)));
	d = min(d,s(uv, vec2(-0.300558, -0.165434), vec2(-0.011401, -0.149753),vec2(0.275514, -0.234876)));
	return min(d, s(uv, vec2(0.201, 0.288), vec2(-0.252, 0.38),vec2(-0.241, 0.176)));
}
float h12(vec2 uv) // shi
{
	float d = s(uv, vec2(-0.068, 0.306), vec2(-0.201, 0.289),vec2(-0.2, 0.072));
	d = min(d, s(uv, vec2(-0.065, 0.306), vec2(0.201, 0.343),vec2(0.306895, 0.038412)));
	return min(d, l(uv, vec2(-0.2, 0.07), vec2(-0.19, -0.33)));
}
float h13(vec2 uv) // su
{
	float d = s(uv, vec2(0.08, -0.056), vec2(0.076019, 0.125774),vec2(-0.051748, 0.136974));
	d = min(d, s(uv, vec2(-0.053, 0.137), vec2(-0.191, 0.142),vec2(-0.18, 0.004)));
	d = min(d, s(uv, vec2(-0.18, 0.004), vec2(-0.172, -0.057),vec2(-0.126, -0.082)));
	d = min(d, s(uv, vec2(0.044, -0.048), vec2(-0.038, -0.126),vec2(-0.124, -0.083)));
	d = min(d, s(uv, vec2(0.046, -0.052), vec2(0.124, 0.039),vec2(0.088, 0.146)));
	d = min(d, s(uv, vec2(0.087226, 0.148175), vec2(0.046, 0.276),vec2(-0.149, 0.316)));
	d = min(d,s(uv, vec2(0.336035, -0.230396), vec2(-0.002435, -0.234876),vec2(-0.340905, -0.214715)));
	return min(d, l(uv, vec2(0.08, -0.0559), vec2(0.08, -0.35)));
}
float h14(vec2 uv) // se
{
	float d = s(uv, vec2(0.353967, -0.147513), vec2(0.015497, -0.136313),vec2(-0.352113, -0.113912));
	d = min(d, s(uv, vec2(-0.18, 0.163), vec2(-0.179515, 0.3565),vec2(0.282239, 0.264658)));
	d = min(d, s(uv, vec2(0.146, 0.08), vec2(0.188095, 0.027211),vec2(0.179129, -0.328958)));
	d = min(d, s(uv, vec2(0.146, 0.08), vec2(0.097, 0.135),vec2(-0.018126, 0.072013)));
	return min(d, l(uv, vec2(-0.18, -0.31), vec2(-0.18, 0.16)));
}
float h15(vec2 uv) // so
{
	float d = s(uv, vec2(0.174646, -0.31), vec2(-0.015884, -0.291),vec2(-0.215, -0.299));
	d = min(d, s(uv, vec2(0.174, -0.308), vec2(-0.097, -0.062),vec2(-0.324, -0.006)));
	d = min(d, s(uv, vec2(0.33, -0.062), vec2(0.042, -0.057),vec2(-0.332, -0.006)));
	d = min(d, s(uv, vec2(0.209, 0.309459), vec2(-0.077, 0.313),vec2(-0.068, 0.163)));
	return min(d, s(uv, vec2(-0.068, 0.162), vec2(-0.056231, 0.013771),vec2(0.33, -0.062)));
}
float h16(vec2 uv) // ta
{
	float d = s(uv, vec2(0.067052, -0.223675), vec2(-0.139168, -0.190074),vec2(-0.331939, -0.194555));
	d = min(d, s(uv, vec2(-0.309524, 0.296019), vec2(-0.192964, 0.058572),vec2(-0.114511, -0.353599)));
	d = min(d, s(uv, vec2(0.291205, -0.104952), vec2(0.129815, -0.111672),vec2(0.008773, -0.087032)));
	return min(d, s(uv, vec2(-0.015884, 0.103373), vec2(-0.177274, 0.36098),vec2(0.322586, 0.289298)));
}
float h17(vec2 uv) // chi
{
	float d = s(uv, vec2(-0.237155, 0.111585), vec2(-0.124465, -0.108956),vec2(-0.054034, -0.343574));
	d = min(d, s(uv, vec2(-0.305239, -0.205149), vec2(-0.082206, -0.193419),vec2(0.255865, -0.226265)));
	d = min(d, s(uv, vec2(0.241779, 0.048238), vec2(0.061, -0.086),vec2(-0.236, 0.111)));
	d = min(d,s(uv, vec2(0.243, 0.23), vec2(0.139, 0.362),vec2(-0.194, 0.278164)));
	return min(d, s(uv, vec2(0.243, 0.23), vec2(0.323, 0.113),vec2(0.243, 0.049)));
}
float h18(vec2 uv) // tsu
{
	float d = s(uv, vec2(0.3, -0.072), vec2(0.237, -0.307),vec2(-0.324021, -0.165264));
	d = min(d, s(uv, vec2(0.188, 0.182), vec2(0.324, 0.099),vec2(0.300471, -0.066725)));
	return min(d, s(uv, vec2(-0.145594, 0.251), vec2(0.047, 0.253),vec2(0.186, 0.183)));
}
float h19(vec2 uv) // te
{
	float d = s(uv, vec2(0.326296, -0.275535), vec2(0.190129, -0.280227),vec2(-0.316978, -0.233304));
	d = min(d, s(uv, vec2(0.324, -0.274), vec2(-0.063424, -0.179),vec2(-0.071, 0.045)));
	return min(d, s(uv, vec2(-0.071, 0.048), vec2(-0.077, 0.259),vec2(0.227692, 0.292241)));
}
float h20(vec2 uv) { // to
	float d = s(uv, vec2(-0.256, 0.164), vec2(-0.26298, -0.045609),vec2(0.234735, -0.160572));
	d = min(d, s(uv, vec2(0.255, 0.274), vec2(-0.235, 0.353242),vec2(-0.256, 0.166)));
	return min(d, s(uv, vec2(-0.132, -0.336536), vec2(-0.099, -0.158226),vec2(-0.062, -0.066)));
}
float h21(vec2 uv) { // na
	float d = s(uv, vec2(-0.333, -0.191072), vec2(-0.183158, -0.193419),vec2(0.011702, -0.212188));
	d = min(d, s(uv, vec2(-0.325, 0.195), vec2(-0.205, 0.013),vec2(-0.118, -0.355)));
	d = min(d, s(uv, vec2(0.131436, -0.233304), vec2(0.248822, -0.188726),vec2(0.323949, -0.132418)));
	d = min(d, s(uv, vec2(-0.028209, 0.315703), vec2(0.161956, 0.357934),vec2(0.161956, 0.20074)));
	d = min(d,s(uv, vec2(-0.032, 0.315), vec2(-0.162, 0.274),vec2(-0.098, 0.164)));
	d = min(d, s(uv, vec2(0.333, 0.259395), vec2(0.251, 0.171),vec2(0.128, 0.129)));
	d = min(d, s(uv, vec2(-0.096292, 0.160855), vec2(-0.041, 0.079),vec2(0.128, 0.129)));
	return min(d, l(uv, vec2(0.161956, 0.198394), vec2(0.143175, -0.083148)));
}
float h22(vec2 uv) { // ni
	float d = s(uv, vec2(-0.251242, 0.322742), vec2(-0.312282, 0.02243),vec2(-0.23246, -0.327151));
	d = min(d, s(uv, vec2(0.288733, -0.230957), vec2(0.086829, -0.207496),vec2(-0.063424, -0.219227)));
	return min(d, s(uv, vec2(0.324, 0.24), vec2(-0.25, 0.329),vec2(-0.032, 0.024)));
}
float h23(vec2 uv) { // nu
	float d = s(uv, vec2(-0.071, 0.214817), vec2(-0.214, -0.052648),vec2(-0.230112, -0.294304));
	d = min(d, s(uv, vec2(0.070395, -0.33419), vec2(0.025789, 0.010699),vec2(-0.151, 0.224)));
	d = min(d, s(uv, vec2(-0.284, 0.239), vec2(-0.212, 0.285),vec2(-0.152, 0.225)));
	d = min(d,s(uv, vec2(-0.04, -0.194), vec2(-0.171, -0.165264),vec2(-0.241, -0.081)));
	d = min(d, s(uv, vec2(0.284037, -0.073763), vec2(0.187781, -0.233304),vec2(-0.04, -0.194)));
	d = min(d, s(uv, vec2(0.268, 0.214), vec2(0.354, 0.082),vec2(0.285, -0.072)));
	d = min(d, s(uv, vec2(0.268, 0.214), vec2(0.163, 0.35),vec2(0.058, 0.261)));
	d = min(d, s(uv, vec2(0.056, 0.144), vec2(0.004, 0.199),vec2(0.058, 0.261)));
	d = min(d, s(uv, vec2(0.057, 0.143), vec2(0.173, 0.043),vec2(0.367, 0.271)));
	return min(d, s(uv, vec2(-0.284, 0.239), vec2(-0.415, 0.138),vec2(-0.242, -0.08)));
}
float h24(vec2 uv) { // ne
	float d = s(uv, vec2(-0.183158, -0.34592), vec2(-0.20194, 0.076392),vec2(-0.194896, 0.334473));
	d = min(d, s(uv, vec2(0.183, -0.196), vec2(0.011, -0.27),vec2(-0.354, 0.189)));
	d = min(d, s(uv, vec2(0.028137, 0.287549), vec2(0.24, 0.369),vec2(0.283, 0.132)));
	d = min(d,s(uv, vec2(-0.006, 0.173), vec2(-0.043, 0.25),vec2(0.027, 0.287)));
	d = min(d, s(uv, vec2(0.153, 0.123), vec2(0.032, 0.099),vec2(-0.006, 0.173)));
	d = min(d, s(uv, vec2(0.183, -0.196), vec2(0.32, -0.135),vec2(0.283, 0.132)));
	d = min(d, s(uv, vec2(0.376, 0.28), vec2(0.301, 0.16),vec2(0.153, 0.123)));
	d = min(d, l(uv, vec2(-0.157333, -0.193419), vec2(-0.1908, -0.1535)));
	return min(d, l(uv, vec2(-0.157333, -0.193419), vec2(-0.340455, -0.174649)));
}
float h25(vec2 uv) { // no
	float d = s(uv, vec2(0.008, -0.284), vec2(-0.042536, 0.308529),vec2(-0.225215, 0.238869));
	d = min(d, s(uv, vec2(-0.31, -0.036), vec2(-0.361, 0.174012),vec2(-0.225215, 0.238869)));
	d = min(d, s(uv, vec2(0.008, -0.284), vec2(-0.226, -0.28),vec2(-0.31, -0.036)));
	d = min(d, s(uv, vec2(0.313, -0.032), vec2(0.338, 0.241),vec2(0.021, 0.298)));
	return min(d, s(uv, vec2(0.008, -0.284), vec2(0.289169, -0.275179),vec2(0.313, -0.032)));
}
float h26(vec2 uv) { // ha
	float d = s(uv, vec2(-0.256402, 0.326023), vec2(-0.338065, 0.035291),vec2(-0.239389, -0.335351));
	d = min(d, s(uv, vec2(-0.113493, -0.165332), vec2(0.196145, -0.167032),vec2(0.328846, -0.184034)));
	d = min(d, s(uv, vec2(-0.042, 0.125), vec2(0.105975, 0.042091),vec2(0.350963, 0.247815)));
	d = min(d, s(uv, vec2(-0.066, 0.27), vec2(-0.128, 0.18),vec2(-0.042, 0.125)));
	d = min(d, s(uv, vec2(-0.066, 0.27), vec2(0, 0.336),vec2(0.097, 0.298)));
	d = min(d, s(uv, vec2(0.179132, 0.174706), vec2(0.180833, 0.264817),vec2(0.097, 0.298)));
	return min(d, l(uv, vec2(0.16, -0.338752), vec2(0.179132, 0.174706)));
}
float h27(vec2 uv) { // hi
	float d = s(uv, vec2(-0.322753, -0.262243), vec2(-0.20196, -0.255442),vec2(-0.050544, -0.297947));
	d = min(d, s(uv, vec2(-0.050544, -0.297947), vec2(-0.397, 0.085),vec2(-0.215571, 0.261416)));
	d = min(d, s(uv, vec2(-0.215571, 0.261416), vec2(-0.142, 0.334),vec2(0.002, 0.299)));
	d = min(d, s(uv, vec2(0.128, -0.295), vec2(0.253989, -0.031017),vec2(0.354366, 0.013188)));
	return min(d, s(uv, vec2(0.002, 0.299), vec2(0.274404, 0.222),vec2(0.128, -0.295)));
}
float h28(vec2 uv) { // fu
	float d = s(uv, vec2(-0.336363, 0.275018), vec2(-0.252999, 0.076095),vec2(-0.244493, -0.010615));
	d = min(d, s(uv, vec2(0.167222, -0.255442), vec2(-0.026726, -0.255442),vec2(-0.198558, -0.314949)));
	d = min(d, s(uv, vec2(0.167222, -0.255442), vec2(-0.166233, -0.14323),vec2(-0.009713, 0.009788)));
	d = min(d, s(uv, vec2(-0.009713, 0.009788), vec2(0.235274, 0.241014),vec2(0, 0.310722)));
	d = min(d, s(uv, vec2(0, 0.310722), vec2(-0.125402, 0.334524),vec2(-0.181545, 0.237613)));
	return min(d, s(uv, vec2(0.342457, 0.261416), vec2(0.311833, 0.106699),vec2(0.219963, -0.017415)));
}
float h29(vec2 uv) { // he
	float d = s(uv, vec2(-0.030129, -0.173833), vec2(-0.101583, -0.267344),vec2(-0.171337, -0.163632));
	d = min(d, s(uv, vec2(-0.030129, -0.173833), vec2(0.175729, 0.084596),vec2(0.35947, 0.225712)));
	return min(d, l(uv, vec2(-0.351675, 0.081196), vec2(-0.171337, -0.163632)));
}
float h30(vec2 uv) { // ho
	float d = s(uv, vec2(-0.256402, 0.326023), vec2(-0.338065, 0.035291),vec2(-0.239389, -0.335351));
	d = min(d, s(uv, vec2(-0.042, 0.125), vec2(0.105975, 0.042091),vec2(0.350963, 0.247815)));
	d = min(d, s(uv, vec2(-0.066, 0.27), vec2(-0.128, 0.18),vec2(-0.042, 0.125)));
	d = min(d, s(uv, vec2(-0.066, 0.27), vec2(0, 0.336),vec2(0.097, 0.298)));
	d = min(d, s(uv, vec2(0.179132, 0.174706), vec2(0.180833, 0.264817),vec2(0.097, 0.298)));
	d = min(d, s(uv, vec2(0.310132, -0.301347), vec2(0.078755, -0.272444),vec2(-0.087973, -0.284346)));
	d = min(d, s(uv, vec2(-0.093077, -0.085423), vec2(0.100872, -0.073522),vec2(0.318638, -0.102425)));
	return min(d, l(uv, vec2(0.16, -0.285), vec2(0.179132, 0.174706)));
}
float h31(vec2 uv) { // ma
	float d = s(uv, vec2(-0.289987, -0.236059), vec2(0.088339, -0.219379),vec2(0.290021, -0.254129));
	d = min(d, s(uv, vec2(-0.281642, -0.066479), vec2(0.022967, -0.055359),vec2(0.291412, -0.088719)));
	d = min(d, s(uv, vec2(0.301148, 0.27685), vec2(0.032703, 0.053061),vec2(-0.200969, 0.121171)));
	d = min(d, s(uv, vec2(-0.200969, 0.121171), vec2(-0.288596, 0.15592),vec2(-0.26356, 0.23237)));
	d = min(d, s(uv, vec2(-0.26356, 0.23237), vec2(-0.214757, 0.327384),vec2(-0.076284, 0.311293)));
	d = min(d, s(uv, vec2(-0.076284, 0.311293), vec2(0.039647, 0.283938),vec2(0.027139, 0.16426)));
	return min(d, l(uv, vec2(0.01184, -0.348649), vec2(0.027139, 0.16426)));
}
float h32(vec2 uv) { // mi
	float d = s(uv, vec2(-0.05, -0.31), vec2(0.010664, -0.313037),vec2(-0.008658, -0.232582));
	d = min(d, s(uv, vec2(-0.008658, -0.232582), vec2(-0.079504, 0.081192),vec2(-0.16, 0.19061)));
	d = min(d, s(uv, vec2(-0.16, 0.19061), vec2(-0.27, 0.309),vec2(-0.321026, 0.176129)));
	d = min(d, s(uv, vec2(-0.321026, 0.176129), vec2(-0.36, 0.07),vec2(-0.25179, -0.005699)));
	d = min(d, s(uv, vec2(-0.25179, -0.005699), vec2(-0.005438, -0.1473),vec2(0.353625, 0.143947)));
	d = min(d, s(uv, vec2(0.239305, -0.190745), vec2(0.242525, 0.235665),vec2(0.012274, 0.322556)));
	return min(d, l(uv, vec2(-0.27, -0.3), vec2(-0.05, -0.31)));
}
float h33(vec2 uv) { // mu
	float d = s(uv, vec2(-0.303541, -0.22891), vec2(-0.141159, -0.225933),vec2(0.062935, -0.243798));
	d = min(d, s(uv, vec2(0.189563, -0.267618), vec2(0.261071, -0.212534),vec2(0.334068, -0.10832)));
	d = min(d, s(uv, vec2(0.140402, 0.302581), vec2(0.337048, 0.251962),vec2(0.222338, 0.048001)));
	d = min(d, s(uv, vec2(0.140402, 0.302581), vec2(0.003346, 0.32789),vec2(-0.13818, 0.305558)));
	d = min(d, s(uv, vec2(-0.13818, 0.305558), vec2(-0.240972, 0.26685),vec2(-0.157547, 0.131372)));
	d = min(d, s(uv, vec2(-0.157547, 0.131372), vec2(-0.036, -0.081522),vec2(-0.211177, -0.0845)));
	d = min(d, s(uv, vec2(-0.211177, -0.0845), vec2(-0.332589, -0.069282),vec2(-0.316597, 0.06841)));
	d = min(d, s(uv, vec2(-0.316597, 0.06841), vec2(-0.301834, 0.175368),vec2(-0.209569, 0.147092)));
	d = min(d, s(uv, vec2(-0.209569, 0.147092), vec2(-0.154, 0.129),vec2(-0.126, 0.06841)));
	return min(d, l(uv, vec2(-0.133711, -0.066), vec2(-0.130731, -0.343545)));
}
float h34(vec2 uv) { // me
	float d = s(uv, vec2(-0.031688, 0.203557), vec2(-0.129642, 0.119877),vec2(-0.205478, -0.312734));
	d = min(d, s(uv, vec2(0.101024, -0.341154), vec2(0.00465, 0.197241),vec2(-0.197578, 0.247765)));
	d = min(d, s(uv, vec2(-0.197578, 0.247765), vec2(-0.32397, 0.261975),vec2(-0.319231, 0.108824)));
	d = min(d, s(uv, vec2(-0.319231, 0.108824), vec2(-0.317651, -0.056957),vec2(-0.15966, -0.15169)));
	d = min(d, s(uv, vec2(-0.15966, -0.15169), vec2(0.097864, -0.27642),vec2(0.262174, -0.121691)));
	d = min(d, s(uv, vec2(0.262174, -0.121691), vec2(0.377507, 0.006198),vec2(0.279553, 0.160927)));
	return min(d, s(uv, vec2(0.279553, 0.160927), vec2(0.198978, 0.280922),vec2(0.00623, 0.307762)));
}
float h35(vec2 uv) { // mo
	float d = s(uv, vec2(-0.284473, -0.214844), vec2(-0.071186, -0.183267),vec2(0.131042, -0.202213));
	d = min(d, s(uv, vec2(-0.311331, -0.008012), vec2(-0.112263, 0.026723),vec2(0.115243, 0.012513)));
	d = min(d, l(uv, vec2(-0.072766, -0.341154), vec2(-0.143861, 0.081984)));
	d = min(d, s(uv, vec2(-0.143861, 0.081984), vec2(-0.1723, 0.329867),vec2(0.037828, 0.320393)));
	return min(d, s(uv, vec2(0.037828, 0.320393), vec2(0.402785, 0.315657),vec2(0.230576, -0.017485)));
}
float h36(vec2 uv) { // ya
	float d = s(uv, vec2(-0.230756, -0.317471), vec2(-0.082245, 0.113561),vec2(-0.044327, 0.340919));
	d = min(d, s(uv, vec2(-0.33187, -0.069588), vec2(-0.012729, -0.227475),vec2(0.184, -0.211687)));
	d = min(d, s(uv, vec2(0.32063, -0.058536), vec2(0.344329, -0.188004),vec2(0.184, -0.211687)));
	d = min(d, s(uv, vec2(0.32063, -0.058536), vec2(0.279553, 0.148296),vec2(0.028348, 0.066195)));
	return min(d, l(uv, vec2(0.061526, -0.352206), vec2(0.069426, -0.210108)));
}
float h37(vec2 uv) { // yu
	float d = s(uv, vec2(-0.287633, 0.19882), vec2(-0.320811, 0.020408),vec2(-0.270254, -0.295367));
	d = min(d, s(uv, vec2(-0.287633, 0.19882), vec2(-0.200738, -0.257474),vec2(0.131, -0.229)));
	d = min(d, s(uv, vec2(0.131, -0.229), vec2(0.344329, -0.199056),vec2(0.319051, 0.00304)));
	d = min(d, s(uv, vec2(0.319051, 0.00304), vec2(0.300092, 0.151454),vec2(0.132, 0.203)));
	d = min(d, s(uv, vec2(0.132, 0.203), vec2(-0.044327, 0.24145),vec2(-0.134382, 0.067774)));
	d = min(d, s(uv, vec2(-0.104364, 0.342498), vec2(0.151581, 0.238292),vec2(0.052047, -0.353785)));
	return d;
}
float h38(vec2 uv) { // yo
	float d = s(uv, vec2(0.035258, 0.165025), vec2(0.004476, -0.077452),vec2(0.000854, -0.343454));
	d = min(d, s(uv, vec2(0.035258, 0.165025), vec2(0.046122, 0.284454),vec2(-0.037171, 0.298931)));
	d = min(d, s(uv, vec2(-0.037171, 0.298931), vec2(-0.22, 0.34),vec2(-0.274375, 0.253692)));
	d = min(d, s(uv, vec2(-0.274375, 0.253692), vec2(-0.344, 0.121),vec2(-0.13676, 0.090834)));
	d = min(d, s(uv, vec2(-0.13676, 0.090834), vec2(0.125, 0.06),vec2(0.286947, 0.273597)));
	return min(d, s(uv, vec2(0.288758, -0.187834), vec2(0.142, -0.155),vec2(0.00666, -0.163)));
}
float h39(vec2 uv) { // ra
	float d = s(uv, vec2(-0.154067, -0.319705), vec2(0.029707, -0.278893),vec2(0.181924, -0.256632));
	d = min(d, s(uv, vec2(-0.256163, 0.099545), vec2(-0.241313, -0.063703),vec2(-0.209756, -0.165733)));
	d = min(d, s(uv, vec2(-0.256163, 0.099545), vec2(-0.085383, -0.048862),vec2(0.096534, -0.028456)));
	d = min(d, s(uv, vec2(0.096534, -0.028456), vec2(0.328, -0.001),vec2(0.263601, 0.181169)));
	return min(d, s(uv, vec2(0.263601, 0.181169), vec2(0.196, 0.344837),vec2(-0.196054, 0.288222)));
}
float h40(vec2 uv) { // ri
	float d = s(uv, vec2(-0.208931, 0.109127), vec2(-0.260077, -0.097026),vec2(-0.171424, -0.345772));
	d = min(d, s(uv, vec2(-0.208931, 0.109127), vec2(-0.127098, -0.28103),vec2(0.041683, -0.279326)));
	d = min(d, s(uv, vec2(0.041683, -0.279326), vec2(0.166137, -0.279326),vec2(0.207054, -0.153249)));
	d = min(d, s(uv, vec2(0.207054, -0.153249), vec2(0.259904, 0.046088),vec2(0.174661, 0.175573)));
	return min(d, s(uv, vec2(0.174661, 0.175573), vec2(0.099648, 0.303353),vec2(-0.120278, 0.330613)));
}
float h41(vec2 uv) { // ru
	float d = s(uv, vec2(0.179776, -0.309994), vec2(-0.014578, -0.291252),vec2(-0.21916, -0.298067));
	d = min(d, s(uv, vec2(0.179776, -0.309994), vec2(0.033158, -0.141323),vec2(-0.309517, 0.081867)));
	d = min(d, s(uv, vec2(-0.309517, 0.081867), vec2(0.123516, -0.132804),vec2(0.25479, 0.022236)));
	d = min(d, s(uv, vec2(0.25479, 0.022236), vec2(0.331508, 0.109127),vec2(0.249675, 0.221574)));
	d= min(d, s(uv, vec2(0.249675, 0.221574), vec2(0.150793, 0.330613),vec2(-0.038445, 0.31528)));
	d = min(d, s(uv, vec2(-0.038445, 0.31528), vec2(-0.209385, 0.293077),vec2(-0.168507, 0.176974)));
	d = min(d, s(uv, vec2(-0.168507, 0.176974), vec2(-0.134084, 0.121072),vec2(-0.041571, 0.136123)));
	d = min(d, s(uv, vec2(0.25479, 0.022236), vec2(0.331508, 0.109127),vec2(0.249675, 0.221574)));
	return min(d, s(uv, vec2(-0.041571, 0.136123), vec2(0.088, 0.169),vec2(0.074607, 0.312)));
}
float h42(vec2 uv) { // re
	float d = s(uv, vec2(-0.183158, -0.34592), vec2(-0.20194, 0.076392),vec2(-0.194896, 0.334473));
	d = min(d,  s(uv, vec2(0.152, -0.219), vec2(0.011, -0.27),vec2(-0.354, 0.189)));
	d = min(d, s(uv, vec2(0.152, -0.219), vec2(0.247138, -0.197006),vec2(0.203037, -0.049533)));
	d = min(d, s(uv, vec2(0.203037, -0.049533), vec2(0.158936, 0.121671),vec2(0.177594, 0.243718)));
	d = min(d, s(uv, vec2(0.177594, 0.243718), vec2(0.201, 0.318),vec2(0.267493, 0.279315)));
	d = min(d, l(uv, vec2(-0.157333, -0.193419), vec2(-0.1908, -0.1535)));
	return min(d, l(uv, vec2(-0.157333, -0.193419), vec2(-0.340455, -0.174649)));
}
float h43(vec2 uv) { // ro
	float d = s(uv, vec2(0.17433, -0.296286), vec2(-0.09899, -0.280485),vec2(-0.214191, -0.287257));
	d = min(d, s(uv, vec2(0.17433, -0.296286), vec2(-0.026707, -0.086351),vec2(-0.306803, 0.098753)));
	d = min(d, s(uv, vec2(-0.306803, 0.098753), vec2(-0.159979, 0.008458),vec2(0.036541, -0.027659)));
	d = min(d, s(uv, vec2(0.036541, -0.027659), vec2(0.251131, -0.057005),vec2(0.29179, 0.085209)));
	return min(d, s(uv, vec2(0.29179, 0.085209), vec2(0.321155, 0.36738),vec2(-0.184826, 0.286115)));
}
float h44(vec2 uv) { // wa
	float d = s(uv, vec2(0.041058, -0.163101), vec2(-0.159979, -0.097638),vec2(-0.345204, 0.180018));
	d = min(d, s(uv, vec2(0.041058, -0.163101), vec2(0.287272, -0.228565),vec2(0.318896, 0.012973)));
	d = min(d, s(uv, vec2(0.318896, 0.012973), vec2(0.343743, 0.23871),vec2(0.034282, 0.279343)));
	d = min(d, l(uv, vec2(-0.19, 0.34), vec2(-0.18, -0.35)));
	d = min(d, l(uv, vec2(-0.342945, -0.176646), vec2(-0.144167, -0.196962)));
	return min(d, l(uv, vec2(-0.1833, -0.12), vec2(-0.144167, -0.196962)));
}
float h45(vec2 uv) { // wo
	float d = s(uv, vec2(0.236574, -0.261088), vec2(-0.012916, -0.21905),vec2(-0.305921, -0.234996));
	d = min(d, s(uv, vec2(-0.034674, -0.348063), vec2(-0.095596, -0.169765),vec2(-0.317526, 0.073764)));
	d = min(d, s(uv, vec2(-0.317526, 0.073764), vec2(0.136488, -0.303126),vec2(0.075566, 0.175234)));
	d = min(d, s(uv, vec2(-0.098497, 0.296999), vec2(-0.326229, 0.127398),vec2(0.330858, -0.059597)));
	return min(d, s(uv, vec2(-0.098497, 0.296999), vec2(0.009, 0.362),vec2(0.288793, 0.305696)));
}
float h46(vec2 uv) { // n
	float d = s(uv, vec2(-0.32093, 0.31), vec2(-0.171901, -0.1093),vec2(-0.083194, -0.33));
	d = min(d, s(uv, vec2(-0.32093, 0.31), vec2(-0.145289, -0.068),vec2(-0.002, -0.027)));
	d = min(d, s(uv, vec2(-0.002, -0.027), vec2(0.066, -0.011),vec2(0.060512, 0.18679)));
	d = min(d, s(uv, vec2(0.146704, 0.305019), vec2(0.300997, 0.314903),vec2(0.332647, 0.081638)));
	return min(d, s(uv, vec2(0.060512, 0.18679), vec2(0.071536, 0.303042),vec2(0.146704, 0.305019)));
}
float hiragana(vec2 p, int char, float scale, int gs, float bevel, float rad)
{
	char = int(fract(float(gs > 1 ? char: char - 1)/46.0)*47.0)+1;
		
	float s = 1.0/scale;
	p *= s;
	
	float d = 1.0;
	
	if (char == 1) d = h1(p);
	if (char == 2) d = h2(p);
	if (char == 3) d = h3(p);
	if (char == 4) d = h4(p);
	if (char == 5) d = h5(p);
	if (char == 6) d = h6(p);
	if (char == 7) d = h7(p);
	if (char == 8) d = h8(p);
	if (char == 9) d = h9(p);
	if (char == 10) d = h10(p);
	if (char == 11) d = h11(p);
	if (char == 12) d = h12(p);
	if (char == 13) d = h13(p);
	if (char == 14) d = h14(p);
	if (char == 15) d = h15(p);
	if (char == 16) d = h16(p);
	if (char == 17) d = h17(p);
	if (char == 18) d = h18(p);
	if (char == 19) d = h19(p);
	if (char == 20) d = h20(p);
	if (char == 21) d = h21(p);
	if (char == 22) d = h22(p);
	if (char == 23) d = h23(p);
	if (char == 24) d = h24(p);
	if (char == 25) d = h25(p);
	if (char == 26) d = h26(p);
	if (char == 27) d = h27(p);
	if (char == 28) d = h28(p);
	if (char == 29) d = h29(p);
	if (char == 30) d = h30(p);
	if (char == 31) d = h31(p);
	if (char == 32) d = h32(p);
	if (char == 33) d = h33(p);
	if (char == 34) d = h34(p);
	if (char == 35) d = h35(p);
	if (char == 36) d = h36(p);
	if (char == 37) d = h37(p);
	if (char == 38) d = h38(p);
	if (char == 39) d = h39(p);
	if (char == 40) d = h40(p);
	if (char == 41) d = h41(p);
	if (char == 42) d = h42(p);
	if (char == 43) d = h43(p);
	if (char == 44) d = h44(p);
	if (char == 45) d = h45(p);
	if (char == 46) d = h46(p);
	return 1.0-clamp(0.0-(d-rad)/max(bevel, 0.00001), 0.0, 1.0);
}
float c_h(vec2 p, int char, float scale, int gs, float bevel, float rad) {
	if(gs > 1) {
		if(box(p,0.5) > 0.0) {
			vec3 gr = grid(p,gs);
			return hiragana(gr.xy,int(gr.z),scale,gs,bevel,rad);
		}
		return 1.0;
	}
	if (box(p,0.5*scale) > 0.0)
		return hiragana(p,char,scale,gs,bevel,rad);
	return 1.0;
}
float katakana(vec2 p, int char, float scale, int gs, float bevel, float rad)
{
	char = int(fract(float(gs > 1 ? char: char - 1)/46.0)*47.0)+1;
		
	float s = 1.0/scale;
	p *= s;
	
	float d = 1.0;
	
	if (char == 1) d = k1(p);
	if (char == 2) d = k2(p);
	if (char == 3) d = k3(p);
	if (char == 4) d = k4(p);
	if (char == 5) d = k5(p);
	if (char == 6) d = k6(p);
	if (char == 7) d = k7(p);
	if (char == 8) d = k8(p);
	if (char == 9) d = k9(p);
	if (char == 10) d = k10(p);
	if (char == 11) d = k11(p);
	if (char == 12) d = k12(p);
	if (char == 13) d = k13(p);
	if (char == 14) d = k14(p);
	if (char == 15) d = k15(p);
	if (char == 16) d = k16(p);
	if (char == 17) d = k17(p);
	if (char == 18) d = k18(p);
	if (char == 19) d = k19(p);
	if (char == 20) d = k20(p);
	if (char == 21) d = k21(p);
	if (char == 22) d = k22(p);
	if (char == 23) d = k23(p);
	if (char == 24) d = k24(p);
	if (char == 25) d = k25(p);
	if (char == 26) d = k26(p);
	if (char == 27) d = k27(p);
	if (char == 28) d = k28(p);
	if (char == 29) d = k29(p);
	if (char == 30) d = k30(p);
	if (char == 31) d = k31(p);
	if (char == 32) d = k32(p);
	if (char == 33) d = k33(p);
	if (char == 34) d = k34(p);
	if (char == 35) d = k35(p);
	if (char == 36) d = k36(p);
	if (char == 37) d = k37(p);
	if (char == 38) d = k38(p);
	if (char == 39) d = k39(p);
	if (char == 40) d = k40(p);
	if (char == 41) d = k41(p);
	if (char == 42) d = k42(p);
	if (char == 43) d = k43(p);
	if (char == 44) d = k44(p);
	if (char == 45) d = k45(p);
	if (char == 46) d = k46(p);
	return 1.0-clamp(0.0-(d-rad)/max(bevel, 0.00001), 0.0, 1.0);
}
float c_k(vec2 p, int char, float scale, int gs, float bevel, float rad) {
	if(gs > 1) {
		if(box(p,0.5) > 0.0) {
			vec3 gr = grid(p,gs);
			return katakana(gr.xy,int(gr.z),scale,gs,bevel,rad);
		}
		return 1.0;
	}
	if (box(p,0.5*scale) > 0.0)
		return katakana(p,char,scale,gs,bevel,rad);
	return 1.0;
}
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
const float p_o51418_d_in1_x = 0.000000000;
const float p_o51418_d_in1_y = 0.000000000;
const float p_o51418_d_in1_z = 0.000000000;
const float p_o51418_d_in2_x = 3.000000000;
const float p_o51418_d_in2_y = 0.500000000;
const float p_o51418_d_in2_z = 1.000000000;
const float p_o51417_default_in1 = 0.000000000;
const float p_o51417_default_in2 = 0.000000000;
const float p_o51412_default_in1 = 0.000000000;
const float p_o51412_default_in2 = 8.000000000;
const float p_o51414_default_in1 = 0.000000000;
const float p_o51414_default_in2 = 0.000000000;
const float p_o51413_default_in1 = 0.000000000;
const float p_o51413_default_in2 = 0.000000000;
const float p_o51408_repeat = 1.000000000;
const float p_o51408_rows = 32.000000000;
const float p_o51408_row_offset = 0.000000000;
const float p_o51408_mortar = 0.050000000;
const float p_o51408_bevel = 0.050000000;
const float p_o51408_round = 0.000000000;
const float p_o51408_corner = 0.300000000;
const float p_o51419_default_in1 = 0.000000000;
const float seed_o51416 = 0.000000000;
const float seed_o51410 = 0.517349422;
const float p_o51410_sx = -1.000000000;
const float p_o51410_sy = 1.000000000;
const float p_o51410_rotate = 0.000000000;
const float p_o51410_scale = 0.000000000;
const float seed_o51407 = 0.481335431;
const float p_o51407_scale = 1.000000000;
const float p_o51407_rad = 0.103000000;
const float p_o51407_gs = 1.000000000;
const float p_o51407_bevel = 0.024000000;
vec4 o51410_input_in(vec2 uv, float _seed_variation_) {
float o51407_0_1_f = 1.0 - c_k((uv)-0.5, int((param_rnd(1,46, (seed_o51407+fract(_seed_variation_))+0.841471))), p_o51407_scale, int(p_o51407_gs), p_o51407_bevel*1.0, p_o51407_rad);
return vec4(vec3(o51407_0_1_f), 1.0);
}
const float seed_o51409 = 0.000000000;
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec4 o51408_0_rect = bricks_rb((uv), vec2((p_o51408_rows), p_o51408_rows), p_o51408_repeat, p_o51408_row_offset);
vec4 o51408_0 = brick((uv), o51408_0_rect.xy, o51408_0_rect.zw, p_o51408_mortar*1.0, p_o51408_round*1.0, max(0.001, p_o51408_bevel*1.0), 1.0 / p_o51408_rows);vec4 o51408_1_2_fill = round(vec4(fract(o51408_0_rect.xy), o51408_0_rect.zw - o51408_0_rect.xy)*4096.0)/4096.0;
vec2 o51411_0_c = fract(o51408_1_2_fill.xy+0.5*o51408_1_2_fill.zw);float o51411_0_1_f = o51411_0_c.y;
vec2 o51415_0_c = fract(o51408_1_2_fill.xy+0.5*o51408_1_2_fill.zw);float o51415_0_1_f = o51415_0_c.x;
vec3 o51416_0_rand = vec3(o51415_0_1_f);vec3 o51416_0_1_rgb = rand3( vec2( float((seed_o51416+fract(_seed_variation_))) + o51416_0_rand.x, rand( o51416_0_rand.yz ) ) );
float o51419_0_clamp_false = (dot(o51416_0_1_rgb, vec3(1.0))/3.0)*(elapsed_time);
float o51419_0_clamp_true = clamp(o51419_0_clamp_false, 0.0, 1.0);
float o51419_0_2_f = o51419_0_clamp_false;
float o51413_0_clamp_false = o51411_0_1_f-o51419_0_2_f;
float o51413_0_clamp_true = clamp(o51413_0_clamp_false, 0.0, 1.0);
float o51413_0_1_f = o51413_0_clamp_false;
float o51414_0_clamp_false = fract(o51413_0_1_f);
float o51414_0_clamp_true = clamp(o51414_0_clamp_false, 0.0, 1.0);
float o51414_0_1_f = o51414_0_clamp_false;
float o51412_0_clamp_false = pow(o51414_0_1_f,p_o51412_default_in2);
float o51412_0_clamp_true = clamp(o51412_0_clamp_false, 0.0, 1.0);
float o51412_0_2_f = o51412_0_clamp_false;
vec4 o51409_0_bb = o51408_1_2_fill;vec3 o51409_0_1_rgb = fill_to_uv_stretch((uv), o51409_0_bb, float((seed_o51409+fract(_seed_variation_))));
vec3 o51410_0_map = o51409_0_1_rgb;
float o51410_0_rnd =  float((seed_o51410+fract(_seed_variation_)))+o51410_0_map.z;
vec4 o51410_0_1_rgba = o51410_input_in(get_from_tileset(1.0, o51410_0_rnd, custom_uv_transform(o51410_0_map.xy, vec2(p_o51410_sx, p_o51410_sy), p_o51410_rotate*0.01745329251, p_o51410_scale, vec2(o51410_0_map.z, float((seed_o51410+fract(_seed_variation_)))))), true ? o51410_0_rnd : 0.0);
float o51417_0_clamp_false = o51412_0_2_f*(dot((o51410_0_1_rgba).rgb, vec3(1.0))/3.0);
float o51417_0_clamp_true = clamp(o51417_0_clamp_false, 0.0, 1.0);
float o51417_0_1_f = o51417_0_clamp_false;
vec3 o51418_0_clamp_false = pow(vec3(o51417_0_1_f),vec3(p_o51418_d_in2_x, p_o51418_d_in2_y, p_o51418_d_in2_z));
vec3 o51418_0_clamp_true = clamp(o51418_0_clamp_false, vec3(0.0), vec3(1.0));
vec3 o51418_0_2_rgb = o51418_0_clamp_true;

	vec4 color_tex = vec4(o51418_0_2_rgb, 1.0);
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	ALBEDO = color_tex.rgb;
	ALPHA = color_tex.a;

}



