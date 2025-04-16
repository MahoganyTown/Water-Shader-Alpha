// Texture samplers
uniform sampler2D noisetex;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D colortex15;

// Uniform variables
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform int fogMode;
uniform int isEyeInWater;
uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int worldTime;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float sunAngle;
uniform float shadowAngle;
uniform float rainStrength;
uniform float thunderStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

// Settings for transitioning between bright and dark environments
const float eyeBrightnessHalflife = 15.0f;

// Settings for shadow pass
const int shadowMapResolution = 2048;
const float shadowIntervalSize = 0.0f;

// Texture targets clear settings
const bool colortex4Clear = false;
const bool colortex8Clear = false;
const vec4 shadowcolor0ClearColor = vec4(0.0, 0.0, 0.0, 5.0);

// Texture formats
/*
const int shadowcolor0Format = RGBA16F; // reflection color
const int shadowcolor1Format = RGBA;    // reflection mask (is water in reflection)
const int colortex0Format = RGBA;       // scene color
const int colortex1Format = RGBA32F;    // position of water blocks in model space
const int colortex2Format = RGBA;       // scene normal (encoded and in world space)
const int colortex3Format = RGBA16F;    // Water mask
const int colortex4Format = RGBA16F;    // ID of water blocks, water mask for next frame for shadow pass (unexpanded)
const int colortex5Format = RGBA;       // Ice mask
const int colortex6Format = RGBA16F;    // Glass mask
const int colortex7Format = RGBA;       // Lightmap color
const int colortex8Format = RGBA;       // Sun and moon texture
const int colortex9Format = RGBA;       // Water color
const int colortex10Format = RGBA;      // Terrain mask
const int colortex11Format = RGBA;      // Water tiling
*/

// Constant variables for water shader
const vec4 necrowizzardWaterColor = vec4(0.0, 0.4, 0.3, 1.0);                   // Necrowizzard water color
const vec4 superbomb17WaterColor = vec4(0.0, 0.4, 0.3, 1.0);                    // Superbomb17 water color
const vec4 necrowizzardUnderwaterFogColorDay = vec4(0.03, 0.05, 0.12, 0.99);    // Necrowizzard fog color when underwater (daytime)
const vec4 superbomb17UnderwaterFogColorDay = vec4(0.03, 0.05, 0.12, 0.99);     // Superbomb17 fog color when underwater (daytime)
const vec4 underwaterFogColorNight = vec4(0.02, 0.13, 0.24, 0.9);               // Fog color when underwater (nighttime)
const float waterSurfaceTransparency = 0.35;                                                    // Water surface/texture transparency
const float waterClipPlane = 1.0;                                                               // Delete vertices too close from water surface (strange results with player reflection otherwise)
const float eyeCameraOffset = 1.68;                                                             // Eye camera offset from player's feet
const float waterBlockOffset = 1.005;                                                           // Water block clipping plane height (inside block)
const int lowerWorldBound = -64;                                                                // Lowest possible water reflection plane height (Minecraft minimum block height)
const float waterBlendFactor = 0.20;                                                            // How much to blend flowing water to scene

// Fog constants
const int GL_LINEAR = 9729;
const int GL_EXP = 2048;
const int GL_EXP2 = 2049;

// Custom uniforms
uniform vec2 iresolution;

#define INFO 0                  // [0]
#define STYLE 1                 // Water surface style [1 2]
#define PLANES 1                // Reflection planes allowed [1 2 3 4]
#define SKYTEXTURED 2           // Sun & moon reflection [1 2]

// Shader Storage Buffer Object for water information in the visible scene (player view)
layout(std430, binding = 0) buffer SSBOWaterShader {
    int layers[384];            // -64 to 320 every possible water layer, store water fragment occurence for each height
    int waterHeights[PLANES];   // Registered heights for reflection calculation in next frame
    int lowestHeight;           // Height counter
} layersData;

// Shader Storage Buffer Object for specifying "water height mask" on all water fragments
layout(std430, binding = 1) buffer SSBOWaterMask {
    int data[];                 // Store water ID (height) for each screen pixel
} mask;

// Common functions
vec4 getWaterColor() {
    #if STYLE == 1
        // Necrowizzard
        return necrowizzardWaterColor;
    #else
        // Superbomb17
        return superbomb17WaterColor;
    #endif
}

vec4 getUnderwaterDaytimeWaterColor() {
    #if STYLE == 1
        // Necrowizzard
        return necrowizzardUnderwaterFogColorDay;
    #else
        // Superbomb17
        return superbomb17UnderwaterFogColorDay;
    #endif
}

vec3 encodeNormal(vec3 normal) {
    return (normal + 1.0) / 2.0;
}

vec3 decodeNormal(vec3 normal) {
    return (normal * 2.0) - 1.0;
}

vec2 reproject(vec2 uv, float depth) {
    /* Find uv coordinate of the pixel in previous frame */
    vec4 frag = gbufferProjectionInverse * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);
    frag /= frag.w;
    frag = gbufferModelViewInverse * frag;

    vec4 prevPos = frag + vec4(cameraPosition - previousCameraPosition, 0.0) * float(depth > 0.56);
    prevPos = gbufferPreviousModelView * prevPos;
    prevPos = gbufferPreviousProjection * prevPos;

    return prevPos.xy / prevPos.w * 0.5 + 0.5;
}

bool isWithinTexture(vec2 uv) {
    // Is uv within texture bounds
    return uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;
}

float linearizeDepth(float depth) {
    // Implemetation from: LearnOpenGL
    float z = depth * 2.0 - 1.0; // back to NDC 
    return ((2.0 * near * far) / (far + near - z * (far - near))) / far;	
}
