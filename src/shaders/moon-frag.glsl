#version 300 es

precision highp float;
precision mediump int;

uniform int u_Time;

in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

in float worleyDistance;

out vec4 color;

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
    vec3 fakeDimensions = vec3(0.4); // some made up grid dimensions
    vec3 gridPos = pixel / fakeDimensions;
    // Determine number of cells (NxN)
    gridPos *= size;

    return gridPos;
}

void main() {

    vec3 fragPos = vec3(fs_Pos);
        
    float summedNoise = 0.0;
    float amplitude = 0.5;
    for (int i = 2; i <= 32; i *= 2) {
        vec3 gridPos = PixelToGrid(fragPos, float(i));
        float perlin = abs(PerlinNoise(gridPos));
        summedNoise += perlin * amplitude;
        amplitude *= 0.5;
    }

    vec3 diffuseColor = vec3(summedNoise);
    if (worleyDistance <= 0.5) {
        diffuseColor.r = mix(diffuseColor.r, diffuseColor.r - 0.1, 1.0 - (worleyDistance / 0.5));
        diffuseColor.g = mix(diffuseColor.g, diffuseColor.g - 0.1, 1.0 - (worleyDistance / 0.5));
        diffuseColor.b = mix(diffuseColor.b, diffuseColor.b - 0.1, 1.0 - (worleyDistance / 0.5));
    } 
    
    diffuseColor = vec3(clamp(diffuseColor.x + 0.6, 0.0, 1.0), 
                          clamp(diffuseColor.y + 0.2, 0.0, 1.0), 
                          clamp(diffuseColor.z - 0.3, 0.0, 1.0));

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.15; // ambient lighting (so shadows aren't black)

    // lambertian term
    float lightIntensity = diffuseTerm + ambientTerm;  

    // Compute final shaded color
    color = vec4(diffuseColor * lightIntensity, 1.0);
    //color = vec4(vec3(fs_Nor), 1.0);

}
