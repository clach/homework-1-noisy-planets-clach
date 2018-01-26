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

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);  

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_Pos = modelposition; // pass the model position (before rotating) to fragment shader

    // calculate light position and light direction
    vec4 lightPos = vec4(1.0);
    lightPos.x = 10.0 * sin(float(u_Time) * 3.14159 * 0.001);
    lightPos.y = 0.0;
    lightPos.z = 10.0 * cos(float(u_Time) * 3.14159 * 0.001);
    mat4 rotationMat = rotationMatrix(vec3(0.0, 0.8, 1.2), -0.52);
    lightPos = rotationMat * lightPos;
    lightPos = vec4(5, 5, 3, 1); 
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies


    // rotate about moon's axis
    mat4 R1 = rotationMatrix(vec3(0.0, 1.0, 0.0), float(u_Time) * 3.14159 * 0.005);
    mat4 T1 = mat4(1.0, 0.0, 0.0, 0.0,
                   0.0, 1.0, 0.0, 0.0,
                   0.0, 0.0, 1.0, 0.0,
                   -2.0, 0.0, 0.0, 1.0);
    mat4 T1_inverse = mat4(1.0, 0.0, 0.0, 0.0,
                           0.0, 1.0, 0.0, 0.0,
                           0.0, 0.0, 1.0, 0.0,
                           2.0, 0.0, 0.0, 1.0);
    modelposition = T1 * R1 * T1_inverse * modelposition;
    fs_Nor = T1 * R1 * T1_inverse * fs_Nor;

    // rotate about origin (main planet)
    mat4 R2 = rotationMatrix(vec3(0.0, 1.1, 0.8), float(u_Time) * 3.14159 * 0.0005);
    modelposition = R2 * modelposition;
    fs_Nor = R2 * fs_Nor;



    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
