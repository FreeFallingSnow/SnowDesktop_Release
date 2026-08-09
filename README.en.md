# SnowDesktop

[简体中文](./README.md) | [English](./README.en.md)

A Windows desktop organization and personalization tool. SnowDesktop replaces native Explorer desktop icons with a custom Direct2D-rendered desktop and supports multi-monitor grid layouts, embeddable widgets, and Lua script extensions.

## 📦 Installation

[![Get it from Microsoft](https://get.microsoft.com/images/en-us%20dark.svg)](https://apps.microsoft.com/detail/9PLLGJVL4LC3)

[Source repository](https://github.com/FreeFallingSnow/SnowDesktop)

[Release repository](https://github.com/FreeFallingSnow/SnowDesktop_Release)

## ✨ Feature Highlights

- 🖥️ **Flexible desktop layouts**: Organize desktop items and widgets on a grid with adjustable rows, columns, and icon spacing. Each display can have its own pages and layouts, with support for display hot-plugging and browsing offline pages.
- 🗂️ **Desktop organization widgets**:
  - **Collections**: Keep applications and desktop shortcuts in resizable containers. Drag items in or out, reorder them, and rename each collection to organize frequently used content by purpose.
  - **Collection groups**: Combine multiple collections into one tabbed widget. Search their contents, reorder tabs with drag-and-drop, and switch between several workspaces without taking up more desktop space.
  - **Desktop file categories**: Automatically group desktop content by file type. Switch between list and icon views, then use category tabs, search, sorting, date groups, box selection, and drag-and-drop.
  - **Folder mappings**: Map any folder directly onto the desktop and browse, search, or manage its contents like a desktop widget without moving the original files.
  - **File groups**: Bring desktop file categories and multiple mapped folders into one widget. Two-level source and category tabs keep content easy to reach while reducing window switching and desktop clutter.
- 🚀 **Dock and floating Dock**:
  - **Flexible placement**: Dock the bar to the top, bottom, left, or right edge in island or edge-attached mode, and show it on a selected display or across all displays.
  - **Everything you use, close at hand**: Add application shortcuts, folder stacks, and collections; surface frequent items; and access Windows or quick search. Items can be added and reordered with drag-and-drop.
  - **Fast window switching**: See running applications in one place, hover for window previews, and quickly activate, minimize, or close a window.
  - **Natural interaction**: Enjoy icon magnification, transition animations, and folder pop-ups. The floating Dock can also be summoned temporarily with a hotkey or screen-edge gesture.
- 🔎 **Quick navigation**: Search desktop items, applications, and Everything file results from a keyboard shortcut, then browse and launch content by sources such as Desktop, Mappings, and Dock.
- 🧩 **Lua widget platform**:
  - **Widget management**: Install, enable, update, roll back, and manage widget packages and offline catalogs.
  - **Built-in widgets**: Includes analog and digital clocks, a month calendar, agenda, reminders, system monitoring, media controls, sticky notes, Pomodoro, an RSS reader, and a quick launcher.
- 🎨 **Personalization**: Configure light and dark themes, glass and acrylic backgrounds, widget styling, Dock appearance, and a dynamic taskbar.
- 💾 **Backup and migration**: Back up and restore layouts, settings, widget packages, and widget data, or migrate them between installed, portable, and other data directories.

## 🛠️ Build

Requirements: CMake 3.24+, Visual Studio 2022, and the Windows 10 SDK (0x0A00).

```bat
.\scripts\build.bat
```

The default build does not stop SnowDesktop or restart Explorer. Its preflight
stops before compilation when the app or hook DLL is active. Exit SnowDesktop
normally first. To clear the lock automatically, use
`.\scripts\build.bat --reload-shell`; it stops SnowDesktop and briefly restarts Explorer.

## 🧱 Technology

- C++20 / MSVC
- Direct2D + Direct3D 11 + DirectComposition
- Dear ImGui (settings window)
- Lua 5.4 (script engine)
- Fluent System Icons Regular (modern context-menu and widget-menu icons)
- Font Awesome 6 Free (backward-compatible widget icons)
- WinHTTP (Lua HTTP runtime)

## 📄 License

The SnowDesktop core is licensed under GNU General Public License v3.0; see
[LICENSE](./LICENSE). Copyright and license information for third-party
components included in this repository is collected in
[THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md).

The separate `steam_bridge/` Workshop bridge is MIT-licensed under
[steam_bridge/LICENSE](./steam_bridge/LICENSE). The Steamworks SDK is not
included in this repository and is not covered by either license.
