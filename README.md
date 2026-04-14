# Zenity Display Switch

A small **Bash** utility that mimics the Windows **Project** / **Display Switch** flow (Win+P): pick how two connected displays should be used—internal only, external only, mirror, or extend—through a lightweight **[Zenity](https://gitlab.gnome.org/GNOME/zenity)** dialog.

| Windows Display Switch                                                                      | Zenity Display Switch                                                             |
| ------------------------------------------------------------------------------------------- |:---------------------------------------------------------------------------------:|
| ![Windows Display Switch](/docs/images/display-switch-windows.png "Windows Display Switch") | ![Zenity Display Switch](/docs/images/display-switch.png "Zenity Display Switch") |

The goal is to stay **minimal**: no heavy GUI framework, only tools that are common on many Linux desktops.



## Features

- **Four modes** mapped to `xrandr`:
  - **Primary** — only the first detected display
  - **Duplicate** — same image on both
  - **Extend** — combines both displays
  - **Secondary** — only the second display
- **Automatic detection** of connected outputs via `xrandr`
- **Simple list UI** built with Zenity (GTK+, often preinstalled on GNOME-based and many other distributions)

## Requirements

| Dependency | Role |
|------------|------|
| `bash` | Script interpreter |
| `xrandr` | Read outputs and apply layout ([X RandR](https://wiki.archlinux.org/title/Xrandr)) |
| `zenity` | Dialog (`zenity --list`) |
| X11 session | `xrandr` applies as documented here under a typical X11 stack |

> **Wayland:** Many Wayland compositors do not expose the same `xrandr` workflow. This script is aimed at **X11** (or XWayland setups where `xrandr` still behaves as expected). If `xrandr` does not list your monitors as expected, use your compositor’s display settings or a Wayland-native tool instead.

## Installation

### With Make (recommended)

Requires `make` and the `install` utility (from **GNU coreutils**, usually already present).

Clone the repository, then install the script into your `PATH` as `display-switch`:

```bash
git clone https://github.com/YOUR_USERNAME/zenity-display-switch.git
cd zenity-display-switch
sudo make install
```

That installs to `/usr/local/bin` by default. To install under your home directory (no `sudo`):

```bash
make install PREFIX="$HOME/.local"
```

Ensure `$HOME/.local/bin` is on your `PATH` (many distributions already add it).

**Packagers** can stage files with `DESTDIR`:

```bash
make install DESTDIR=/tmp/stage PREFIX=/usr
```

Uninstall removes only the installed name `display-switch` (not the copy in the clone):

```bash
sudo make uninstall
# or, for a user-local install:
make uninstall PREFIX="$HOME/.local"
```

Replace the clone URL with your real remote when you publish the project.

### Manual (no Make)

Clone or copy the repository, then make the script executable:

```bash
git clone https://github.com/YOUR_USERNAME/zenity-display-switch.git
cd zenity-display-switch
chmod +x display-switch.sh
```

## Usage

If you used **Make**, run the installed command (it must be on your `PATH`):

```bash
display-switch
```

If you use the **manual** layout, run it from the repository directory:

```bash
./display-switch.sh
```

Choose a mode in the dialog. Canceling the dialog exits without changing the layout.

### Bind to a keyboard shortcut

Most desktop environments let you assign a custom shortcut to a command.

- After **`make install`**, use the command name:

  ```text
  display-switch
  ```

- With a **manual** clone, use the **absolute path** to the script, for example:

  ```text
  /home/you/Projects/zenity-display-switch/display-switch.sh
  ```

That gives you a Win+P-style workflow without relying on vendor-specific keys.

## Configuration

### Display Extend Direction

You can set the display extension direction from the command line.

```bash
display-switch --config extend-direction=left
# or
display-switch --config extend-direction=right
```

Accepted values are `left` and `right` (aliases `left-of` and `right-of` are also accepted).  
This setting is used by the **Extend** mode.


## Assumptions and limitations

- **Connected display ordering** — The script uses the first two outputs reported as `connected` by `xrandr`. The first is treated as “primary” and the second as “secondary”. With more than two monitors, behavior is undefined; extending the script for explicit selection would be a natural follow-up.
- **Single-monitor behavior** — If no secondary monitor is detected, the script warns the user and keeps only the primary display enabled.
- **Extend direction options** — Extend direction supports `left` and `right` through configuration. Other geometries (`above`, `below`, etc.) are not exposed yet.

## Contributing

Issues and pull requests are welcome—especially for Wayland-safe alternatives, smarter monitor ordering, or optional extend directions.

Please keep changes aligned with the project goal: **small footprint**, few dependencies, and clarity over feature creep.

## License

This project is released under the [MIT License](LICENSE).

---

**Disclaimer:** This project is not affiliated with Microsoft or the Windows “Project” feature; it only provides a similar *workflow* on Linux using standard tools.
