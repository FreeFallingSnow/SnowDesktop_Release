---
name: snowdesktop-lua-widget
description: Create, modify, debug, validate, and package Lua desktop widget folders for SnowDesktop. Use when writing a widget package with widget.json and main.lua, adding drawing or mouse behavior, using widget storage and settings UI, querying desktop items, declaring permissions, or diagnosing a SnowDesktop Lua widget that does not load or render.
---

# SnowDesktop Lua Widget

Create widgets against SnowDesktop's built-in sandboxed Lua API. Every runnable component is one package directory:

```text
widgets/
└── my-widget/
    ├── widget.json
    ├── main.lua
    ├── assets/
    ├── modules/
    └── locales/
```

SnowDesktop discovers validated package folders, never loose `.lua + .widget.json`
pairs. Built-ins live under the read-only executable `widgets` directory.
Installed and development packages live under `data\widgets\installed` and
`data\widgets\dev`. Layouts store the immutable package UUID, not a path.

## Workflow

1. Copy [assets/widget-template](assets/widget-template) as a new package directory.
2. Generate a new UUID for `id`, choose a lowercase hyphenated `slug`, and keep the UUID forever across channels.
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
11. For repository development, run `scripts\widget-dev.bat widgets\my-widget`.
    The first run syncs the package into `.build\<Config>\data\widgets\dev`,
    activates the development override, and then watches source files. Later
    saves update the live package without rebuilding the host.
12. Run `snowwidget validate <directory>` and `snowwidget pack <directory> <name.snowwidget>`.
13. Check transactional hot reload after saving; a failed reload keeps the last-known-good VM.

Read [references/api.md](references/api.md) whenever using callbacks, permissions, drawing arguments, desktop integration, settings controls, or troubleshooting.

## Required structure

Every script should define:

```lua
name = l10n.tr("lua_widget.my_widget.name")

function render()
    local w = layout.width()
    local pad = layout.cu(12)
    draw.text(pad, pad, l10n.tr("lua_widget.my_widget.hello"),
        layout.cu(15), 0xFFFFFF, w - pad * 2)
end
```

Use these optional top-level flags and appearance globals:

- `useCustomStyle = true`: enable Lua-controlled background appearance and the
  host's unified **外观** settings panel for this widget.
- `followPersonalizationDefault = true`: make a new instance follow the global
  appearance until the user explicitly changes its follow state.
- When `followPersonalizationDefault = true`, omit `settings.presets` that only
  repeat the global default, dark/light, transparent, or standard appearance.
  Keep presets only when they provide a component-specific visual mode, such
  as sticky-note paper colors or a materially different clock face.
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
  "schemaVersion": 1,
  "id": "f527797f-a986-4ad1-a58d-250ef91f53d3",
  "slug": "my-widget",
  "name": "My Widget",
  "nameKey": "lua_widget.my_widget.name",
  "version": "1.0.0",
  "apiVersion": 1,
  "dataVersion": 1,
  "entry": "main.lua",
  "minHostVersion": "1.0.1.0",
  "author": "Your Name",
  "license": "MIT",
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
- `ui.notify`: enable rate-limited host notifications.
- `desktop.read`: enable desktop queries and `draw.icon`.
- `desktop.action`: enable open, reveal, and desktop refresh actions.
- `system.read`: enable cached CPU, memory, battery, and network snapshots.
- `media.read`: read the current Windows media session.
- `media.action`: play/pause, skip next, and skip previous.
- `network.http`: enable asynchronous requests to arbitrary HTTP and HTTPS
  URLs. The host does not enforce a per-domain or public-network allowlist.
- `calendar.read`: read shared local calendar dates and events.
- `calendar.write`: select a shared date and create, edit, or delete events.

Keep `defaultSize.columns` and `defaultSize.rows` between 1 and 8.

## Implementation rules

- SnowDesktop uses a **design unit** system where `layout.cu(15)` converts grid-cell-relative
  design values to DPI-scaled pixels. Prefer `layout.cu()` over hardcoded pixel values so widgets
  scale correctly across monitors and DPI settings. See [references/api.md](references/api.md) for the full layout API.
- Treat `render()` as a hot path. Do not write storage or perform desktop queries repeatedly unless necessary.
- Use literal keys with `l10n.tr("key", arguments...)`; placeholders use
  `{0}`, `{1}`, and so on. `l10n.language()` returns the effective language
  (for example, `zh-CN`, `zh-TW`, `ja-JP`, or `en-US`) for behavior that truly
  varies by locale.
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
- Pass image paths relative to the current package directory. Absolute paths,
  parent traversal, symlinks, junctions, and reparse points are rejected.
- Pass desktop item tables directly to `draw.icon`, `desktop.open`, or `desktop.reveal`.
- Add `ui.input` before defining `imguiRender`; otherwise `imgui` is absent from the sandbox.
- Add `ui.contextMenu` before defining custom menu callbacks; otherwise the host ignores them.
- Context-menu items may set `icon` to a Font Awesome 6 Free Solid glyph, for
  example `{ id = 1, label = "刷新", icon = "" }`. They may instead set
  `iconFont = "fluent"` and use a Fluent System Icons Regular glyph. The default
  remains Font Awesome for compatibility; leave `icon` out for no icon.
- Use `draw.fluent(glyph, x, y, size, color)` for matching in-component Fluent
  controls; `draw.fa` remains available for existing component compatibility.
- To unlock the debug page, open **设置 → 关于** and click the version number
  five times. Then open **调试 → Font Awesome 图标字符** or
  **Fluent System Icons Regular 图标字符**; clicking an icon copies it to the
  clipboard.
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
- Use `ui.button`, `ui.toggle`, `ui.textInput`, `ui.textArea`, `ui.progress`,
  `ui.scrollArea`, and `ui.virtualList` when host-managed interaction or
  scrolling is sufficient. `ui.textInput` and `ui.textArea` are
  Direct2D-rendered and transparent like the desktop file search field; do not
  layer a native text editor over them. `ui.textArea` provides wrapped
  multiline input and wheel scrolling. Both controls provide host-managed
  caret placement, mouse-drag text selection, selection highlighting, and
  standard keyboard/clipboard replacement behavior.
- Treat `widget.editText` as a legacy compatibility API. It opens the old
  system-style editor and is not recommended for new or updated widgets. Use
  `ui.textInput` for one line and `ui.textArea` for multiple lines.
- Use `onSelected()` when a widget should react as soon as the desktop selects
  it. For search-oriented widgets, call `ui.focusInput(id)` there so the
  host-rendered input is ready for typing immediately.
- Use `widget.openPanel()` plus `renderPanel()` for form-heavy editors or
  details that do not fit the component's normal grid span. Keep the primary
  component useful while the host-owned transient panel is open.
- Never call `http.request()` unconditionally from `render()`. Start requests
  from lifecycle, timer, menu, or UI callbacks and consume them in
  `onHttpResponse`. Redirect targets may use HTTP or HTTPS.
- Do not use `io`, `os`, `require`, `package`, `load`, or arbitrary filesystem/process APIs. They are not exposed.
- Keep colors in `0xRRGGBB`; pass opacity separately where supported.
- Log recoverable diagnostics with `widget.log("info"|"warn"|"error"|"debug", message)`.

## Verification

For repository development:

1. Save the package directory under the source `widgets` directory.
2. Run `scripts/test.bat` to catch untranslated Lua strings and missing keys through the CTest localization contract.
3. Build the host once, then run `scripts\widget-dev.bat widgets\my-widget`.
   It validates and mirrors the source package into the active development
   directory. When the override is first created, SnowDesktop restarts once to
   discover it; subsequent `main.lua`, manifest, locale, module, and asset saves
   are synced and trigger the host's transactional Lua hot reload.
4. Use `-Once` for a one-time sync or `-RestartHost` when package discovery
   needs to be forced. Stop watch mode with `Ctrl+C`; the development override
   remains available for the next session.
5. Run `.build\Release\snowwidget.exe validate widgets\my-widget`.
6. In SnowDesktop, right-click the desktop and choose **添加组件**, then select the manifest display name.
7. Exercise click, double-click, wheel, editor, context-menu, and language-switch behavior as applicable.
8. Run `scripts\build.bat` only for final delivery verification. The release process
   copies the complete built `widgets` tree, including this skill and its
   resources, into `release\widgets`.

Before finishing, verify:

- The package contains `widget.json` and its declared `main.lua` entry.
- `id` is a stable UUID; `version` is SemVer; `apiVersion` is supported.
- JSON is valid UTF-8.
- `defaultSize` falls within any declared `minSize` / `maxSize`.
- Every used privileged API has its permission.
- Every network request uses an HTTP or HTTPS URL.
- Timers and HTTP requests are not started repeatedly from `render()`.
- `render()` works at the manifest's default span and at a resized span.
- No storage write occurs unconditionally on every frame.
