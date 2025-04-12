#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/water.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec4 getRefractedColor() {
    // Code from: Water Shader Mod by Necrowizzard
    float in_water;
    vec4 colorOut;
    vec4 stencil = getStencil(texcoord);

    if (stencil.r > 0.05)
        in_water = 1.0;
    else
        in_water = 0.0;

    //distortion begin
    float x_scale = 1.0;
    float z_scale = 1.0;

    float used_timer = frameTimeCounter;
    float time_scale = 0.275;
    float size_scale = 1.6 * 6.3;

    if (stencil.r <= 0.15) {
        size_scale *= 6.0;
        time_scale *= 1.5;
    } else {
        size_scale *= stencil.r;
    }

    //timer needs to be 'in period'
    if (stencil.r >= 0.5) {
        x_scale = (1.0 + (sin(2.0 * time_scale * 3.14159 * used_timer - sin(0.5 * size_scale * 3.14159 * stencil.g) + (size_scale * 3.14159 * stencil.g)) / 200.0)); //scales btw 0.995 and 1.005
    }
    z_scale = (1.0 + (sin(sin(time_scale * 3.14159 * used_timer) + 1.5 * sin(0.8 * size_scale * 3.14159 * stencil.b)) / 200.0));

    vec2 disturbed = vec2(x_scale * texcoord.x, z_scale * texcoord.y);

    time_scale = 0.45;

    //'refraction'(for all under-water)
    if (in_water > 0.05) {
        float look_up_range = 0.001;
        float limit = 0.001;
        //costs performance! (masking to avoid outside water look-ups, alternative another scene clipping)
        if (getStencil(vec2(disturbed.r + look_up_range, disturbed.g + look_up_range)).r > limit &&
            getStencil(vec2(disturbed.r - look_up_range, disturbed.g - look_up_range)).r > limit &&
            getStencil(vec2(disturbed.r, disturbed.g)).r > limit) {
            colorOut = texture2D(colortex0, disturbed.rg); //drunken effect without stencil if
        } else {
            colorOut = texture2D(colortex0, texcoord.rg);
        }
    } else {
        colorOut = texture2D(colortex0, texcoord.rg);
    }

    return vec4(vec3(colorOut), 1.0);
}

vec4 getReflectedColor() {
    // Code from: Water Shader Mod by Necrowizzard
    float in_water;
    vec4 stencil = getStencil(texcoord);

    if (stencil.r > 0.05)
        in_water = 1.0;
    else
        in_water = 0.0;

    // distortion begin
    float x_scale = 1.0;
    float z_scale = 1.0;

    float used_timer = frameTimeCounter;
    float time_scale = 0.275;
    float size_scale = 1.6 * 6.3;

    if (stencil.r <= 0.15) {
        size_scale *= 6.0;
        time_scale *= 1.5;
    } else {
        size_scale *= stencil.r;
    }

    // timer needs to be 'in period'
    if (stencil.r >= 0.5) {
        x_scale = (1.0 + (sin(2.0 * time_scale * 3.14159 * used_timer - sin(0.5 * size_scale * 3.14159 * stencil.g) + (size_scale * 3.14159 * stencil.g)) / 200.0));
    }
    z_scale = (1.0 + (sin(sin(time_scale * 3.14159 * used_timer) + 1.5 * sin(0.8 * size_scale * 3.14159 * stencil.b)) / 200.0));

    vec2 disturbed = vec2(x_scale * texcoord.x, z_scale * texcoord.y);
    vec4 reflection = getWaterReflectionColor(disturbed);

    time_scale = 0.45;
    size_scale = 2.4 * 6.3 * stencil.r;

    // timer needs to be 'in period'
    if (stencil.r >= 0.5) {
        x_scale = (1.0 + (sin(2.0 * time_scale * 3.14159 * used_timer - sin(0.25 * size_scale * 3.14159 * stencil.g) + size_scale * 3.14159 * stencil.g) / 250.0));
    }
    z_scale = (1.0 + (sin(sin(time_scale * 3.14159 * used_timer) + 1.5 * sin(size_scale * 3.14159 * stencil.b)) / 250.0));

    vec2 disturbed_2 = vec2(x_scale * texcoord.x, z_scale * texcoord.y);
    vec4 reflection_2 = getWaterReflectionColor(disturbed_2);
    reflection = (reflection + reflection_2) / 2.0;

    // Edge-case
    if (reflection.a > 1.0) {
        return getWaterReflectionColor(texcoord);
    }

    return reflection;
}

void getSurfaceEffect(inout vec4 reflectionColor, inout vec4 waterRawColor) {
    // Code from: Superbomb17
    float in_water;
    vec4 stencil = getStencil(texcoord);

    if (stencil.r > 0.05)
        in_water = 1.0;
    else
        in_water = 0.0;

    // distortion begin
    float x_scale = 1.0;
    float z_scale = 1.0;

    float used_timer = frameTimeCounter;
    float time_scale = 0.275;
    float size_scale = 1.6 * 6.3;

    if (stencil.r <= 0.15) {
        size_scale *= 6.0;
        time_scale *= 1.5;
    } else {
        size_scale *= stencil.r;
    }

    // timer needs to be 'in period'
    if (stencil.r >= 0.5) {
        x_scale = (1.0 + (sin(2.0 * time_scale * 3.14159 * used_timer - sin(0.5 * size_scale * 3.14159 * stencil.g) + (size_scale * 3.14159 * stencil.g)) / 200.0));
    }
    z_scale = (1.0 + (sin(sin(time_scale * 3.14159 * used_timer) + 1.5 * sin(0.8 * size_scale * 3.14159 * stencil.b)) / 200.0));

    vec2 disturbed = vec2(x_scale * texcoord.x, z_scale * texcoord.y);

    float surface_effects = 1.0;
    if (surface_effects > 0.0) {
        for (int i = -3; i < 3; i++) {
            vec2 uv = disturbed.rg;
            uv.y += 0.001 * i;

            vec3 col = getWaterReflectionColor(uv).rgb;
            if (reflectionColor.r < 0.01)
                col = vec3(0.0);

            float str = (col.x + col.y + col.z) / 3.0;
            str = str * str - 0.325;

            reflectionColor.rgb += clamp((str * col), 0.0, 3.0);
        }
        reflectionColor /= 6;
    }

    color = vec4(color.rgb, 1.0) + vec4(reflectionColor.rgb, 1.0);
    waterRawColor = mix(color, waterRawColor, 0.60);
}

float getReflectionPower() {
    return min((getWaterDepth(texcoord) + 0.005) * 20.0, 0.65);
}

void main() {
    color = texture(colortex0, texcoord);

    // Fetch data
    vec4 waterMask = getWaterMask(texcoord);
    vec4 glassMask = getGlassMask(texcoord);
    vec4 iceMask = getIceMask(texcoord);

    vec3 waterNormal = getWaterNormal(texcoord);
    vec4 waterRawColor = getWaterRawColor(texcoord);

    bool water = isWater(waterMask);
    bool glass = isGlass(glassMask);
    bool ice = isIce(iceMask);

    float glassAlpha = getGlassTransparency(glassMask);
    float fadeAmount = getTransitionAmount(waterMask);
    float waterLength = getWaterDistance(waterMask);
    float glassLength = getGlassDistance(glassMask);

    if (isLookingAtStillWaterThroughTransluscent(glass, ice, water, waterLength, glassLength, waterNormal)) {
        // Mare sure you can see water reflection through glass and ice when placed in water on solid block
        fadeAmount = 1.0;
    }

    if ((water || glass) && !ice) {
        // Water reflection fetch
        color = getRefractedColor();
        vec4 reflectionColor = (isEyeInWater == 1) ? color : getReflectedColor();

        // Apply reflection to water
        reflectionColor = mix(color, reflectionColor, fadeAmount);

        // Amount of reflection allowed: lass reflection in shallow water
        float reflectionStrength = getReflectionPower();

        // Superbomb17 effect on water surface
        #if STYLE == 2
        if (!glass && isEyeInWater == 0)
            getSurfaceEffect(reflectionColor, waterRawColor);
        #endif

        // Blend flowing water to still water
        waterRawColor = mix(waterRawColor, color, 0.70 - reflectionStrength);

        // Blending reflection factor (how much of reflection color in final fragment)
        // Make sure transluscent geometry (glass) is correctly blended
        float reflectionBlendAmount = (glass) ? 0.75 - glassAlpha : reflectionStrength;
        color = mix(color, reflectionColor, reflectionBlendAmount);
    }

    if (water && isEyeInWater == 0) {
        // Blend flowing water to scene when outside water
        float divisor = (glassLength < waterLength) ? 2.0 : 8.0;
        float factor = max(0.0, waterBlendFactor - glassAlpha / divisor);
        color = blendWaterInScene(color, waterRawColor, factor, fadeAmount);
    }

    if (isEyeInWater == 1 && dot(vec3(1.0), color.rgb) < 0.01) {
        // Fix weird bug underwater when looking at horizon (kinda patchy by works so...)
        color = mix(underwaterFogColorNight, getUnderwaterDaytimeWaterColor(), getSunAmount());
    }
}
