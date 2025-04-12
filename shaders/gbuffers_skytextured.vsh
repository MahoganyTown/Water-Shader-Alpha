#version 430 compatibility

#include "/lib/common.glsl"

out vec2 gshTexcoord;
out vec4 gshGlcolor;

void main() {
    gl_Position = ftransform();
	gshTexcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	gshGlcolor = gl_Color;
}