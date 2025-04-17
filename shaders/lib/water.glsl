// ---------------- Encoding ----------------
int YToArray(int Y) {
    return Y + 64;
}

int ArrayToY(int index) {
    return index - 64;
}

int getIndex(ivec2 pixelCoord) {
    // Convert 2D pixel coordinate to 1D array index
    return int(pixelCoord.y * viewWidth + pixelCoord.x);
}

int getSSBOWaterMaskIndex(vec2 pixel) {
    /* Return SSBO 1D index for given pixel. */
    vec2 uv = pixel / shadowMapResolution;
    ivec2 pixelCoord = ivec2(uv * iresolution);
    int index = getIndex(pixelCoord);

    return index;
}

int resolveSSBOWaterMaskIndex(vec2 pixel) {
    /* Compute a uv velocity (motion vector) to nudge the sampling position (in SSBO) 
    toward center of water mask / water mass
    to avoid weird visual artifacts near water edges when moving the camera rapidly. 
    */
    vec2 uv = pixel / shadowMapResolution;
    vec2 oldUV = reproject(uv, gl_FragCoord.z);
    vec2 velocity = uv - oldUV;
    int index = 0;

    if (isWithinTexture(uv - velocity)) {
        ivec2 pixelCoord = ivec2((uv - velocity) * iresolution);
        index = getIndex(pixelCoord);
    } else {
        index = getSSBOWaterMaskIndex(pixel);
    }

    return index;
}

// ---------------- Planar Reflection Utils ----------------
mat4 invertPitch(mat4 viewMatrix) {
    mat4 invertedView = viewMatrix;

    // Invert camera pitch
    invertedView[1].y *= -1;
    invertedView[1].x *= -1;
    invertedView[1].z *= -1;

    return invertedView;
}

vec3 getWorldPositionFromModelPosition(vec4 modelPos) {
    dvec3 viewPos = (gbufferModelView * modelPos).xyz;
    dvec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    dvec3 worldPos = eyePlayerPos + cameraPosition + gbufferModelViewInverse[3].xyz;

    return vec3(worldPos);
}

// ---------------- Water Utils ----------------
float getDepth(vec2 uv) {
    return texture(depthtex0, uv).r;
}

float getDepthNoTransluscent(vec2 uv) {
    return texture(depthtex1, uv).r;
}

float getWaterDepth(vec2 uv) {
    return linearizeDepth(getDepthNoTransluscent(uv)) - linearizeDepth(getDepth(uv));
}

vec4 getWaterMask(vec2 uv) {
    return texelFetch(colortex3, ivec2(uv * iresolution), 0);
}

vec4 getGlassMask(vec2 uv) {
    return texelFetch(colortex6, ivec2(uv * iresolution), 0);
}

vec4 getIceMask(vec2 uv) {
    return texelFetch(colortex5, ivec2(uv * iresolution), 0);
}

vec4 getWaterRawColor(vec2 uv) {
    return texture(colortex9, uv);
}

vec4 getStencil(vec2 uv) {
    return texture2D(colortex11, uv);
}

bool isWater(vec4 mask) {
    return mask.b > 0.99;
}

bool isFlowing(vec2 uv) {
    return texture(colortex11, uv).b > 0.0;
}

bool isIce(vec4 mask) {
    return mask.r > 0.99;
}

bool isGlass(vec4 mask) {
    return mask.r > 0.99;
}

bool isTerrain(vec2 uv) {
    return texture(colortex10, uv).a > 0.99;
}

float getGlassTransparency(vec4 mask) {
    return mask.g;
}

float getGlassDistance(vec4 mask) {
    return mask.b;
}

float getWaterDistance(vec4 mask) {
    return mask.r;
}

vec4 getWaterModelPos(vec2 uv) {
    return texture(colortex1, uv);
}

vec3 getWaterNormal(vec2 uv) {
    return decodeNormal(texture(colortex2, uv).xyz);
}

float getTransitionAmount(vec4 mask) {
    // Transition from still water to flowing water [0.0, 1.0]
    return mask.g;
}

vec4 getWaterReflectionColor(vec2 uv) {
    return texelFetch(shadowcolor0, ivec2(uv * shadowMapResolution), 0);
}

float getIceDistance(vec4 mask) {
    return mask.g;
}

bool isStillWater(vec4 pos, vec3 normal) {
    /* Still water has its normal pointing straight up
    Still water is always located at the same position in world space
    This code actually captures a bit more than just still water
    (ie all water fragments close to still water in normal and height) */

    vec3 worldPos = getWorldPositionFromModelPosition(pos);
    float ratioPointingUp = dot(normal, vec3(0.0, 1.0, 0.0));
    float YPos = fract(worldPos.y);

    // return ratioPointingUp >= 0.988 && YPos >= 0.885;
    return YPos >= 0.885 && YPos < 0.90 && ratioPointingUp >= 0.988;
}

vec3 getWaterTiling(vec2 uv) {
    return texture(colortex11, uv).rgb;
}

int getWaterID(vec4 modelPos) {
    // Return water ID ie water height world space
    int id = int(getWorldPositionFromModelPosition(modelPos).y);
    return (id < 0) ? id - 1 : id;
}

float getFresnelFactor(vec3 viewDir, vec3 waterNormal) {
    // Fresnel: amount of reflection / refraction
    float fresnel = dot(-viewDir, waterNormal);
    fresnel = clamp(fresnel, 0.0, 1.0);

    return fresnel;
}

vec4 getWaterLighting(vec2 uv) {
    return texture(colortex7, uv);
}

vec4 blendWaterInScene(vec4 color, vec4 waterRawColor, float waterBlendFactor, float transitionAmount) {
    // Water compositing: add water to scene
    waterBlendFactor *= 1.0 - transitionAmount;
    color = mix(color, waterRawColor, waterBlendFactor);

    return color;
}

bool isLookingAtStillWaterThroughTransluscent(bool glass, bool ice, bool water, float waterLength, float glassLength, vec3 waterNormal) {
    // Check if glass or ice is directly in contact with water (block embedded in water patch at same height)
    bool isSideFace = abs(dot(waterNormal, vec3(0.0, 1.0, 0.0))) < 0.1;
    return (glass || ice) && water && isSideFace && waterLength >= glassLength;
}
