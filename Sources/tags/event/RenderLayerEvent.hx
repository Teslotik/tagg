package tags.event;

import crovown.backend.Backend;
import crovown.component.Component;
import crovown.ds.Matrix;
import crovown.event.Event;
import crovown.types.Blend;
import tags.component.layer.Layer;

@:build(crovown.Macro.event())
class RenderLayerEvent extends Event {
    var w:Float;
    var h:Float;
    var iBuffer = 0;

    var buffers:Array<Surface> = null;
    public var backbuffer(default, null):Surface = null;

    public var buffer(get, never):Surface;
    function get_buffer() {
        return buffers[iBuffer];
    }

    public var source(get, never):Surface;
    function get_source() {
        return buffers[iBuffer - 1];
    }

    public var mixer:MixShader = null;

    public function new(backend:Backend, maxWidth:Int, maxHeight:Int) {
        super();
        this.w = maxWidth;
        this.h = maxHeight;

        // Up to 30 effects
        buffers = [for (i in 0...30) backend.surface(maxWidth, maxHeight)];
        backbuffer = backend.surface(maxWidth, maxHeight);
        mixer = backend.shader(MixShader.label);
    }

    public function setCamera(w:Int, h:Int) {
        this.w = w;
        this.h = h;
        
        backbuffer.clear(Transparent);
        backbuffer.clearTransform();
        backbuffer.viewport(0, 0, w, h);
        backbuffer.pushTransform(Matrix.Orthogonal(0, w, h, 0, 0.1, 100));
        backbuffer.pushTransform(Matrix.Translation(0, 0, -50));

        for (buffer in buffers) {
            buffer.clear(Transparent);
            buffer.clearTransform();
            buffer.viewport(0, 0, w, h);
            buffer.pushTransform(Matrix.Orthogonal(0, w, h, 0, 0.1, 100));
            buffer.pushTransform(Matrix.Translation(0, 0, -50));
        }
    }

    public function pushBuffer() {
        if (iBuffer + 1 >= buffers.length) throw "Too many effects";
        iBuffer++;
        buffer.clear(Transparent);
        backbuffer.clear(Transparent);
        return buffer;
    }

    public function popBuffer(?blend:Blend, factor = 1.0) {
        if (iBuffer <= 0) throw  "No more buffers";
        
        if (blend == null) {
            buffer.clear(Transparent);
            return buffers[--iBuffer];
        }
        
        var dst = buffer;
        var src = buffers[--iBuffer];
        mixer.setBlend(blend);
        mixer.setSource(src);
        mixer.setDestination(dst);
        mixer.setFactor(factor);
        backbuffer.setShader(mixer);
        backbuffer.fill();
        backbuffer.flush();
        var tmp = backbuffer;
        backbuffer = buffer;
        buffers[iBuffer] = tmp;
        return buffer;
    }

    public function swap() {
        var tmp = backbuffer;
        backbuffer = buffer;
        buffers[iBuffer] = tmp;
        return buffer;
    }

    override function onForward(component:Component) {
        var layer = cast(component, Layer);
        layer.onForward(this);
    }

    override function onBackward(component:Component) {
        var layer = cast(component, Layer);
        layer.onBackward(this);
    }
}