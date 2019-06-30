attribute vec4 Position;
attribute vec2 TextureCoord;

varying vec2 TextureCoordsVarying;

void main() {
    gl_Position = Position;
    TextureCoordsVarying = TextureCoord;
}
