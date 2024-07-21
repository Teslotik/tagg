package tags.shader;

import crovown.backend.Backend.Shader;
import crovown.backend.Backend.Surface;
import crovown.backend.Context;
import crovown.backend.LimeBackend;
import crovown.ds.Vector;
import crovown.types.Color;
import lime.graphics.opengl.GLProgram;

class LimeShadowShader extends Shader {
    public var program(default, null):GLProgram = null;
    var image:LimeSurface = null;
    var color = new Vector();
    var origin = new Vector();
    var magnitude = 1.0;
    var samples = 10;

    public function new(context:Context) {
        program = LimeShader.createProgram(context.structure.generateVertex(), "
            in vec3 pos;
            in vec4 col;
            in vec2 uv;

            uniform sampler2D image;
            uniform vec4 color;
            uniform vec2 origin;
            uniform float magnitude;
            uniform int samples;

            out vec4 frag;
            
            void main() {
                frag = texture(image, uv);
                if (frag.w > 0.01) {
                    return;
                }

                // float r = 1.0; // @todo lamp radius
                for (int s = 0; s < samples; s++) {
                    vec2 offset = (origin - uv) * (float(s) / float(samples)) * magnitude;
                    vec4 c = texture(image, uv + offset);
                    if (c.w < 0.01) continue;
                    // frag = vec4(c.xyz * color.xyz, color.w);
                    frag = color;
                    break;
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
        LimeShader.setFloat2(program, "origin", origin.x, origin.y);
        LimeShader.setFloat(program, "magnitude", magnitude);
        LimeShader.setInt(program, "samples", samples);
    }

    public function setSurface(surface:Surface) {
        image = cast surface;
    }

    public function setColor(v:Color) {
        color = Color.fromARGB(v);
    }

    public function setOrigin(x:Float, y:Float) {
        origin.set(x, 1 - y);
    }

    public function setMagnitude(v:Float) {
        magnitude = v;
    }

    public function setSamples(v:Int) {
        samples = v;
    }
}