#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/water.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;

in flat int blockID;
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec4 position;
in vec3 normal;
in float stillWaterAmount;

/* RENDERTARGETS: 0,1,2,3,5,6,9,11 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 waterPosition;
layout(location = 2) out vec4 waterNormal;
layout(location = 3) out vec4 waterMask;
layout(location = 4) out vec4 iceMask;
layout(location = 5) out vec4 glassMask;
layout(location = 6) out vec4 waterColoredTexture;
layout(location = 7) out vec4 waterTiling;

void main() {
	float isItIce = 0.0;
	float isItGlass = 0.0;
	float isItWater = 0.0;
	float y = 0.0;
	
	vec4 outColor = texture(gtexture, texcoord) * texture(lightmap, lmcoord);

	if (blockID == 3) {
		// Ice
		isItIce = 1.0;
		color = applyFog(outColor * glcolor, 1.0, false);
		color.a = min(color.a + 0.125, 1.0);
	} else if (blockID > 10000) {
		// Glass
		y = 1.0;
		isItGlass = 1.0;
		color = applyFog(outColor * glcolor, 1.0, false);
	} else {
		// Water
		y = 1.0;
		isItWater = 1.0;
		outColor.a = 1.0;
		waterPosition = position;
		waterNormal = vec4(encodeNormal(normal), 1.0);
		waterColoredTexture = tintWater(outColor * mix(glcolor, getWaterColor(), 0.50), position);
		color = vec4(outColor.rgb, waterBlendFactor) * glcolor;
	}

	// Water tiling
	float tiling = 10.0;
	vec3 worldPos = getWorldPositionFromModelPosition(position);
	float x = mod(worldPos.x, tiling) / tiling;
	float z = mod(worldPos.z, tiling) / tiling;

	// Output masks
	iceMask = vec4(isItIce, 0.0, 0.0, isItIce);
	waterMask = vec4(length(position), stillWaterAmount, isItWater, isItWater);
	glassMask = vec4(isItGlass, outColor.a, length(position), isItGlass);
	waterTiling = vec4(y, x, z, 1.0);
}