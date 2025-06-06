#version 430 compatibility

#include "/lib/common.glsl"

out vec4 glcolor;

void main() {
	glcolor = gl_Color;
    vec3 pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    pos = (gbufferModelViewInverse * vec4(pos,1)).xyz;
    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(pos,1);
    gl_FogFragCoord = length(pos);
}
