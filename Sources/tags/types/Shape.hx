package tags.types;

enum Shape {
    Rectangle;
    Circle;
    Star(radius:Float, count:Int, rotation:Float);
    // Line(x1:Float, y1:Float, x2:Float, y2:Float, thickness:Float);
    // Parallelogram(skewX:Float, skewY:Float);
}