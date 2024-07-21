package tags.component.layer;

import crovown.Crovown;
import crovown.backend.Context;
import crovown.types.Color;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;
import tags.shader.LimePixelateShader;

@:build(crovown.Macro.component())
class PixelateLayer extends Layer {
    @:p public var radius:Float = 0.01;
    
    var pixelate:LimePixelateShader = null;
    
    public static function build(crow:Crovown, component:PixelateLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        pixelate ??= new LimePixelateShader(Context.active);
        pixelate.setSurface(event.buffer);
        pixelate.setRadius(radius);
        event.backbuffer.setShader(pixelate);
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
        event.label("Pixelate");
        event.number("Radius", 0.01, 1.0, 0.01, 100, radius, v -> {
            radius = v;
            return true;
        });
    }
}