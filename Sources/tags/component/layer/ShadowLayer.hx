package tags.component.layer;

import crovown.Crovown;
import crovown.backend.Context;
import crovown.ds.Vector;
import crovown.types.Color;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;
import tags.shader.LimeShadowShader;

@:build(crovown.Macro.component())
class ShadowLayer extends Layer {
    @:p public var fill:Color = Green;
    @:p public var origin:Vector = new Vector();
    @:p public var magnitude:Float = 0.1;
    @:p public var samples:Int = 50;
    
    var shadow:LimeShadowShader = null;
    
    public static function build(crow:Crovown, component:ShadowLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        shadow ??= new LimeShadowShader(Context.active);
        shadow.setSurface(event.buffer);
        shadow.setColor(fill);
        shadow.setOrigin(origin.x, origin.y);
        shadow.setMagnitude(magnitude);
        shadow.setSamples(samples);
        event.backbuffer.setShader(shadow);
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
        event.label("Shadow");
        event.color("Color", fill, v -> {
            fill = v;
            return true;
        });
        event.number("Origin X", -5.0, 5.0, 0.05, 100, origin.x, v -> {
            origin.x = v;
            return true;
        });
        event.number("Origin Y", -5.0, 5.0, 0.05, 100, origin.y, v -> {
            origin.y = v;
            return true;
        });
        event.number("Magnitude", 0.0, 1.0, 0.05, 100, magnitude, v -> {
            magnitude = v;
            return true;
        });
        event.number("Samples", 1, 100, 1, 1, samples, v -> {
            samples = Std.int(v);
            return true;
        });
    }
}