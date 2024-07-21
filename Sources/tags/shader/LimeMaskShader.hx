package tags.shader;

import crovown.backend.Backend.Shader;
import crovown.backend.Backend.Surface;
import crovown.backend.Context;
import crovown.backend.LimeBackend;
import lime.graphics.opengl.GLProgram;

class LimeMaskShader extends Shader {
    public var program(default, null):GLProgram = null;
    var image:LimeSurface = null;
    var mask:LimeSurface = null;

    public function new(context:Context) {
        program = LimeShader.createProgram(context.structure.generateVertex(), "
            in vec3 pos;
            in vec4 col;
            in vec2 uv;

            uniform sampler2D image;
            uniform sampler2D mask;

            out vec4 frag;
            
            void main() {
                vec4 c = texture(image, uv);
                vec4 m = texture(mask, uv);
                frag = vec4(c.x, c.y, c.z, c.w * m.x);
                // frag = m.x > 0.01 ? c : vec4(0.0, 0.0, 0.0, 0.0);
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
        LimeShader.setTexture(program, "mask", 1, mask.texture);
    }

    public function setSurface(surface:Surface) {
        image = cast surface;
    }

    public function setMask(mask:Surface) {
        this.mask = cast mask;
    }
}