# SnowDesktop Lua Widget API

## Contents

- [Runtime model](#runtime-model)
- [Callbacks](#callbacks)
- [Drawing](#drawing)
- [Widget and system](#widget-and-system)
- [Storage](#storage)
- [Desktop integration](#desktop-integration)
- [Everything search](#everything-search)
- [Settings UI](#settings-ui)
- [Manifest and permissions](#manifest-and-permissions)
- [Troubleshooting](#troubleshooting)

## Runtime model

Scripts run in a sandbox containing:

- Base functions: `assert`, `error`, `ipairs`, `next`, `pairs`, `pcall`, `select`, `tonumber`, `tostring`, `type`, `xpcall`.
- Libraries: `string`, `table`, `math`, `utf8`.
- Host APIs: `draw`, `sys`, `layout`, `storage`, `widget`, `desktop`,
  `everything`, `media`, `http`, and `ui`.
- `imgui` only when the manifest declares `ui.input`.
- `widgetId`, a unique string for the current component instance.

Coordinates passed to drawing and mouse callbacks are local to the component. The origin is its upper-left corner.

Coordinates passed to drawing and mouse callbacks are local to the component. The origin is its upper-left corner.

### Script-level flags

```lua
showTitle = true        -- display widget.setTitle() value in the bottom bar
bottomBarHover = true   -- show the bottom bar only while hovering (default: true)
useCustomStyle = true   -- read bg/border/alpha/gradientEndA globals instead of personalization
```

The host reads these from the script globals before each render. `showTitle` defaults to `false`.

The host checks the script timestamp and hot-reloads it while rendering. Persistent storage is scoped by component instance ID, so two instances of the same script keep separate values.

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
function onDesktopChanged(reason) end
function onVisible() end
function onHidden() end
function onSizeChanged(columns, rows) end
function onTimer(name) end
function onHttpResponse(id, response) end
function onUiAction(id, value) end
function getContextMenu() return {} end
function onMenu(id) end
```

- Mouse callbacks receive four arguments even if the script only declares `x, y`.
- For wheel handling, use the sign of `delta`.
- `onDesktopChanged(reason)` requires `desktop.read`.
- `imguiRender()` requires `ui.input`.
- Context-menu callbacks require `ui.contextMenu`.

Menu example:

```lua
function getContextMenu()
    return {
        { id = 1, label = "执行操作", icon = "" },
        { separator = true },
        { id = 2, label = "不可用项", icon = "", enabled = false }
    }
end

function onMenu(id)
    if id == 1 then widget.log("info", "menu action") end
end
```

Menu item fields:

- `id`: integer passed to `onMenu(id)`.
- `label`: displayed text.
- `icon`: optional Font Awesome 6 Free Solid glyph rendered by the host menu.
- `enabled`: optional boolean; defaults to `true`.
- `separator`: set to `true` for a separator and omit the other fields.

The built-in Lua widget settings command is labeled **详细设置** and opens
`imguiRender()`.
Use the debug page's **Font Awesome 图标字符** grid to preview the embedded font
and click-copy a glyph for the `icon` field. To unlock **调试**, open
**设置 → 关于** and click the version number five times.

## Drawing

Colors use `0xRRGGBB`.

### `draw.text`

```lua
draw.text(x, y, text, size?, color?, maxWidth?, bold?, singleLine?, maxHeight?)
```

- Defaults: `size=14`, `color=0xFFFFFF`, `maxWidth=0`.
- `maxWidth > 0` enables wrapping.
- `singleLine=true` disables wrapping and adds character ellipsis trimming.

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

### Images and shell icons

```lua
draw.image(relativePath, x, y, width, height, alpha?)
draw.icon(pathOrDesktopItem, x, y, size?, alpha?)
```

- `draw.image` accepts only a path relative to the root executable `widgets` directory.
- Supported image decoding is provided by Windows Imaging Component.
- `draw.icon` resolves a Windows shell icon and requires `desktop.read`.
- `pathOrDesktopItem` may be a path string or an item table returned by `desktop`.

## Widget and system

```lua
local info = widget.info()
-- info.id, info.width, info.height

widget.setTitle("新标题")
widget.invalidate()
widget.log("info", "message")

local theme = widget.theme()
-- theme.bg, theme.border, theme.alpha, theme.gradientEndA

widget.editText(key, x, y, width, height, multiline,
    initialText?, selectAll?, textColor?)

widget.openSettings()
```

`widget.openSettings` opens the host settings panel for the current widget
instance. Call this from `onDoubleClick` or `onMenu` to let the user configure
the widget without using the right-click menu.

`widget.editText` opens a host edit control and saves the result to `storage` under `key`. Defaults:

`widget.editText` opens a host edit control and saves the result to `storage` under `key`. Defaults:

- `initialText`: current stored value.
- `selectAll`: `true`.
- `textColor`: `0x000000`.

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
local fontSize = layout.cu(14)       -- 14 design units converted to px
```

`cellWidth` and `cellHeight` return the current monitor's DPI-scaled grid cell
dimensions — the same values used to size desktop icons and collection items.
`cellGap` returns the vertical grid gap in DPI-scaled pixels.
`barHeight` returns the bottom bar height in design units (cu), configurable
between 16 and 48 in settings. Use `layout.cu(layout.barHeight())` to get the
pixel height for layout calculations.
`cellScale` returns the component scale relative to the standard `92 x 116`
grid cell. `cu(value)` converts a design value to current pixels. Existing
`draw.text` sizes remain pixel values, so use `draw.text(..., layout.cu(14))`
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
ui.progress(x, y, width, height, value0To1, color?)
local offset = ui.scrollArea(id, x, y, width, height, contentHeight)
local range = ui.virtualList(id, x, y, width, height, itemHeight, itemCount)
-- range.first, range.last, range.offset

function onUiAction(id, value)
end
```

Buttons and toggles use host hit-testing. Scroll areas and virtual lists consume
the mouse wheel while the pointer is inside their bounds. The host automatically
draws a scrollbar at the right edge of the widget frame when the content height
exceeds the viewport height.

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
local matches = desktop.find("query")
```

`desktop.find` matches item titles by normal text, pinyin initials, and compact
full pinyin for Chinese titles. For example, `"wx"` and `"weixin"` can match
`"微信"`.

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

## Settings UI

Declare `ui.input`, then define `imguiRender()`.

```lua
imgui.text(text)
imgui.textWrapped(text)
imgui.separator()
imgui.sameLine(offset?, spacing?)
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

Controls return the new/current value. Persist a value only when it differs from the previous value.

## Manifest and permissions

The manifest filename is derived by replacing `.lua` with `.widget.json`.

```json
{
  "name": "示例组件",
  "version": "1.0.0",
  "description": "示例说明。",
  "defaultSize": { "columns": 2, "rows": 1 },
  "minSize": { "columns": 2, "rows": 1 },
  "maxSize": { "columns": 4, "rows": 3 },
  "permissions": ["ui.input", "network.http"],
  "networkDomains": ["api.example.com", "*.example.net"],
  "publisher": "Example",
  "minHostVersion": "0.1.2",
  "entry": "example.lua",
  "settings": [
    { "key": "enabled", "label": "启用", "type": "bool", "default": "1" },
    { "key": "count", "label": "数量", "type": "int", "default": "5", "min": 1, "max": 20 },
    { "key": "mode", "label": "模式", "type": "select", "default": "A", "options": ["A", "B"] }
  ]
}
```

`minSize` and `maxSize` are optional grid-span constraints. If omitted, the
component can use any valid grid span from `1 x 1` up to the current page size.
A `maxSize` dimension of `0` is also treated as unrestricted. The host adjusts
`defaultSize` into the declared range and enforces the limits while resizing,
restoring saved layouts, and reacting to grid changes.

| Permission | Required for |
|---|---|
| `ui.input` | `imgui`, `imguiRender()` |
| `ui.contextMenu` | `getContextMenu()`, `onMenu(id)` |
| `desktop.read` | `desktop.items`, `selection`, `find`, `draw.icon`, desktop-change callback |
| `desktop.action` | `desktop.open`, `reveal`, `refresh` |
| `everything.search` | `everything.search(query, maxResults)` |
| `system.read` | `sys.cpu`, `memory`, `battery`, `network`, `gpu` |
| `media.read` | `media.current` |
| `media.action` | Media playback controls |
| `network.http` | `http.request`, `http.cancel` |

Missing permissions produce a runtime error for guarded APIs. Context menus and desktop-change callbacks are skipped by the host when their permission is absent.

Declarative setting types are `text`, `bool`, `int`, `float`, and `select`.
Values are stored in the same per-instance string storage used by `storage`.

For local package installation, select a `.widget.json` from
**设置 → 调试 → 安装/升级组件包**. The optional `entry` field names the paired
Lua file. Reinstalling the same manifest stem upgrades it. An optional
`signature` field accepts `sha256:<64 lowercase hex characters>` and is checked
against the Lua entry file. `minHostVersion` hides and rejects incompatible
widgets. Installation validates temporary files first and restores the previous
version if replacement fails.

## Troubleshooting

### Component is absent from **添加组件**

- Put the `.lua` file directly in the executable's `widgets` directory.
- Do not put runnable scripts in a subdirectory.
- Rebuild or run the widget sync script after editing the source repository's `widgets` folder.
- Confirm the extension is exactly `.lua`.

### Manifest is ignored

- Match `example.lua` with `example.widget.json`.
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

- Use a relative path under the root `widgets` directory.
- Do not pass an absolute path.
- Verify Windows Imaging Component supports the file.

### Settings or render stutters

- Remove unconditional `storage.set` calls from `render()`.
- Cache or limit desktop queries where possible.
- Avoid loading many shell icons every frame.
