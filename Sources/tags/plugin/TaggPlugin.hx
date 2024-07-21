package tags.plugin;

import crovown.Crovown;
import crovown.Storage;
import crovown.algorithm.Easing;
import crovown.algorithm.MathUtils;
import crovown.backend.Backend.Surface;
import crovown.ds.Assets;
import crovown.ds.Matrix;
import crovown.event.InputEvent;
import crovown.plugin.Plugin;
import crovown.types.Icons;
import crovown.types.Layout;
import tags.event.RenderLayerEvent;
import tags.event.RenderPropertiesEvent;
import tags.event.RenderTypesEvent;
import format.png.Tools;
import format.png.Writer;
import haxe.Json;
#if js
import js.Browser;
#else
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

using Lambda;
using StringTools;
using crovown.component.Component;
using crovown.component.OperationComponent;
using crovown.component.animation.Animation;
using crovown.component.animation.SequenceAnimation;
using crovown.component.widget.AspectWidget;
using crovown.component.widget.BoxWidget;
using crovown.component.widget.DpiWidget;
using crovown.component.widget.LayoutWidget;
using crovown.component.widget.ScrollWidget;
using crovown.component.widget.SpacerWidget;
using crovown.component.widget.SplitWidget;
using crovown.component.widget.SplitWidget;
using crovown.component.widget.StageGui;
using crovown.component.widget.TextEditWidget;
using crovown.component.widget.TextWidget;
using crovown.component.widget.TreeWidget.TreeItem;
using crovown.component.widget.Widget;
using tags.component.layer.FillLayer;
using tags.component.layer.Layer;
using tags.component.layer.TextLayer;


// @todo rename
typedef TTTheme = {
    // Colors
    background:Int,
    foreground:Int,
    accent:Int,
    second:Int,
    text:Int,
    
    icons:Surface,
    
    // Paddings
    padding:Int,
    spacing:Int,
    gap:Int,
    insets:Int,
    tabulation:Int,

    // Sizes
    title:Int,
    size:Int,
    thickness:Int,
    icon:Int,
    radius:Int,
}



@:build(crovown.Macro.plugin(true))
class TaggPlugin extends Plugin {
    public static var theme:TTTheme = null;
    public var tree:Component = null;
    public var project = new UserStorage("projects");
    public var saves = new UserStorage("saves");
    
    public var name:String = Date.now().toString().replace(":", "_");
    // public var activeLayer(default, null):Layer = null;

    var renderLayerEvent:RenderLayerEvent = null;

    override function onEnable(crow:Crovown) {
        
        crow.rule(component -> {
            if (component.getType() != TextWidget.type) return;
            var text = cast(component, TextWidget);
            text.color = Color(theme.foreground);
            text.font = Assets.font_Inter;
            text.size = theme.size;
        });

        crow.rule(component -> {
            if (component.getType() != TextEditWidget.type) return;
            var text = cast(component, TextEditWidget);
            text.color = Color(theme.foreground);
            text.font = Assets.font_Inter;
            text.size = theme.size;
        });

        crow.rule(component -> {
            if (component.getType() != SpacerWidget.type) return;
            var spacer = cast(component, SpacerWidget);
            spacer.color = Color(theme.foreground);
            spacer.thickness = theme.thickness;
        });

        crow.rule(component -> {
            if (component.label != "layer") return;
            var item = cast(component, TreeItem);
            item.color = Color(Transparent);
            item.horizontal = Fill;
            item.vertical = Hug;
            item.gap = Fixed(theme.gap);
            item.indent = theme.tabulation;
        });

        crow.rule(component -> {
            if (component.label != "icon") return;
            var widget = cast(component, Widget);
            widget.horizontal = Fixed(theme.icon);
            widget.vertical = Fixed(theme.icon);
            widget.align = 0;
        });

        crow.rule(component -> {
            if (component.label != "picker") return;
            var picker = cast(component, BoxWidget);
            picker.color = Color(theme.foreground);
            picker.anchors = Center(theme.radius * 1.1);
            picker.borderRadius = All(theme.radius);
            picker.borderWidth = All(theme.thickness);
            picker.borderColor = Color(theme.background);
        });

        crow.rule(component -> {
            if (component.label != "slider") return;
            var split = cast(component, SplitWidget);
            split.horizontal = Fill;
            split.vertical = Fixed(theme.thickness);
        });

        crow.application.onLoad = app -> {
            theme = {
                // Colors
                background: 0xFF313131,
                foreground: 0xFFB5B5B5,
                accent: 0xFF6AB50E,
                second: 0xFF0E72B5,
                text: 0xFFFFFFFF,
                
                icons: crow.application.backend.loadImage(Assets.image_icons),
                
                // Paddings
                padding: 30,
                spacing: 24,
                gap: 16,
                insets: 22,
                tabulation: 48,

                // Sizes
                thickness: 3,
                icon: 24,
                radius: 8,
                title: 300,
                size: 22
            }

            app.framerate = 60;
            #if (!js && !android)
            app.resize(600, 950);
            #end

            renderLayerEvent = new RenderLayerEvent(app.backend, 1024, 1024);

            tree = crow.Component([
                crow.SequenceAnimation(sequence -> {
                    sequence.url = "animation";
                }, [
                    crow.Animation(animation -> {
                        animation.label = "dragging";
                        animation.duration = 1;
                        animation.isLooped = true;
                        animation.easing = Easing.easeInOutLinear;
                        animation.onFrameChanged = (animation, progress) -> {
                            var amplitude = 5.0;
                            var data:Widget = cast(animation.data);
                            data.transform = Matrix.Translation(
                                Math.sin(progress * 2 * Math.PI) * amplitude,
                                Math.cos(progress * 2 * Math.PI) * amplitude
                            );
                        }
                        animation.onEnd = animation -> {
                            var data:Widget = cast(animation.data);
                            data.transform = Matrix.Identity();
                        }
                    })
                ]),
                crow.OperationComponent(op -> {
                    op.url = "redraw";
                    op.onExecute = component -> {
                        trace("Redraw");
                        var canvas:Widget = tree.get("canvas");

                        renderLayerEvent.setCamera(renderLayerEvent.buffer.getWidth(), renderLayerEvent.buffer.getHeight());

                        tree.dispatch(renderLayerEvent);
                        canvas.color = Image(renderLayerEvent.buffer.getWidth(), renderLayerEvent.buffer.getHeight(), renderLayerEvent.buffer, Stretch);

                        return true;
                    }
                }),
                crow.StageGui([
                    crow.DpiWidget(dpi -> {
                        dpi.dpi = 700.0 / 2.54;
                        // @todo turn on in release
                        #if html5
                        dpi.enableDpiSupport = false;
                        #else
                        dpi.enableDpiSupport = true;
                        #end

                        dpi.onInput = event -> {
                            var step = 2.54 * 6;
                            if (event.input.isCombination([KeyCode(Ctrl), KeyCode(Plus)])) {
                                dpi.dpi -= step;
                                return false;
                            }
                            if (event.input.isCombination([KeyCode(Ctrl), KeyCode(Minus)])) {
                                dpi.dpi += step;
                                return false;
                            }
                            return true;
                        }
                    }, [
                        crow.LayoutWidget(layout -> {
                            layout.color = Color(theme.background);
                            layout.horizontal = Fill;
                            layout.vertical = Fill;
                            layout.padding = theme.padding;
                            layout.gap = Fixed(theme.spacing);
                            layout.direction = Column;
                        }, [
                            crow.BoxWidget(box -> {
                                box.label = "preview";
                                box.color = Color(Transparent);
                                box.horizontal = Fill;
                                box.vertical = Fixed(230);
                            }, [
                                crow.BoxWidget(box -> {
                                    box.label = "card";
                                    box.color = Color(0xFF4A4A4A);
                                    box.left = Fixed(theme.padding);
                                    box.right = Fixed(0);
                                    box.top = Fixed(theme.padding);
                                    box.bottom = Fixed(0);
                                    box.borderRadius = All(theme.radius);
                                }),
                                crow.BoxWidget(box -> {
                                    box.label = "card";
                                    box.color = Color(0xFF636363);
                                    box.left = Fixed(0);
                                    box.right = Fixed(theme.padding);
                                    box.top = Fixed(theme.padding / 2);
                                    box.bottom = Fixed(theme.padding / 2);
                                    box.borderRadius = All(theme.radius);
                                }),
                                crow.LayoutWidget(layout -> {
                                    layout.label = "card";
                                    layout.color = Color(theme.background);
                                    layout.left = Fixed(theme.padding / 2);
                                    layout.right = Fixed(theme.padding / 2);
                                    layout.top = Fixed(0);
                                    layout.bottom = Fixed(theme.padding);
                                    layout.borderWidth = All(theme.thickness);
                                    layout.borderColor = Color(0xFFB5B5B5);
                                    layout.borderRadius = All(theme.radius);
                                    layout.hjustify = 0;
                                    layout.vjustify = 0;
                                    layout.padding = 4;
                                }, [
                                    crow.AspectWidget(aspect -> {
                                        // @todo change to something nicer
                                        aspect.url = "canvas";
                                        aspect.label = "card";
                                        aspect.anchors = Fixed(0);
                                        aspect.ratio = renderLayerEvent.buffer.getWidth() / renderLayerEvent.buffer.getHeight();
                                        aspect.borderColor = Color(Black);
                                        aspect.borderWidth = All(theme.thickness);
                                        aspect.onInput = event -> {
                                            var area = aspect.getArea();
                                            if (event.input.isReleased(KeyCode(Space))) {
                                                var op:OperationComponent = tree.get("redraw");
                                                op.execute(crow);
                                            }
                                            return true;
                                        }
                                    })
                                ])
                            ]),
                            crow.LayoutWidget(layout -> {
                                layout.label = "toolbar";
                                layout.color = Color(Transparent);
                                layout.direction = Row;
                                layout.horizontal = Fill;
                                layout.vertical = Hug;
                                layout.gap = Fixed(theme.gap);
                            }, [
                                crow.Widget(widget -> {
                                    widget.label = "icon";
                                    widget.color = Tile(0, Icons.Left, 1, 1 / Icons.size, theme.icons, theme.foreground);
                                }),
                                crow.Widget(widget -> {
                                    widget.label = "icon";
                                    widget.color = Tile(0, Icons.Right, 1, 1 / Icons.size, theme.icons, theme.foreground);
                                }),
                                // crow.Widget(widget -> {
                                //     widget.label = "icon";
                                //     widget.color = Tile(0, Icons.Save, 1, 1 / Icons.size, theme.icons, theme.foreground);
                                // })
                            ]),
                            crow.SpacerWidget(),
                            crow.ScrollWidget(scroll -> {
                                scroll.color = Color(Transparent);
                                scroll.horizontal = Fill;
                                scroll.vertical = Fill;
                                scroll.clip = true;
                                scroll.viewY = 0;
                            }, [
                                crow.LayoutWidget(layout -> {
                                    layout.label = "outline";
                                    layout.color = Color(Transparent);
                                    layout.padding = theme.insets;
                                    layout.top = Fixed(0);
                                    layout.horizontal = Fill;
                                    layout.vertical = Hug;
                                    layout.direction = Column;
                                    layout.gap = Fixed(theme.gap);

                                }, [
                                    crow.FillLayer(tree -> {
                                        tree.url = "layers";
                                        tree.label = "layer";
                                        var save:String = null;
                                        setupItem(tree);
                                        var input:InputEvent->Bool = null;
                                        function load() {
                                            #if js
                                            // @todo
                                            trace("[Error] Loading is not supported on this target");
                                            #else
                                            var file = project.read("save.tagg");
                                            if (file != null) {
                                                var data = Json.parse(file);
                                                crow.application.delay(app -> {
                                                    tree.load(crow, data, component -> {
                                                        var component:TreeItem = cast(component);
                                                        setupItem(component);
                                                        trace("loaded");
                                                    });
                                                    tree.onInput = input;
                                                    var op:OperationComponent = this.tree.get("redraw");
                                                    op.execute(crow);
                                                });
                                            }
                                            #end
                                        }
                                        input = event -> {
                                            // @todo ctrl+c / ctrl+v
                                            if (event.input.isCombination([KeyCode(Ctrl), KeyCode(S)])) {
                                                #if js
                                                trace("[Error] Saving is not supported on this target");
                                                #else
                                                trace("saved");
                                                crow.application.delay(app -> {
                                                    save = Json.stringify(tree.store(true), "    ");
                                                    project.write(name + ".tagg", save);
                                                    new Writer(File.write(haxe.io.Path.join([Sys.getCwd(), name + ".png"]))).write(Tools.build32BGRA(
                                                        renderLayerEvent.buffer.getWidth(),
                                                        renderLayerEvent.buffer.getHeight(),
                                                        renderLayerEvent.buffer.save()
                                                    ));
                                                });
                                                #end
                                            }
                                            if (event.input.isCombination([KeyCode(Ctrl), KeyCode(L)])) {
                                                load();
                                            }
                                            return true;
                                        }
                                        tree.onInput = input;
                                        tree.onReady = _ -> {
                                            load();
                                        }
                                    })
                                ])
                            ])
                        ]),
                        crow.BoxWidget(box -> {
                            box.color = Color(Transparent);
                        }, [
                            crow.ScrollWidget(scroll -> {
                                scroll.url = "menu";
                                scroll.color = Color(Transparent);
                                scroll.isEnabled = false;
                                scroll.left = Fixed(theme.padding);
                                scroll.right = Fixed(theme.padding);
                                scroll.bottom = Fixed(theme.padding);
                                scroll.top = Fixed(300);
                                scroll.viewY = 0;
                                scroll.clip = true;
                                scroll.color = Color(theme.background);
                                scroll.borderColor = Color(theme.foreground);
                                scroll.borderRadius = Only(theme.radius, theme.radius, 0, 0);
                                scroll.borderWidth = Only(theme.thickness, theme.thickness, theme.thickness, 0);

                                scroll.onInput = event -> {
                                    var area = scroll.getArea();
                                    if (event.input.isReleased(Button(Left)) && !area.isOver && !area.isDropped) {
                                        var animation:Animation = scroll.animation.search("close");
                                        animation.play(crow);
                                    }
                                    return true;
                                }
    
                                scroll.animation = crow.SequenceAnimation([
                                    crow.Animation(animation -> {
                                        animation.label = "open";
                                        animation.duration = 0.4;
                                        animation.easing = Easing.easeOutQuint;
                                        animation.onFrameChanged = (animation, progress) -> {
                                            scroll.top = Fixed(MathUtils.mix(progress, 600, 300));
                                        }
                                        animation.onStart = animation -> {
                                            scroll.isEnabled = true;
                                            scroll.top = Fixed(600);
                                            // trace("open start");
                                        }
                                        animation.onEnd = animation -> {
                                            // trace("open end");
                                        }
                                    }),
                                    crow.Animation(animation -> {
                                        animation.label = "close";
                                        animation.duration = 0.4;
                                        animation.easing = Easing.easeInQuint;
                                        animation.onFrameChanged = (animation, progress) -> {
                                            scroll.top = Fixed(MathUtils.mix(progress, 300, 600));
                                        }
                                        animation.onStart = animation -> {
                                            // trace("close start");
                                        }
                                        animation.onEnd = animation -> {
                                            // trace("close end");
                                            scroll.isEnabled = false;
                                            scroll.removeChildren();
                                            var op:OperationComponent = this.tree.get("redraw");
                                            op.execute(crow);
                                        }
                                    })
                                ]);
                            })
                        ])
                    ])
                    
                ])
            ]);

            // Grid menu with layer types
            tree.subscribe(RenderTypesEvent.type, event -> {
                var event:RenderTypesEvent = cast(event);
                for (item in Component.factory.keyValueIterator()) {
                    if (!item.value.isVisible) continue;
                    var parts = item.key.split(".");
                    if (!parts.contains("layer")) continue;
                    event.layout.addChild(crow.LayoutWidget(layout -> {
                        layout.color = Color(theme.background);
                        layout.horizontal = Fixed(130);
                        layout.vertical = Fixed(130);
                        layout.hjustify = 0;
                        layout.vjustify = 0;
                        layout.borderColor = Color(theme.foreground);
                        layout.borderRadius = All(theme.radius);
                        layout.borderWidth = All(theme.thickness);
                        layout.onInput = e -> {
                            var area = layout.getArea();
                            if (area.isReleased) {
                                var layer:Layer = cast(event.parent) ?? tree.get("layers");
                                var tree:Layer = cast(item.value.builder(crow).callFactory(crow));
                                tree.delegate = this.item(crow, tree.getType().replace("Layer", ""));
                                tree.animation = crow.SequenceAnimation([
                                    crow.Animation(animation -> {
                                        animation.label = "delete";
                                        animation.duration = 0.2;
                                        animation.easing = Easing.easeInOutLinear;
                                        animation.onFrameChanged = (animation, progress) -> {
                                            tree.transform = Matrix.Translation(Math.sin(progress * Math.PI * 2 * 3.0) * 10);
                                        }
                                        animation.onEnd = animation -> {
                                            tree.parent = null;
                                            var op:OperationComponent = this.tree.get("redraw");
                                            op.execute(crow);
                                        }
                                    }),
                                    crow.Animation(animation -> {
                                        animation.label = "over";
                                        animation.duration = 0.05;
                                        animation.easing = Easing.easeInOutQuart;
                                        var offset = 0.02;
                                        animation.onFrameChanged = (animation, progress) -> {
                                            tree.transform = Matrix.Scale(1 + progress * offset, 1 + progress * offset);
                                        }
                                        animation.onStart = animation -> {
                                            tree.transform = Matrix.Identity();
                                        }
                                        animation.onEnd = animation -> {
                                            tree.transform = Matrix.Scale(1 + offset, 1 + offset);
                                        }
                                    }),
                                ]);
                                tree.onInput = event -> {
                                    var area = tree.delegate.getArea();
                                    if (area.isExit) {
                                        var animation:Animation = tree.animation.search("over");
                                        animation.stop(crow);
                                        tree.transform = Matrix.Identity();
                                    } else if (area.isEntered) {
                                        var animation:Animation = tree.animation.search("over");
                                        animation.play(crow);
                                    }
                                    return true;
                                }
                                if (event.replace) {
                                    while (layer.children.length > 0) {
                                        var child = layer.getChildFirst();
                                        layer.removeChild(child);
                                        tree.addChild(child);
                                    }
                                    layer.replace(tree);
                                    trace("Layer replaced by", item.key);
                                } else {
                                    layer.addChild(tree);
                                    trace("Layer added", item.key);
                                }
                                var animation:Animation = this.tree.get("menu").animation.search("close");
                                animation.play(crow);
                            }
                            return !area.isOver;
                        }
                    }, [
                        crow.TextWidget(text -> {
                            text.text = parts[parts.length - 1].replace("Layer", "");
                        })
                    ]));
                }
            });

            var op:OperationComponent = tree.get("redraw");
            op.execute(crow);
        }
    }


    public function setupItem(tree:TreeItem) {
        crow.application.delay(app -> {
            tree.delegate = this.item(crow, tree.getType().replace("Layer", ""), tree.parent.label != "layer");
        });
        tree.animation = crow.SequenceAnimation([
            crow.Animation(animation -> {
                animation.label = "delete";
                animation.duration = 0.2;
                animation.easing = Easing.easeInOutLinear;
                animation.onFrameChanged = (animation, progress) -> {
                    tree.transform = Matrix.Translation(Math.sin(progress * Math.PI * 2 * 3.0) * 10);
                }
                animation.onEnd = animation -> {
                    tree.parent = null;
                    var op:OperationComponent = this.tree.get("redraw");
                    op.execute(crow);
                }
            }),
            crow.Animation(animation -> {
                animation.label = "over";
                animation.duration = 0.05;
                animation.easing = Easing.easeInOutQuart;
                var offset = 0.02;
                animation.onFrameChanged = (animation, progress) -> {
                    tree.transform = Matrix.Scale(1 + progress * offset, 1 + progress * offset);
                }
                animation.onStart = animation -> {
                    tree.transform = Matrix.Identity();
                }
                animation.onEnd = animation -> {
                    tree.transform = Matrix.Scale(1 + offset, 1 + offset);
                }
            }),
        ]);
        tree.onInput = event -> {
            var area = tree.delegate.getArea();
            if (area.isExit) {
                var animation:Animation = tree.animation.search("over");
                animation.stop(crow);
                tree.transform = Matrix.Identity();
            } else if (area.isEntered) {
                var animation:Animation = tree.animation.search("over");
                animation.play(crow);
            }
            return true;
        }
    }

    public function item(crow:Crovown, name:String, isRoot = false) {
        return crow.LayoutWidget(layout -> {
            layout.color = Color(theme.background);
            layout.horizontal = Fill;
            layout.vertical = Hug;
            layout.padding = theme.insets;
            layout.borderColor = Color(theme.foreground);
            layout.borderRadius = All(theme.radius);
            layout.borderWidth = All(theme.thickness);
            layout.gap = Fixed(theme.gap);

            if (!isRoot) {
                layout.addChild(crow.Widget(spring -> {
                    spring.color = Color(Transparent);
                    spring.vertical = Fixed(1);
                    spring.horizontal = Fixed(15);
                }));
                layout.addChild(crow.Widget(widget -> {
                    widget.label = "icon";
                    widget.color = Tile(0, Icons.Trashcan, 1, 1 / Icons.size, theme.icons, theme.foreground);
                    widget.onInput = event -> {
                        var area = widget.getArea();
                        if (area.isReleased) {
                            var animation:Animation = layout.parent.animation.search("delete");
                            animation.play(crow);
                        }
                        return true;
                    }
                }));
            }
        }, [
            crow.Widget(widget -> {
                widget.label = "icon";
                widget.color = Tile(0, Icons.Drag, 1, 1 / Icons.size, theme.icons, theme.foreground);
                widget.onInput = event -> {
                    var area = widget.getArea();
                    
                    if (area.isPressed) {
                        // @todo
                        // activeLayer = 
                    }
                    if (area.dragStarted) {
                        var animation:Animation = tree.get("animation").search("dragging");
                        animation.data = widget.parent.parent;
                        animation.play(crow);
                        var layout:Widget = widget.getParent();
                        layout.borderColor = Color(theme.accent);
                    }
                    if (area.isDropped) {
                        var animation:Animation = tree.get("animation").search("dragging");
                        animation.stop(crow);
                        var layout:Widget = widget.getParent();
                        layout.borderColor = Color(theme.foreground);
                    }
                    if (area.isDropped) {
                        // Searching a root of the tree
                        var tree:TreeItem = widget.parent.getParent();
                        while (tree.parent.label == "layer") {
                            tree = tree.getParent();
                        }

                        // Searching a place to insert item
                        var target:TreeItem = null;
                        var pos = 0;
                        for (component in tree) {
                            var child:TreeItem = cast(component);
                            // Mouse pointing at the delegate - placing as a child of its TreeItem
                            if (event.position.y > child.delegate.y && event.position.y < child.delegate.y + child.delegate.h) {
                                if (component != widget.parent.parent) {
                                    target = cast(component);
                                }
                                break;
                            }
                            // Mouse pointing between delegates - placing as a child of the parent TreeItem
                            if (component.parent.label == "layer" && event.position.y <= child.delegate.y) {
                                if (component.parent != widget.parent.parent) {
                                    target = cast(component.parent);
                                    pos = target.indexOf(component) - 1;
                                }
                                break;
                            }
                        };
                        if (target != null) {
                            if (target.isParent(widget.parent.parent)) {
                                // Layers swap
                                // @todo
                                // @note not working yet
                                // var item = widget.parent.parent;
                                // var parent = item.parent;
                                // var p = parent.getChildIndex(item);
                                // target.parent.insertChild(pos, item);
                                // parent.insertChild(p, target);
                            } else {
                                crow.application.delay(app -> {
                                    target.insertChild(pos, widget.parent.parent);
                                });
                            }
                            crow.application.delay(app -> {
                                var op:OperationComponent = this.tree.get("redraw");
                                op.execute(crow);
                            });
                        }
                    }
                    if (area.isDragging) return false;
                    return true;
                }
            }),
            crow.TextEditWidget(text -> {
                text.text = name;
                text.align = 0;
            }),
            crow.Widget(spring -> {
                spring.color = Color(Transparent);
                spring.vertical = Fixed(1);
            }),
            crow.Widget(widget -> {
                widget.label = "icon";
                widget.color = Tile(0, Icons.PlusSign, 1, 1 / Icons.size, theme.icons, theme.accent);
                widget.onInput = event -> {
                    var area = widget.getArea();
                    if (area.isReleased) {
                        tree.dispatch(new RenderTypesEvent(widget.parent.parent, menu(Row)));
                    }
                    return true;
                }
            }),
            crow.Widget(widget -> {
                widget.label = "icon";
                widget.color = Tile(0, Icons.Entity, 1, 1 / Icons.size, theme.icons, theme.foreground);
                widget.onInput = event -> {
                    var area = widget.getArea();
                    if (area.isReleased) {
                        tree.dispatch(new RenderTypesEvent(widget.parent.parent, menu(Row), true));
                    }
                    return true;
                }
            }),
            crow.Widget(widget -> {
                widget.label = "icon";
                widget.color = Tile(0, Icons.Settings, 1, 1 / Icons.size, theme.icons, theme.foreground);
                widget.onInput = event -> {
                    var area = widget.getArea();
                    if (area.isReleased) {
                        tree.dispatch(new RenderPropertiesEvent(crow, theme, tree, widget.parent.parent, menu(Column)));
                    }
                    return true;
                }
            })
        ]);
    }

    public function menu(direction:Layout = Row) {
        var widget:Widget = tree.get("menu");
        var layout:LayoutWidget = null;
        widget.children = [
            crow.LayoutWidget(layout -> {
                layout.color = Color(Transparent);
                layout.horizontal = Fill;
                layout.vertical = Hug;
                layout.direction = Column;
            }, [
                layout = crow.LayoutWidget(layout -> {
                    layout.color = Color(Transparent);
                    layout.direction = direction;
                    layout.padding = theme.insets;
                    layout.left = Fixed(0);
                    layout.right = Fixed(0);
                    layout.top = Fixed(0);
                    layout.vertical = Hug;
                    layout.wrap = direction.match(Row);
                    layout.gap = Fixed(theme.spacing);
                })
            ])
        ];
        var animation:Animation = widget.animation.search("open");
        animation.play(crow);
        return layout;
    }
}