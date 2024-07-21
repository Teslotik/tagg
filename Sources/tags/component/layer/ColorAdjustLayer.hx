package tags.component.layer;

import crovown.Crovown;
import crovown.backend.Context;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;
import tags.shader.LimeColorAdjustShader;

@:build(crovown.Macro.component())
class ColorAdjustLayer extends Layer {
    @:p public var invert:Bool = false;
    
    var adjust:LimeColorAdjustShader = null;
    
    public static function build(crow:Crovown, component:ColorAdjustLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        adjust ??= new LimeColorAdjustShader(Context.active);
        adjust.setSurface(event.buffer);
        adjust.setInvert(invert);
        event.backbuffer.setShader(adjust);
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
        event.label("Color Adjust");
        event.checkbox("Invert", invert, v -> {
            invert = v;
            return true;
        });
    }
}