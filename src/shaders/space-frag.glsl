#version 300 es

precision highp float;

uniform vec2 u_AspectRatio;
uniform int u_Time;

in vec4 fs_Pos;
out vec4 out_Col;

mat2 rotate2D(float angle) { 
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)); 
}

void main() {
    // frag coord now represents window width/height
	vec2 fragCoord = ((fs_Pos.xy + 1.0) / 2.0) * u_AspectRatio.xy;
	
	vec3 viewDir = getRayDirection(45.0, u_AspectRatio.xy, fragCoord);
    
    mat4 viewToWorld = getViewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);

    vec2 pos = (fragCoord.xy - 0.5 * u_AspectRatio.xy) / u_AspectRatio.y;
    vec2 rotatedPos = rotate2D(0.6) * pos;
                    
    float xMax = 0.5 * u_AspectRatio.x / u_AspectRatio.y;
	
    out_Col = vec4(color, 1.0);

}