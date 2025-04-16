#version 430 compatibility

uniform int renderStage;

#include "/lib/common.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

in vec4 glcolor;

/* RENDERTARGETS: 0,7 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 light;

void main() {
	if (renderStage == MC_RENDER_STAGE_STARS) {
		color = glcolor;
	} else {
		vec3 pos = screenToView(vec3(gl_FragCoord.xy / iresolution, 1.0));
		color = vec4(calcSkyColor(normalize(pos)), 1.0);
	}

	light = vec4(1.0);
}
