#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/water.glsl"

in vec2 mc_Entity;

out vec3 gshNormal;
out vec4 gshModelPos;
out vec4 gshColor;
out vec2 gshTexcoord;
out vec2 gshLmcoord;
out flat int gshBlockID;

void main() {
    // Always pass the vertex shader and postpone planar reflection computation in the geometry buffer
    gl_Position = vec4(0.0, 0.0, 0.0, 1.0);

    // Output normal color, texture coordinate, etc to shadow geometry shader
    gshModelPos = gl_Vertex;
    gshNormal = gl_Normal.xyz;
    gshColor = gl_Color;
	gshBlockID = int(mc_Entity.x);
	gshTexcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	gshLmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}
