# Tasks
[![Translation status](https://l10n.elementary.io/widgets/tasks/-/svg-badge.svg)](https://l10n.elementary.io/engage/tasks/?utm_source=widget)

## Building and Installation

You'll need the following dependencies:
* glib-2.0
* gobject-2.0
* granite >=0.5
* gtk+-3.0
* libecal-2.0
* libedataserver-1.2
* libhandy-1-dev >= 0.90.0
* libical
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

```bash
meson build --prefix=/usr
cd build
ninja
```

To install, use `ninja install`, then execute with `io.elementary.tasks`

```bash
ninja install
io.elementary.tasks
```
