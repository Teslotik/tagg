package tags.component.layer;

import crovown.Crovown;
import crovown.algorithm.MathUtils;
import crovown.backend.LimeBackend.LimeSurface;
import crovown.ds.Rectangle;
import crovown.types.Color;
import haxe.ds.Option;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;

using crovown.algorithm.Shape;


@:build(crovown.Macro.component())
class ShapeLayer extends Layer {
    @:p public var fill:Color = Yellow;
    @:p public var shape:tags.types.Shape = Rectangle;

    public static function build(crow:Crovown, component:ShapeLayer) {
        return component;
    }

    override function serialize(name:String):Option<Dynamic> {
        switch name {
            case "shape":
                switch shape {
                    case Rectangle: return Some({
                        type: shape.getName()
                    });
                    case Circle: return Some({
                        type: shape.getName()
                    });
                    case Star(radius, count, rotation): return Some({
                        type: shape.getName(),
                        radius: radius,
                        count: count,
                        rotation: rotation
                    });
                }
            default: return super.serialize(name);
        }
    }

    override function deserialize(name:String, v:Dynamic) {
        switch name {
            case "shape":
                switch v.type {
                    case "Rectangle": shape = Rectangle;
                    case "Circle": shape = Circle;
                    case "Star": shape = Star(v.radius, v.count, v.rotation);
                }
            default: super.deserialize(name, v);
        }
    }

    override public function onForward(event:RenderLayerEvent) {
        var buffer:LimeSurface = cast(event.buffer);
        buffer.coloredShader.setColor(fill);
        buffer.setShader(buffer.coloredShader);
        switch shape {
            case Rectangle:
                buffer.drawRect(10, 10, buffer.getWidth() - 20, buffer.getHeight() - 20);
                buffer.flush();
            case Circle:
                buffer.drawCircle(buffer.getWidth() / 2, buffer.getHeight() / 2, buffer.getWidth() / 2, buffer.getHeight() / 2);
                buffer.flush();
            case Star(inner, count, rotation):
                var step = Math.PI / count;
                inner *= buffer.getWidth() / 2;
                var outer = buffer.getWidth() / 2;
                var x = buffer.getWidth() / 2;
                var y = buffer.getHeight() / 2;
                for (i in 0...count) {
                    var angle = step * 2.0 * i + rotation;
                    buffer.drawTri(
                        x, y,
                        x + Math.cos(angle) * outer, y + Math.sin(angle) * outer,
                        x + Math.cos(angle + step) * inner, y + Math.sin(angle + step) * inner
                    );
                    buffer.drawTri(
                        x, y,
                        x + Math.cos(angle) * outer, y + Math.sin(angle) * outer,
                        x + Math.cos(angle - step) * inner, y + Math.sin(angle - step) * inner
                    );
                }
                buffer.flush();
            default:
        }
        event.pushBuffer();
    }

    override public function onBackward(event:RenderLayerEvent) {
        event.popBuffer(blend);
    }

    override function onRenderPropertiesEvent(event:RenderPropertiesEvent) {
        if (event.parent != this) return;
        event.label("Shape");
        event.color("Color", fill, v -> {
            fill = v;
            return true;
        });
        event.radio("Shape", shape.getName(), ["Rectangle", "Circle", "Star"], v -> {
            var match = v == shape.getName();
            if (v == "Rectangle") {
                shape = Rectangle;
            } else if (v == "Circle") {
                shape = Circle;
            } else if (v == "Star") {
                shape = Star(0.5, 5, 0);
            }
            if (!match) event.redraw();
            return true;
        });
        switch shape {
            case Rectangle:
            case Circle:
            case Star(radius, count, rotation):
                event.number("Radius", 0.05, 1.0, 0.05, 100, radius, v -> {
                    radius = v;
                    shape = Star(radius, count, rotation);
                    return true;
                });
                event.number("Count", 2, 8, 1, 1, count, v -> {
                    count = Std.int(v);
                    shape = Star(radius, count, rotation);
                    return true;
                });
                event.number("Rotation", 0, 360, 1, 1, MathUtils.degrees(rotation), v -> {
                    rotation = MathUtils.radians(v);
                    shape = Star(radius, count, rotation);
                    return true;
                });
        }
    }
}