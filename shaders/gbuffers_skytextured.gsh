#version 430 compatibility

#include "/lib/common.glsl"

layout(triangles) in;
layout(triangle_strip, max_vertices = 6) out;

in vec2 gshTexcoord[];
in vec4 gshGlcolor[];

out flat int mode;
out vec2 texcoord;
out vec4 glcolor;

uniform int renderStage;

void outputOfflineVertex(int i, vec2 uv) {
	// Output single vertex for offline texture
	texcoord = gshTexcoord[i];
	glcolor = gshGlcolor[i];
	uv.x /= aspectRatio;
	gl_Position = vec4(uv, 0.0, 1.0);
	EmitVertex();
}

void outForOffline() {
	// For offline texture rendering (reflections)
	float size = 1.0;
	vec2 bias = (renderStage == MC_RENDER_STAGE_SUN) ? vec2(0.20) : vec2(-0.20);
	vec2 center = vec2(size / 2.0) + bias;
	mode = 1;

	if (gshTexcoord[1].y > gshTexcoord[2].y) {
		// Triangle on the left
		outputOfflineVertex(1, vec2(0.0, size) - center);
		outputOfflineVertex(2, vec2(0.0, 0.0) - center);
		outputOfflineVertex(0, vec2(size, size) - center);
	} else {
		// Triangle on the right
		outputOfflineVertex(2, vec2(size, size) - center);
		outputOfflineVertex(0, vec2(0.0, 0.0) - center);
		outputOfflineVertex(1, vec2(size, 0.0) - center);
	}

    EndPrimitive();
}

void outputNormalVertex(int i) {
	texcoord = gshTexcoord[i];
	glcolor = gshGlcolor[i];
	gl_Position = gl_in[i].gl_Position;
	EmitVertex();
}

void passThru() {
	// For normal sun and moon sky rendering
	// pass-thru unchanged to fragment shader
	mode = 0;
	outputNormalVertex(0);
	outputNormalVertex(1);
	outputNormalVertex(2);

    EndPrimitive();
}

void main() {
	#if SKYTEXTURED == 1
		if (frameCounter == 1)
    		outForOffline();
	#endif

	passThru();
}