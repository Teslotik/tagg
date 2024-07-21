package tags.component.layer;

import crovown.Crovown;
import crovown.backend.Context;
import crovown.types.Color;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;
import tags.shader.LimeSolidifySahder;

@:build(crovown.Macro.component())
class SolidifyLayer extends Layer {
    @:p public var fill:Color = Green;
    @:p public var radius:Int = 5;
    
    var outline:LimeSolidifySahder = null;
    
    public static function build(crow:Crovown, component:SolidifyLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        outline ??= new LimeSolidifySahder(Context.active);
        outline.setSurface(event.buffer);
        outline.setRadius(radius);
        outline.setColor(fill);
        event.backbuffer.setShader(outline);
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
        event.label("Solidify");
        event.color("Color", fill, v -> {
            fill = v;
            return true;
        });
        event.number("Radius", 0, 20, 1, 1, radius, v -> {
            radius = Std.int(v);
            return true;
        });
    }
}