package tags.shader;

import crovown.backend.Backend.Shader;
import crovown.backend.Backend.Surface;
import crovown.backend.Context;
import crovown.backend.LimeBackend;
import lime.graphics.opengl.GLProgram;

class LimeColorAdjustShader extends Shader {
    public var program(default, null):GLProgram = null;
    var image:LimeSurface = null;
    var invert = false;

    public function new(context:Context) {
        program = LimeShader.createProgram(context.structure.generateVertex(), "
            in vec3 pos;
            in vec4 col;
            in vec2 uv;

            uniform sampler2D image;
            uniform int invert;

            out vec4 frag;
            
            void main() {
                vec4 c = texture(image, uv);
                if (invert == 1) {
                    c.x = 1.0 - clamp(c.x, 0.0, 1.0);
                    c.y = 1.0 - clamp(c.y, 0.0, 1.0);
                    c.z = 1.0 - clamp(c.z, 0.0, 1.0);
                    c.w = 1.0;
                    // c.w = 1.0 - clamp(c.w, 0.0, 1.0);
                }
                frag = c;
            }
        ");
        context.structure.bind(program);
    }

    override public function apply(surface:Surface) {
        var gl = LimeBackend.gl;
        gl.useProgram(program);
        var surface = cast(surface, LimeSurface);
        LimeShader.setMatrix4(program, "mvp", surface.getLimeTransform());
        LimeShader.setTexture(program, "image", 0, image.texture);
        LimeShader.setInt(program, "invert", invert ? 1 : 0);
    }

    public function setSurface(surface:Surface) {
        image = cast surface;
    }

    public function setInvert(i:Bool) {
        invert = i;
    }
}