#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/water.glsl"
#include "/lib/sky.glsl"
#include "/lib/shading.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec4 computeWaterLighting(vec2 uv) {
    vec4 colorOut = texture2D(colortex0, uv);
    float amountLighting = clamp(1.0 - getSunAmount(), 0.0, 1.0);

    if (isEyeInWater == 0) {
        colorOut *= mix(getWaterLighting(uv), vec4(1.0), amountLighting);
    }

    return colorOut;
}

vec4 getRefractedColor(vec4 stencil) {
    // Code from: Water Shader Mod by Necrowizzard
    float in_water;
    vec4 colorOut;

    if (stencil.r > 0.05)
        in_water = 1.0;
    else
        in_water = 0.0;

    //distortion begin
    float x_scale = 1.0;
    float z_scale = 1.0;

    float used_timer = frameTimeCounter;
    float time_scale = 0.250;
    float size_scale = 1.6 * 6.3;

    if (stencil.r <= 0.15) {
        size_scale *= 6.0;
        time_scale *= 1.5;
    } else {
        size_scale *= stencil.r;
    }

    // timer needs to be 'in period'
    if (stencil.r >= 0.5) {
        x_scale = (1.0 + (sin(2.0 * time_scale * 3.14159 * used_timer - sin(0.5 * size_scale * 3.14159 * stencil.g) + (size_scale * 3.14159 * stencil.g)) / 150.0)); //scales btw 0.995 and 1.005
    }
    z_scale = (1.0 + (sin(sin(time_scale * 3.14159 * used_timer) + 1.5 * sin(0.8 * size_scale * 3.14159 * stencil.b)) / 200.0));

    vec2 disturbed = vec2(x_scale * texcoord.x, z_scale * texcoord.y);

    time_scale = 0.45;

    // 'refraction' (for all under-water)
    if (in_water > 0.05) {
        float look_up_range = 0.008;
        float limit = 0.001;
        // costs performance! (masking to avoid outside water look-ups, alternative another scene clipping)
        if (getStencil(vec2(disturbed.r + look_up_range, disturbed.g + look_up_range)).r > limit &&
            getStencil(vec2(disturbed.r - look_up_range, disturbed.g - look_up_range)).r > limit &&
            getStencil(vec2(disturbed.r, disturbed.g)).r > limit) {
            // drunken effect without stencil if
            colorOut = computeWaterLighting(disturbed);
        } else {
            colorOut = computeWaterLighting(texcoord);
        }
    } else {
        colorOut = computeWaterLighting(texcoord);
    }

    return vec4(vec3(colorOut), 1.0);
}

vec4 getReflectedColor(vec4 stencil) {
    // Code from: Water Shader Mod by Necrowizzard
    float in_water;

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
        x_scale = (1.0 + (sin(2.0 * time_scale * 3.14159 * used_timer - sin(0.5 * size_scale * 3.14159 * stencil.g) + (size_scale * 3.14159 * stencil.g)) / 150.0));
    }
    z_scale = (1.0 + (sin(sin(time_scale * 3.14159 * used_timer) + 1.5 * sin(0.8 * size_scale * 3.14159 * stencil.b)) / 150.0));

    vec2 disturbed = vec2(x_scale * texcoord.x, z_scale * texcoord.y);
    disturbed = clamp(disturbed, 0.001, 0.999);
    vec4 reflection = getWaterReflectionColor(disturbed);

    time_scale = 0.45;
    size_scale = 2.4 * 6.3 * stencil.r;

    // timer needs to be 'in period'
    if (stencil.r >= 0.5) {
        x_scale = (1.0 + (sin(2.0 * time_scale * 3.14159 * used_timer - sin(0.25 * size_scale * 3.14159 * stencil.g) + size_scale * 3.14159 * stencil.g) / 150.0));
    }
    z_scale = (1.0 + (sin(sin(time_scale * 3.14159 * used_timer) + 1.5 * sin(size_scale * 3.14159 * stencil.b)) / 150.0));

    vec2 disturbed_2 = vec2(x_scale * texcoord.x, z_scale * texcoord.y);
    disturbed_2 = clamp(disturbed_2, 0.001, 0.999);
    vec4 reflection_2 = getWaterReflectionColor(disturbed_2);
    reflection = (reflection + reflection_2) / 2.0;

    // Edge-case
    if (reflection.a > 1.0) {
        return getWaterReflectionColor(texcoord);
    }

    return reflection;
}

void getSurfaceEffect(in vec4 stencil, inout vec4 reflectionColor, inout vec4 waterRawColor, in float fadeAmount) {
    // Code from: Superbomb17
    float in_water;

    if (stencil.r > 0.05)
        in_water = 1.0;
    else
        in_water = 0.0;

    // distortion begin
    float x_scale = 1.0;
    float z_scale = 1.0;

    float used_timer = frameTimeCounter;
    float time_scale = 0.250;
    float size_scale = 1.6 * 6.3;

    if (stencil.r <= 0.15) {
        size_scale *= 6.0;
        time_scale *= 1.5;
    } else {
        size_scale *= stencil.r;
    }

    // timer needs to be 'in period'
    if (stencil.r >= 0.5) {
        x_scale = (1.0 + (sin(2.0 * time_scale * 3.14159 * used_timer - sin(0.5 * size_scale * 3.14159 * stencil.g) + (size_scale * 3.14159 * stencil.g)) / 150.0));
    }
    z_scale = (1.0 + (sin(sin(time_scale * 3.14159 * used_timer) + 1.5 * sin(0.8 * size_scale * 3.14159 * stencil.b)) / 200.0));

    vec2 disturbed = vec2(x_scale * texcoord.x, z_scale * texcoord.y);
    disturbed = clamp(disturbed, 0.001, 0.999);

    float surface_effects = 1.0;
    if (surface_effects > 0.0) {
        for (int i = -3; i < 3; i++) {
            vec2 uv = disturbed.rg;
            uv.y += 0.001 * i;

            vec3 col = getWaterReflectionColor(uv).rgb;
            if (reflectionColor.r < 0.01)
                col = vec3(0.0);

            col = col * pow(fadeAmount, 0.2);

            float str = (col.x + col.y + col.z) / 3.0;
            str = str * str - 0.325;

            reflectionColor.rgb += clamp((str * col), 0.0, 3.0);
        }
        reflectionColor /= 6.0;
    }

    color = vec4(color.rgb, 1.0) + vec4(reflectionColor.rgb, 1.0);
    waterRawColor = mix(color, waterRawColor, 0.60);
}

vec4 computeFinalWaterColor(vec4 stencil, vec4 color, float fadeAmount, bool glass, float glassAlpha, vec4 waterRawColor) {
    // Water reflection fetch
    color = (!glass) ? getRefractedColor(stencil) : color;
    vec4 reflectionColor = (isEyeInWater == 1) ? color : getReflectedColor(stencil) * fadeAmount;
        
    float in_water;

    if (stencil.r > 0.05)
        in_water = 1.0;
    else
        in_water = 0.0;

    // combine reflection and scene at water surfaces
    float reflection_strength = 0.30 * (stencil.r - 0.1);
    float disable_refl = stencil.r - 0.1;
    
    if (disable_refl <= 0.0) disable_refl = 0.0; // no reflection
    
    // times inverted color.r for a stronger reflection in darker water parts!
    vec3 reflection_color = vec3(1.0, 1.0, 1.0);
    reflection_color =  reflection_strength * disable_refl * reflectionColor.rgb;
    
    // more color in darker water in relation to the reflection
    // color darkened
    float difference = (reflection_color.r + reflection_color.g + reflection_color.b) / 3.0 - (color.r + color.g + color.b) / 5.5;
    if (difference < 0.0) difference = 0.0;
    vec3 regular_color = color.rgb * (1.0 - in_water * reflection_strength) + (in_water * (difference * getWaterColor().rgb));
    
    color = vec4(regular_color, 1.0);
    reflectionColor = vec4(reflection_color, 1.0);

    // Apply reflection to water
    reflectionColor = mix(color, reflectionColor, fadeAmount);

    // Superbomb17 effect on water surface
    #if STYLE == 2
        if (!glass && isEyeInWater == 0)
            getSurfaceEffect(stencil, reflectionColor, waterRawColor, fadeAmount);
    #endif

    // Blending reflection factor (how much of reflection color in final fragment)
    // Make sure transluscent geometry (glass) is correctly blended
    float reflectionBlendAmount = (glass) ? 0.85 - glassAlpha : 0.40;
    color = mix(color, reflectionColor, reflectionBlendAmount);

    return color;
}

void main() {
    // Fetch data
    color = texture(colortex0, texcoord);

    vec4 waterMask = getWaterMask(texcoord);
    vec4 glassMask = getGlassMask(texcoord);
    vec4 cloudMask = getCloudMask(texcoord);
    vec4 iceMask = getIceMask(texcoord);
    vec4 stencil = getStencil(texcoord);

    vec4 waterModelPos = getWaterModelPos(texcoord);
    vec3 waterNormal = getWaterNormal(texcoord);
    vec4 waterRawColor = getWaterRawColor(texcoord);

    bool water = isWater(waterMask);
    bool glass = isGlass(glassMask);
    bool ice = isIce(iceMask);
    bool cloud = isCloud(cloudMask);

    float glassAlpha = getGlassTransparency(glassMask);
    float fadeAmount = getTransitionAmount(waterMask);
    float waterLength = getWaterDistance(waterMask);
    float glassLength = getGlassDistance(glassMask);
    float cloudLength = getCloudLength(cloudMask);

    if (!cloud && cloudLength < waterLength) {
        // Make sure clouds hide water like the rest of terrain, if no clouds in front then do water stuff

        if (isLookingAtStillWaterThroughTransluscent(glass, ice, water, waterLength, glassLength, waterNormal)) {
            // Mare sure you can see water reflection through glass and ice when placed in water on solid block
            fadeAmount = 1.0;
        }

        if ((water || glass) && !ice) {
            // Compute reflections, refractions, and wawing water into color
            color = computeFinalWaterColor(stencil, color, fadeAmount, glass, glassAlpha, waterRawColor);
        }

        if (water && isEyeInWater == 0) {
            // Blend flowing water to scene when outside water
            float divisor = (glassLength < waterLength) ? 2.0 : 8.0;
            float factor = max(0.0, waterBlendFactor - glassAlpha / divisor);
            color = blendWaterInScene(color, waterRawColor, factor, fadeAmount);
            color = applyFogOnWater(color, waterModelPos);
        }
    }
}
