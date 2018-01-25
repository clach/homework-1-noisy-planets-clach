#version 300 es

precision highp float;

uniform int u_Time;

in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 color;

const vec3 a = vec3(0.0, 0.2, 0.8);
const vec3 b = vec3(0.2, 0.4, 0.4);
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

void main() {
//#define BASIC
//#define SUMMED
//#define ABSOLUTE
//#define RECURSIVE1
#define RECURSIVE2


#ifdef BASIC
    // Basic Perlin noise
    vec3 fragPos = vec3(fs_Pos);
    vec3 gridPos = PixelToGrid(fragPos, 10.0);
    float perlin = PerlinNoise(gridPos);
    color = vec4(vec3((perlin + 1.0) * 0.5), 1.0);
#endif

// use Summed to get.... a moon ////////////////////////////////////////////////
#ifdef SUMMED
    vec3 fragPos = vec3(fs_Pos);
    float summedNoise = 0.0;
    float amplitude = 0.5;
    for(int i = 2; i <= 32; i *= 2) {
        vec3 gridPos = PixelToGrid(fragPos, float(i));
        //uv = vec2(cos(3.14159/3.0 * i) * uv.x - sin(3.14159/3.0 * i) * uv.y, sin(3.14159/3.0 * i) * uv.x + cos(3.14159/3.0 * i) * uv.y);
        float perlin = abs(PerlinNoise(gridPos)) * amplitude;
        summedNoise += perlin; // * amplitude;
        amplitude *= 0.5;
    }
    //color = vec3(summedNoise);//vec3((summedNoise + 1) * 0.5);
    color = vec4(vec3(summedNoise + 0.3), 1.0);
#endif



// use absoute1 to get.... wiggly space ////////////////////////////////////////////////

#ifdef ABSOLUTE
    vec2 uv = PixelToGrid(gl_FragCoord.xy, 10.0);
    float perlin = PerlinNoise(uv);
    color = vec3(1.0) - vec3(abs(perlin));
//    color.r += step(0.98, fract(uv.x)) + step(0.98, fract(uv.y));
#endif

#ifdef RECURSIVE1
    vec3 fragPos = vec3(fs_Pos);
    vec3 gridPos = PixelToGrid(fragPos, 10.0);
    vec3 offset = vec3(PerlinNoise(gridPos + float(u_Time) * 0.01), PerlinNoise(gridPos + vec3(5.2, 1.3, 2.8)),
        PerlinNoise(gridPos + vec3(1.8, 2.9, 6.1)));
    float perlin = PerlinNoise(gridPos + offset);
    color = vec4(vec3((perlin + 1.0) * 0.5), 1.0);
#endif

#ifdef RECURSIVE2
    // Recursive Perlin noise (2 levels)
    vec3 fragPos = vec3(fs_Pos);
    vec3 gridPos = PixelToGrid(fragPos, 10.0);
    vec3 offset1 = vec3(PerlinNoise(gridPos + cos(float(u_Time) * 3.14159 * 0.01)), 
                        PerlinNoise(gridPos + vec3(5.2, 1.3, 2.8)),
                        PerlinNoise(gridPos + vec3(1.8, 2.9, 6.1)));
    vec3 offset2 = vec3(PerlinNoise(gridPos + offset1 + vec3(1.7, 9.2, 3.4)), 
                        PerlinNoise(gridPos + sin(float(u_Time) * 3.14159 * 0.01) + offset1 + vec3(8.3, 2.8, 4.3)),
                        PerlinNoise(gridPos + sin(float(u_Time) * 3.14159 * 0.01) + offset1 + vec3(2.3, 4.3, 6.7)));
    float perlin = PerlinNoise(gridPos + offset2);
    vec3 gradient = Gradient(perlin);
    gradient = mix(gradient, vec3(perlin), length(offset1));
    vec3 diffuseColor = gradient;


    vec4 lightDirection = vec4(1.0);
    lightDirection.x = 5.0 * sin(float(u_Time) * 3.14159 * 0.009);
    lightDirection.y = 0.0;
    lightDirection.z = 5.0 * cos(float(u_Time) * 3.14159 * 0.009);
    mat4 rotationMat = rotationMatrix(vec3(0.0, 0.8, 1.2), -0.52);
    lightDirection = rotationMat * lightDirection;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(lightDirection));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.15; // ambient lighting (so shadows aren't black)

    // lambertian term
    float lightIntensity = diffuseTerm + ambientTerm;  

    // blinn-phong term
    float specularIntensity = max(pow(dot(normalize(lightDirection), normalize(fs_Nor)), 64.0), 0.0);
    vec3 specularColor = vec3(0.9, 0.9, 1.0); // want specular color to be white

    // Compute final shaded color
    color = vec4(diffuseColor * lightIntensity + specularColor * specularIntensity, 1.0);
#endif



// use moving recrusive 1 for water of some kind 
}
