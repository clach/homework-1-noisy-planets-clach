#version 300 es

precision highp float;
precision mediump int;

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

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

out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;

out float worleyDistance;


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
    vec3 fakeDimensions = vec3(0.4); // some made up grid dimensions
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

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);  

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_Pos = modelposition; // pass the model position (before rotating) to fragment shader

    // worley noise
    vec3 fragPos = vec3(fs_Pos);
    float numWorleyCells = 4.0;
    vec3 worleyGridPos = PixelToGrid(fragPos, numWorleyCells);
    ivec3 worleyCell = ivec3(worleyGridPos);

    float minDistance = worleyNoise(worleyGridPos, worleyCell);
    worleyDistance = minDistance;

    if (minDistance < 0.5) {
        modelposition = modelposition - vec4(clamp(minDistance * fs_Nor.x, 0.0, 0.01),
                                             clamp(minDistance * fs_Nor.y, 0.0, 0.01),
                                             clamp(minDistance * fs_Nor.z, 0.0, 0.01), 0.0); 
    } 

    // calculate light position and light direction
    vec4 lightPos = vec4(5, 5, 3, 1); 
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    // rotate about moon's axis
    mat4 R1 = rotationMatrix(vec3(0.0, 1.0, 0.0), float(u_Time) * 3.14159 * 0.002);
    mat4 T1 = mat4(1.0, 0.0, 0.0, 0.0,
                   0.0, 1.0, 0.0, 0.0,
                   0.0, 0.0, 1.0, 0.0,
                   -4.0, 0.0, 0.0, 1.0);
    mat4 T1_inverse = mat4(1.0, 0.0, 0.0, 0.0,
                           0.0, 1.0, 0.0, 0.0,
                           0.0, 0.0, 1.0, 0.0,
                           4.0, 0.0, 0.0, 1.0);
    modelposition = T1 * R1 * T1_inverse * modelposition;
    fs_Nor = T1 * R1 * T1_inverse * fs_Nor;

    // rotate about origin (main planet)
    mat4 R2 = rotationMatrix(vec3(0.0, 1.1, 0.8), float(u_Time) * 3.14159 * 0.0005);
    modelposition = R2 * modelposition;
    fs_Nor = R2 * fs_Nor;



    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
