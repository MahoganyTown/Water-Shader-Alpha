#version 430 compatibility

#include "/lib/common.glsl"

attribute vec4 mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 position;
out vec3 normal;
out vec4 glcolor;
out flat int blockID;

void main() {
    vec3 pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    pos = (gbufferModelViewInverse * vec4(pos,1)).xyz;
    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(pos,1);
    gl_FogFragCoord = length(pos);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	position = gl_Vertex;
	normal = normalize(gl_NormalMatrix * gl_Normal);
	blockID = int(mc_Entity.x);
}