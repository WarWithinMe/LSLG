About
----------
I was thinking learning swift and opengl/glsl. So I made LSLG, an OSX application to view opengl shaders.


Interface
----------
<img src="https://raw.githubusercontent.com/WarWithinMe/LSLG/master/Screenshot.jpg" width="363">

Buttons in the top-left corner : Close, Pin, 50% Transparent

Buttons in the bottom-right corner : VertexShader, GeometryShader, FragmentShader, Model, Log, Settings.

Notice that Shader button is only visible when your working folder has shaders.


Get started
----------
Drag your working folder to an LSLG window, then the window will try to visualize your assets.
Your working folder would contain your shader source, model and texture.
Whenever your assets change, LSLG will automatically reload.


Interaction
----------
Move : `w` `s` `a` `d` `↑` `↓` `←` `→` `right mouse drag`

Rotate : `left mouse drag`

Reset : `r`

Zoom  : `scrollwheel`

Show normal : `n`


Vertex Shader
----------
Files with `.vert` extension is consider vertex shader by default.

Checkout the built-in vertex shader to see the defined inputs:
```
// Built-in Vertex Shader
#version 410 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 texcord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float frame;

out vec2 varTexcoord;

void main()
{
    gl_Position = projection * view * model * vec4(position, 1.0);
    varTexcoord = texcord;
}
```

Fragment Shader
----------
Files with `.frag` extension is consider fragment shader by default.
```
// Built-in Fragment Shader
#version 410 core

in vec2 varTexcoord;
out vec4 color;

uniform float frame;

void main() {
  color = vec4(varTexcoord, sin(radians(mod(frame,360.0))), 1.0);
}
```

Geometry Shader
----------
Files with `.geom` extension is consider fragment shader by default.


Model
----------
Files with `.obj` extension is consider model. Currently only `Wavefront` obj format is supported.
The face can be triangle or quad. Texture Coordinate or Normal is optional.


Texture
----------
All images(png, bmp, jpg) in working folder are imported as texture.
If there're two images, you can reference them in shader by `texture1`, `texture2`.
Images are sorted by its name.

For example, if there're `apple.jpg` `banana.png` `cherry.bmp` in the working folder.
Reference them in fragment shader:
```
// ================
// Fragment shader:
// ================
#version 410 core

in vec2 varTexcoord;
out vec4 color;

uniform sampler2D texture1; // This is apple.jpg
uniform sampler2D texture2; // This is banana.png
uniform sampler2D texture3; // This is cherry.bmp

void main() {}
```
