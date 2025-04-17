#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/sky.glsl"

out vec2 texcoord;
out vec4 glcolor;
out vec4 position;

void main() {
    vec3 pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    pos = (gbufferModelViewInverse * vec4(pos,1)).xyz;
    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(pos,1);
    gl_FogFragCoord = length(pos);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
    position = gl_Vertex;
}