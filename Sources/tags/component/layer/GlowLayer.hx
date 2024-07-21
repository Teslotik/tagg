package tags.component.layer;

import crovown.Crovown;
import crovown.backend.Context;
import crovown.types.Color;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;
import tags.shader.LimeGlowShader;

@:build(crovown.Macro.component())
class GlowLayer extends Layer {
    @:p public var radius:Int = 10;
    @:p public var inner:Bool = false;
    @:p public var outer:Bool = true;
    
    var glow:LimeGlowShader = null;
    
    public static function build(crow:Crovown, component:GlowLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        glow ??= new LimeGlowShader(Context.active);
        glow.setSurface(event.buffer);
        glow.setRadius(radius);
        glow.setInner(inner);
        glow.setOuter(outer);
        event.backbuffer.setShader(glow);
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
        event.label("Glow");
        event.checkbox("Inner", inner, v -> {
            inner = v;
            return true;
        });
        event.checkbox("Outer", outer, v -> {
            outer = v;
            return true;
        });
        event.number("Radius", 0, 20, 1, 1, radius, v -> {
            radius = Std.int(v);
            return true;
        });
    }
}