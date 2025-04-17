// Smoothing functions from: https://easings.net/
float easeOutQuint(float x) {
    return 1.0 - pow(1.0 - x, 5.0);
}

float getSkyBrightnessAmount() {
    return eyeBrightnessSmooth.y / 240.0;
}

float getAmountInDarkness() {
    return 1.0 - getSkyBrightnessAmount();
}

vec4 shadeWaterColorInReflection(vec4 color) {
    // Shade water fragments in reflection on water surface relative to environment and time on day
    float amountInDarkness = getAmountInDarkness();
    float amountMiday = getMidDayFastFrac01();
    float amountMidnight = easeOutQuint(getNightAmount());

    vec3 colordayWaterColor = vec3(0.01, 0.07, 0.14);
    vec3 nightWaterColor = vec3(0.0, 0.03, 0.08);

    colordayWaterColor = mix(colordayWaterColor, nightWaterColor, max(0.0, amountMidnight));

    float dayColorAmount = max(0.0, clamp(0.0, 0.5, amountMiday) - amountInDarkness);
    float nightColorAmount = 0.0; //max(0.0, amountMidnight);

    color = mix(color, vec4(colordayWaterColor, color.a), dayColorAmount);
    color = mix(color, vec4(nightWaterColor, color.a), nightColorAmount);
    color.rgb = mix(color.rgb, nightWaterColor, max(0.0, amountInDarkness - 0.45));

    return color;
}

float getVanillaLighting(vec3 n) {
    // Implementation from: https://modrinth.com/shader/vanillaa
    return min(n.x * n.x * 0.6 + n.y * n.y * 0.25 * (3.0 + n.y) + n.z * n.z * 0.8, 1.0);
}

vec4 applyFog(vec4 color, float factor, bool applyAlpha) {
    // Fogify entites, terrain, visible geometry
    vec4 fogColor = gl_Fog.color;
    float density = gl_Fog.density;
    float scale = gl_Fog.scale;

    if (isEyeInWater == 1) {
        // Underwater fog
        float sunAmount = getSunAmount();
        float waterFogAlpha = mix(underwaterFogColorNight.a, getUnderwaterDaytimeWaterColor().a, sunAmount);
        vec3 waterFogColor = mix(underwaterFogColorNight.rgb, getUnderwaterDaytimeWaterColor().rgb, sunAmount);

        fogColor.rgb = waterFogColor;
        fogColor *= waterFogAlpha;
        density -= mix(0.005, 0.015, sunAmount);
    }

    // Implementation from: https://modrinth.com/shader/vanillaa
    float fog = 0.0;
    if (fogMode == GL_LINEAR) {
        fog = clamp((gl_FogFragCoord - gl_Fog.start) * scale * factor, 0.0, 1.0);
        color.rgb = mix(color.rgb, fogColor.rgb, fog);
    } else if (fogMode == GL_EXP || fogMode == GL_EXP2 || isEyeInWater >= 1) {
        fog = 1.0 - clamp(exp(-gl_FogFragCoord * density * factor), 0.0, 1.0);
        color.rgb = mix(color.rgb, fogColor.rgb, fog);
    }

    if (applyAlpha) {
        // For fading clouds in the distance
        color.a = 1.0 - fog;
    }

    return color;
}

vec4 applyFogOnWater(vec4 color, vec4 waterModelPos) {
    // Fogify water
    vec3 worldPos = getWorldPositionFromModelPosition(waterModelPos);
    float l = length(worldPos - cameraPosition);
    float d = clamp((l - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
    color = mix(color, gl_Fog.color, d);

    return color;
}

vec4 getSkyColor(vec4 waterModelPos) {
    // Get sky color on water fragment relative to player view direction
    vec3 skyDir = vec3(0.0, 1.0, 0.0);
    vec3 viewDir = normalize(waterModelPos.xyz);
    vec3 reflectDir = reflect(viewDir, vec3(0.0, 1.0, 0.0));
    skyDir = normalize(mix(skyDir, reflectDir, 0.60));

    return vec4(calcSkyColor(skyDir), 1.0);
}

vec4 addSkyTexturedToWater(vec4 waterCol, vec3 waterNormal, vec4 waterModelPosition) {
    vec4 outColor = waterCol;

    #if SKYTEXTURED == 1
        // Reflect the sun and moon
        vec3 ro = vec3(0.0);
        vec3 worldPos = getWorldPositionFromModelPosition(waterModelPosition);
        vec3 rd = normalize(worldPos - (cameraPosition + gbufferModelViewInverse[3].xyz));
        vec3 reflected = reflect(rd, waterNormal);
        float weather = max(thunderStrength, rainStrength);
        outColor = mix(skyTexturedReflection(ro, reflected, waterCol), waterCol, weather);
    #endif

    return outColor;
}

vec4 tintWater(vec4 waterCol, vec4 waterModelPosition) {
    // Tint water based on sky color and cave ambient color
    float amountMinWaterColor = mix(0.0, 0.70, getMidDayFastFrac01());
    float amountInDarkness = mix(amountMinWaterColor, 0.85, getAmountInDarkness());
    vec4 skyColor = getSkyColor(waterModelPosition);
    vec4 waterEnvironmentColor = mix(skyColor, waterCol, amountInDarkness);

    return waterEnvironmentColor;
}