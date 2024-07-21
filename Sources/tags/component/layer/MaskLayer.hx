package tags.component.layer;

import crovown.Crovown;
import crovown.backend.Context;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;
import tags.shader.LimeMaskShader;

@:build(crovown.Macro.component())
class MaskLayer extends Layer {
    var mask:LimeMaskShader = null;

    public static function build(crow:Crovown, component:MaskLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        mask ??= new LimeMaskShader(Context.active);
        event.pushBuffer();
    }

    override public function onBackward(event:RenderLayerEvent) {
        mask.setSurface(event.source);
        mask.setMask(event.buffer);
        event.backbuffer.clear(Transparent);
        event.backbuffer.setShader(mask);
        event.backbuffer.fill();
        event.backbuffer.flush();
        event.popBuffer();
        event.swap();
        event.backbuffer.clear(Transparent);
    }

    override function onRenderPropertiesEvent(event:RenderPropertiesEvent) {
        if (event.parent != this) return;
        event.label("Mask");
    }
}