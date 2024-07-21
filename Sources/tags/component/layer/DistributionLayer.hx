package tags.component.layer;

import crovown.Crovown;
import crovown.algorithm.MathUtils;
import crovown.backend.Backend.SurfaceShader;
import crovown.backend.LimeBackend.LimeSurface;
import crovown.ds.Matrix;
import crovown.ds.Rectangle;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;

@:build(crovown.Macro.component())
class DistributionLayer extends Layer {
    // var shader:LimeDistributionShader = null;    // @todo?
    @:p public var spread:Rectangle = new Rectangle(0, 0, 1, 1);
    @:p public var count:Int = 5;
    @:p public var size:Float = 0.5;
    // @todo rotation

    var shader:SurfaceShader = null;

    public static function build(crow:Crovown, component:DistributionLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        var buffer:LimeSurface = cast(event.buffer);
        shader ??= crow.application.backend.shader(SurfaceShader.label);
        var dst = event.pushBuffer();
        shader.setSurface(buffer);
        dst.setShader(shader);
        for (i in 0...count) {
            dst.pushTransform(Matrix.Translation(
                MathUtils.mix(Math.random(), spread.x - size, spread.x + spread.w) * dst.getWidth(),
                MathUtils.mix(Math.random(), spread.y - size, spread.y + spread.h) * dst.getHeight(),
            ));
            dst.drawRect(0, 0, size * dst.getWidth(), size * dst.getHeight());
            dst.flush();
            dst.popTransform();
        }
        event.popBuffer(Normal);

        event.pushBuffer();
    }

    override function onBackward(event:RenderLayerEvent) {
        event.popBuffer(blend);
    }

    @:eventHandler
    override public function onRenderPropertiesEvent(event:RenderPropertiesEvent) {
        if (event.parent != this) return;
        event.label("Distribution");
        event.number("Count", 0, 100, 1, 1, count, v -> {
            count = Std.int(v);
            return true;
        });
        event.number("Position X", 0, 1, 0.01, 100, spread.x, v -> {
            spread.x = v;
            return true;
        });
        event.number("Position Y", 0, 1, 0.01, 100, spread.y, v -> {
            spread.y = v;
            return true;
        });
        event.number("Size", 0.01, 1.0, 0.01, 100, size, v -> {
            size = v;
            return true;
        });
        event.number("Width", 0.0, 1.0, 0.01, 100, spread.w, v -> {
            spread.w = v;
            return true;
        });
        event.number("Height", 0.0, 1.0, 0.01, 100, spread.h, v -> {
            spread.h = v;
            return true;
        });
    }
}