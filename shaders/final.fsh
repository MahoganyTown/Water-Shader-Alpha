#version 430 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
    
    // Zero out all layer occurence counters
    for (int i = 0; i < 384; i++) {
        layersData.layers[i] = 0;
    }
}