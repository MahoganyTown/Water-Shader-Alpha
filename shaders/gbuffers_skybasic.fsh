#version 430 compatibility

uniform int renderStage;

#include "/lib/common.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	if (renderStage == MC_RENDER_STAGE_STARS) {
		color = glcolor;
	} else {
		vec3 pos = screenToView(vec3(gl_FragCoord.xy / iresolution, 1.0));
		color = vec4(calcSkyColor(normalize(pos)), 1.0);
	}

	color = applyFog(color, 1.0, false);
}
