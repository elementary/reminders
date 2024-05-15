/*
 * Copyright 2019-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Tasks.Widgets.SourceRow : Gtk.ListBoxRow {
    public E.Source source { get; construct; }

    private Gtk.Grid source_color;
    private Gtk.Image status_image;
    private Gtk.Label display_name_label;
    private Gtk.Stack status_stack;
    private Gtk.Revealer revealer;

    public SourceRow (E.Source source) {
        Object (source: source);
    }

    construct {
        source_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER
        };
        source_color.get_style_context ().add_class ("source-color");

        display_name_label = new Gtk.Label (source.display_name) {
            halign = Gtk.Align.START,
            hexpand = true,
            margin_end = 9
        };

        status_image = new Gtk.Image () {
            pixel_size = 16
        };

        var spinner = new Gtk.Spinner () {
            active = true,
            tooltip_text = _("Connecting…")
        };

        status_stack = new Gtk.Stack ();
        status_stack.add_named (status_image, "image");
        status_stack.add_named (spinner, "spinner");

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 12,
            margin_end = 6
        };
        box.add (source_color);
        box.add (display_name_label);
        box.add (status_stack);

        revealer = new Gtk.Revealer () {
            reveal_child = true
        };
        revealer.add (box);

        add (revealer);

        build_drag_and_drop ();

        update_request ();
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (this, Gtk.DestDefaults.HIGHLIGHT | Gtk.DestDefaults.MOTION, Application.DRAG_AND_DROP_TASK_DATA, Gdk.DragAction.MOVE);

        drag_motion.connect (on_drag_motion);
        drag_drop.connect (on_drag_drop);
        drag_data_received.connect (on_drag_data_received);
        drag_leave.connect (on_drag_leave);
    }

    private bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        if (!get_style_context ().has_class ("drop-hover")) {
            get_style_context ().add_class ("drop-hover");
        }
        return true;
    }

    private void on_drag_leave (Gdk.DragContext context, uint time_) {
        get_style_context ().remove_class ("drop-hover");
    }

    private Gee.HashMultiMap<string, string> received_drag_data;

    private async bool on_drag_drop_move_tasks () throws Error {
        E.SourceRegistry registry = yield Application.model.get_registry ();
        var move_successful = true;

        var source_uids = received_drag_data.get_keys ();
        foreach (var source_uid in source_uids) {
            var src_source = registry.ref_source (source_uid);

            var component_uids = received_drag_data.get (source_uid);
            foreach (var component_uid in component_uids) {
                if (!yield Application.model.move_task (src_source, source, component_uid)) {
                    move_successful = false;
                }
            }
        }
        return move_successful;
    }

    private bool on_drag_drop (Gdk.DragContext context, int x, int y, uint time) {
        var target = Gtk.drag_dest_find_target (this, context, null);
        if (target != Gdk.Atom.NONE) {
            Gtk.drag_get_data (this, context, target, time);
        }

        var drop_successful = false;
        var move_successful = false;
        if (received_drag_data != null && received_drag_data.size > 0) {
            drop_successful = true;

            on_drag_drop_move_tasks.begin ((obj, res) => {
                try {
                    move_successful = on_drag_drop_move_tasks.end (res);

                } catch (Error e) {
                    var error_dialog = new Granite.MessageDialog (
                        _("Moving task failed"),
                        _("There was an error while moving the task to the desired list."),
                        new ThemedIcon ("dialog-error"),
                        Gtk.ButtonsType.CLOSE
                    );
                    error_dialog.show_error_details (e.message);
                    error_dialog.run ();
                    error_dialog.destroy ();

                } finally {
                    Gtk.drag_finish (context, drop_successful, move_successful, time);
                }
            });
        }

        return drop_successful;
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint info, uint time) {
        received_drag_data = new Gee.HashMultiMap<string,string> ();

        var uri_scheme = "task://";
        var uris = selection_data.get_uris ();

        foreach (var uri in uris) {
            string? source_uid = null;
            string? component_uid = null;

            if (uri.has_prefix (uri_scheme)) {
                var uri_parts = uri.substring (uri_scheme.length).split ("/");

                if (uri_parts.length == 2) {
                    source_uid = uri_parts[0];
                    component_uid = uri_parts[1];
                }
            }

            if (source_uid == null || component_uid == null) {
                warning ("Can't handle drop data: Unexpected uri format: %s", uri);

            } else if (source_uid == source.uid) {
                debug ("Dropped task onto the same list, so we have nothing to do.");

            } else {
                received_drag_data.set (source_uid, component_uid);
            }
        }
    }

    public void update_request () {
        Tasks.Application.set_task_color (source, source_color);

        display_name_label.label = source.display_name;

        if (source.connection_status == E.SourceConnectionStatus.CONNECTING) {
            status_stack.visible_child_name = "spinner";
        } else {
            status_stack.visible_child_name = "image";

            switch (source.connection_status) {
                case E.SourceConnectionStatus.AWAITING_CREDENTIALS:
                    status_image.icon_name = "dialog-password-symbolic";
                    status_image.tooltip_text = _("Waiting for login credentials");
                    break;
                case E.SourceConnectionStatus.DISCONNECTED:
                    status_image.icon_name = "network-offline-symbolic";
                    status_image.tooltip_text = _("Currently disconnected from the (possibly remote) data store");
                    break;
                case E.SourceConnectionStatus.SSL_FAILED:
                    status_image.icon_name = "security-low-symbolic";
                    status_image.tooltip_text = _("SSL certificate trust was rejected for the connection");
                    break;
                default:
                    status_image.gicon = null;
                    status_image.tooltip_text = null;
                    break;
            }
        }
    }

    public void remove_request () {
        revealer.reveal_child = false;
        GLib.Timeout.add (revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
