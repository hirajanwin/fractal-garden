precision highp float;
uniform vec2 screenSize;
uniform vec2 offset;
uniform vec2 repeat;
uniform float time;
uniform vec3 cameraPosition;
uniform mat4 cameraDirection;

const int MAX_ITER = 100;
const float HIT_THRESHOLD = 0.00001;
const float variance = 0.01;
// const float PI = 3.14159265359;


vec3 getRay() {
    vec2 normalizedCoords = gl_FragCoord.xy - vec2(0.5) + (offset / repeat);
    vec2 pixel = (normalizedCoords - 0.5 * screenSize) / min(screenSize.x, screenSize.y);

    // as if the higher the pixel value, the more the offset is being applied
    // normalize to get unit vector
    return (cameraDirection * normalize(vec4(pixel.x, pixel.y, 1, 0))).xyz;
}

vec3 opRepeat(vec3 p, vec3 distance) {
    return mod(p + 0.5 * distance, distance) - 0.5 * distance;
}

float doModel(vec3 p) {
    float Power = 6.0;
    vec3 pos = opRepeat(p, vec3(2.5));
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < MAX_ITER ; i++) {
		r = length(z);
		if (r > 12.) break;
		
		// convert to polar coordinates
		float theta = acos(z.z / r);
		float phi = atan(z.y, z.x);
		dr =  pow(r, Power - 1.1) * Power * dr + 1.0;
		
		// scale and rotate the point
		float zr = pow(r, Power);
		theta = theta * Power;
		phi = phi * Power;
		
		// convert back to cartesian coordinates
		z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
		z -= pos;
	}
	return 0.5 * log(r) * r / dr;
}
// this is kinda contrived and does a bunch of stuff I'm not using right now, but I'll leave it like this for now
vec3 trace(vec3 origin, vec3 direction, out int iterations) {
    vec3 position = origin;
    for(int i = 0; i < MAX_ITER; i++) {
        iterations = i;
        float d = doModel(position);
        if (d < HIT_THRESHOLD) break;
        position += d * direction;
    }
    return position;
}

float getIllumination(vec3 collision, int iterations) {
    float occlusionLight = 1. - float(iterations) / float(MAX_ITER);
    return occlusionLight;
}

// const float col = 0.05; // amount of coloring

void main() {
    vec3 direction = getRay();
    // gl_FragColor = vec4(offset / (repeat - vec2(1)), 0, 1);
    // return;

    float brightness = 0.;
    int iterations;
    vec3 collision = trace(cameraPosition, direction, iterations);
    if (iterations < MAX_ITER - 1) { // actual collision
        brightness = getIllumination(collision, iterations);
    }
    gl_FragColor = vec4(
        brightness,
        brightness,
        brightness,
        1.
    );
}