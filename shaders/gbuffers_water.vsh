#version 430 compatibility

#include "/lib/common.glsl"

attribute vec4 mc_Entity;

out flat int gshBlockID;
out vec2 gshLmcoord;
out vec2 gshTexcoord;
out vec4 gshGlcolor;
out vec4 gshPosition;
out vec3 gshPosition2;
out vec3 gshWorldPos;
out vec3 gshNormal;

void main() {
    vec3 pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    pos = (gbufferModelViewInverse * vec4(pos,1)).xyz;
	gshPosition2 = pos;
    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(pos, 1);
	gshTexcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	gshLmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	gshGlcolor = gl_Color;
	gshPosition = gl_Vertex;
	gshNormal = gl_Normal;
	gshBlockID = int(mc_Entity.x);
	gshWorldPos = getWorldPositionFromModelPosition(gl_Vertex);
}