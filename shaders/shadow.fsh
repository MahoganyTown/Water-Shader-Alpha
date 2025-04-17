#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/water.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;

in vec3 waterNormal;
in vec4 waterModelPos;
in vec3 worldPosition;
in vec4 ccolor;
in vec2 texcoord;
in vec2 lmcoord;
in float waterMaskID;
in flat int blockID;
in flat int mode;

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 shadowcolor00;
layout(location = 1) out vec4 shadowcolor01;

void computeBackgroundColor() {
    /* Background color in water (sky + sun/moon) */
    vec4 skycol = getSkyColor(waterModelPos);
    skycol = addSkyTexturedToWater(skycol, waterNormal, waterModelPos);
    
    // Store water ID on SSBO water mask
    mask.data[getSSBOWaterMaskIndex(gl_FragCoord.xy)] = getWaterID(waterModelPos);
    
    // Sky color is background in water reflection -> always behind
    // This is always water fragments here
    gl_FragDepth = 1.0;
    shadowcolor00 = skycol;
    shadowcolor01 = vec4(0.0, 1.0, 0.0, 0.0);
}

void computeReflectionColor() {
    /* Planar reflection */
    float waterY = waterMaskID;
    int waterID = mask.data[resolveSSBOWaterMaskIndex(gl_FragCoord.xy)];

    if (abs(waterID - waterY) > 0.1 || waterID < lowerWorldBound) {
        // Discard all geometry that is not for this water fragment (for this plane)
        discard;
    }

    // Make sure you remove all geometry above clipping plane to avoid visual artifacts
    if (worldPosition.y < waterY + waterBlockOffset) {
        // Clip all geometry below "clipping plane"
        discard;
    }

    // Delete fragments too close from water surface
    if (abs(worldPosition.y - waterY) < waterClipPlane) {
        discard;
    }

    // Compute reflection water color (sample texture atlas * terrain color * default lightmap color)
    vec4 finalColor = texture(gtexture, texcoord) * ccolor;
    finalColor *= texture(lightmap, lmcoord);

    // Modify water reflection of water in water
    float isItWater = (blockID == 2) ? 1.0 : 0.0;
    if (isItWater == 1.0) {
        // If reflected water is too close from water surface, then discard to avoid weird transition
        if (abs(worldPosition.y - waterY) < waterClipPlane + 0.9) {
            discard;
        }
        
        // Remove auto color and make it look like reflected water
        finalColor = shadeWaterColorInReflection(finalColor / ccolor);
    }

    // Discard transparent objects from reflection map but not water
    if (finalColor.a < 0.99 && isItWater == 0.0 && blockID != 5) {
        discard;
    }

    // Output reflection water color to shadow map
    // Effectively the reflection texture of the world
    shadowcolor00 = finalColor;
    // g: is reflection water fragment (true/false)
    shadowcolor01 = vec4(0.0, isItWater, 0.0, 0.0);
    gl_FragDepth = gl_FragCoord.z;
}

void main() {
    /* Build reflection texture */
    if (mode == 1) {
        computeBackgroundColor();
    } else {
        computeReflectionColor();
    }
}