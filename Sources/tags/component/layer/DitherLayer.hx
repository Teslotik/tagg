package tags.component.layer;

import crovown.Crovown;
import crovown.backend.Context;
import crovown.types.Color;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;
import tags.shader.LimeDitherShader;

@:build(crovown.Macro.component())
class DitherLayer extends Layer {
    @:p public var radius:Int = 10;
    @:p public var fill:Color = Red;
    @:p public var power:Float = 1.0;
    @:p public var frequency:Float = 20.0;
    
    var dither:LimeDitherShader = null;
    
    public static function build(crow:Crovown, component:DitherLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        dither ??= new LimeDitherShader(Context.active);
        dither.setSurface(event.buffer);
        dither.setColor(fill);
        dither.setPower(power);
        dither.setFrequency(frequency);
        event.backbuffer.setShader(dither);
        event.backbuffer.fill();
        event.backbuffer.flush();
        event.swap();
        event.pushBuffer();
    }

    override public function onBackward(event:RenderLayerEvent) {
        event.popBuffer(blend);
    }

    override function onRenderPropertiesEvent(event:RenderPropertiesEvent) {
        if (event.parent != this) return;
        event.label("Dither");
        event.color("Color", fill, v -> {
            fill = v;
            return true;
        });
        event.number("Power", 0, 5, 0.1, 10, power, v -> {
            power = v;
            return true;
        });
        event.number("Frequency", 0, 200, 1, 10, frequency, v -> {
            frequency = v;
            return true;
        });
    }
}