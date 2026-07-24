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

Place runnable `.lua` files directly in SnowDesktop's active `widgets` directory. Portable builds use the `widgets` directory beside the executable directly. MSIX builds use `LocalState\data\widgets`, initially seeded from the packaged `widgets` directory. SnowDesktop only discovers `widgets\*.lua`; it does not scan subdirectories.

## Workflow

1. Copy [assets/widget-template.lua](assets/widget-template.lua) and [assets/widget-template.widget.json](assets/widget-template.widget.json) into the root `widgets` directory.
2. Rename both files to the same stem, using ASCII `snake_case` for predictable paths.
3. Implement `render()` first using local widget coordinates starting at `(0, 0)`.
4. Put every user-visible string behind `l10n.tr("literal.key")`, including the
   script name, settings, menus, placeholders, status text, and notifications.
5. Add `nameKey` and `descriptionKey` to the manifest.
6. Add every new translation key to each language under the manifest's
   `locales` object. Lua widget text must not be added to the host `lang/*.json`.
7. Add only the callbacks required by the behavior.
8. Declare every privileged API in the manifest. Keep unused permissions out.
9. Store persistent values as strings and parse them with `tonumber` or explicit boolean conversion.
10. Test at multiple widget spans. Derive layout from `layout.width()` and `layout.height()` instead of assuming pixels.
11. Check hot reload after saving. If a render error invalidates the widget, refresh/re-add it after correcting the script.

Read [references/api.md](references/api.md) whenever using callbacks, permissions, drawing arguments, desktop integration, settings controls, or troubleshooting.

## Required structure

Every script should define:

```lua
name = l10n.tr("lua_widget.my_widget.name")

function render()
    local w = layout.width()
    local pad = layout.cu(12)
    draw.text(pad, pad, l10n.tr("lua_widget.my_widget.hello"),
        layout.cu(14), 0xFFFFFF, w - pad * 2)
end
```

Use these optional top-level flags and appearance globals:

- `useCustomStyle = true`: enable Lua-controlled background appearance and the
  host's unified **外观** settings panel for this widget.
- `followPersonalizationDefault = true`: make a new instance follow the global
  appearance until the user explicitly changes its follow state.
- `showTitle = true`: show the host title and enable host rename actions. When
  false or omitted, the host hides **重命名** and ignores F2 for the widget.
- `bottomBarHover = false`: keep the bottom bar from using the default hover-only behavior.
- `bg`, `border`: `0xRRGGBB`.
- `alpha`, `borderAlpha`, `gradientEndA`: decimal values from `0.0` to `1.0`.
- `glassEnabled`: per-widget frosted backdrop switch. Blur radius is owned by
  the global appearance page.

For `useCustomStyle` widgets, prefer declarative `settings.presets` for visual
presets and `settings.fields` for behavior. Presets should stay appearance-only:
put colors, alpha, and glass there;
keep data sources, intervals, toggles, durations, and other behavior in fields.
The host displays one independent **跟随全局** checkbox and one **主题** selector.
The selector contains the four host themes, **自定义**, and all manifest/script
presets. Theme changes never change the follow checkbox, and presets must not
contain `followPersonalization`.

## Manifest

Create a matching manifest even when no permission is needed:

```json
{
  "name": "My Widget",
  "nameKey": "lua_widget.my_widget.name",
  "version": "1.0.0",
  "description": "A short English fallback description.",
  "descriptionKey": "lua_widget.my_widget.description",
  "locales": {
    "zh-CN": {
      "lua_widget.my_widget.name": "我的组件",
      "lua_widget.my_widget.description": "一句话说明组件用途。",
      "lua_widget.my_widget.hello": "你好"
    },
    "en-US": {
      "lua_widget.my_widget.name": "My Widget",
      "lua_widget.my_widget.description": "A short description.",
      "lua_widget.my_widget.hello": "Hello"
    }
  },
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
- Use literal keys with `l10n.tr("key", arguments...)`; placeholders use
  `{0}`, `{1}`, and so on. `l10n.language()` returns the effective language
  (`zh-CN` or `en-US`) for behavior that truly varies by locale.
- Keep the manifest `name` and `description` as English fallbacks and put their
  localized keys in `nameKey` and `descriptionKey`. Store all Lua translations
  in that same manifest's `locales` object.
- Put state-dependent localized title keys in the manifest `titleKeys` array
  and refresh those titles in `onLanguageChanged()`.
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
  select, and color fields; keep `imguiRender()` for custom editors.
- The host wraps `imguiRender()` in a scrollable editor area. For
  `useCustomStyle` widgets, manual appearance controls are shown only when the
  host **主题** selector is set to **自定义**. **恢复默认设置** restores declarative
  behavior fields.
- Lua scripts may also declare `settings = { presets = {...}, fields = {...} }`
  directly. The host merges manifest and script declarations into the same
  settings panel.
- Do not expose `cornerRadius` or `barHeight` as Lua settings or preset values.
  They are host-owned layout settings; read them through `widget.theme()` and
  `layout.barHeight()` only when alignment requires it.
- Use `widget.setTimer()` instead of frame-count timing. Stop unnecessary timers
  in `onHidden()` and restart them in `onVisible()`.
- Use `ui.button`, `ui.toggle`, `ui.textInput`, `ui.progress`, `ui.scrollArea`,
  and `ui.virtualList` when host-managed interaction or scrolling is sufficient.
  `ui.textInput` is Direct2D-rendered and transparent like the desktop file
  search field; do not layer a native text editor over it.
- Use `onSelected()` when a widget should react as soon as the desktop selects
  it. For search-oriented widgets, call `ui.focusInput(id)` there so the
  host-rendered input is ready for typing immediately.
- Never call `http.request()` unconditionally from `render()`. Start requests
  from lifecycle, timer, menu, or UI callbacks and consume them in
  `onHttpResponse`. Redirect targets must also be declared in `networkDomains`.
- Do not use `io`, `os`, `require`, `package`, `load`, or arbitrary filesystem/process APIs. They are not exposed.
- Keep colors in `0xRRGGBB`; pass opacity separately where supported.
- Log recoverable diagnostics with `widget.log("info"|"warn"|"error"|"debug", message)`.

## Verification

For repository development:

1. Save the files under the source `widgets` directory.
2. Run `scripts/check_l10n.bat` to catch untranslated Lua strings and missing keys.
3. Run `build.bat`; CMake copies the complete directory recursively to `.build\Release\widgets`.
4. In SnowDesktop, right-click the desktop and choose **添加组件**, then select the manifest display name.
5. Exercise click, double-click, wheel, editor, context-menu, and language-switch behavior as applicable.
6. Build Release before delivery. The release process copies the complete built `widgets` tree, including this skill and its resources, into `release\widgets`.

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
