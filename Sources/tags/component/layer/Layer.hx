package tags.component.layer;

import crovown.Crovown;
import crovown.component.Component;
import crovown.component.widget.TreeWidget.TreeItem;
import crovown.types.Blend;
import haxe.ds.Option;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;

@:build(crovown.Macro.component({isVisible:false}))
class Layer extends TreeItem {
    // @:p public var blend:Blend = Normal;
    @:p public var blend:Blend = AlphaOver;

    public function new() {
        super();
        label = "layer";
    }

    override function serialize(name:String):Option<Dynamic> {
        switch name {
            case "blend": return Some(Std.int(blend));
            default: return super.serialize(name);
        }
    }

    override function deserialize(name:String, v:Dynamic) {
        switch name {
            case "blend": blend = v;
            default: super.deserialize(name, v);
        }
    }

    public static function build(crow:Crovown, component:Layer) {
        return component;
    }

    @:eventHandler
    public function onRenderLayerEvent(event:RenderLayerEvent) {
        
    }

    public function onForward(event:RenderLayerEvent) {
        // event.pushBuffer();
    }

    public function onBackward(event:RenderLayerEvent) {
        // event.popBuffer(AlphaOver);
        // event.popBuffer(blend);
    }

    @:eventHandler
    public function onRenderPropertiesEvent(event:RenderPropertiesEvent) {
        
    }
}