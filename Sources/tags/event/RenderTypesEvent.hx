package tags.event;

import crovown.component.Component;
import crovown.component.widget.LayoutWidget;
import crovown.event.Event;

@:build(crovown.Macro.event())
class RenderTypesEvent extends Event {
    public var parent:Component = null;
    public var layout:LayoutWidget = null;
    public var replace:Bool = false;    // @todo вынести?

    public function new(parent:Component, layout:LayoutWidget, replace = false) {
        super();
        this.parent = parent;
        this.layout = layout;
        this.replace = replace;
    }
}