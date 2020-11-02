/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public abstract class Tasks.EntryPopover<T> : Gtk.EventBox {
    public Gtk.Image image { get; set; }
    public Gtk.Popover popover { get; private set; }
    public string? placeholder { get; set; }

    public T value { get; set; }
    private T value_on_popover_show { get; set; }
    public signal void value_changed (T value);
    public signal string? value_format (T value);

    private static Gtk.CssProvider style_provider;
    private Gtk.MenuButton popover_button;

    class construct {
        set_css_name ("entry-popover");
    }

    static construct {
        style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("io/elementary/tasks/EntryPopover.css");
    }

    construct {
        events |= Gdk.EventMask.ENTER_NOTIFY_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK;

        popover = new Gtk.Popover (popover_button);

        popover_button = new Gtk.MenuButton () {
            always_show_image = true,
            label = (placeholder != null && placeholder.length > 0 ? placeholder : _("Set Value")),
            popover = popover
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

        var button_box = new Gtk.Grid ();
        button_box.add (popover_button);
        button_box.add (delete_button_revealer);
        button_box.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        add (button_box);

        bind_property ("image", popover_button, "image");

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

        notify["placeholder"].connect (() => {
            if (value_format (value) == null) {
                popover_button.label = (placeholder != null && placeholder.length > 0 ? placeholder : _("Set Value"));
            }
        });

        notify["value"].connect (() => {
            var value_formatted = value_format (value);
            if (value_formatted == null) {
                popover_button.label = (placeholder != null && placeholder.length > 0 ? placeholder : _("Set Value"));

                if (delete_button_revealer.reveal_child) {
                    Timeout.add (150, () => {
                        delete_button_revealer.reveal_child = false;
                        return GLib.Source.REMOVE;
                    });
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
            value_on_popover_show = value;
        });

        popover.closed.connect (() => {
            if (value != value_on_popover_show) {
                value_changed (value);
            }
        });
    }
}