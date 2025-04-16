#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/water.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec3 normal;
in vec4 position;
in vec4 glcolor;
in flat int blockID;

/* RENDERTARGETS: 0,10,7 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 terrainMask;
layout(location = 2) out vec4 terrainLightMapForWater;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color *= texture(lightmap, lmcoord);
	if (color.a < alphaTestRef && blockID != 5) {
		// Remove / fill holes in tree leaves
		discard;
	}

	// Vanilla-like lighting
    vec3 n = (blockID == 1) ? vec3(0, 1, 0) : (gbufferModelViewInverse * vec4(normal, 0)).xyz;
	color.rgb *= getVanillaLighting(n);

	// Apply fog
	color = applyFog(color, 1.0, false);

	// Terrain lighting (for darker water in deeper areas)
	terrainLightMapForWater = clamp(pow(texture(lightmap, lmcoord), vec4(1.0)), 0.0, 1.0);
	terrainLightMapForWater *= getVanillaLighting(n);

	// Terrain mask
	terrainMask = vec4(position.xyz, 1.0);
}