package tags.shader;

import crovown.backend.Backend.Shader;
import crovown.backend.Backend.Surface;
import crovown.backend.Context;
import crovown.backend.LimeBackend;
import crovown.ds.Vector;
import crovown.types.Color;
import lime.graphics.opengl.GLProgram;

class LimeDitherShader extends Shader {
    public var program(default, null):GLProgram = null;
    var image:LimeSurface = null;
    var color = Vector.Ones();
    var power = 1.0;
    var frequency = 1.0;

    public function new(context:Context) {
        program = LimeShader.createProgram(context.structure.generateVertex(), "
            in vec3 pos;
            in vec4 col;
            in vec2 uv;

            uniform sampler2D image;
            uniform vec4 color;
            uniform float power;
            uniform float frequency;

            out vec4 frag;
            
            void main() {
                float x = sin(uv.x * frequency);
                float y = sin(uv.y * frequency);
                float v = pow(x * y, power);
                frag = vec4(color.xyz, v > 0.01 ? 1.0 : 0.0);
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
        LimeShader.setFloat(program, "power", power);
        LimeShader.setFloat(program, "frequency", frequency);
    }

    public function setSurface(surface:Surface) {
        image = cast surface;
    }

    public function setColor(c:Color) {
        color = Color.fromARGB(c);
    }

    public function setPower(v:Float) {
        power = v;
    }

    public function setFrequency(v:Float) {
        frequency = v;
    }
}