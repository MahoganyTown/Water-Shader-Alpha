#version 430 compatibility

#include "/lib/common.glsl"
#include "/lib/water.glsl"

layout(triangles) in;
layout(triangle_strip, max_vertices = 15) out;

// max_vertices: 3 * PLANES + water background -> input manually
// Here we allow for 4 different planes at most: 3 * 4 + 3 = 15
in vec3 gshNormal[];
in vec4 gshModelPos[];
in vec4 gshColor[];
in vec2 gshTexcoord[];
in vec2 gshLmcoord[];
in flat int gshBlockID[];

out vec3 waterNormal;
out vec4 waterModelPos;
out vec3 worldPosition;
out vec4 ccolor;
out vec2 texcoord;
out vec2 lmcoord;
out float waterMaskID;
out flat int blockID;
out flat int mode;

void main() {
    // Water background mode: only rasterize water fragments to build background in reflection
    if (gshBlockID[0] == 2 && gshBlockID[1] == 2 && gshBlockID[2] == 2) {
        mode = 1;

        for (int i = 0; i < 3; i++) {
            waterNormal = gshNormal[i];
            waterModelPos = shadowModelViewInverse * gl_ModelViewMatrix * gshModelPos[i];
            gl_Position = gbufferProjection * gbufferModelView * waterModelPos;
            EmitVertex();
        }

        EndPrimitive();
    }

    // Planar Reflection mode: duplicate scene tocompute reflection for all blocks at water multiple heights
    mode = 0;

    // Planar Reflection 1st step: invert camera pitch
    mat4 invertedView = invertPitch(gbufferModelView);

    for (int j = 0; j < PLANES; j++) {
        float waterY = float(layersData.waterHeights[j]);

        if (waterY < lowerWorldBound) {
            // If no plane set, don't engage reflection process
            break;
        }
        
        // Distance from block to water Y position
        float distWaterCameraY = abs(waterY + waterBlockOffset - cameraPosition.y);

        for (int i = 0; i < 3; i++) {
            // Remove any shadow view transformation to vertex
            vec4 modelPos = shadowModelViewInverse * gl_ModelViewMatrix * gshModelPos[i];

            // World position of block in world space (scene)
            worldPosition = getWorldPositionFromModelPosition(modelPos);

            // Planar Reflection 2nd step: move down camera (adversely move up entire world) to render reflection picture
            vec3 reflectedBlockPos = modelPos.xyz + 2.0 * vec3(0, distWaterCameraY, 0);

            // Pass-thru to fragment shader
            ccolor = gshColor[i];
            texcoord = gshTexcoord[i];
            lmcoord = gshLmcoord[i];
            blockID = gshBlockID[i];
            waterMaskID = waterY;

            // Vertex position transformed to clip space taking into account camera pitch inversion and camera translation
            gl_Position = gbufferProjection * invertedView * vec4(reflectedBlockPos, 1.0);
            EmitVertex();
        }

        EndPrimitive();
    }
}