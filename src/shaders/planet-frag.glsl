#version 300 es

precision highp float;
precision mediump int;

uniform int u_Time;

in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

in float fbmHeight;

uniform int u_LandMoveTime;

out vec4 color;

const vec3 a = vec3(0.0, 80.0, 120.0) / 255.0;
const vec3 b = vec3(0.1, 0.1, 0.1);
const vec3 c = vec3(0.5, 0.5, 0.5);
const vec3 d = vec3(0.0, 0.9, 0.7);

//http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

// Return a random direction in a circle
vec2 random2( vec2 p ) {
    return normalize(2.0 * fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453) - 1.0);
}

vec3 random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

vec3 Gradient(float t) {
    return a + b * cos(6.2831 * (c * t + d));
}

float surflet(vec3 P, vec3 gridPoint) {
    // Compute falloff function by converting linear distance to a polynomial
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float distZ = abs(P.z - gridPoint.z);
    float tX = 1.0 - 6.0 * pow(distX, 5.0) + 15.0 * pow(distX, 4.0) - 10.0 * pow(distX, 3.0);
    float tY = 1.0 - 6.0 * pow(distY, 5.0) + 15.0 * pow(distY, 4.0) - 10.0 * pow(distY, 3.0);
    float tZ = 1.0 - 6.0 * pow(distZ, 5.0) + 15.0 * pow(distZ, 4.0) - 10.0 * pow(distZ, 3.0);

    // Get the random vector for the grid point 
    vec3 gradient = random3(gridPoint);
    // Get the vector from the grid point to P
    vec3 diff = P - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * tX * tY * tZ;
}

float PerlinNoise(vec3 gridPos) {
    // Tile the space
    vec3 gridXLYLZL = floor(gridPos);
    vec3 gridXHYLZL = gridXLYLZL + vec3(1.f, 0.f, 0.f);
    vec3 gridXLYHZL = gridXLYLZL + vec3(0.f, 1.f, 0.f); 
    vec3 gridXLYLZH = gridXLYLZL + vec3(0.f, 0.f, 1.f);
    vec3 gridXHYHZL = gridXLYLZL + vec3(1.f, 1.f, 0.f);
    vec3 gridXHYLZH = gridXLYLZL + vec3(1.f, 0.f, 1.f); 
    vec3 gridXLYHZH = gridXLYLZL + vec3(0.f, 1.f, 1.f);
    vec3 gridXHYHZH = gridXLYLZL + vec3(1.f, 1.f, 1.f);

    return surflet(gridPos, gridXLYLZL) + surflet(gridPos, gridXHYLZL) + surflet(gridPos, gridXLYHZL) + 
        surflet(gridPos, gridXLYLZH) + surflet(gridPos, gridXHYHZL) + surflet(gridPos, gridXHYLZH) + 
        surflet(gridPos, gridXLYHZH) + surflet(gridPos, gridXHYHZH);
}

vec3 PixelToGrid(vec3 pixel, float size) {
    vec3 fakeDimensions = vec3(2.f); // some made up grid dimensions
    vec3 gridPos = pixel / fakeDimensions;
    // Determine number of cells (NxN)
    gridPos *= size;

    return gridPos;
}

float worleyNoise(vec3 gridPos, ivec3 cell) {
    vec3 surroundingPoints[26]; // points within the 26 surrounding cells

    int count = 0;
    for (int i = cell.x - 1; i <= cell.x + 1; i++) {
        for (int j = cell.y - 1; j <= cell.y + 1; j++) {
            for (int k = cell.z -1; k <= cell.z + 1; k++) {
             // get random vec3 from (-1, 1) based on current cell
            vec3 randomP = random3(vec3(i, j, k));
            randomP = (randomP + 1.f) / 2.f; // scale to (0, 1)
            randomP = randomP + vec3(i, j, k); // get random point within current cellID

            surroundingPoints[count] = randomP;
            count++;
            }
        }
    }

    // find closest random point to current fragment
    float minDistance = 9999999.f;
    vec3 closestPoint = vec3(0.f, 0.f, 0.f);
    for (int i = 0; i < surroundingPoints.length(); i++) {
        float distance = sqrt(pow(surroundingPoints[i].x - gridPos.x, 2.0) + 
                              pow(surroundingPoints[i].y - gridPos.y, 2.0) +
                              pow(surroundingPoints[i].z - gridPos.z, 2.0));
        if (distance < minDistance) {
            minDistance = distance;
            closestPoint = surroundingPoints[i];
        }
    }

    return minDistance;
    
}

void main() {
    vec3 fragPos = vec3(fs_Pos);
    vec3 diffuseColor = vec3(0.0);

/*
    // worley noise
    float numWorleyCells = 5.0;
    vec3 worleyGridPos = PixelToGrid(fragPos, numWorleyCells);
    ivec3 worleyCell = ivec3(worleyGridPos);

    float minDistance = worleyNoise(worleyGridPos, worleyCell);

    if (minDistance < 0.5) {
        diffuseColor = vec3(minDistance, 0.1, 0.1);
    } else {*/
    
        // Recursive Perlin noise (2 levels)
        vec3 perlinGridPos = PixelToGrid(fragPos, 15.0);
        vec3 offset1 = vec3(PerlinNoise(perlinGridPos + cos(float(u_Time) * 3.14159 * 0.001)), 
                            PerlinNoise(perlinGridPos + vec3(5.2, 1.3, 2.8)),
                            PerlinNoise(perlinGridPos + vec3(1.8, 2.9, 6.1)));
        vec3 offset2 = vec3(PerlinNoise(perlinGridPos + offset1 + vec3(1.7, 9.2, 3.4)), 
                            PerlinNoise(perlinGridPos + sin(float(u_Time) * 3.14159 * 0.001) + offset1 + vec3(8.3, 2.8, 4.3)),
                            PerlinNoise(perlinGridPos + sin(float(u_Time) * 3.14159 * 0.001) + offset1 + vec3(2.3, 4.3, 6.7)));
        float perlin = PerlinNoise(perlinGridPos + offset2);
        vec3 gradient = Gradient(perlin);
        gradient = mix(gradient, vec3(perlin), length(offset1));
        diffuseColor = gradient;
    //}

    vec3 shoreColor = vec3(190.0, 150.0, 110.0) / 255.0;
    vec3 bottomGreen = vec3(0.0, 0.1, 0.0);
    vec3 topGreen = vec3(0.5, 1.0, 0.5);

    if (fbmHeight > 0.5) {
        if (fbmHeight < 0.55) {
            float scaledFbmHeight = (fbmHeight - 0.5) * 20.0;
            diffuseColor = mix(shoreColor, bottomGreen, scaledFbmHeight);

        } else {
       
            float scaledFbmHeight = (fbmHeight - 0.55) * 2.222222;
            diffuseColor = mix(bottomGreen, topGreen, scaledFbmHeight);
        }

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.15; // ambient lighting (so shadows aren't black)

    // lambertian term
    float lightIntensity = diffuseTerm + ambientTerm;  

    color = vec4(diffuseColor * lightIntensity, 1.0);

   } else {

      if (fbmHeight > 0.49) {
          float shoreScale = (fbmHeight - 0.49) * 100.0;
          diffuseColor = mix(diffuseColor, shoreColor, shoreScale);

      } 

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.15; // ambient lighting (so shadows aren't black)

    // lambertian term
    float lightIntensity = diffuseTerm + ambientTerm;  

    // blinn-phong term
    float specularIntensity = max(pow(dot(normalize(fs_LightVec), normalize(fs_Nor)), 64.0), 0.0);

    // was getting weird specular reflection in shadow, so I made the part in shadow a lambert
    if (dot(normalize(fs_Nor), normalize(fs_LightVec)) < 0.0) {
        color = vec4(diffuseColor * lightIntensity, 1.0);
    } else { // part not in shadow is a blinn-phong
        vec3 specularColor = vec3(0.9, 0.9, 1.0); // want specular color to be white

        // Compute final shaded color
        color = vec4(diffuseColor * lightIntensity + specularColor * specularIntensity, 1.0);
    }
   }

}
