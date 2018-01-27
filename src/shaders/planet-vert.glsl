#version 300 es

precision highp float;
precision mediump int;

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform int u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

uniform int u_LandMoveTime;

out float fbmHeight;

out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

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


float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float fbm(vec3 x) {
	float v = 0.0;
	float a = 0.5;
    vec3 shift;
    
    shift = vec3(10.0 * mod289(0.0003 * float(u_LandMoveTime)));
	
	for (int i = 0; i < 10; ++i) {
		v += a * noise(x);
		x = x * 2.5 + shift;
		a *= 0.5;
	}
	return v;
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_Pos = modelposition;

    // calculate FBM for height of terrain
    vec3 fragPos = vec3(fs_Pos);
    fbmHeight = fbm(fragPos);

    if (fbmHeight > 0.5) {
        // terrain becomes land
        modelposition = modelposition + fbmHeight * vs_Nor;
    } else {
        // terrain becomes water (water moves up and down a little to look like waves)
        modelposition = modelposition + 0.5 * vs_Nor;
        modelposition = modelposition + 0.01 * cos(6.282 * 0.01 * float(u_Time) * fbmHeight) * vs_Nor;
    }

    // rotate about origin
    mat4 R = rotationMatrix(vec3(0.2, 0.2, 0.7), float(u_Time) * 3.14159 * 0.0005);
    modelposition = R * modelposition;

    // Compute the direction in which the light source lies
    vec4 lightPos = vec4(5, 5, 3, 1);
    fs_LightVec = lightPos - modelposition; 

    fs_Nor = R * fs_Nor;

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

}
