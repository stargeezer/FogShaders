attribute vec4 Position;
uniform mat4 Projection;

attribute vec2 TexCoordIn;
varying vec2 TexCoordOut;

void main(void)
{
    gl_Position = Position * Projection;
    TexCoordOut = TexCoordIn;
}