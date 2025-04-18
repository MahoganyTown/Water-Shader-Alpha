float mapRange(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

vec3 getSunPosition() {
    // Compute sun position in world space
	return mat3(gbufferModelViewInverse) * sunPosition;
}

vec3 getMoonPosition() {
    // Compute moon position in world space
	return mat3(gbufferModelViewInverse) * moonPosition;
}

float getSunAmount() {
	// If in between 0 and 12000 => 1.0
	// If between 14000 and 22000 => 0.0
	// Else, interpolation

	float sunsetStart = 12000;
	float sunsetEnd = 13000;
	float sunriseStart = 22000;
	float sunriseEnd = 24000;
	float amount = 0.0;

	// Day
	if (worldTime >= 0 && worldTime < sunsetStart) {
		amount = 1.0;
	}
	// Night
	else if (worldTime >= sunsetEnd && worldTime < sunriseStart) {
		amount = 0.0;
	}
	// Sunrise
	else if (worldTime >= sunriseStart && worldTime < sunriseEnd) {
		amount = mapRange(worldTime, sunriseStart, sunriseEnd, 0.0, 1.0);
	}
	// Sunset
	else if (worldTime >= sunsetStart && worldTime < sunsetEnd) {
		amount = mapRange(worldTime, sunsetStart, sunsetEnd, 1.0, 0.0);
	}

	return amount;
}

float getMidDayFastFrac01() {
	// Return 0-1.0 from start day to midday
	// Roll back from 1.0-0 from midday to end day
	// Return 0.0 if night

	float startDay = 0.0;
	float beforeMidday = 2000.0;
	float afterMidday = 10000.0;
	float endDay = 14000;

	float t = 0.0;

	if (worldTime >= 23000 && worldTime <= 24000) {
		t = mapRange(worldTime, 23000, 24000, 0.0, 0.333);
	}
	else if (worldTime >= startDay && worldTime <= beforeMidday) {
		t = mapRange(worldTime, startDay, beforeMidday, 0.333, 1.0);
	} else if (worldTime > beforeMidday && worldTime <= afterMidday) {
		t = 1.0;
	} else if (worldTime > afterMidday && worldTime <= endDay) {
		t = mapRange(worldTime, afterMidday, endDay, 1.0, 0.0);
	}

	return t;
}

float getNightAmount() {
    // Return 0.0-1.0 from start night to midnight
    // Return 1.0-0.0 from midnight to end night
    // Return 0.0 otherwise
	
    float startNight = 14000;
    float midnight = 18000;
    float endNight = 23000;

	float t = 0.0;

	if (worldTime >= startNight && worldTime <= midnight) {
		t = mapRange(worldTime, startNight, midnight, 0.0, 1.0);
	} else if (worldTime > midnight && worldTime <= endNight) {
		t = mapRange(worldTime, midnight, endNight, 1.0, 0.0);
	}

    return t;
}

float getNightPercentage() {
	// Return 0.0-1.0 from start night to end night
	// Return 1.0 during day

	if (worldTime >= 12500 && worldTime <= 24000) {
		return mapRange(worldTime, 12500, 24000, 0.0, 0.9);
	}
	
	if (worldTime >= 0 && worldTime <= 1000) {
		return mapRange(worldTime, 0, 1000, 0.9, 1.0);
	}

	return 1.0;
}

float getDayPercentage() {
	// Return 0.0-1.0 from start day to end day
	// Return 1.0 during day

	if (worldTime >= 23000 && worldTime <= 24000) {
		return mapRange(worldTime, 23000, 24000, 0.0, 0.1);
	}
	
	if (worldTime >= 0 && worldTime <= 12500) {
		return mapRange(worldTime, 0, 12500, 0.1, 1.0);
	}

	return 1.0;
}

float gradientNoise(vec2 uv) {
    // For banding issues
	// Code from: http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
	return fract(52.9829189 * fract(dot(uv, vec2(0.06711056, 0.00583715))));
}

float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) {
	// Code from Balint's Minecraft shader project template 1.17+
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	float w = (isEyeInWater == 1) ? 0.0 : 0.25;

	// Compute final sky color and remove banding issues
	vec3 color = mix(skyColor, fogColor, fogify(max(upDot, 0.0), w));
    color.rgb += (1.0 / 63.0) * gradientNoise(gl_FragCoord.xy) - (0.5 / 63.0);

	return color;
}

vec3 screenToView(vec3 screenPos) {
	vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * ndcPos;

	return tmp.xyz / tmp.w;
}

bool rayPlaneIntersection(vec3 rayOrigin, vec3 rayDirection, 
	vec3 planeNormal, vec3 planePoint, 
	float size_x, float size_y, out vec2 texCoords) {
    // Calculate the dot product of the ray direction and the plane normal
    float dotProduct = dot(rayDirection, planeNormal);

    // If the dot product is zero, the ray is parallel to the plane
    if (abs(dotProduct) < 1e-6) {
        return false;
    }

    // Calculate the vector from the ray origin to the plane point
    vec3 rayToPlane = planePoint - rayOrigin;

    // Calculate the parameter t where the ray intersects the plane
    float t = dot(rayToPlane, planeNormal) / dotProduct;

    // If t is negative, the intersection is behind the ray origin
    if (t < 0.0) {
        return false;
    }

    // Calculate the intersection point
    vec3 intersectionPoint = rayOrigin + t * rayDirection;

    // Project the intersection point onto the plane's local coordinate system
    vec3 planeXAxis = normalize(cross(planeNormal, vec3(0.0, 1.0, 0.0)));
    vec3 planeYAxis = normalize(cross(planeNormal, planeXAxis));
    vec3 localIntersectionPoint = intersectionPoint - planePoint;
    float localX = dot(localIntersectionPoint, planeXAxis);
    float localY = dot(localIntersectionPoint, planeYAxis);

    // Check if the intersection point is within the bounds of the plane
    if (abs(localX) <= size_x / 2.0 && abs(localY) <= size_y / 2.0) {
        // Calculate the texture coordinates (u, v)
        texCoords.x = (localX + size_x / 2.0) / size_x;
        texCoords.y = (localY + size_y / 2.0) / size_y;
        return true;
    }

    return false;
}

float getSunSize() {
	float risingAmount = getDayPercentage();
	float risingSize = 16.5;
	float settingSize = 14.5;
	float size = mix(risingSize, settingSize, risingAmount);

	return size;
}

float getMoonSize() {
	float risingAmount = getNightPercentage();
	float risingSize = 11.0;
	float settingSize = 9.5;
	float size = mix(risingSize, settingSize, risingAmount);

	return size;
}

vec4 reflectLightCaster(vec3 ro, vec3 rd, vec4 color, vec3 lightCasterPos, float size, vec2 bias) {
	vec3 planeNormal = normalize(-lightCasterPos);
	vec3 planePosition = lightCasterPos;
	vec2 uv = vec2(0.0);

	if (rayPlaneIntersection(ro, rd, planeNormal, planePosition, size, size, uv)) {
		uv += bias;
		vec2 localUV = mix(vec2(-0.275 / 4.5), vec2(0.275 / 4.5), uv);
		localUV.x /= aspectRatio;
		color.rgb = texture(colortex8, vec2(0.5) + localUV).rgb;
	}

	return color;
}

vec4 skyTexturedReflection(vec3 ro, vec3 rd, vec4 color) {
	color = reflectLightCaster(ro, rd, color, getMoonPosition(), getMoonSize(), vec2(0.80));
	color = reflectLightCaster(ro, rd, color, getSunPosition(), getSunSize(), vec2(-0.81));

	return color;
}

vec4 getCloudMask(vec2 uv) {
	return texture(colortex4, uv);
}

bool isCloud(vec4 mask) {
	return mask.r > 0.99;
}

float getCloudLength(vec4 mask) {
	return mask.g;
}