#version 430 compatibility

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

#include "/lib/common.glsl"

void setValue(int index, int elem, inout int[PLANES] array) {
    array[index] = elem;
}

void shiftRight(int index, int replacement, inout int[PLANES] array) {
    int j;
    for (j = PLANES - 1; j > index; j--) {
        array[j] = array[j - 1];
    }

    array[j] = replacement;
}

void insert(int Y, int occurence, inout int[PLANES] heights, inout int[PLANES] occurences) {
    for (int i = 0; i < PLANES; i++) {
        if (occurence > occurences[i]) {
            shiftRight(i, lowerWorldBound - 1, heights);
            shiftRight(i, 0, occurences);
            setValue(i, Y, heights);
            setValue(i, occurence, occurences);
            return;
        }
    }
}

void findBiggestWaterPatches(inout int[PLANES] heights, inout int[PLANES] occurences) {
    // Maximum possible height for reflections because cannot reflect inside or below water
    int endY = int(cameraPosition.y);
    // Minimum starting Y position to start looking for water patches
    int startY = max(lowerWorldBound, layersData.lowestHeight);

    // Search water patches from Y=startY going up to camera position, and sort by occurence
    for (int y = startY; y < endY; y++) {
        int occurence = layersData.layers[YToArray(y)];

        if (occurence > 0) {
            // If occurence, then water patch exists at y
            insert(y, occurence, heights, occurences);
        }
    }
}

void main() {
    /* This compute shader computes the ordered list of reflection planes
    Sort by order occurence number, so big water patches are reflected first (next frame)
    This leads to potentially omitting some water patches if too many planes, but the ones discarded are the smallest on screen
    */
    int heights[PLANES] = int[PLANES](lowerWorldBound - 1);
    int occurences[PLANES] = int[PLANES](0);

    findBiggestWaterPatches(heights, occurences);
    layersData.waterHeights = heights;
}