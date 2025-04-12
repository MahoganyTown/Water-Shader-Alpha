#version 430 compatibility

#include "/lib/common.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;
uniform int renderStage;

in flat int mode;
in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0,8 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 sunColor;

void removeHalo(vec4 texturedColor) {
	if (dot(texturedColor, vec4(1.0)) < 2.0) {
		// Remove sun & moon halo
		discard;
	}
}

void main() {
	vec4 texturedColor = texture(gtexture, texcoord) * glcolor;
	if (texturedColor.a < alphaTestRef) {
		discard;
	}

	if (mode == 1) {
		removeHalo(texturedColor);

		if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON) {
			// Sun && moon fragments
			if (frameCounter == 1)
				sunColor = texturedColor;
			else
				discard;
		}
	} else {
		// Normal rendering to sky
		color = texturedColor;
	}
}