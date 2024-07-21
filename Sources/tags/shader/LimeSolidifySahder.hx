package tags.shader;

import crovown.backend.Backend.Shader;
import crovown.backend.Backend.Surface;
import crovown.backend.Context;
import crovown.backend.LimeBackend;
import crovown.ds.Vector;
import crovown.types.Color;
import lime.graphics.opengl.GLProgram;

class LimeSolidifySahder extends Shader {
    public var program(default, null):GLProgram = null;
    var image:LimeSurface = null;
    var color = new Vector();
    var radius = 20;

    public function new(context:Context) {
        program = LimeShader.createProgram(context.structure.generateVertex(), "
            in vec3 pos;
            in vec4 col;
            in vec2 uv;

            uniform sampler2D image;
            uniform vec4 color;
            uniform int radius;

            out vec4 frag;
            
            void main() {
                frag = texture(image, uv);
                if (frag.w > 0.01) {
                    return;
                }
                
                int d = radius * 2;
                for (int i = 0; i < d * d; ++i) {
                    float dx = float(i % d - radius) / 100.0;
                    float dy = float(i / d - radius) / 100.0;
                    vec2 p = uv + vec2(dx, dy);
                    if (texture(image, p).w > 0.01) {
                        frag = color;
                        break;
                    }
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
        LimeShader.setFloat4(program, "color", color.x, color.y, color.z, color.w);
        LimeShader.setInt(program, "radius", radius);
    }

    public function setSurface(surface:Surface) {
        image = cast surface;
    }

    public function setColor(v:Color) {
        color = Color.fromARGB(v);
    }

    public function setRadius(v:Int) {
        radius = v;
    }
}