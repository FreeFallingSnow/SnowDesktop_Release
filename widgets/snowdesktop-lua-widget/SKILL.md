---
name: snowdesktop-lua-widget
description: Create, modify, debug, validate, and package SnowDesktop API v2 Lua desktop widget folders with widget.json and main.lua, package resources, localization, storage, drawing, context, and the snowwidget CLI.
---

# SnowDesktop Lua Widget

Create widgets against the sandboxed API v2 contract. A runnable widget is one
validated package directory, never a loose `.lua + .widget.json` pair:

```text
my-widget/
├── widget.json
├── main.lua
├── assets/
├── modules/
└── LICENSE
```

Built-ins live under the executable `widgets` directory. Installed and
development packages live under `data\widgets\installed` and
`data\widgets\dev`. Layouts store the immutable package UUID, not a path.

## Workflow

1. Resolve this Skill directory and run `bin\snowwidget.exe capabilities`.
   Treat the returned JSON as the available CLI contract. If that bundled CLI
   predates API v2, use the repository/runtime v2 contract and refresh the CLI
   before distributing the Skill. Run `bin\snowwidget.exe api-contract` when
   selecting callable host functions instead of inferring availability from
   documentation prose. Only `executableSchemaVersions` and
   `executableApiVersions` can run.
2. Copy `assets/widget-template` as a complete package directory.
3. Generate a new UUID for `id`, choose a lowercase hyphenated `slug`, and keep
   the UUID across all versions and channels.
4. Keep `schemaVersion` and `apiVersion` at `2`. Implement exactly one local
   `render` or `view` function and return it through `widget.define(...)` from
   `main.lua`. Require `view.tree.core` when using the declarative subset.
5. Put every user-visible string behind a literal `l10n.tr("key")`. Add every
   key to every locale catalog in `widget.json`; never put component strings in
   the host `lang/` directory.
6. Probe `layout.relativeUnits` and derive responsive geometry from
   `layout.contentWidth/contentHeight` plus `layout.vw/vh/vmin/vmax`. Use
   `layout.cu/fontCu` for density-stable minimum sizes, strokes, spacing, and
   typography, not as a substitute for total-surface proportions. Keep legacy
   `layout.width/height` only when full-surface immediate drawing is intended.
   Test multiple spans, DPI values and preview mode.
7. Declare package images/fonts in `resources`, create their handles while the
   entry script loads, and pass only handles to v2 draw functions.
8. Load package modules only with `module.require("modules/name.lua")` while the
   entry script is loading.
9. Add only features and permissions used by the component. Basic time,
   context, drawing, localization and package resources require no high-risk
   permission. Run `snowwidget permissions <directory>` to inspect required vs
   optional risk classes, consent, network domains and the API/topic/task
   capabilities associated with each declaration.
10. Use `state` for JSON-like VM-lifetime values and `storage` for persistent
    JSON-like values. Write persistent values only when they change.
11. Run `snowwidget lint <directory>`, `snowwidget test <directory>`, and
    `snowwidget preview <directory> <preview.png>` at the default size. Repeat
    preview with relevant `--columns`, `--rows`, `--dpi`, `--locale`,
    `--appearance`, `--background`, `--data-state`, and `--storage` values,
    then run
    `snowwidget validate <directory>` and
    `snowwidget pack <directory> <name.snowwidget>`.
12. In the repository, also run `scripts\test.bat`, the standard Release build,
    and `scripts\widget-dev.bat <directory>` for transactional hot reload.

Read `references/api-v2.md` completely before implementing API calls, features,
resources or troubleshooting. Use `library/snowdesktop-v2.lua` as the LuaLS
library. The host and authoring tools accept only schema/API v2 packages.

`snowwidget preview` launches the installed SnowDesktop renderer out of process
and writes a real API v2/D2D PNG; it does not emulate the view tree. The PNG is
complete and opaque: it includes the developer-selected background, the
resolved normal/glass/acrylic material, and the component content. Pass
`--background <image-file>` when generating the final package preview. Use
`--appearance dark|light|glass-dark|glass-light|acrylic-dark|acrylic-light`;
legacy `--theme dark|light` remains a shorthand and cannot be combined with
`--appearance`. A CLI copied outside the SnowDesktop directory may need `--host
<SnowDesktop.exe>` or the `SNOWDESKTOP_HOST` environment variable. Use
`--data-state` to exercise ready, empty, loading, error, stale, and
permission-denied subscription envelopes. Generate the final PNG with
`preview` before running `pack`; `pack` only validates and archives the preview
declared by the manifest. It does not package the source background unless the
manifest separately declares that file as a component resource.

## Required entry

```lua
local function render()
    local padding = layout.cu(12)
    draw.text(padding, padding,
        l10n.tr("lua_widget.my_widget.hello"),
        layout.fontCu(15), 0xFFFFFF,
        layout.contentWidth() - padding * 2)
end

return widget.define({
    name = l10n.tr("lua_widget.my_widget.name"),
    render = render,
})
```

Do not define removed globals such as top-level `render`, `onClick`,
`getContextMenu`, `imguiRender`, or `onHttpResponse`. The current host
supports optional `setup(context)` and `dispose(context, model, reason)`;
`setup` runs once and its return value is passed to `render` or `view`, `event`, and
`dispose`. Optional `event(context, model, event)` receives host surface events;
immediate-mode elements use `interaction.region`. The transitional
view parser reads public node names, owning features, allowed properties, and
direct required properties from one enumerable host contract matrix. Treat a
"does not accept field" diagnostic as a node/property mismatch; do not retry
with an ignored compatibility field. Probe `view.identity.diagnostics` before
adding optional `debugName` or `testId` metadata. They appear only in the
copied developer diagnostic scene snapshot and never replace the globally
unique behavioral `key`, alter layout/hit testing, or change UIA AutomationId.
The transitional
`view.tree.core` subset supports box/row/column/grid/flow/stack/text/image/
button/icon/iconButton/shape/progressBar/progressRing/spacer nodes, stable element actions,
package resource handles, hover/pressed styles, and per-element context-menu
bindings. Probe `view.dataSeries` for bounded sparkline/lineChart/barChart/
waveform/spectrum nodes; keep each series within 512 finite samples and the
whole tree within 4096, and always provide `accessibility.label`. The subset
also publishes `view.statusVisuals` for badge/divider/meter; give every meter
an `accessibility.label` and use meter only for a current reading, not task
progress. Probe `view.selectionControls` for controlled toggle/checkbox nodes:
always pass an explicit `checked` value and handle their `change` action by
updating component-owned state; never bind `click` or assume the host persists
the proposed value. Probe `view.checkbox.indeterminate` before using a mixed
checkbox; mixed requires `checked=false`, reports both previous/proposed mixed
state, and activation proposes a checked, determinate state. Probe
`view.state.selected` before applying generic controlled `selected` plus
`selectedStyle`; listItem/slotItem selection is also exposed through host
SelectionItem semantics.
Probe `view.actionControls` for host-rendered link/radioGroup/slider nodes.
Treat radioGroup and slider as controlled: update component-owned state from
`selection` or `controlValue`, then invalidate. Radio options use generated
`<group-key>/<option-key>` targets for independent hover, press, semantics, and
context menus; slider changes are emitted during captured left-button drag.
Probe `view.keyboardNavigation.basic` before relying on host focus outlines,
Tab/Shift+Tab traversal, spatial arrows, Enter/Space activation, or slider
arrow-step changes. Pointer activation still updates semantic focus, but the
host focus outline is reserved for keyboard, access-key, programmatic, text
editing, and accessibility focus; use hover/pressed/selected styles for pointer
feedback. Probe `view.keyboard.accessKey` before assigning a unique
single ASCII letter/digit `accessKey` to a direct focus target. Alt+key focuses
inputs and sliders and activates ordinary action/selection nodes through their
existing controlled action. `acceleratorText` is UI Automation metadata for a
shortcut the component already implements; it never registers a global key.
Probe `view.keyboard.events` only when a focused node must
observe `events.keyDown/keyUp`. These actions receive a symbolic `key`, Windows
`virtualKey`, repeat/modifier state, and a stable key-up pairing; they cannot
cancel host activation or SnowDesktop shortcuts and are not a character/IME
input channel. The host publishes basic UI Automation patterns and state, while deep
virtualization and every platform pattern are not implied by this feature.
Probe `view.pointer.events` before observing declarative `pointerMove` or
`wheel`. Keep pointerMove actions lightweight; a wheel action observes but
cannot cancel host-managed scroll movement.
Probe `view.keyboardNavigation.order` before overriding `focusable` or
`tabIndex`. Use -1 only to keep pointer/UIA focus while skipping sequential
keyboard traversal; positive indices run before 0/source order and retain
declaration order when equal. Do not use custom order to make visual and
semantic reading order disagree.
Probe `view.inputControls` for declarative textInput/textArea/searchBox/
numberInput/select nodes. Treat every value and select expansion as controlled:
write `text`, valid `controlValue`, `selection`, or `expanded` proposals into the
component model, then invalidate. Inputs reuse host keyboard, selection,
clipboard proxy, and IME behavior and may emit focus/blur/submit; they still do
not expose clipboard data or native handles. Select requires both click (toggle
proposal) and change (option proposal), and its bounded popup is clipped by the
widget/parent scroll surface. Do not confuse these nodes with the storage-bound
immediate `control.textInput/textArea` compatibility calls. Probe
`view.input.selection` before declaring `selection = { start, finish }` on a
textInput, textArea, or searchBox. The range is zero-based, half-open, and uses
UTF-8 byte offsets at code-point boundaries; it conflicts with `selectAll` and
requires `events.selectionChange`. Apply the event's proposed `selection` to
component-owned state and invalidate. Text `change` events also include the
resulting selection when this controlled property is present. Probe
`view.input.required` before declaring `required`; it supplies form semantics
to accessibility clients but does not validate values or block component actions.
Probe `view.styledText.basic` for 1-64 bounded text spans with per-span color,
size, bold, italic, underline, and strikethrough. Probe
`view.styledText.actions` before adding a stable span `key`, click `action`,
pointer/key `events`, element `contextMenu`, tooltip, accessibility label, or
hover/pressed colors. The host uses exact wrapped-line fragments for hit
testing and targets the span as `<styledText-key>/<span-key>`; persistent state
changes still belong in the descriptor event callback. Probe
`view.styledText.inlineIcons` to replace a span's `text` with one host icon-font
`glyph` plus optional `iconFont="fa"|"fluent"`; keyed icon spans require an
accessibility label and cannot request bold or italic. Probe `view.monthCalendar` for a
host-rendered six-week Gregorian grid: provide seven localized weekday labels
in Sunday-first order, keep `selectedDate` controlled, and apply the proposed
ISO date from the action event's `selection` field. Date cells have stable
`<calendar-key>/<YYYY-MM-DD>` targets and independent hover/context menus.
Probe `slots.model` and `view.logicalSlots` before using manifest-declared
logical bindings or collections. Open them with `slots.binding(id)` or
`slots.collection(id)`, render the exact host snapshot with
`view.slotSurface/slotItem`, and only call bind/add/clear/remove/move from the
current trusted action event. These methods persist references; they do not
grant file contents, expose paths, or move source objects. Probe
`settings.appReference` for a host settings field whose `binding` names one
replaceable manifest binding accepting `app.reference`. The selector writes directly to
the host-owned slot, never to ordinary storage; replacement and clearing join
slot history, and the component reads the result with `slots.binding(id):item()`.
The host can mark a persisted item unavailable after app-catalog changes, and
an unavailable reference cannot be launched. Probe
`settings.desktopItemReference`, `settings.fileReference`, or
`settings.folderReference` for the equivalent host picker bound to
`desktop.item` or `filesystem.reference`. File and folder fields filter both
visible results and committed candidates by type, write only the selected
opaque slot item, and grant neither enumeration nor file-content access. Probe
`settings.url`, `settings.date`, and `settings.time` before declaring validated
HTTP(S), ISO-date, or 24-hour-time text fields. Probe `settings.range` for a
finite min/max/positive-step numeric slider and `settings.multiSelect` for a
1-64 option host checklist. Range values are Lua numbers and multi-select
values are string arrays in defaults, presets, and typed storage; do not encode
either as delimiter-separated text. Probe
`settings.groups` before organizing fields under stable group IDs; group and
field descriptions must be localized package text, not host-language keys.
Use non-collapsible groups for short sections and collapsible groups only when
the hidden controls remain discoverable. Probe `settings.description` before
adding bounded supporting text below a field. Probe `settings.validation`
before declaring `required`, `minLength`, `maxLength`, and a localized
`validationMessage`. Probe `settings.dependencies` for `dependsOn` or
`enabledWhen`, and `settings.showWhen` for conditional visibility. Conditions
may reference only another declared field, may not form cycles, and preserve
the controlled field's value while hidden or disabled. Use `contains` only for
multiSelect fields and presence/truthiness tests for host-managed references. Probe
`settings.fileHandle` or `settings.folderHandle` when a persistent settings
field must own one user-selected filesystem capability. Declare read, write,
or readWrite access and optional safe file extensions; read the opaque handle
with storage.get, never persist a path, default, or preset. These handles are
independently revocable host-managed values, so Lua must not call
filesystem.release on them; filesystem tasks still require the matching
userSelected permission. Probe
`view.referenceIcon` to render a bound/search result's opaque reference as a
host-resolved icon without requiring a package image or exposing its target;
this visual node does not grant launch, open, reveal, or file-content access.
Probe
`slots.nativeDrop` when a committed slotSurface should accept one native
desktop/Application/Explorer object with host insertion preview. Probe
`view.logicalSlots.dropStyle` before styling that accepted target: background
and border remain clipped to the slotSurface, foreground colors the host-owned
insertion indicator, and the style never changes manifest acceptance policy.
Probe `view.logicalSlots.emptyContent` before supplying one bounded fallback
node for a host snapshot with no binding or collection items; never fabricate
an empty scene while the host model still contains references.
Probe
`slots.pointerReorder` when collection slotItem nodes should support direct
same-surface dragging; the host owns the drag threshold, insertion indicator,
atomic move, undo record, and `slot.changed` event. Probe
`slots.keyboardNavigation` for host focus outlines, Tab/Shift+Tab cycling,
spatial arrow navigation, Enter/Space activation of the slotItem's own click,
Alt+arrow same-slot reorder, Escape, and policy-aware Delete. These keys are
handled by the host and do not expose raw key streams to Lua. Probe
`slots.nativeContextMenu` for host-owned per-item move/remove menus, and handle
`slot.changed` only after probing `slots.event.changed`; re-read the slot model
instead of trusting event data as writable state. Probe `slots.hostPicker` and
call a binding/collection handle's `pick()` only from the current trusted action
to open the manifest-filtered host picker; cancellation does not mutate the slot
or grant file-content access. Multi-object native ingress and native item
drag-out are not available yet. A
source reference used by Lua mutation must still come from a bounded host
search or explicit file-reference task.
Probe `slots.history` to expose explicit component actions for the bounded
per-instance undo/redo history. Call undo/redo only from the current trusted
action and use canUndo/canRedo while rendering; history is not restored after
reload or restart. Probe `slots.hostHistory` when documenting that a selected
widget also receives host Ctrl+Z, Ctrl+Shift+Z, and Ctrl+Y for this history.
Probe `view.scroll` for a host-owned vertical or horizontal viewport. Give it
exactly one child, keep that child visible, and keep the same key so the host
retains its clamped offset; never offset descendants yourself. Probe
`view.scroll.events` before declaring `events.scrollEnd`; it fires once when a
host wheel or accessibility scroll moves from before the end to the maximum
offset, and accessibility never gains trusted-gesture status. Probe
`view.collection.basic` for
non-virtual `list/gridList/listItem`: collection children must be listItem,
each item needs exactly one visible child, a globally stable key, and
`accessibility.label`.
Keep a tree within 256 list items and use per-item actions/context menus. With
`view.keyboardNavigation.basic`, actionable materialized items join host
keyboard traversal. Probe `view.collection.selection` when the container owns
controlled single/multiple selection: declare the container's `selectedKeys`
and `events.change`, consume `previousSelectedKeys/selectedKeys`, and do not put
click/change on its listItem children (use doubleClick, a nested button, or the
item context menu for activation). Selection state, keyboard input, and UI
Automation collection patterns share that controlled source. Probe
`view.collection.contentStates` for one-node `emptyContent`/`loadingContent`
fallbacks and `view.state.busy` for the controlled busy flag. Loading content
replaces items only while busy, empty content activates only for a truly empty
collection, and neither state creates an implicit timer or localized label.
Probe `view.collection.orientation` before setting an eager `list` to horizontal;
vertical remains the default. Probe `view.collection.virtual.orientation` for
a horizontal `virtualList`; pass the same horizontal orientation, content
viewport width, main-axis size, and column gap to `view.virtualRange`.
Estimated widths additionally require `view.collection.virtual.variableExtent`.
Horizontal section headers and virtualGrid remain rejected.
For larger data, probe
`view.collection.virtual`, call `view.virtualRange` with the stable collection
key and actual main-axis content-viewport extent, create only its inclusive 1-based
window, then submit `virtualList` or `virtualGrid` with matching fixed extent,
row gap, columns, overscan, firstIndex, and contiguous listItem children. Keep
the materialized window within 128 items. Probe
`view.collection.virtual.variableExtent` to replace fixed itemExtent with a
virtualList estimate plus layoutRevision; the host measures committed heights
or widths according to orientation.
Probe `view.collection.virtual.stickyHeaders` to pass one sorted global section
index array to both calls, use the returned stickyHeaderIndex, and prepend that
one item only when it falls before firstIndex. Probe
`view.scroll.programmatic` for scrollTo/scrollBy/scrollToIndex. Do not emulate
horizontal virtualGrid or variable-height virtualGrid.
Probe `view.grid.uniform` before using `view.grid`; it is a bounded row-major
equal-column layout with 1–64 columns and optional `columnGap`/`rowGap`. Probe
`view.grid.placement` before setting `gridColumn`, `gridRow`, `columnSpan`, or
`rowSpan` on direct grid/gridList children. Coordinates are 1-based, spans are
limited to 64 tracks, and the host rejects overlap or out-of-bounds placement.
Probe `view.grid.tracks` before replacing integer `columns` or adding `rows`
with bounded fixed/auto/fr/minmax track definitions. `virtualGrid` intentionally
keeps integer equal-width columns and rejects explicit row tracks so its fixed
virtual range remains deterministic.
Probe `view.layout.overflow` before using `overflow="clip"` on a container;
the host applies the same content rectangle to descendant paint, pointer hit,
inputs, and semantic visibility. `clip=true` remains compatibility syntax and
must not contradict overflow. Probe `view.shadow` for bounded frame shadows and
`view.image.tint` for alpha-preserving RGB tint on package image nodes.
Probe `view.theme.tokens` before replacing declarative RGB values with the
host semantic colors `widgetBackground`, `surface`, `surfaceVariant`,
`textPrimary`, `textSecondary`, `textDisabled`, `border`, `borderStrong`,
`systemAccent`, `accentText`, `info`, `success`, `warning`, or `error`.
They work in all state styles, styled-text span colors, shadow color, and image
tint. The host resolves them after state overlay and before transitions and
uses Windows system colors in high contrast. They do not apply to immediate
drawing commands.
Probe `view.transform.basic` before declaring a node `transform` with bounded
`translateX`, `translateY`, positive uniform `scale`, or normalized
`originX`/`originY`. Transforms are post-layout, inherit through descendants,
and move drawing, hit targets, host inputs, clips, and accessibility bounds
together. Probe `view.transform.affine` before adding positive `scaleX`/
`scaleY` multipliers, bounded degree `rotate`, or bounded `skewX`/`skewY`;
affine hit targets and slider
axes remain exact, while host-managed inputs, scroll viewports, logical slots,
and clipping nodes intentionally require a positive axis-aligned matrix. Probe
`view.transition.visual` separately before declaring `transition`. It accepts
1–4 unique `background`/`foreground`/`borderColor`/`opacity` properties, a
1–2000 ms duration, and linear/easeIn/easeOut/easeInOut easing. The host
interpolates committed styles without rerunning `view()` on every animation
frame and snaps to the final style for preview, unavailable timing, or reduced
motion. Color appearance/disappearance, layout, transform, enter, and exit
changes still snap; do not emulate them with an unconditional Lua frame loop.
Probe `view.state.visibility` before using `visibility`. `hidden` keeps layout
space but removes the whole subtree from paint, hit testing, host inputs, and
UI Automation; `collapsed` also removes its layout space. Legacy `visible=false`
means collapsed. Do not use `opacity=0` to hide an interactive node.
Probe `view.flow.wrap` before using `view.flow`; it wraps fixed/auto-width
children horizontally, skips hidden children, and supports per-line
`columnGap`/`rowGap`, but it is not a scrolling or virtualized collection.
Probe `view.flex.sizing` before using `flexBasis` or `flexShrink` on children
of row, column, or list. A numeric/auto basis participates before free-space
distribution; grow handles positive space and shrink handles overflow while
respecting min sizes. `flexShrink=0` preserves an item's basis, and `fill`
keeps an implicit grow factor of 1 when `flexGrow` is omitted.
Probe `view.flex.layout` before setting `flexDirection`, `flexWrap`, or
`alignContent` on row/column. Direction also accepts rowReverse/columnReverse,
wrap accepts noWrap/wrap/wrapReverse, and wrapped lines distribute independently
with bounded grow and shrink. justifyContent and alignContent support
spaceBetween/spaceAround/spaceEvenly; reverse changes layout placement without
changing declaration, paint, hit-test, keyboard, or semantic order.
Probe `view.text.flow` before using `textWrap`, `maxLines`, `overflowText`, or
`verticalAlign` on text and label-bearing nodes. Plain text and labels default
to `noWrap` plus `ellipsis`; `styledText` defaults to `wrap` plus `clip`.
`maxLines=0` is unlimited and the bounded maximum is 64. Use explicit heights
or parent constraints when vertical alignment or multi-line clipping matters.
Probe `view.text.typography` before using `fontWeight`, `fontStyle`,
`lineHeight`, or `letterSpacing`. Weight uses 100-step values from 100 through
900 and overrides the compatibility `bold` flag; style is normal/italic,
lineHeight is 1..1024, and letterSpacing is -64..256 logical units. These
properties apply to plain/styled text and label-bearing declarative nodes, not
to host text editors in this feature.
Probe `view.tooltip` before using a plain-string `tooltip` on any declarative
node. Probe `view.tooltip.rich` for `{ title?, text }`; title/body are bounded
to 256/4096 UTF-8 bytes and remain host-rendered text, not markup. The host
creates a clipped hover region even for non-actionable text, draws the tooltip
above view/select/input overlays, and exposes it as semantic help text when no
validation message is present. Do not put secrets, commands, or essential
always-visible instructions in tooltips.
Probe `view.layout.constraints` before using numeric `minWidth`, `maxWidth`,
`minHeight`, `maxHeight`, `aspectRatio`, or `margin`. Keep sizes and uniform
outer margins within 0 through 4096, ratios within 0.01 through 100, and do
not declare mutually incompatible constraints or mismatched fixed width and
height. Margin is reserved outside the node frame by linear, grid, flow,
stack, scroll, and virtual layouts; use parent `gap` for spacing that should
exist only between siblings.
Probe `view.keyboardNavigation.basic` for ordinary actionable declarative
nodes and storage-bound immediate text controls. The subset does not provide
arbitrary shortcut interception, variable-height virtualization, or the
complete `view.tree` contract. Optional
`menu(context, model, request)` builds an element's synchronous native context
menu.
Use `readOnly=true` on text-like or numeric declarative inputs that should
remain focusable, selectable, and copyable without accepting any mutation.
A read-only input does not need a change action; do not emulate it with
`enabled=false`.
Use `validationState` and `validationMessage` on declarative inputs/selects
for bounded validation feedback. The host renders a default state-colored
border and exposes the message as semantic help text. If the message must
always be visible, also render it in a sibling text node; never communicate an
error by color alone. Customize the state with `validationStyle` only when the
default border does not fit the component design.

## Manifest rules

- `schemaVersion: 2` and `apiVersion: 2` must match.
- `id` is an immutable UUID; `version` is SemVer; `dataVersion` is positive.
- `name` and `description` are English fallbacks; localized values use
  `nameKey`, `descriptionKey`, and manifest `locales`.
- `requiredFeatures` must be supported for activation. Put degradable feature
  IDs in `optionalFeatures` and probe them before use.
- Use `resources` for package images and fonts. Keep resource names stable;
  use package-relative files and include font license metadata.
- Keep `permissions` empty unless a currently documented guarded v2 call needs
  one. Reserved permission vocabulary does not make an API available.
- Keep size dimensions from 1 through 8; a max dimension of `0` means
  unrestricted where the manifest schema permits it.
- Never include DLLs, executables, absolute paths, parent traversal, symlinks,
  junctions, reparse points or files outside the package.

## Implementation rules

- Treat `render` and `view` as hot paths. Do not write storage, create resource
  handles, load modules, or perform future data queries during every frame.
- `state.set` deep-copies JSON-like data and requests another frame only when
  the value changes. Do not use it as persistent storage.
- Group related persistent JSON-like writes with `storage.transaction`; access
  storage only through its `tx` argument until the callback returns. A callback
  error or final quota failure rolls back the complete change. Never write
  persistent storage from `render`.
- `storage.typed` preserves booleans, finite numbers, strings, arrays, objects,
  and null while keeping legacy unmarked values as strings. Use
  `storage.keys()` when stored null must be distinguished from a missing key.
- `storage.writeBudget` permits a burst of 32 changed persistent commits per
  instance and refills one commit per second. A transaction counts once; an
  unchanged write, preview, or migration overlay does not consume the budget.
- Use `schedule.every/after/at/cancel` for v2 timers and handle
  `event.kind == "schedule"`; API v2 does not expose `widget.setTimer` or
  `widget.cancelTimer`.
- Use `schedule.timeline` for 1–64 strictly increasing absolute state entries.
  Elapsed entries coalesce to the newest due value; inspect `timelineIndex`,
  `timelineCount`, `timelineEnded`, and `missed`. With `reload = "atEnd"`,
  publish the next timeline when the final event reports `reload = true`.
- Set `whenHidden` deliberately: prefer `pause` for purely visual clocks and
  animation, `throttle` for low-frequency freshness, and `continue` only when
  deadlines must remain active while the component is hidden.
- Use `animation.requestFrame(id)` only for short, visible immediate-mode
  animation loops. Handle `event.kind == "frame"` and request the ID again only
  while the loop should continue; hidden, preview, and reduced-motion contexts
  reject or cancel frame work. Use `animation.cancelFrame(id)` to stop an
  already pending request.
- For continuously scrolling single-line overflow text on the desktop render
  surface, declare and use `draw.marqueeText` instead of advancing offsets with
  `animation.requestFrame` or `schedule.every`. Give each visible text a stable
  key. The host caches the remaining immediate drawing, pauses while hidden,
  honors reduced motion, and advances local repaint frames without re-entering
  Lua. Treat the marquee as a native overlay above that render's cached drawing.
- Preview time is deterministic (`time.previewClock`): do not expect preview
  schedules to advance or wait for real deadlines. Use manifest preview data
  to present the intended state.
- Create `data.subscribe` handles once in `setup` or module scope, read their
  immutable envelopes during render, and declare `system.performance.read`
  `system.power.read`, or `system.network.read` as optional when system data
  can degrade gracefully.
- For local calendars, subscribe to `calendar.events` and
  `calendar.selectedDate` under `calendar.read`; use permission-free
  `calendar.dateInfo/addDays/selectDate` for date math and SnowDesktop's shared
  selection. Rebuild range subscriptions from `event.kind == "data.change"`,
  and do not request `calendar.write` unless event records are mutated.
- Mutate local calendar records through
  `task.start("calendar.create"|"calendar.update"|"calendar.remove", args)`
  and match `task.complete`. Preserve event `id/revision`, handle `conflict`,
  and start remove only from a direct trusted action or menu command.
- Fetch public HTTPS data with `task.start("network.request", args)` and declare
  `network.internet`. Leave `networkDomains` absent when a user setting may
  point at arbitrary public HTTPS hosts; add exact hostnames only when the
  package intentionally narrows its own network scope. Keep requests as
  bounded requests, match the returned task ID, handle stable failure codes,
  and use only a declared `password` setting's opaque reference in a host
  secret descriptor for credentials; never place credential plaintext in Lua,
  ordinary storage, request arguments, logs, or package defaults. Keep public
  GET responses cacheable only when they contain no secret, cancel outstanding
  work in `dispose`; never restore v1 `http` in an API v2
  widget.
- Open an article or other external public HTTPS URL only with
  `task.start("shell.openUri", { url = value })` from a direct trusted action
  or menu command. Declare `shell.launch` as optional when opening links is not
  the widget's core function, and do not accept file, command, or custom-scheme
  targets.
- Start `media.play/pause/toggle/stop/next/previous/seek/setRate/setShuffle/setRepeat`
  with `task.start` only inside a direct trusted gesture callback. Pass the
  opaque `sessionId` from `media.sessions/current` when the widget displays or
  controls a specific session; omit it to target the current Windows session.
  Match the returned ID in `event.kind == "task.complete"`. Never loop media
  actions from the completion event; it intentionally has no trusted-gesture
  activation.
- Read the current session cover through `media.artwork`. Pass its temporary
  `image` handle directly to `draw.image` or `view.image.source`; never expect
  encoded bytes or a cache path, never persist the handle after unsubscribing,
  and treat `notPresent` as a normal no-cover state.
- Use `process.summary` only for a visible, bounded system monitor after
  declaring `process.summary.read`. Treat `id` as opaque and ephemeral, and
  render only the returned display name and aggregate CPU/memory counters;
  never infer a PID, path, command line, window title, user, token, or process
  control capability from the summary.
- Change only the current default audio endpoint with
  `audio.output.setVolume` or `audio.output.setMute` from a direct trusted
  gesture. Declare `audio.output.control`, treat `rateLimited` as a normal
  rejection, and never emulate per-process or non-default-device control.
- Open Windows Settings only with `system.openSettings` and one documented
  page name. Declare `shell.launch`, start it from a direct trusted gesture,
  and never accept or construct a raw `ms-settings:` URI in widget code.
- Read clipboard `text`, `image`, or `file-reference` only through
  `clipboard.read` from a direct trusted gesture. Probe
  `task.clipboard.image` or `task.clipboard.fileReference` before using the
  latter formats. Treat returned image handles and item refs as temporary and
  instance-scoped; never infer a path or file-content grant from a file ref.
  Clipboard write and clear remain text-only through
  `clipboard.write/clear`; declare `clipboard.read` separately from
  `clipboard.write`, keep text within 256 KiB, and do not claim clipboard
  history access.
- Ask the user to grant a concrete file or folder only through
  `filesystem.pickOpen/pickSave/pickFolder` in a direct trusted gesture.
  Declare `filesystem.userSelected.read` and/or `.write` for the requested
  access, retain or persist only the returned opaque handle token, and show
  its display-only name. Probe `task.filesystem.access` before using bounded
  `filesystem.stat/list/read/write/release` tasks, and probe
  `task.filesystem.binary` before selecting `encoding = "binary"`. Preserve revisions and pass
  `expectedRevision` when updating content. Never parse, log, or replace a
  handle with a filesystem path. For direct-child change notifications,
  declare `filesystem.userSelected.watch`, probe `data.filesystem.watch`, and
  subscribe with the selected folder handle. Treat `overflow=true` as a signal
  to run a fresh bounded `filesystem.list`; watching pauses while hidden and
  never recurses or follows reparse points.
- Search applications with the bounded `task.start("app.search", { query,
  limit, offset })` task and retain only its opaque `ref` values. Render one
  declaratively with `view.referenceIcon` after probing that feature. Launch one
  with `task.start("app.launch", { ref = item.ref })` inside the direct click
  action. Never persist or invent refs, and never substitute a path, command
  line, or working directory.
- Search SnowDesktop items or the local Everything index with bounded
  `desktop.search` / `everything.search` tasks. Render their opaque refs with
  `draw.icon`, and use `shell.openItem` / `shell.revealItem` only inside a
  direct trusted action. `desktop.refresh` is also gesture-gated. Never expose,
  persist, parse, or replace these refs with filesystem paths.
- Post optional notifications with `notification.show`, keep the host-issued
  `task.complete.value.notificationId`, and use `notification.update` /
  `notification.dismiss` for delivered IDs or `notification.schedule` /
  `notification.cancel` for future delivery. Scheduled delivery reports
  `notification.delivered`, survives an app restart while the same instance
  and package remain authorized, and must not be recreated in a polling loop.
  Structured notifications may use one package `resource.image`, progress from
  0 through 1, and at most two uniquely identified action buttons. Handle
  `notification.action` by its `notificationId` and `actionId`; the callback is
  a trusted gesture, but is safely dropped if the owning VM no longer exists.
  Use `false` in `notification.update` to clear image or progress, and an empty
  actions array to clear buttons. Runtime image handles are not accepted.
  Declare `notification.post` as optional when the widget can
  keep working without it, and never fall back to the removed `system.notify`.
- Create `resource.image/font` handles synchronously at entry scope. Handle
  stable `resource.image: code` / `resource.font: code` load failures; use
  `resource.status` for later ready/error diagnostics and do not poll it for a
  pending state.
- Use `draw.measureText`, clipping, explicit `maxWidth`, and separate opacity.
- Probe `draw.advanced` before using `draw.arc/path/gradientRect/imageFit/shadow/
  sparkline`. Keep paths within 256 strict commands and sparklines within 512
  finite values. Pass only image handles to `imageFit`; its fit, alignment, and
  interpolation are host-controlled. Shadow blur stops at 64 and uses at most
  16 bounded falloff layers, so do not describe it as an arbitrary shader or
  unbounded Gaussian effect.
- Submit every immediate-mode hit target with a stable `interaction.region`
  key during render. Read `interaction.isHovered/isPressed` for visuals and
  handle serialized region actions in `event`; never synthesize click from raw
  down/up callbacks. Build an element menu only through `widget.define.menu`
  and `ui.menu`, keeping the callback synchronous and I/O-free.
  Probe `interaction.pointerCapture` before setting `capturePointer=true` on a
  view node or immediate region. Bind `pointerMove` or `pointerUp`, and treat
  capture as a host-cancelable primary-pointer drag lifecycle rather than
  global input access.
  Probe `interaction.contextMenu.submenu` before adding non-actionable menu
  parents with `children`; keep the whole tree within 64 descriptors and three
  submenu levels, with globally unique action IDs on leaves.
  Probe `interaction.contextMenu.resourceImage` before putting a declared
  package `resource.image(...)` handle in a menu item's `image` field. Do not
  combine it with the host-glyph `icon` field or pass runtime image handles.
  Probe `interaction.tooltip` before adding bounded string tooltips and
  `interaction.tooltip.rich` before using `{ title?, text }`. Probe
  `interaction.keyboard` before setting `focusable/tabIndex` or observing
  `keyDown/keyUp`; use `interaction.isFocused(key)` to draw the focus state.
  Key observers cannot cancel host activation or text input.
  Only regions with declared accessibility metadata enter the host semantic
  snapshot. Supply role and label for meaningful elements. Probe
  `interaction.accessibility.metadata` before adding value, hint, headingLevel,
  live, positionInSet/setSize, or hidden. hidden is rejected on interactive or
  focusable regions. Probe `view.accessibility.metadata` for the same semantic
  values on declarative nodes, plus labelledBy/describedBy relationships,
  one-based grid row/column indices, and non-interactive hidden subtrees. The Windows
  UIA provider exposes the current tree, properties, navigation, hit testing,
  host focus, and Invoke/Toggle/RangeValue/Value/ExpandCollapse/Selection/
  SelectionItem/Scroll/Grid/GridItem patterns. Accessibility actions are
  untrusted (`source="accessibility"`) and
  never grant permission authority. Successful desktop frames also emit
  structure, focus, bounds, name, role, help/value metadata, live-region,
  set-position, enabled, offscreen, toggle, value, expand/collapse, and scroll
  UIA changes. Declarative radio options, expanded select
  options, and month-calendar dates are individual SelectionItem children;
  their parent exposes Selection. Scroll containers expose their current host
  offset through Scroll, while grids and materialized cells expose zero-based
  Grid/GridItem coordinates. ScrollItem, unrealized virtual collection items,
  and real Narrator validation remain pending, so do not claim complete
  screen-reader support.
- Register immediate-mode overflow with `interaction.scroll`, translate content
  along the returned main-axis offset, and pair the viewport with
  `draw.pushClip/popClip`. Vertical is the default; probe
  `interaction.scroll.orientation` before using horizontal `contentWidth`.
  Do not use the v1 `ui.scrollArea` compatibility API.
- Submit storage-bound text editors with `control.textInput/textArea` during
  render. Keep keys stable, set an explicit practical `maxBytes`, and call
  `control.focus` or `control.blur` only inside a direct trusted action or menu
  callback. `control.blur` commits only the matching focused text control and
  leaves other focus unchanged. After
  probing `view.focus.request`, the same call may target any enabled focusable
  declarative node, including list/slot items; a newly rendered target resolves
  only after the next successful tree submission. Ordinary
  editing does not require `ui.input`; Lua never receives clipboard contents.
- Put an auxiliary editor in the optional `widget.define.panel` callback and
  open it with `widget.openPanel`. After probing `view.surface.panel`, the
  callback may return the same declarative nodes used by `view`; nil keeps the
  immediate drawing path. The panel owns a separate scene, hit set, scroll
  offsets, host controls, and focus state, and its actions identify
  `surface="panel"`. Persistent writes still belong in events rather than the
  panel callback. Panel UI Automation export and host logical-slot behavior
  remain pending, so do not claim those capabilities.
- Put confirmation, focused editing, or short modal workflows in the optional
  `widget.define.dialog` callback and open them with `widget.openDialog` after
  probing `view.surface.dialog`. The host centers the surface, draws a scrim,
  blocks background desktop input without entering a blocking modal loop, and
  keeps focus on the dialog. Outside-click dismissal defaults to false and
  Escape dismissal defaults to true; set either option explicitly when the
  workflow requires different behavior. Close it with `widget.closeDialog`.
  Only one panel, dialog, or popover can be active for the host at a time.
- Put a lightweight element-attached surface in `widget.define.popover` and
  open it only from a trusted desktop action with
  `widget.openPopover({ anchorKey = stableElementKey, ... })` after probing
  `view.surface.popover`. The anchor must exist and be enabled in the last
  successful desktop scene; Lua never supplies screen coordinates. Use
  `placement` for auto/top/bottom/left/right or start/end variants. Omitting
  the title selects compact chrome. Popovers default to outside-click and
  Escape dismissal and share the single auxiliary-surface slot with panels
  and dialogs; nesting them is not supported.
- Keep colors in `0xRRGGBB`.
- Respect `widget.context().accessibility`, theme, DPI, visibility and preview
  state. Do not request permission for an ordinary pointer clock or static UI.
- Treat the bottom host bar as reserved movement/resize space.
- Use `widget.log("debug"|"info"|"warn"|"error", message)` for recoverable
  diagnostics.
- Never use `io`, `os`, `require`, `package`, `load`, arbitrary filesystem or
  process APIs; the sandbox does not expose them.
- Do not invent v2 APIs from old v1 documentation. The synchronous `media`
  library remains v1-only; v2 media reads use `data.subscribe` and the three
  implemented controls use `task`. API v2 intentionally omits the synchronous
  `desktop`, `everything`, `http`, `sys`, and legacy `ui` libraries; their
  implemented replacements are scoped data subscriptions and bounded tasks.
  `ui.menu` is the only current v2 `ui` entry and is valid only as the result
  of the descriptor menu callback.

## Verification

For every package change:

1. Validate the directory with `snowwidget validate` and resolve every error.
2. Pack it with `snowwidget pack`, then validate the resulting `.snowwidget`.
3. Run the repository localization and contract tests.
4. Preview compact and expanded spans; check text clipping, theme, DPI and
   resource rendering.
5. Activate the development candidate and verify hot reload. A failed reload
   must keep the last-known-good VM.

Do not claim pointer interaction, context-menu interaction, declarative element events, resource visuals,
multi-monitor DPI or permission UX is verified from validation/build alone;
those require an observable desktop run.
