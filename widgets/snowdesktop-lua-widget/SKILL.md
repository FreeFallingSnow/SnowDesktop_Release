---
name: snowdesktop-lua-widget
description: Create, modify, debug, and package Lua desktop widgets for SnowDesktop. Use when writing a new `.lua` widget and matching `.widget.json` manifest, adding drawing or mouse behavior, using widget storage and settings UI, querying desktop items, declaring permissions, or diagnosing a SnowDesktop Lua widget that does not load or render.
---

# SnowDesktop Lua Widget

Create widgets against SnowDesktop's built-in sandboxed Lua API. Keep the script and manifest names paired:

```text
widgets/
├── my_widget.lua
└── my_widget.widget.json
```

Place runnable `.lua` files directly in the executable's `widgets` directory. SnowDesktop only discovers `widgets\*.lua`; it does not scan subdirectories.

## Workflow

1. Copy [assets/widget-template.lua](assets/widget-template.lua) and [assets/widget-template.widget.json](assets/widget-template.widget.json) into the root `widgets` directory.
2. Rename both files to the same stem, using ASCII `snake_case` for predictable paths.
3. Implement `render()` first using local widget coordinates starting at `(0, 0)`.
4. Add only the callbacks required by the behavior.
5. Declare every privileged API in the manifest. Keep unused permissions out.
6. Store persistent values as strings and parse them with `tonumber` or explicit boolean conversion.
7. Test at multiple widget spans. Derive layout from `layout.width()` and `layout.height()` instead of assuming pixels.
8. Check hot reload after saving. If a render error invalidates the widget, refresh/re-add it after correcting the script.

Read [references/api.md](references/api.md) whenever using callbacks, permissions, drawing arguments, desktop integration, settings controls, or troubleshooting.

## Required structure

Every script should define:

```lua
name = "组件名称"

function render()
    local w = layout.width()
    local pad = layout.cu(12)
    draw.text(pad, pad, "Hello", layout.cu(14), 0xFFFFFF, w - pad * 2)
end
```

Use these optional top-level flags:

- `useCustomStyle = true`: read `bg`, `border`, `alpha`, and `gradientEndA` from the script.
- `showTitle = true`: show the host title and enable host rename actions. When
  false or omitted, the host hides **重命名** and ignores F2 for the widget.
- `bottomBarHover = false`: keep the bottom bar from using the default hover-only behavior.
- `bg`, `border`: `0xRRGGBB`.
- `alpha`, `gradientEndA`: decimal values from `0.0` to `1.0`.

## Manifest

Create a matching manifest even when no permission is needed:

```json
{
  "name": "组件名称",
  "version": "1.0.0",
  "description": "一句话说明组件用途。",
  "defaultSize": { "columns": 1, "rows": 1 },
  "minSize": { "columns": 1, "rows": 1 },
  "maxSize": { "columns": 4, "rows": 3 },
  "permissions": []
}
```

`minSize` and `maxSize` are optional. When omitted, the widget has no declared
size restriction beyond the desktop grid itself (effective minimum `1 x 1`).
Each `maxSize` dimension may also be `0` to mean unrestricted.

Valid permissions:

- `ui.input`: expose `imgui` and support settings-editor controls.
- `ui.contextMenu`: enable `getContextMenu()` and `onMenu(id)`.
- `desktop.read`: enable desktop queries and `draw.icon`.
- `desktop.action`: enable open, reveal, and desktop refresh actions.
- `system.read`: enable cached CPU, memory, battery, and network snapshots.
- `media.read`: read the current Windows media session.
- `media.action`: play/pause, skip next, and skip previous.
- `network.http`: enable asynchronous HTTP requests to `networkDomains`.

Keep `defaultSize.columns` and `defaultSize.rows` between 1 and 8.

## Implementation rules

- SnowDesktop uses a **design unit** system where `layout.cu(14)` converts grid-cell-relative
  design values to DPI-scaled pixels. Prefer `layout.cu()` over hardcoded pixel values so widgets
  scale correctly across monitors and DPI settings. See [references/api.md](references/api.md) for the full layout API.
- Treat `render()` as a hot path. Do not write storage or perform desktop queries repeatedly unless necessary.
- Use `storage.set` only when a value changes; it persists immediately to disk.
- Use `draw.measureText` for centering or fitting text.
- Use `maxWidth` with `singleLine = true` to get single-line ellipsis.
- Treat the bottom 24px as a host-reserved move/resize area. Do not place clickable
  controls there, even when the bottom bar is visually hidden or hover-only.
- Pass image paths relative to the root `widgets` directory. Absolute paths are rejected.
- Pass desktop item tables directly to `draw.icon`, `desktop.open`, or `desktop.reveal`.
- Add `ui.input` before defining `imguiRender`; otherwise `imgui` is absent from the sandbox.
- Add `ui.contextMenu` before defining custom menu callbacks; otherwise the host ignores them.
- Context-menu items may set `icon` to a Font Awesome 6 Free Solid glyph, for
  example `{ id = 1, label = "刷新", icon = "" }`. Leave it out for no icon.
- To unlock the debug page, open **设置 → 关于** and click the version number
  five times. Then open **调试 → Font Awesome 图标字符**; clicking an icon copies
  it to the clipboard.
- Use `imguiRender()` for the host **详细设置** panel.
- Prefer declarative manifest `settings` for simple text, bool, integer, float,
  and select fields; keep `imguiRender()` for custom editors.
- Use `widget.setTimer()` instead of frame-count timing. Stop unnecessary timers
  in `onHidden()` and restart them in `onVisible()`.
- Use `ui.button`, `ui.toggle`, `ui.progress`, `ui.scrollArea`, and
  `ui.virtualList` when host-managed interaction or scrolling is sufficient.
- Never call `http.request()` unconditionally from `render()`. Start requests
  from lifecycle, timer, menu, or UI callbacks and consume them in
  `onHttpResponse`. Redirect targets must also be declared in `networkDomains`.
- Do not use `io`, `os`, `require`, `package`, `load`, or arbitrary filesystem/process APIs. They are not exposed.
- Keep colors in `0xRRGGBB`; pass opacity separately where supported.
- Log recoverable diagnostics with `widget.log("info"|"warn"|"error"|"debug", message)`.

## Verification

For repository development:

1. Save the files under the source `widgets` directory.
2. Run `build.bat`; CMake copies the complete directory recursively to `.build\Release\widgets`.
3. In SnowDesktop, right-click the desktop and choose **添加组件**, then select the manifest display name.
4. Exercise click, double-click, wheel, editor, and context-menu behavior as applicable.
5. Build Release before delivery. The release process copies the complete built `widgets` tree, including this skill and its resources, into `release\widgets`.

Before finishing, verify:

- Script and manifest stems match.
- The script sits directly under `widgets`.
- JSON is valid UTF-8.
- `defaultSize` falls within any declared `minSize` / `maxSize`.
- Every used privileged API has its permission.
- Every HTTP hostname is present in `networkDomains`.
- Timers and HTTP requests are not started repeatedly from `render()`.
- `render()` works at the manifest's default span and at a resized span.
- No storage write occurs unconditionally on every frame.
