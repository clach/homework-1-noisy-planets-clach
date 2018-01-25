#version 300 es
#define M_PI 3.1415926535897932384626433832795

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;
precision mediump int;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

uniform int u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        float distanceFromCenter = length(vec3(fs_Pos.x, fs_Pos.y, fs_Pos.z));

        float redColor = (sin(abs(distanceFromCenter - (float(u_Time) * 0.05)) * M_PI) + 1.0) * 0.5;
        float blueColor = (cos(abs(distanceFromCenter - (float(u_Time) * 0.05)) * M_PI) + 1.0) * 0.5;
        vec4 color = vec4(redColor, blueColor, 0.8, 1.0);

        // Compute final shaded color
        out_Col = vec4(color.rgb * lightIntensity, color.a);
        
}
