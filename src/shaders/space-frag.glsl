#version 300 es

precision highp float;

uniform vec2 u_AspectRatio;
uniform int u_Time;

in vec4 fs_Pos;
out vec4 out_Col;

// noise function that returns vec2 in the range (-1, 1)
vec2 random2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))) ) * 43758.5453);
}

// returns value between -1 and 1
float rand(vec2 n) {
    return (fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453));
}

float interpNoise2D(float x, float y) {
    float intX = floor(x);
    float fractX = fract(x);
    float intY = floor(y);
    float fractY = fract(y);

    float v1 = rand(vec2(intX, intY));
    float v2 = rand(vec2(intX + 1.0, intY));
    float v3 = rand(vec2(intX, intY + 1.0));
    float v4 = rand(vec2(intX + 1.0, intY + 1.0));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);

    return mix(i1, i2, fractY);
}

// returns float from 0 to 2
float fbm(float x, float y) {
    float total = 0.0;
    float persistence = 0.7;
    int octaves = 8;

    for (int i = 0; i < octaves; i++) {
        float freq = pow(2.0, float(i));
        float amp = pow(persistence, float(i));

        total += interpNoise2D(x * freq, y * freq) * amp;
    }

    return total;
}

mat2 rotate2D(float angle) { 
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)); 
}

void main() {
    // frag coord now represents window width/height
	vec2 fragCoord = ((fs_Pos.xy + 1.0) / 2.0); // * u_AspectRatio.xy;

    // galaxy colors of bg       	
    float fbmResult1 = fbm(fragCoord.x * 5.0, fragCoord.y * 5.0);
    fbmResult1 = fbmResult1 * 0.05;

    float fbmResult2 = fbm((fragCoord.x + 10.0) * 5.0, (fragCoord.y + 10.0) * 5.0);
    fbmResult2 = fbmResult2 * 0.08;

    vec3 color = vec3(0.0, 0.0, 0.0);
    vec3 purple = vec3(0.2, 0.0, 0.6);
    vec3 pink = vec3(0.78, 0.08, 0.52);

    color += fbmResult1 * purple;
    color += fbmResult2 * pink;



    // stars using worley noise
    int numCells = 15; // number of cells
    vec2 cellUV = fragCoord.xy * float(numCells);
    ivec2 cellID = ivec2(cellUV); // current cell
    vec2 surroundingPoints[9]; // points within the 9 surrounding cells

    int count = 0;
    for (int i = cellID.x - 1; i <= cellID.x + 1; i++) {
        for (int j = cellID.y - 1; j <= cellID.y + 1; j++) {
             // get random vec2 from (-1, 1) based on current cell, position varies with time
            vec2 randomPoint = cos(2.f * 3.14159265358979 * random2(vec2(float(i), float(j))));
            randomPoint = (randomPoint + 1.0) / 2.0; // scale to (0, 1)
            randomPoint = randomPoint + vec2(float(i), float(j)); // get random point within current cellID

            surroundingPoints[count] = randomPoint;
            count++;
        }
    }

    // find closest random point to current fragment
    float minDistance = 9999999.0;
    vec2 closestPoint = vec2(0.0, 0.0);
    for (int i = 0; i < surroundingPoints.length(); i++) {
        float distance = sqrt(pow(surroundingPoints[i].x - cellUV.x, 2.0) + pow(surroundingPoints[i].y - cellUV.y, 2.0));
        if (distance < minDistance) {
            minDistance = distance;
            closestPoint = surroundingPoints[i];
        }
    }

    float starRadius = 0.05 * (rand(closestPoint) + 1.0) * 0.5 * (rand(closestPoint) + 1.0) * 0.5 * ((sin(float(u_Time) * 0.002 * rand(closestPoint)) + 1.0) * 0.5) + 0.005; 
    if (minDistance < starRadius) {
        color += vec3(1.0, 1.0, 1.0) / (100.0 * minDistance);
    }

    //color = vec3(fragCoord.x, 0.0, 0.0);
    out_Col = vec4(color, 1.0);


}