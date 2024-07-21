package tags.component.layer;

import crovown.Crovown;
import crovown.component.Component;
import crovown.types.Color;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;

@:build(crovown.Macro.component())
class FillLayer extends Layer {
    @:p public var fill:Color = Blue;

    public static function build(crow:Crovown, component:FillLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        var shader = event.buffer.coloredShader;
        shader.setColor(fill);
        event.buffer.setShader(shader);
        event.buffer.fill();
        event.buffer.flush();
        event.pushBuffer();
    }

    override public function onBackward(event:RenderLayerEvent) {
        event.popBuffer(blend);
    }

    @:eventHandler
    override public function onRenderPropertiesEvent(event:RenderPropertiesEvent) {
        if (event.parent != this) return;
        event.label("Fill");
        event.color("Color", fill, v -> {
            fill = v;
            return true;
        });
    }
}