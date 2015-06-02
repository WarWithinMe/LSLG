// ================
// Fragment shader:
// ================
#version 410 core

in vec2 varTexcoord;
out vec4 color;

uniform float frame;

uniform sampler2D texture1;
uniform sampler2D texture2;

void main() {
  color = texture(texture1, varTexcoord)* 0.5 + texture(texture2, varTexcoord) * 0.5;
}
