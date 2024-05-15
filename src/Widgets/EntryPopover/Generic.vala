/*
 * Copyright 2021-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public abstract class Tasks.Widgets.EntryPopover.Generic<T> : Gtk.EventBox {
    public signal string? value_format (T value);
    public signal void value_changed (T value);

    public Gtk.Popover popover { get; private set; }
    public string? icon_name { get; construct; }
    public string placeholder { get; construct; }
    public T value { get; set; }

    private Gtk.MenuButton popover_button;
    private T value_on_popover_show;

    protected Generic (string placeholder, string? icon_name = null) {
        Object (
            icon_name: icon_name,
            placeholder: placeholder
        );
    }

    class construct {
        set_css_name ("entry-popover");
    }

    construct {
        events |= Gdk.EventMask.ENTER_NOTIFY_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK;

        popover = new Gtk.Popover (popover_button);

        popover_button = new Gtk.MenuButton () {
            label = placeholder,
            popover = popover,
            image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.BUTTON),
            always_show_image = icon_name != null
        };
        popover_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var delete_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.BUTTON) {
            tooltip_text = _("Remove")
        };
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var delete_button_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            reveal_child = false
        };
        delete_button_revealer.add (delete_button);

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        button_box.add (popover_button);
        button_box.add (delete_button_revealer);

        add (button_box);

        delete_button.clicked.connect (() => {
            var value_has_changed = value != null;
            value = null;
            if (value_has_changed) {
                value_changed (value);
            }
        });

        popover_button.clicked.connect (() => {
            if (delete_button_revealer.reveal_child) {
                delete_button_revealer.reveal_child = false;
            }
        });

        notify["value"].connect (() => {
            var value_formatted = value_format (value);
            if (value_formatted == null) {
                popover_button.label = placeholder;

                if (delete_button_revealer.reveal_child) {
                    delete_button_revealer.reveal_child = false;
                }

            } else {
                popover_button.label = value_formatted;
            }
        });

        enter_notify_event.connect (() => {
            if (value_format (value) != null) {
                delete_button_revealer.reveal_child = true;
            }
        });

        leave_notify_event.connect (() => {
            if (delete_button_revealer.reveal_child) {
                delete_button_revealer.reveal_child = false;
            }
        });

        popover.show.connect (() => {
            GLib.Idle.add (() => {
                value_on_popover_show = value;
                return GLib.Source.REMOVE;
            });
        });

        popover.closed.connect (() => {
            GLib.Idle.add (() => {
                if (value != value_on_popover_show) {
                    value_changed (value);
                }
                return GLib.Source.REMOVE;
            });
        });
    }
}
