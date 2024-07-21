package tags.shader;

import crovown.backend.Backend.Shader;
import crovown.backend.Backend.Surface;
import crovown.backend.Context;
import crovown.backend.LimeBackend;
import lime.graphics.opengl.GLProgram;

class LimePixelateShader extends Shader {
    public var program(default, null):GLProgram = null;
    var image:LimeSurface = null;
    var radius = 1.0;

    public function new(context:Context) {
        program = LimeShader.createProgram(context.structure.generateVertex(), "
            in vec3 pos;
            in vec4 col;
            in vec2 uv;

            uniform sampler2D image;
            uniform float radius;

            out vec4 frag;
            
            void main() {
                frag = texture(image, vec2(
                    floor(uv.x / radius) * radius,
                    floor(uv.y / radius) * radius
                ));
                frag.w = 1.0;
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
        LimeShader.setFloat(program, "radius", radius);
    }

    public function setSurface(surface:Surface) {
        image = cast surface;
    }

    public function setRadius(v:Float) {
        radius = v;
    }
}