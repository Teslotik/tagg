package tags.component.layer;

import crovown.Crovown;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;

@:build(crovown.Macro.component())
class FolderLayer extends Layer {
    public static function build(crow:Crovown, component:FolderLayer) {
        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        
    }

    override public function onBackward(event:RenderLayerEvent) {
        
    }

    override function onRenderPropertiesEvent(event:RenderPropertiesEvent) {
        if (event.parent != this) return;
        event.label("Folder");
    }
}