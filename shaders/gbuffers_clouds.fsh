#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/water.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;
in vec4 position;

/* RENDERTARGETS: 0,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 cloudsMask;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	if (color.a < alphaTestRef) {
		discard;
	}
	
	// Apply fog
	color = applyFog(color, 0.075, true);

	// Mask clouds
	cloudsMask = vec4(1.0, length(position), 0.0, 1.0);
}