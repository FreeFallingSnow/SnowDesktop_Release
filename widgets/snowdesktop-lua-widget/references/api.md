# SnowDesktop Lua Widget API

## Contents

- [Runtime model](#runtime-model)
- [Localization](#localization)
- [Callbacks](#callbacks)
- [Drawing](#drawing)
- [Widget and system](#widget-and-system)
- [Storage](#storage)
- [Desktop integration](#desktop-integration)
- [Everything search](#everything-search)
- [Calendar](#calendar)
- [Settings UI](#settings-ui)
- [Manifest and permissions](#manifest-and-permissions)
- [Troubleshooting](#troubleshooting)

## Runtime model

Scripts run in a sandbox containing:

- Base functions: `assert`, `error`, `ipairs`, `next`, `pairs`, `pcall`, `select`, `tonumber`, `tostring`, `type`, `xpcall`.
- Libraries: `string`, `table`, `math`, `utf8`.
- Host APIs: `draw`, `sys`, `layout`, `storage`, `widget`, `desktop`, `l10n`,
  `everything`, `media`, `http`, and `ui`.
- `imgui` only when the manifest declares `ui.input`.
- `widgetId`, a unique string for the current component instance.

Coordinates passed to drawing and mouse callbacks are local to the component. The origin is its upper-left corner.

### Script-level flags

```lua
showTitle = true        -- display widget.setTitle() value in the bottom bar
bottomBarHover = true   -- show the bottom bar only while hovering (default: true)
useCustomStyle = true   -- enable Lua custom background style and the unified appearance panel
followPersonalizationDefault = true -- follow global appearance until explicitly changed
```

The host reads these from the script globals before each render. `showTitle` defaults to `false`.
When `useCustomStyle` is true, the host reads these optional appearance globals
as script defaults:

```lua
bg = 0x18202A
border = 0xFFFFFF
alpha = 0.92
borderAlpha = 0.18
gradientEndA = 0.28
glassEnabled = false
```

`bg` and `border` use `0xRRGGBB`. The alpha fields use `0.0` through `1.0`.
Blur radius is a host-wide native-composition value owned by the global
appearance page; scripts and per-instance storage do not override it.
The widget editor exposes a separate **跟随全局** checkbox and a **主题** selector.
The selector contains the four host themes, **自定义**, and themes injected by
the manifest or Lua script. Switching themes does not change the follow state.
Set `followPersonalization` to `"1"`/`true` in storage when the widget should
follow global personalization. Use the top-level
`followPersonalizationDefault = true` declaration to make this the initial
state without coupling it to a theme preset.

The host checks the script timestamp and hot-reloads it while rendering. Persistent storage is scoped by component instance ID, so two instances of the same script keep separate values.

## Localization

```lua
name = l10n.tr("lua_widget.my_widget.name")

local status = l10n.tr("lua_widget.my_widget.item_count", #items)
local language = l10n.language()
```

- `l10n.tr(key, arguments...)` reads a string from the active host language
  resource and replaces `{0}`, `{1}`, and later placeholders with the supplied
  values. A missing key is returned unchanged so the error remains visible.
- `l10n.language()` returns the effective language such as `zh-CN` or `en-US`;
  when the user chooses the system language, it returns the resolved language.
- Language switching reloads Lua widgets. Compute localized top-level names,
  settings labels, presets, menus, and other cached strings with `l10n.tr`.
- Every widget must use literal keys and add the same keys to every language in
  its own manifest `locales` object. Lua widget strings do not belong in the
  host `lang/*.json`. Run `scripts/test.bat` to validate missing keys,
  placeholders, manifest keys, and hard-coded Chinese in Lua strings through
  the CTest localization contract.
- Manifests support `nameKey` and `descriptionKey`. Keep `name` and
  `description` as English fallbacks for hosts that do not contain those keys.
- If a script uses localized state-dependent titles, list those keys in the
  manifest's `titleKeys` array and update the title from
  `onLanguageChanged()`.

The widget's default title follows the active language. Once the user renames
an instance, later language switches preserve that custom title.

## Callbacks

All callbacks are optional except `render()` for visible output.

```lua
function render() end
function imguiRender() end
function onOpen() end
function onClick(x, y, button, delta) end
function onDoubleClick(x, y, button, delta) end
function onMouseDown(x, y, button, delta) end
function onMouseMove(x, y, button, delta) end
function onMouseUp(x, y, button, delta) end
function onWheel(x, y, button, delta) end
function renderPanel() end
function onPanelOpened() end
function onPanelClosed() end
function onPanelClick(x, y, button, delta) end
function onPanelMouseDown(x, y, button, delta) end
function onPanelMouseMove(x, y, button, delta) end
function onPanelMouseUp(x, y, button, delta) end
function onPanelWheel(x, y, button, delta) end
function onDesktopChanged(reason) end
function onCalendarChanged(reason) end
function onLanguageChanged() end
function onVisible() end
function onHidden() end
function onSelected() end
function onSizeChanged(columns, rows) end
function onTimer(name) end
function onHttpResponse(id, response) end
function onUiAction(id, value) end
function getContextMenu() return {} end
function onMenu(id) end
```

- Mouse callbacks receive four arguments even if the script only declares `x, y`.
- Panel mouse callbacks use coordinates local to the panel content area.
- `renderPanel()` is rendered in a host-owned transient panel opened with
  `widget.openPanel`. Only one component panel is open at a time; Escape,
  clicking outside, and the host close button dismiss it.
- `onSelected()` runs when the desktop selects the widget.
- For wheel handling, use the sign of `delta`.
- `onDesktopChanged(reason)` requires `desktop.read`.
- `onCalendarChanged(reason)` requires `calendar.read`; `reason` is
  `"selection"` or `"events"`.
- `onLanguageChanged()` runs after the widget has been reloaded with its new
  manifest locale. Use it to refresh state-dependent titles or other runtime
  text caches.
- `imguiRender()` requires `ui.input`.
- Context-menu callbacks require `ui.contextMenu`.

Menu example:

```lua
function getContextMenu()
    return {
        { id = 1, label = "执行操作", icon = "" },
        { id = 2, label = "刷新", icon = "", iconFont = "fluent" },
        { separator = true },
        { id = 3, label = "不可用项", icon = "", enabled = false }
    }
end

function onMenu(id)
    if id == 1 then widget.log("info", "menu action") end
end
```

Menu item fields:

- `id`: integer passed to `onMenu(id)`.
- `label`: displayed text.
- `icon`: optional icon glyph rendered by the host menu.
- `iconFont`: optional `"fa"` or `"fluent"`. It defaults to `"fa"` for
  compatibility; `"fluent"` selects the embedded Fluent System Icons Regular
  font.
- `enabled`: optional boolean; defaults to `true`.
- `separator`: set to `true` for a separator and omit the other fields.

The built-in Lua widget settings command is labeled **详细设置** and opens
`imguiRender()`.
Use the debug page's **Font Awesome 图标字符** or
**Fluent System Icons Regular 图标字符** grid to preview the embedded fonts and
click-copy a glyph for the `icon` field. To unlock **调试**, open
**设置 → 关于** and click the version number five times.

## Drawing

Colors use `0xRRGGBB`.

### `draw.text`

```lua
draw.text(x, y, text, size?, color?, maxWidth?, bold?, singleLine?, maxHeight?, alpha?)
```

- Defaults: `size=14`, `color=0xFFFFFF`, `maxWidth=0`.
- `maxWidth > 0` enables wrapping.
- `singleLine=true` disables wrapping and adds character ellipsis trimming.
- `alpha` controls text opacity from `0.0` (transparent) to `1.0` (opaque).

### `draw.measureText`

```lua
local metrics = draw.measureText(text, size?, maxWidth?, bold?)
-- metrics.width, metrics.height
```

Defaults match `draw.text`. Use this before drawing centered or fitted text.

### Shapes

```lua
draw.rect(x, y, width, height, color?, radius?, alpha?)
draw.strokeRect(x, y, width, height, color?, radius?, thickness?, alpha?)
draw.line(x1, y1, x2, y2, thickness?, color?, alpha?)
draw.circle(centerX, centerY, radius, color?, alpha?)
draw.pushClip(x, y, width, height)
draw.popClip()
```

Defaults:

- Color: `0xFFFFFF`.
- Alpha: `1.0`.
- Radius: `0`.

Use `pushClip` / `popClip` around scrollable content so partially visible rows
cannot draw over fixed headers or reserved areas. The host automatically unwinds
unbalanced widget clips after each render.
- Thickness: `1.0`.

`draw.circle` draws a filled circle.

### `draw.fa`

```lua
draw.fa(glyph, x, y, size?, color?)
```

Renders a single Font Awesome 6 Free Solid glyph at the given position.
Defaults: `size=20`, `color=0xFFFFFF`. The glyph is drawn centered in a square
of `size × size` pixels. Useful glyph codes include media controls (`` `` `` ``)
and icons (`` `` ``).

### `draw.fluent`

```lua
draw.fluent(glyph, x, y, size?, color?)
```

Renders one embedded Fluent System Icons Regular glyph with the same centering
and defaults as `draw.fa`. Prefer this for new controls when a Fluent glyph has
the same action semantics. The complete glyph list is available on the
SnowDesktop debug settings page.

### Images and shell icons

```lua
draw.image(relativePath, x, y, width, height, alpha?)
draw.icon(pathOrDesktopItem, x, y, size?, alpha?)
```

- `draw.image` accepts only a path relative to the root executable `widgets` directory.
- Supported image decoding is provided by Windows Imaging Component.
- `draw.icon` resolves a Windows shell icon and requires `desktop.read`.
- Resolved shell icons are cached across frames and refreshed after desktop
  changes; large result sets should still use `ui.virtualList` so only visible
  icons are drawn.
- `pathOrDesktopItem` may be a path string or an item table returned by `desktop`.

## Widget and system

```lua
local info = widget.info()
-- info.id, info.width, info.height, info.selected
-- info.selectedPackageId is the package UUID of the one selected
-- Lua widget, or an empty string when that is not applicable

widget.setTitle("新标题")
widget.invalidate()
widget.log("info", "message")

local theme = widget.theme()
-- theme.bg, theme.border, theme.alpha, theme.borderAlpha, theme.gradientEndA
-- theme.cornerRadius

widget.editText(key, x, y, width, height, multiline,
    initialText?, selectAll?, textColor?, fontSize?, backgroundColor?)

widget.openSettings()
widget.openPanel({
    title = "编辑",
    width = 560,
    height = 620,
})
widget.closePanel()
```

`widget.openSettings` opens the host settings panel for the current widget
instance. Call this from `onDoubleClick` or `onMenu` to let the user configure
the widget without using the right-click menu.

`widget.openPanel(options)` opens a collection-popup-style auxiliary surface
for form-heavy or detail-heavy interactions. The host clamps `width` to
320–900 pixels and `height` to 280–900 pixels and further constrains the panel
to the current work area. Render its content in `renderPanel()` using the same
`draw`, `layout`, and host-rendered `ui` controls as the widget. Use
`widget.closePanel()` after save or cancel. Prefer this surface for editors
that would otherwise crowd the widget's normal grid span.

`widget.editText` is a legacy compatibility API that opens the old system-style
editor and saves the result to `storage` under `key`. It is not recommended for
new or updated widgets; use `ui.textInput` or `ui.textArea` instead. Defaults:

- `initialText`: current stored value.
- `selectAll`: `true`.
- `textColor`: `0x000000`.
- `fontSize`: `15` pixels. Pass `layout.fontCu(...)` to match widget text.
- `backgroundColor`: `0xFFFFFF`.

Time:

```lua
local t = sys.getTime()
-- year, month, day, wday (1=Sunday), hour, min, sec
```

Notification:

```lua
sys.notify(title, message)
```

Shows a system tray balloon notification. Both arguments are required strings.

Layout:

```lua
local width = layout.width()
local height = layout.height()
local columns = layout.columns()
local rows = layout.rows()
local sizeClass = layout.sizeClass() -- small, medium, large
local cellW = layout.cellWidth()     -- grid cell width (DPI-aware, px)
local cellH = layout.cellHeight()    -- grid cell height (DPI-aware, px)
local gapY = layout.cellGap()        -- grid vertical gap (DPI-aware, px)
local barH = layout.barHeight()      -- bottom bar height in cu (default 24, range 16-48)
local scale = layout.cellScale()     -- min(cellW / 92, cellH / 116)
local fontSize = layout.cu(15)       -- 15 design units converted to px
```

`cellWidth` and `cellHeight` return the current monitor's DPI-scaled grid cell
dimensions — the same values used to size desktop icons and collection items.
`cellGap` returns the vertical grid gap in DPI-scaled pixels.
`barHeight` returns the bottom bar height in design units (cu), configurable
between 16 and 48 in settings. Use `layout.cu(layout.barHeight())` to get the
pixel height for layout calculations.
`cellScale` returns the component scale relative to the standard `92 x 116`
grid cell. `cu(value)` converts a design value to current pixels. Existing
`draw.text` sizes remain pixel values, so use `draw.text(..., layout.cu(15))`
when a widget should scale with its grid cell.

Cached system snapshots require `system.read`:

```lua
local cpu = sys.cpu()
-- available, usagePercent, logicalProcessors
local memory = sys.memory()
-- available, totalBytes, usedBytes, freeBytes, usagePercent
local battery = sys.battery()
-- available, percent, charging, pluggedIn, saver
local network = sys.network()
-- available, connected, downloadBytesPerSec, uploadBytesPerSec,
-- receivedBytes, sentBytes
local gpu = sys.gpu()
-- available, name, usagePercent, vramTotalBytes, vramUsedBytes
```

Media requires `media.read`; controls require `media.action`:

```lua
local current = media.current()
-- available, title, artist, album, sourceApp, playbackStatus,
-- canPlayPause, canNext, canPrevious
media.playPause()
media.next()
media.previous()
```

Named timers:

```lua
widget.setTimer("refresh", 60000, true)
widget.cancelTimer("refresh")
function onTimer(name) end
```

Intervals are clamped to 100 ms through 24 hours. One-shot timers pass `false`
as the third argument.

## Asynchronous HTTP

Declare `network.http` and list exact or wildcard hosts in `networkDomains`.

```lua
local requestId = http.request({
    url = "https://api.example.com/data",
    method = "GET",
    headers = { ["Accept"] = "application/json" },
    body = "",
    timeoutMs = 10000,
    cacheSeconds = 300
})

function onHttpResponse(id, response)
    -- response.ok, status, body, error, fromCache
end

http.cancel(requestId)
```

The host permits at most four concurrent requests per widget, a 64 KiB request
body, a 1 MiB response, three redirects, and a 30-second maximum timeout.
Callbacks are dispatched on the Lua host thread. Every redirect target must
still match `networkDomains`, and `response.ok` is true only for HTTP 2xx.

## Host controls

```lua
ui.button(id, label, x, y, width, height, enabled?)
ui.toggle(id, label, x, y, width, height, value)
local value = ui.textInput(id, storageKey, x, y, width, height, options?)
local text = ui.textArea(id, storageKey, x, y, width, height, options?)
local focused = ui.focusInput(id)
ui.progress(x, y, width, height, value0To1, color?)
local offset = ui.scrollArea(id, x, y, width, height, contentHeight)
local range = ui.virtualList(id, x, y, width, height, itemHeight, itemCount)
-- range.first, range.last, range.offset
ui.setScrollOffset(id, offset)

function onUiAction(id, value)
end
```

Buttons and toggles use host hit-testing. Scroll areas and virtual lists consume
the mouse wheel while the pointer is inside their bounds. The host automatically
draws a scrollbar at the right edge of the widget frame when the content height
exceeds the viewport height. Scroll offsets are clamped automatically when the
viewport or content shrinks. Use `ui.setScrollOffset(id, 0)` when replacing a
list with a new data set that should start at the top.

`ui.textInput` draws a persistent, transparent single-line input field entirely
through Direct2D and saves the edited value under `storageKey`. It uses the
desktop's hidden keyboard input window, so focusing it never creates an opaque
native control over the widget. Clicking the field focuses it and places the
caret at the pointed character; dragging selects an arbitrary text range.
`ui.focusInput(id)` does the same programmatically. Supported options are
`placeholder`, `fontSize` (pixels, default `15`), `textColor`, `placeholderColor`,
`backgroundColor`, `borderColor`, `focusedBorderColor`, `backgroundAlpha`,
`focusedBackgroundAlpha`, `borderAlpha`, `focusedBorderAlpha`, `radius`,
`padding`, `borderThickness`, `selectAll`, and `liveUpdate`. The transparency
default to 0.05 at rest and 0.12 while focused. Pass `layout.fontCu(...)` as
`fontSize` to match other widget text.
`liveUpdate` defaults to `true`; pressing Escape restores the value from before
editing.

`ui.textArea` uses the same Direct2D-rendered input path and option set, but
wraps text across multiple lines and scrolls with the mouse wheel when its
content exceeds the viewport. It also accepts `placeholderWhenWhitespace`;
when `true`, text containing only whitespace is treated as empty for the
unfocused placeholder. Enter inserts a newline, Ctrl+Enter commits and leaves
the field, and Escape restores the value from before editing. Both input types
highlight mouse-drag or Shift+arrow selections. Typing, Backspace, Delete,
cutting, or pasting replaces the selected range; Ctrl+A/C/X/V use the standard
selection and clipboard behavior. Windows IME composition text and candidate
windows follow the rendered caret, including the scroll offset inside a
multiline field. Uncommitted IME text is rendered inline with an underline and
does not enter widget storage until the IME commits it.

## Storage

```lua
local value = storage.get("key") -- string or nil
storage.set("key", tostring(value))
storage.remove("key")
local keys = storage.keys()
```

All values are strings. Each `storage.set` and `storage.remove` persists immediately, so call them on user actions or actual changes rather than every render.

Common conversions:

```lua
local count = tonumber(storage.get("count")) or 0
local enabled = storage.get("enabled") ~= "0"
storage.set("enabled", enabled and "1" or "0")
```

## Desktop integration

Reading requires `desktop.read`:

```lua
local all = desktop.items()
local selected = desktop.selection()
local matches = desktop.find("query", 200) -- optional result limit
local apps = desktop.findApplications("query", 40)
```

`desktop.find` matches item titles by normal text, pinyin initials, and compact
full pinyin for Chinese titles. For example, `"wx"` and `"weixin"` can match
`"微信"`. Its optional result limit is clamped to 1–1000; omit it or pass a
non-positive value for all matches. Search widgets should use a practical limit
and debounce live input so large folder-backed components do not create a large
Lua table for every keystroke.

`desktop.findApplications` searches the Windows `shell:AppsFolder` application
index used by SnowDesktop's native search popup. It returns the same item shape
with `source = "Applications"` and `type = "application"`, requires
`desktop.read`, and accepts a result limit clamped to 1–200. The first call can
start background indexing; widgets receive `onDesktopChanged("applications")`
when the index becomes available and should refresh a non-empty search then.

Each item contains:

```lua
{
    id = "...",
    title = "...",
    path = "...",
    source = "...",
    type = "...",
    selected = false
}
```

Actions require `desktop.action`:

```lua
local opened = desktop.open(itemOrPath)
local revealed = desktop.reveal(itemOrPath)
desktop.refresh()
```

`desktop.open` and `desktop.reveal` return booleans.

## Everything search

Everything search is separate from `desktop.find` and requires
`everything.search`:

```lua
local results = everything.search("query", 40)
```

The optional second argument is the maximum number of results, clamped by the
host. Returned items use the same shape as desktop items; `source` is
`"Everything"`, and `path` contains the full filesystem path.

## Calendar

Shared local calendar data is stored by the host. Reading requires
`calendar.read`; selecting a date and mutating events requires
`calendar.write`:

```lua
local selected = calendar.selectedDate() -- YYYY-MM-DD
calendar.setSelectedDate("2026-07-30")

local info = calendar.dateInfo("2026-07-30")
-- year, month, day, weekday (1=Sunday), daysInMonth
local tomorrow = calendar.addDays("2026-07-30", 1)

local events = calendar.events("2026-07-30", "2026-08-05")
local created = calendar.create({
    title = "Design review",
    date = "2026-07-30",
    allDay = false,
    startMinutes = 600,
    endMinutes = 660,
    notes = "",
    reminderMinutes = 15,
})
local updated = calendar.update(created.id, created.revision, {
    title = "Updated design review",
    date = "2026-07-30",
    allDay = false,
    startMinutes = 600,
    endMinutes = 660,
    notes = "",
    reminderMinutes = 15,
})
local removed = calendar.remove(created.id)
```

Mutation results contain `ok`, `id`, `revision`, and `error`. Updates require
the revision returned by the latest query or mutation and return
`error = "conflict"` rather than overwriting a newer edit.

Events contain `id`, `revision`, `title`, `date`, `allDay`, `startMinutes`,
`endMinutes`, `notes`, and `reminderMinutes`. Dates use local time and ISO
`YYYY-MM-DD`. Timed events cannot cross midnight. Reminder values supported by
the host are `-1` (none), `0`, `5`, `15`, `30`, `60`, and `1440`
minutes before the event. All-day reminders use 09:00 local time as their
base.

## Settings UI

Declare `ui.input`, then define `imguiRender()`.

The host renders the widget editor inside a scrollable page. When
`imguiRender()` exists, its output is also wrapped in a scrollable child region,
so scripts should emit controls directly and should not add an extra full-page
scroll container only to compensate for editor height.

```lua
imgui.text(text)
imgui.textWrapped(text)
imgui.separator()
imgui.sameLine(offset?, spacing?)
imgui.settingRow(label, width?) -- right-aligns the next control
imgui.spacing()

local open = imgui.collapsingHeader(label)
local treeOpen = imgui.treeNode(label)
imgui.treePop()

local clicked = imgui.button(label)
local text = imgui.input(label, currentText)       -- multiline
local text = imgui.inputText(label, currentText)   -- single line
local checked = imgui.checkbox(label, checked)
local color = imgui.colorEdit3(label, color)
local number = imgui.sliderFloat(label, value, min, max)
local integer = imgui.sliderInt(label, value, min, max)
local index = imgui.combo(label, oneBasedIndex, { "A", "B" })
local clicked = imgui.selectable(label, selected)
local clicked = imgui.radio(label, active)
imgui.beginDisabled(disabled)
imgui.endDisabled()
```

Controls return the new/current value. Persist a value only when it differs from
the previous value.

For `useCustomStyle = true` widgets, the host shows **跟随全局** and **主题** by
default. Manual colors, opacity, gradient, and glass controls appear only for
the **自定义** theme. **恢复默认设置** applies declarative field defaults,
falling back to matching values from the default preset when a field has no
explicit `default`.

Keep custom `imguiRender()` reset buttons consistent with that split when a
widget exposes both visual style and behavior/data settings.

## Manifest and permissions

The package manifest is always `widget.json` at the component root. Its `entry`
field identifies `main.lua` or another safe package-relative Lua file.

```json
{
  "schemaVersion": 1,
  "id": "bea2cf61-ce15-4dd7-aec0-af3c29a16440",
  "slug": "example-widget",
  "name": "Example Widget",
  "nameKey": "lua_widget.example.name",
  "version": "1.0.0",
  "apiVersion": 1,
  "dataVersion": 1,
  "description": "Example description.",
  "descriptionKey": "lua_widget.example.description",
  "locales": {
    "zh-CN": {
      "lua_widget.example.name": "示例组件",
      "lua_widget.example.description": "示例说明。"
    },
    "en-US": {
      "lua_widget.example.name": "Example Widget",
      "lua_widget.example.description": "Example description."
    }
  },
  "defaultSize": { "columns": 2, "rows": 1 },
  "minSize": { "columns": 2, "rows": 1 },
  "maxSize": { "columns": 4, "rows": 3 },
  "permissions": ["ui.input", "network.http"],
  "networkDomains": ["api.example.com"],
  "author": "Example",
  "license": "MIT",
  "minHostVersion": "1.0.1.0",
  "entry": "main.lua",
  "presets": [
    {
      "id": "default",
      "label": "默认",
      "default": true,
      "values": {
        "bg": 1581098,
        "border": 16777215,
        "alpha": 0.92,
        "borderAlpha": 0.18,
        "gradientEndA": 0.28
      }
    }
  ],
  "settings": [
    { "key": "enabled", "label": "启用", "type": "bool", "default": "1" },
    { "key": "count", "label": "数量", "type": "int", "default": "5", "min": 1, "max": 20 },
    { "key": "mode", "label": "模式", "type": "select", "default": "A", "options": ["A", "B"] },
    { "key": "color", "label": "颜色", "type": "color", "default": "16777215" }
  ]
}
```

Lua scripts can also declare the same settings directly:

```lua
settings = {
  presets = {
    { id = "default", label = "默认", default = true,
      values = {
        bg = 0x18202A,
        border = 0xFFFFFF,
        alpha = 0.92,
        borderAlpha = 0.18,
        gradientEndA = 0.28,
        glassEnabled = false
      } }
  },
  fields = {
    { key = "enabled", label = "启用", type = "bool", default = true },
    { key = "color", label = "颜色", type = "color", default = 0xFFFFFF }
  }
}
```

For `useCustomStyle = true` widgets, manifest and script presets are appended to
the **主题** selector after the four host themes and **自定义**. Selecting one
applies only these visual keys:

| Key | Meaning |
|---|---|
| `bg` | background color, `0xRRGGBB` |
| `border` | border color, `0xRRGGBB` |
| `alpha` | background opacity, `0.0` through `1.0` |
| `borderAlpha` | border opacity, `0.0` through `1.0` |
| `gradientEndA` | bottom gradient opacity, `0.0` through `1.0` |
| `glassEnabled` | enable the per-widget frosted backdrop |

`followPersonalization` is controlled separately and should not be included in
theme presets.

Keep presets appearance-only. Put data URLs, refresh intervals, feature toggles,
timers, and other behavior into declarative fields so visual presets do not
silently change how the component works.

`cornerRadius` and `barHeight` are host-owned layout settings. Widgets may read
the current values through theme/layout APIs for alignment, but declarative
settings and presets cannot override them.

`minSize` and `maxSize` are optional grid-span constraints. If omitted, the
component can use any valid grid span from `1 x 1` up to the current page size.
A `maxSize` dimension of `0` is also treated as unrestricted. The host adjusts
`defaultSize` into the declared range and enforces the limits while resizing,
restoring saved layouts, and reacting to grid changes.

| Permission | Required for |
|---|---|
| `ui.input` | `imgui`, `imguiRender()` |
| `ui.contextMenu` | `getContextMenu()`, `onMenu(id)` |
| `ui.notify` | rate-limited `sys.notify` |
| `desktop.read` | `desktop.items`, `selection`, `find`, `draw.icon`, desktop-change callback |
| `desktop.action` | `desktop.open`, `reveal`, `refresh` |
| `everything.search` | `everything.search(query, maxResults)` |
| `system.read` | `sys.cpu`, `memory`, `battery`, `network`, `gpu` |
| `media.read` | `media.current` |
| `media.action` | Media playback controls |
| `network.http` | `http.request`, `http.cancel` |
| `calendar.read` | selected date, date helpers, event queries, calendar-change callback |
| `calendar.write` | shared date selection and event create/update/delete |

Missing permissions produce a runtime error for guarded APIs. Context menus and desktop-change callbacks are skipped by the host when their permission is absent.

Declarative setting types are `text`, `bool`, `int`, `float`, `select`, and `color`.
Values are stored in the same per-instance string storage used by `storage`.

Validate and export with `snowwidget validate <directory>` and
`snowwidget pack <directory> <output.snowwidget>`. Installation always stages
and validates the complete package. Package identity is the UUID, versions are
SemVer, and last-known-good versions remain available for rollback. Source
changes and permission/domain expansion require explicit confirmation.

## Troubleshooting

### Component is absent from **添加组件**

- Put `widget.json` and its declared Lua entry in one package directory.
- Do not put runnable loose scripts directly in `widgets`.
- Rebuild or run the widget sync script after editing the source repository's `widgets` folder.
- Run `snowwidget validate` and fix every error in its JSON report.

### Manifest is ignored

- Name the manifest `widget.json` and keep `entry` package-relative.
- Validate JSON syntax.
- Keep `defaultSize` values between 1 and 8.
- Ensure `defaultSize` is compatible with optional `minSize` and `maxSize`.

### `imgui` is nil

Add `"ui.input"` to the manifest permissions.

### Permission denied

Add the exact permission required by the API and reload the widget.

### Widget shows a red error panel

- Inspect syntax and argument types.
- Use `widget.log` before the failing branch.
- Save the correction, then refresh/re-add the widget if it was marked invalid.

### Image does not render

- Use a relative path under the current package directory.
- Do not pass an absolute path.
- Verify Windows Imaging Component supports the file.

### Settings or render stutters

- Remove unconditional `storage.set` calls from `render()`.
- Cache or limit desktop queries where possible.
- Avoid loading many shell icons every frame.
