#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/water.glsl"

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in flat int gshBlockID[];
in vec2 gshLmcoord[];
in vec2 gshTexcoord[];
in vec4 gshGlcolor[];
in vec4 gshPosition[];
in vec3 gshPosition2[];
in vec3 gshNormal[];

out flat int blockID;
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec4 position;
out vec3 normal;
out float stillWaterAmount;

void outVertex(int i, float amount) {
    gl_Position = gl_in[i].gl_Position;

	texcoord = gshTexcoord[i];
	lmcoord = gshLmcoord[i];
	glcolor = gshGlcolor[i];
	position = gshPosition[i];
	normal = gshNormal[i];
	blockID = gshBlockID[i];
    stillWaterAmount = amount;
    gl_FogFragCoord = length(gshPosition2[i]);

    EmitVertex();
}

void main() {
    // Used for interpolating between still water and flowing water (for reflection seamless transition)
    float stillWaterV0 = (isStillWater(gshPosition[0], gshNormal[0])) ? 1.0 : 0.0;
    float stillWaterV1 = (isStillWater(gshPosition[1], gshNormal[1])) ? 1.0 : 0.0;
    float stillWaterV2 = (isStillWater(gshPosition[2], gshNormal[2])) ? 1.0 : 0.0;

    // Pass-thru
    outVertex(0, stillWaterV0);
    outVertex(1, stillWaterV1);
    outVertex(2, stillWaterV2);

    EndPrimitive();
}