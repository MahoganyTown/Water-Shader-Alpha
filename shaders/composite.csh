#version 430 compatibility

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

#include "/lib/common.glsl"
#include "/lib/water.glsl"

void main() {
    // This compute shader counts the number of water fragments for each height (Y coordinate)
    ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = pixelCoords / iresolution;
    
    vec4 modelPos = getWaterModelPos(uv);
    vec3 normal = getWaterNormal(uv);

    if (isStillWater(modelPos, normal)) {
        // Count water fragment and avoid counting glass as water
        int waterY = getWaterID(modelPos);
        int indexY = YToArray(waterY);

        atomicAdd(layersData.layers[indexY], 1);

        if (waterY < layersData.lowestHeight) {
            layersData.lowestHeight = waterY;
        }
    }
}