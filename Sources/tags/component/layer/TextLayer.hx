package tags.component.layer;

import crovown.Crovown;
import crovown.backend.Backend.Font;
import crovown.backend.Backend.SdfShader;
import crovown.backend.Backend.Surface;
import crovown.types.Color;
import tags.ds.TagsAssets;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;

typedef Fnt = {
    font:Font,
    texture:Surface
}

@:build(crovown.Macro.component())
class TextLayer extends Layer {
    @:p public var fill:Color = Red;
    @:p public var font:String = null;
    @:p public var text:String = "glagol";
    @:p public var size:Float = 128;
    @:p public var contrast:Float = 0.3;
    @:p public var layerX:Float = 20;
    @:p public var layerY:Float = 20;
    
    public var shader:SdfShader = null;

    public var fonts = new Map<String, Fnt>();

    public static function build(crow:Crovown, component:TextLayer) {
        component.fonts.set("Inter", {
            font: TagsAssets.font_Inter,
            texture: crow.application.backend.loadImage(TagsAssets.image_Inter)
        });

        component.fonts.set("Airfool", {
            font: TagsAssets.font_Airfool,
            texture: crow.application.backend.loadImage(TagsAssets.image_Airfool)
        });

        component.fonts.set("Arco", {
            font: TagsAssets.font_Arco,
            texture: crow.application.backend.loadImage(TagsAssets.image_Arco)
        });
        
        component.fonts.set("Permanent Marker", {
            font: TagsAssets.font_PermanentMarker,
            texture: crow.application.backend.loadImage(TagsAssets.image_PermanentMarker)
        });

        component.fonts.set("Pershotravneva 55", {
            font: TagsAssets.font_Pershotravneva55,
            texture: crow.application.backend.loadImage(TagsAssets.image_Pershotravneva55)
        });

        component.font = "Inter";

        return component;
    }

    override public function onForward(event:RenderLayerEvent) {
        var item = fonts.get(font);
        shader ??= crow.application.backend.shader(SdfShader.label);
        shader.setColor(fill);
        shader.setThreshold(0.45);
        shader.setContrast(contrast);
        shader.setSurface(item.texture);
        event.buffer.setShader(shader);
        event.buffer.setFont(item.font);
        item.font.setSize(size);
        event.buffer.drawString(text, layerX, layerY);
        // @todo in normalized coordinates
        // event.buffer.drawString(text, layerX * event.buffer.getWidth(), layerY * event.buffer.getHeight());
        event.buffer.flush();
        event.pushBuffer();
    }

    override public function onBackward(event:RenderLayerEvent) {
        event.popBuffer(blend);
    }

    @:eventHandler
    override public function onRenderPropertiesEvent(event:RenderPropertiesEvent) {
        if (event.parent != this) return;
        event.label("Text");
        event.text("Text", text, v -> {
            text = v;
            return true;
        });
        event.color("Color", fill, v -> {
            fill = v;
            return true;
        });
        event.number("Position X", -1024, 1024, 5, 1, layerX, v -> {
            layerX = v;
            return true;
        });
        event.number("Position Y", -1024, 1024, 5, 1, layerY, v -> {
            layerY = v;
            return true;
        });
        event.radio("Font", font, [for (f in fonts.keys()) f], v -> {
            font = v;
            return true;
        });
        event.number("Size", 6, 256, 1, 10, size, v -> {
            size = v;
            return true;
        });
        event.number("Contrast", 0.01, 6.0, 0.01, 100, contrast, v -> {
            contrast = v;
            return true;
        });
        event.number("Letter Spacing", -10, 100, 0.1, 10, fonts.get(font).font.letterSpacing[0], v -> {
            fonts.get(font).font.letterSpacing[0] = Std.int(v);
            return true;
        });
        
    }
}