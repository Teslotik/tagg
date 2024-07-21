package tags.shader;

import crovown.backend.Backend.Shader;
import crovown.backend.Backend.Surface;
import crovown.backend.Context;
import crovown.backend.LimeBackend;
import lime.graphics.opengl.GLProgram;

class LimeGlowShader extends Shader {
    public var program(default, null):GLProgram = null;
    var image:LimeSurface = null;
    var radius = 1;
    var inner = false;
    var outer = true;

    public function new(context:Context) {
        program = LimeShader.createProgram(context.structure.generateVertex(), "
            in vec3 pos;
            in vec4 col;
            in vec2 uv;

            uniform sampler2D image;
            uniform int radius;
            uniform int inner;
            uniform int outer;

            out vec4 frag;
            
            void main() {
                vec4 p = texture(image, uv);
                vec4 c = vec4(0.0, 0.0, 0.0, 0.0);

                frag = p;

                // int count = radius * radius;
                int d = radius * 2;
                int count = d * d;
                for (int i = 0; i < d * d; ++i) {
                    float dx = float(i % d - radius) / 100.0;
                    float dy = float(i / d - radius) / 100.0;
                    c += texture(image, uv + vec2(dx, dy));
                }

                if (inner == 1 && p.w > 0.01) {
                    frag = c / float(count);
                }
                
                if (outer == 1 && p.w < 0.01) {
                    frag = c / float(count);
                }
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
        LimeShader.setInt(program, "radius", radius);
        LimeShader.setInt(program, "inner", inner ? 1 : 0);
        LimeShader.setInt(program, "outer", outer ? 1 : 0);
    }

    public function setSurface(surface:Surface) {
        image = cast surface;
    }

    public function setRadius(v:Int) {
        radius = v;
    }

    public function setInner(v:Bool) {
        inner = v;
    }

    public function setOuter(v:Bool) {
        outer = v;
    }
}