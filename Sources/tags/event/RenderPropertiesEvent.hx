package tags.event;

import crovown.Crovown;
import crovown.algorithm.MathUtils;
import crovown.component.Component;
import crovown.component.OperationComponent;
import crovown.event.Event;
import tags.plugin.TaggPlugin.TTTheme;

using crovown.component.widget.BoxWidget;
using crovown.component.widget.LayoutWidget;
using crovown.component.widget.RadioProperty;
using crovown.component.widget.SplitWidget;
using crovown.component.widget.TextEditWidget;
using crovown.component.widget.TextWidget;
using crovown.component.widget.Widget;

@:build(crovown.Macro.event())
class RenderPropertiesEvent extends Event {
    public var crow:Crovown = null;
    public var theme:TTTheme = null;
    public var parent:Component = null;
    public var root:Component = null;
    public var layout:LayoutWidget = null;

    public function new(crow:Crovown, theme:TTTheme, root:Component, parent:Component, layout:LayoutWidget) {
        super();
        this.crow = crow;
        this.theme = theme;
        this.root = root;
        this.parent = parent;
        this.layout = layout;
    }

    public function redraw() {
        crow.application.delay(app -> {
            layout.removeChildren();
            root.dispatch(this);
        });
    }

    public function label(label:String, align = 0.0) {
        layout.addChild(Label(label, align));
    }

    public function checkbox(label:String, value:Bool, onChange:Bool->Bool) {
        layout.addChild(Checkbox(label, value, v -> {
            if (onChange(v)) cast(root.get("redraw"), OperationComponent).execute(crow);
        }));
    }

    public function number(title:String, min:Float, max:Float, step:Float, round = 10, value:Float, onChange:Float->Bool) {
        layout.addChild(Number(title, min, max, step, round, value, v -> {
            if (onChange(v)) cast(root.get("redraw"), OperationComponent).execute(crow);
        }));
    }

    public function text(title:String, value:String, onChange:String->Bool) {
        layout.addChild(Text(title, value, v -> {
            if (onChange(v)) cast(root.get("redraw"), OperationComponent).execute(crow);
        }));
    }

    public function color(title:String, value:crovown.types.Color, onChange:Int->Bool) {
        layout.addChild(ColorPicker(title, value, v -> {
            if (onChange(v)) cast(root.get("redraw"), OperationComponent).execute(crow);
        }));
    }

    public function radio(title:String, value:String, options:Array<String>, onChange:String->Bool) {
        layout.addChild(Radio(title, value, options, v -> {
            if (onChange(v)) cast(root.get("redraw"), OperationComponent).execute(crow);
        }));
    }

    public function Label(label:String, align = 0.0) {
        return crow.TextWidget(text -> {
            text.text = label;
            text.align = align;
        });
    }

    public function Checkbox(label:String, value:Bool, onChange:Bool->Void) {
        return crow.LayoutWidget(layout -> {
            layout.color = Color(Transparent);
            layout.direction = Row;
            layout.vertical = Hug;
            layout.horizontal = Fill;
            layout.gap = Fixed(theme.gap);
        }, [
            crow.TextWidget(text -> {
                text.text = '${label}';
                text.align = 0;
            }),
            crow.BoxWidget(box -> {
                box.color = Color(value ? theme.accent : theme.background);
                box.align = 0;
                box.horizontal = Fixed(theme.icon);
                box.vertical = Fixed(theme.icon);
                box.borderColor = Color(theme.foreground);
                box.borderWidth = All(theme.thickness);
                box.borderRadius = All(4);
                box.onInput = event -> {
                    var area = box.getArea();
                    if (area.isReleased) {
                        value = !value;
                        box.color = Color(value ? theme.accent : theme.background);
                        onChange(value);
                    }
                    return true;
                }
            })
        ]);
    }

    public function Number(title:String, min:Float, max:Float, step:Float, round = 10, value:Float, onChange:Float->Void) {
        var text:TextWidget = null;
        return crow.LayoutWidget(layout -> {
            layout.color = Color(Transparent);
            layout.direction = Column;
            layout.vertical = Hug;
            layout.horizontal = Fill;
            layout.gap = Fixed(theme.gap);
        }, [
            text = crow.TextWidget(text -> {
                text.text = '${title}: ${value}';
                text.align = -1;
            }),
            crow.SplitWidget(split -> {
                split.label = "slider";
                split.color = Color(theme.foreground);
    
                split.pos = Scale(MathUtils.lerp(value, min, 0, max, 1));
    
                split.onChange = v -> {
                    var v = switch v {
                        // Трансформируем положение от 0 до 1 в значение
                        // и затем, выравниваем по шагу
                        case Scale(v): Std.int(MathUtils.mix(v, min, max) / step) * step;
                        default: 0;
                    }
                    // Убираем ошибки округления
                    var value = Math.round(v * round) / round;
                    text.text = '${title}: ${value}';
                    onChange(value);
                }
    
                split.splitter = crow.BoxWidget(box -> {
                    box.color = Color(Transparent);
                    box.horizontal = Fixed(theme.thickness);
                }, [
                    crow.BoxWidget(box -> {
                        box.label = "picker";
                        split.drag = _ -> box.getArea();
                    })
                ]);
    
                split.first = crow.BoxWidget(box -> box.color = Color(Transparent));
                split.second = crow.BoxWidget(box -> box.color = Color(Transparent));
            })
        ]);
    }

    public function Text(title:String, placeholder:String, onChange:String->Void) {
        return crow.LayoutWidget(layout -> {
            layout.color = Color(Transparent);
            layout.direction = Row;
            layout.vertical = Hug;
            layout.horizontal = Fill;
            layout.gap = Fixed(theme.gap);
            layout.onInput = event -> {
                var area = layout.getArea();
                return !area.wasDown;
            }
        }, [
            crow.TextWidget(text -> {
                text.text = '${title}:';
            }),
            crow.TextEditWidget(edit -> {
                edit.text = placeholder;
                edit.onChange = _ -> {
                    onChange(edit.text);
                }
                edit.onReady = _ -> {
                    edit.color = Color(theme.second);
                }
            })
        ]);
    }

    public function DropBox() {

    }

    public function Radio(title:String, value:String, options:Array<String>, onChange:String->Void) {
        return crow.LayoutWidget(layout -> {
            layout.color = Color(Transparent);
            layout.direction = Column;
            layout.vertical = Hug;
            layout.horizontal = Fill;
            layout.gap = Fixed(theme.gap);
        }, [
            crow.TextWidget(text -> {
                text.text = '${title}:';
                text.align = -1;
            }),
            crow.RadioProperty(radio -> {
                radio.color = Color(theme.background);
                radio.horizontal = Hug;
                radio.vertical = Hug;
                radio.direction = Column;
                radio.padding = theme.insets;
                radio.gap = Fixed(theme.gap);
                radio.borderColor = Color(theme.foreground);
                radio.borderWidth = All(theme.thickness);
                radio.borderRadius = All(theme.radius);
                radio.onChange = _ -> onChange(cast(radio.active, TextWidget).text);
            }, [for (option in options) crow.TextWidget(text -> {
                text.isActive = option == value;
                text.text = option;
                text.align = -1;
                text.onInput = event -> {
                    text.color = Color(text.isActive ? theme.accent: theme.foreground);
                    var area = text.getArea();
                    if (area.isReleased) {
                        text.isActive = true;
                    }
                    return !area.wasDown;
                }
            })])
        ]);
    }

    public function ColorPicker(title:String, value:crovown.types.Color, onChange:Int->Void) {
        var color = crovown.types.Color.ARGBToHSVA(value);
        var preview:Widget = null;

        return crow.LayoutWidget(layout -> {
            layout.color = Color(Transparent);
            layout.direction = Column;
            layout.vertical = Hug;
            layout.horizontal = Fill;
            layout.gap = Fixed(theme.gap);
        }, [
            preview = crow.TextWidget(text -> {
                text.text = '${title}';
                text.align = -1;
            }),
            crow.SplitWidget(split -> {
                split.label = "slider";
                split.color = LinearGradient(0, 0, 1, 0, [for (i in 0...16) {
                    stop: i / 16,
                    color: crovown.types.Color.fromHSVA(i / 16, 1, 1, 1)
                }]);
                
                var picker:Widget = null;

                split.splitter = crow.BoxWidget(box -> {
                    box.color = Color(Transparent);
                    box.horizontal = Fixed(theme.thickness);
                }, [
                    picker = crow.BoxWidget(box -> {
                        box.label = "picker";
                        split.drag = _ -> box.getArea();
                    })
                ]);

                split.first = crow.BoxWidget(box -> box.color = Color(Transparent));
                split.second = crow.BoxWidget(box -> box.color = Color(Transparent));

                split.onChange = anchor -> {
                    var v = switch anchor {
                        case Scale(v): color.x = v;
                        default: 0;
                    }
                    picker.color = Color(crovown.types.Color.fromHSVA(color.x, 1, 1, 1));
                    var value = crovown.types.Color.fromHSVA(color.x, color.y, color.z, color.w);
                    preview.color = Color(value);
                    onChange(value);
                }
                split.pos = Scale(color.x);
                split.onChange(split.pos);
            }),
            crow.SplitWidget(split -> {
                split.label = "slider";
                split.color = LinearGradient(0, 0, 1, 0, [for (i in 0...16) {
                    stop: i / 16,
                    color: crovown.types.Color.fromHSVA(1, i / 16, 1, 1)
                }]);
                
                var picker:Widget = null;

                split.splitter = crow.BoxWidget(box -> {
                    box.color = Color(Transparent);
                    box.horizontal = Fixed(theme.thickness);
                }, [
                    picker = crow.BoxWidget(box -> {
                        box.label = "picker";
                        split.drag = _ -> box.getArea();
                    })
                ]);

                split.first = crow.BoxWidget(box -> box.color = Color(Transparent));
                split.second = crow.BoxWidget(box -> box.color = Color(Transparent));

                split.onChange = anchor -> {
                    var v = switch anchor {
                        case Scale(v): color.y = v;
                        default: 0;
                    }
                    picker.color = Color(crovown.types.Color.fromHSVA(1, color.y, 1, 1));
                    var value = crovown.types.Color.fromHSVA(color.x, color.y, color.z, color.w);
                    preview.color = Color(value);
                    onChange(value);
                }
                split.pos = Scale(color.y);
                split.onChange(split.pos);
            }),
            crow.SplitWidget(split -> {
                split.label = "slider";
                split.color = LinearGradient(0, 0, 1, 0, [for (i in 0...16) {
                    stop: i / 16,
                    color: crovown.types.Color.fromHSVA(1, 1, i / 16, 1)
                }]);
                
                var picker:Widget = null;

                split.splitter = crow.BoxWidget(box -> {
                    box.color = Color(Transparent);
                    box.horizontal = Fixed(theme.thickness);
                }, [
                    picker = crow.BoxWidget(box -> {
                        box.label = "picker";
                        split.drag = _ -> box.getArea();
                    })
                ]);

                split.first = crow.BoxWidget(box -> box.color = Color(Transparent));
                split.second = crow.BoxWidget(box -> box.color = Color(Transparent));

                split.onChange = anchor -> {
                    var v = switch anchor {
                        case Scale(v): color.z = v;
                        default: 0;
                    }
                    picker.color = Color(crovown.types.Color.fromHSVA(1, 1, color.z, 1));
                    var value = crovown.types.Color.fromHSVA(color.x, color.y, color.z, color.w);
                    preview.color = Color(value);
                    onChange(value);
                }
                split.pos = Scale(color.z);
                split.onChange(split.pos);
            }),
            crow.SplitWidget(split -> {
                split.label = "slider";
                split.color = LinearGradient(0, 0, 1, 0, [for (i in 0...16) {
                    stop: i / 16,
                    color: crovown.types.Color.fromHSVA(1, 0, i / 16, 1)
                }]);
                
                var picker:Widget = null;

                split.splitter = crow.BoxWidget(box -> {
                    box.color = Color(Transparent);
                    box.horizontal = Fixed(theme.thickness);
                }, [
                    picker = crow.BoxWidget(box -> {
                        box.label = "picker";
                        split.drag = _ -> box.getArea();
                    })
                ]);

                split.first = crow.BoxWidget(box -> box.color = Color(Transparent));
                split.second = crow.BoxWidget(box -> box.color = Color(Transparent));

                split.onChange = anchor -> {
                    var v = switch anchor {
                        case Scale(v): color.w = v;
                        default: 0;
                    }
                    picker.color = Color(crovown.types.Color.fromHSVA(1, 0, color.z, 1));
                    var value = crovown.types.Color.fromHSVA(color.x, color.y, color.z, color.w);
                    preview.color = Color(value);
                    onChange(value);
                }
                split.pos = Scale(color.w);
                split.onChange(split.pos);
            })
        ]);
    }
}