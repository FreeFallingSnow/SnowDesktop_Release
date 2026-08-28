---@meta SnowDesktop API v2

---@alias SnowWidgetSizeClass 'small'|'medium'|'large'
---@alias SnowWidgetSurfaceKind 'desktop'|'panel'|'dialog'|'popover'|'preview'
---@alias SnowResourceState 'ready'|'error'
---@alias SnowResourceLoadError 'loadPhaseRequired'|'invalidName'|'notDeclared'|'typeMismatch'|'hostUnavailable'|'unavailable'|'quotaExceeded'|'decodeFailed'|'deviceUnavailable'|'fontLoadFailed'|'invalidHandle'
---@alias SnowDateStyle 'none'|'short'|'long'
---@alias SnowTimeStyle 'none'|'short'|'long'
---@alias SnowDurationStyle 'short'|'clock'
---@alias SnowStateValue nil|boolean|number|string|SnowStateValue[]|table<string, SnowStateValue>

---@class SnowSize
---@field width number
---@field height number

---@class SnowRect: SnowSize
---@field left number
---@field top number
---@field right number
---@field bottom number

---@class SnowDpiContext
---@field x integer
---@field y integer
---@field scaleX number
---@field scaleY number

---@class SnowGridContext
---@field columns integer
---@field rows integer

---@class SnowMonitorContext
---@field available boolean
---@field primary boolean
---@field pixelBounds SnowRect
---@field pixelWorkArea SnowRect
---@field logicalBounds SnowRect
---@field logicalWorkArea SnowRect

---@class SnowThemeContext
---@field mode 'dark'|'light'
---@field background integer RGB color
---@field border integer RGB color
---@field accentToken 'systemAccent'
---@field accentColor integer RGB color
---@field highContrast boolean

---@class SnowAccessibilityContext
---@field highContrast boolean
---@field reducedMotion boolean
---@field textScale number

---@class SnowWidgetContext
---@field logicalSize SnowSize
---@field pixelSize SnowSize
---@field layoutSize SnowSize Root content size in the same coordinate space as declarative view lengths and layout relative units.
---@field dpi SnowDpiContext
---@field sizeClass SnowWidgetSizeClass
---@field grid SnowGridContext
---@field monitor SnowMonitorContext
---@field theme SnowThemeContext
---@field accessibility SnowAccessibilityContext
---@field locale string BCP-47 locale
---@field region string ISO 3166 region when available
---@field timeZone string Windows time-zone key
---@field utcOffsetMinutes integer
---@field inputLanguage string BCP-47 input language when available
---@field visible boolean
---@field preview boolean
---@field focused boolean Whether any host-managed input or declarative element on this surface owns focus.
---@field selected boolean
---@field surface SnowWidgetSurfaceKind

---@class SnowWidgetInfo
---@field id string
---@field width number
---@field height number
---@field selected boolean
---@field selectedPackageId string

---@class SnowWidgetTheme
---@field bg integer
---@field border integer
---@field alpha number
---@field borderAlpha number
---@field gradientEndA number
---@field cornerRadius number
---@field contentTheme integer

---@class SnowSettingCondition
---@field key string Stable key of another declared setting field.
---@field operator 'equals'|'notEquals'|'oneOf'|'notOneOf'|'contains'|'notContains'|'set'|'unset'|'truthy'|'falsy'
---@field value? string|number|boolean|(string|number|boolean)[] Required by comparison operators and omitted by set/unset/truthy/falsy.

---@class SnowSettingField
---@field key string
---@field label string
---@field description? string Localized supporting text rendered below the field; up to 2048 UTF-8 bytes.
---@field group? string ID of one declared SnowSettingGroup.
---@field validationMessage? string Localized error text required when required/minLength/maxLength is declared.
---@field required? boolean Require a non-empty value; for bool this requires true and for host-managed references this requires a selected value.
---@field minLength? integer Minimum Unicode code-point count for text/url/date/time.
---@field maxLength? integer Maximum Unicode code-point count for text/url/date/time; up to 2048.
---@field dependsOn? string Shorthand for enabledWhen={key=dependsOn,operator='truthy'}.
---@field showWhen? SnowSettingCondition Hide the field while the condition is false without clearing its value.
---@field enabledWhen? SnowSettingCondition Disable the field while the condition is false without clearing its value.
---@field type 'text'|'password'|'bool'|'int'|'float'|'select'|'color'|'url'|'date'|'time'|'range'|'multiSelect'|'fileHandle'|'folderHandle'|'appReference'|'desktopItemReference'|'fileReference'|'folderReference'|'appSearch'
---@field default? string|number|boolean|string[] multiSelect defaults are stable option arrays; range defaults are exposed to Lua as numbers. Ignored for password, filesystem-handle, and entity reference fields.
---@field searchKey? string Required by appSearch; stores the user's query separately from the selected display title.
---@field binding? string Required by appReference, desktopItemReference, fileReference, and folderReference; names one uniquely used replacePolicy='allow' manifest binding accepting only the matching reference kind.
---@field access? 'read'|'write'|'readWrite' fileHandle/folderHandle capability; defaults to read.
---@field emptyLabel? string Localized empty-state label used by appSearch, filesystem-handle, and entity reference fields.
---@field noResultsLabel? string Localized label shown after an application search returns no results.
---@field min? number
---@field max? number
---@field step? number Positive range increment; defaults to 1.
---@field options? string[] Stable select or multiSelect values; multiSelect accepts 1-64 unique values.
---@field optionLabels? string[] Localized labels parallel to stable select or multiSelect option values.
---@field extensions? string[] Up to 16 safe file extensions for fileHandle; leading dots are optional. Not accepted by folderHandle.

---@class SnowSettingGroup
---@field id string Stable ASCII identifier unique across manifest and Lua declarations.
---@field label string Localized section or collapsible-header label.
---@field description? string Localized supporting text rendered before the group's fields.
---@field collapsible? boolean Whether the host renders a collapsible header; defaults to false.
---@field defaultExpanded? boolean Initial open state for a collapsible group; defaults to true.

---@class SnowSettingPreset
---@field id string
---@field label string
---@field default? boolean
---@field values table<string, string|number|boolean|string[]>

---@class SnowWidgetSettings
---@field groups? SnowSettingGroup[]
---@field fields? SnowSettingField[]
---@field presets? SnowSettingPreset[]

---@class SnowInteractionAction
---@field id string Stable action identifier delivered through event.kind == 'action'.
---@field value? SnowStateValue Deep-copied JSON-like payload.
---@field scope? 'element'|'component' Context-menu scope; defaults to element. Component scope is appended to the widget menu; element menus retain a host-provided entry that opens the component panel.

---@alias SnowViewLength number|'auto'|'fill'
---@alias SnowViewFlexBasis number|'auto'
---@alias SnowViewFlexDirection 'row'|'rowReverse'|'column'|'columnReverse'
---@alias SnowViewFlexWrap 'noWrap'|'wrap'|'wrapReverse'
---@alias SnowViewContentAlignment 'start'|'center'|'end'|'stretch'|'spaceBetween'|'spaceAround'|'spaceEvenly'
---@alias SnowViewTextWrap 'noWrap'|'wrap'
---@alias SnowViewTextOverflow 'clip'|'ellipsis'
---@alias SnowViewTextDirection 'auto'|'ltr'|'rtl'
---@alias SnowViewAlignment 'start'|'center'|'end'|'stretch'
---@alias SnowViewSelfAlignment 'auto'|'start'|'center'|'end'|'stretch'
---@alias SnowViewImageFit 'fill'|'contain'|'cover'|'none'
---@alias SnowViewImageAlignment 'start'|'center'|'end'
---@alias SnowViewImageInterpolation 'nearest'|'linear'
---@alias SnowViewOverflow 'visible'|'clip'
---@alias SnowViewVisibility 'visible'|'hidden'|'collapsed'
---@alias SnowViewTransitionEasing 'linear'|'easeIn'|'easeOut'|'easeInOut'
---@alias SnowViewTransitionProperty 'background'|'foreground'|'borderColor'|'opacity'|'transform'|'layout'
---@alias SnowViewThemeColor 'widgetBackground'|'surface'|'surfaceVariant'|'textPrimary'|'textSecondary'|'textDisabled'|'border'|'borderStrong'|'systemAccent'|'accentText'|'info'|'success'|'warning'|'error'
---@alias SnowViewColor integer|SnowViewThemeColor
---@alias SnowViewGridTrack number|'auto'|SnowViewGridFractionTrack|SnowViewGridMinMaxTrack
---@alias SnowViewValidationState 'none'|'info'|'success'|'warning'|'error'
---@alias SnowViewSelectionMode 'none'|'single'|'multiple'
---@alias SnowViewScrollAlignment 'nearest'|'start'|'center'|'end'
---@alias SnowDrawImageFit 'fill'|'contain'|'cover'|'none'
---@alias SnowDrawImageAlignment 'start'|'center'|'end'
---@alias SnowDrawImageInterpolation 'nearest'|'linear'
---@alias SnowDrawGradientDirection 'horizontal'|'vertical'|'diagonalDown'|'diagonalUp'
---@alias SnowDrawPathFillRule 'alternate'|'winding'

---@class SnowViewEdgeInsets
---@field horizontal? number Applied to left and right before explicit side overrides.
---@field vertical? number Applied to top and bottom before explicit side overrides.
---@field top? number
---@field right? number
---@field bottom? number
---@field left? number

---@class SnowViewOffset
---@field x? number Horizontal visual offset from -4096 through 4096.
---@field y? number Vertical visual offset from -4096 through 4096.

---@class SnowViewShadow
---@field color? SnowViewColor RGB or host theme token; defaults to black. Theme tokens require view.theme.tokens.
---@field blur? number Bounded soft-shadow spread from 0 through 64; defaults to 12.
---@field offsetX? number Horizontal offset from -4096 through 4096; defaults to 0.
---@field offsetY? number Vertical offset from -4096 through 4096; defaults to 4.
---@field alpha? number Opacity from 0 through 1; defaults to 0.25.

---@class SnowViewTransform
---@field translateX? number Post-layout horizontal translation from -4096 through 4096; defaults to 0.
---@field translateY? number Post-layout vertical translation from -4096 through 4096; defaults to 0.
---@field scale? number Positive uniform scale from 0.05 through 8; defaults to 1 and nested cumulative scale must remain between 1/64 and 64.
---@field scaleX? number Positive horizontal multiplier; combined with scale it must remain from 0.05 through 8. Requires view.transform.affine.
---@field scaleY? number Positive vertical multiplier; combined with scale it must remain from 0.05 through 8. Requires view.transform.affine.
---@field rotate? number Clockwise rotation in degrees from -360 through 360. Requires view.transform.affine.
---@field skewX? number Horizontal skew angle in degrees from -80 through 80. Requires view.transform.affine.
---@field skewY? number Vertical skew angle in degrees from -80 through 80. Requires view.transform.affine.
---@field originX? number Normalized horizontal transform origin from 0 through 1; defaults to 0.5.
---@field originY? number Normalized vertical transform origin from 0 through 1; defaults to 0.5.

---@class SnowViewTransition
---@field durationMs? integer Host-driven duration from 1 through 2000 milliseconds; defaults to 120.
---@field easing? SnowViewTransitionEasing Defaults to easeOut.
---@field properties SnowViewTransitionProperty[] One to four unique presentation properties; color endpoints must both be explicit. Transform and layout interpolation require their matching view.transition features.

---@class SnowViewPresenceTransition
---@field durationMs? integer Host-driven duration from 1 through 2000 milliseconds; defaults to 120.
---@field easing? SnowViewTransitionEasing Defaults to easeOut.
---@field opacity? number Enter-start or exit-target opacity from 0 through 1.
---@field transform? SnowViewTransform Full enter-start or exit-target transform; omitted fields use normal transform defaults rather than inheriting the node target.

---@class SnowViewGridFractionTrack
---@field fr number Positive fraction weight no greater than 1000.

---@class SnowViewGridMinMaxTrack
---@field min number Fixed minimum from 0 through 100000 logical units.
---@field max number|'auto'|SnowViewGridFractionTrack Fixed cap, intrinsic cap, or fractional maximum.

---@class SnowViewStyle
---@field background? SnowViewColor RGB or host theme token.
---@field foreground? SnowViewColor RGB or host theme token.
---@field borderColor? SnowViewColor RGB or host theme token.
---@field borderWidth? number
---@field cornerRadius? number
---@field opacity? number Between 0 and 1.

---@class SnowViewAccessibility
---@field role? string Optional semantic role override.
---@field label? string
---@field value? string Localized semantic value override without changing the controlled model value.
---@field hint? string Localized operation or validation guidance exposed as UIA HelpText.
---@field labelledBy? string Stable key of another declared node whose accessible text becomes this node's name.
---@field describedBy? string Stable key of another declared node whose accessible text is appended to HelpText.
---@field headingLevel? integer Heading level from 1 through 9; omit or use 0 for none.
---@field live? 'off'|'polite'|'assertive' UIA live-region priority; defaults to off.
---@field positionInSet? integer One-based position from 1 through 32767.
---@field setSize? integer Total set size from 1 through 32767 and no smaller than positionInSet.
---@field rowIndex? integer One-based semantic row for a direct child of grid/gridList/virtualGrid.
---@field columnIndex? integer One-based semantic column for a direct child of grid/gridList/virtualGrid.
---@field hidden? boolean Remove this non-interactive subtree from UI Automation while preserving visual layout.

---@class SnowViewTextSelection
---@field start integer Zero-based inclusive UTF-8 byte offset at a code-point boundary.
---@field finish integer Zero-based exclusive UTF-8 byte offset at a code-point boundary; no smaller than start.

---@class SnowTooltipDescriptor
---@field title? string Optional UTF-8 title up to 256 bytes.
---@field text string Required non-empty UTF-8 body up to 4096 bytes.

---@class SnowViewEvents
---@field pointerEnter? SnowInteractionAction
---@field pointerLeave? SnowInteractionAction
---@field pointerDown? SnowInteractionAction
---@field pointerMove? SnowInteractionAction High-frequency explicit observation; declarative nodes require view.pointer.events.
---@field pointerUp? SnowInteractionAction
---@field click? SnowInteractionAction
---@field doubleClick? SnowInteractionAction
---@field wheel? SnowInteractionAction Declarative nodes require view.pointer.events; host scrolling still proceeds.
---@field contextMenu? SnowInteractionAction
---@field keyDown? SnowInteractionAction Focused-node key press observation; requires view.keyboard.events and cannot cancel host behavior.
---@field keyUp? SnowInteractionAction Paired focused-node key release observation; requires view.keyboard.events.
---@field change? SnowInteractionAction Controlled selection, slider, or input value proposal.
---@field selectionChange? SnowInteractionAction Controlled text selection proposal from pointer or keyboard movement.
---@field focus? SnowInteractionAction Input gained host keyboard/IME focus.
---@field blur? SnowInteractionAction Input lost host keyboard/IME focus.
---@field submit? SnowInteractionAction Single-line Enter or textArea Ctrl+Enter.
---@field scrollEnd? SnowInteractionAction Scroll/virtual collection reached its maximum offset after a host wheel or accessibility scroll.

---@class SnowViewChoiceOption
---@field key string Stable option key; its interaction target is '<group-key>/<option-key>'.
---@field value string Stable non-empty value unique within the group.
---@field label string Non-empty visible and accessible label.
---@field enabled? boolean Defaults to true.

---@class SnowViewTextSpan
---@field key? string Required when the span has actions, events, tooltip, accessibility metadata, or interactive colors; target becomes '<styledText-key>/<span-key>'.
---@field text? string Non-empty bounded UTF-8 text; exactly one of text or glyph is required.
---@field glyph? string Exactly one valid Unicode scalar rendered from the host Font Awesome or Fluent icon font; mutually exclusive with text and requires view.styledText.inlineIcons.
---@field iconFont? 'fa'|'fluent'|'fluent-regular' Host icon font for glyph; defaults to fa and is invalid on text spans.
---@field foreground? SnowViewColor Per-span RGB or host theme token.
---@field hoverForeground? SnowViewColor Color while the exact span fragments are hovered; requires view.styledText.actions.
---@field pressedForeground? SnowViewColor Color while the exact span fragments are pressed; requires view.styledText.actions.
---@field fontSize? number Per-span font size from 1 through 512.
---@field bold? boolean
---@field italic? boolean
---@field underline? boolean
---@field strikethrough? boolean
---@field cursor? 'default'|'hand'|'text'|'crosshair'
---@field tooltip? string|SnowTooltipDescriptor Host-owned tooltip; descriptor form requires view.tooltip.rich.
---@field accessibility? SnowViewAccessibility
---@field events? SnowViewTextSpanEvents Pointer, menu, and focused key actions for this span.
---@field action? SnowInteractionAction Click shorthand.

---@class SnowViewTextSpanEvents
---@field pointerEnter? SnowInteractionAction
---@field pointerLeave? SnowInteractionAction
---@field pointerDown? SnowInteractionAction
---@field pointerMove? SnowInteractionAction
---@field pointerUp? SnowInteractionAction
---@field click? SnowInteractionAction
---@field doubleClick? SnowInteractionAction
---@field wheel? SnowInteractionAction
---@field contextMenu? SnowInteractionAction
---@field keyDown? SnowInteractionAction Focused-span key press observation; requires view.keyboard.events and cannot cancel host behavior.
---@field keyUp? SnowInteractionAction Paired focused-span key release observation; requires view.keyboard.events.

---@class SnowViewVirtualRangeOptions
---@field key string Stable virtual collection key.
---@field itemCount integer Total logical items from 0 through 1000000.
---@field itemExtent? number Fixed logical main-axis item extent; row height for vertical collections and item width for horizontal virtualList. Mutually exclusive with estimatedItemSize.
---@field estimatedItemSize? number Variable virtualList main-axis estimate used instead of itemExtent after probing view.collection.virtual.variableExtent.
---@field layoutRevision? integer Bump when variable-list ordering or height-affecting content changes so stale measurements are discarded.
---@field viewportExtent number Positive logical content-viewport extent after padding: height for vertical and width for horizontal.
---@field columns? integer Grid column count from 1 through 64; defaults to 1.
---@field orientation? 'horizontal'|'vertical' Defaults to vertical. Horizontal requires view.collection.virtual.orientation, columns=1, and no section headers; estimated widths also require view.collection.virtual.variableExtent.
---@field columnGap? number Horizontal virtualList item gap; defaults to 0.
---@field rowGap? number Logical gap between rows; defaults to 0.
---@field overscan? integer Extra rows on each side from 0 through 16; defaults to 2.
---@field initialScrollIndex? integer Same 1-based initial item passed to the virtual node; used only while this stable key has no accepted host scroll state.
---@field sectionHeaderIndices? integer[] Sorted unique 1-based virtualList section-header indices. Requires view.collection.virtual.stickyHeaders.

---@class SnowViewVirtualRange
---@field firstIndex integer First 1-based item to materialize, or 0 when empty.
---@field lastIndex integer Last inclusive 1-based item to materialize, or 0 when empty.
---@field offset number Host-owned clamped scroll offset.
---@field maximum number Maximum scroll offset.
---@field viewportExtent number Validated viewport extent.
---@field contentExtent number Total bounded logical content extent.
---@field stickyHeaderIndex? integer Active 1-based section header at the first visible item; prepend this item when it is before firstIndex.

---@class SnowViewScrollResult
---@field offset integer Applied logical offset.
---@field maximum integer Current maximum logical offset.
---@field changed boolean Whether the host offset changed.

---@class SnowViewNodeOptions
---@field key string Globally unique stable key in the returned tree.
---@field debugName? string Developer-readable node name, 1..256 UTF-8 bytes without control characters when present; it only appears in copied host diagnostics and does not affect behavior.
---@field testId? string Developer test selector, 1..128 ASCII letters/digits or ._:-/ when present; it is diagnostics-only and does not replace key or UIA AutomationId. Requires view.identity.diagnostics.
---@field text? string Used by text nodes.
---@field spans? SnowViewTextSpan[] Required by styledText; 1 to 64 bounded spans. Interactive span fields require view.styledText.actions.
---@field label? string Required by button, link, toggle, and checkbox nodes.
---@field glyph? string Required by icon and iconButton nodes.
---@field source? SnowImageResource Required by image nodes.
---@field font? SnowFontResource Package-private font for text and label-bearing nodes, including link and radioGroup.
---@field fit? SnowViewImageFit Image scaling mode; defaults to contain.
---@field alignment? SnowViewImageAlignment Image alignment on both axes; defaults to center.
---@field interpolation? SnowViewImageInterpolation Image sampling mode; defaults to linear.
---@field tint? SnowViewColor Image-only RGB or host theme tint that replaces source RGB while preserving source alpha.
---@field alt? string Required by image and referenceIcon nodes; use an empty string for decorative visuals.
---@field iconFont? 'fa'|'fluent'|'fluent-regular'
---@field shape? 'rectangle'|'roundedRectangle'|'circle'|'ellipse'
---@field orientation? 'horizontal'|'vertical' Divider, radioGroup/slider, scroll, eager list, or virtualList axis; scroll and lists default to vertical.
---@field value? number|string Numeric progress/slider/numberInput value, or controlled textInput/textArea/searchBox string.
---@field values? number[] Required by data-series nodes; 1 to 512 finite samples, with at most 4096 samples across one tree.
---@field min? number Explicit data-series, slider, or numberInput minimum; defaults to 0 for controls.
---@field max? number Explicit data-series, slider, or numberInput maximum; defaults to 1 for controls.
---@field step? number Positive slider/numberInput step no larger than max-min; defaults to 0.01.
---@field options? SnowViewChoiceOption[] Required by radioGroup/select; 1 to 64 unique keys and values.
---@field selectedValue? string Required controlled radioGroup/select value; empty means no selection.
---@field year? integer Required Gregorian year from 1 through 9999 for monthCalendar.
---@field month? integer Required month from 1 through 12 for monthCalendar.
---@field firstDayOfWeek? integer MonthCalendar week start, 1=Sunday through 7=Saturday; defaults to 1.
---@field selectedDate? string Required controlled ISO YYYY-MM-DD selection for monthCalendar; empty means none.
---@field todayDate? string Optional ISO YYYY-MM-DD date highlighted as today.
---@field eventDates? string[] Up to 366 unique ISO dates rendered with event markers.
---@field weekdayLabels? string[] Required seven localized labels ordered Sunday through Saturday.
---@field showAdjacentDates? boolean Render leading/trailing adjacent-month dates; defaults to true.
---@field placeholder? string Input or select placeholder.
---@field expanded? boolean Required controlled select popup state; defaults to false when omitted.
---@field selectAll? boolean Select all text on first focus.
---@field selection? SnowViewTextSelection Controlled textInput/textArea/searchBox selection; requires view.input.selection and events.selectionChange, and conflicts with selectAll.
---@field liveUpdate? boolean Emit each input edit when true (default); emit on commit when false.
---@field readOnly? boolean Text-like and numeric inputs remain focusable/selectable but reject typing, IME, paste, cut, delete, UIA value changes, and numeric stepping.
---@field required? boolean Text-like, numeric, and select form requirement exposed through host accessibility semantics; it does not validate or block submission.
---@field validationState? SnowViewValidationState Input/select validation state; defaults to none.
---@field validationMessage? string Bounded validation detail exposed as semantic help text; render a text node too when the message must be visibly persistent.
---@field maxBytes? integer Input UTF-8 limit from 0/default through 65536; declarative default is the 4096-byte node limit.
---@field thickness? number Progress or data-series stroke thickness.
---@field trackOpacity? number Progress track or chart guide opacity between 0 and 1.
---@field fillOpacity? number Progress or data-series foreground opacity between 0 and 1.
---@field width? SnowViewLength
---@field height? SnowViewLength
---@field minWidth? number Minimum bounded logical width, from 0 through 4096.
---@field maxWidth? number Maximum bounded logical width, from 0 through 4096.
---@field minHeight? number Minimum bounded logical height, from 0 through 4096.
---@field maxHeight? number Maximum bounded logical height, from 0 through 4096.
---@field aspectRatio? number Width divided by height, from 0.01 through 100; conflicting fixed dimensions or constraints reject the tree.
---@field margin? number|SnowViewEdgeInsets Outer spacing from 0 through 4096 per edge; parent layout reserves it outside the node frame.
---@field padding? number|SnowViewEdgeInsets Inner spacing from 0 through 4096 per edge.
---@field offset? SnowViewOffset Visual translation allowed only on direct stack children; it does not consume layout space.
---@field zIndex? integer Stable paint and hit-test order from -1024 through 1024, allowed only on direct stack children.
---@field clip? boolean Compatibility clipping flag; use matching overflow='clip' in new widgets.
---@field overflow? SnowViewOverflow Container descendant overflow behavior; defaults to visible.
---@field shadow? SnowViewShadow Bounded host-rendered frame shadow that does not change layout or hit bounds.
---@field transform? SnowViewTransform Post-layout transform inherited by descendants. Probe view.transform.basic for translation/uniform scale and view.transform.affine for non-uniform scale, rotation, and skew.
---@field transition? SnowViewTransition Host-driven style, transform, or layout presentation transition after probing the matching view.transition feature; interpolation frames do not re-run view().
---@field enterTransition? SnowViewPresenceTransition Host-driven starting opacity/transform for stable keys inserted after the initial scene. Requires view.transition.enter.
---@field exitTransition? SnowViewPresenceTransition Host-driven target opacity/transform for removed stable keys; retained snapshots are presentation-only and bounded. Requires view.transition.exit.
---@field gap? number
---@field columns? integer|SnowViewGridTrack[] Required by grid, gridList, and virtualGrid. Track arrays require view.grid.tracks and are rejected by virtualGrid.
---@field rows? integer|SnowViewGridTrack[] Optional explicit grid/gridList rows; integer creates that many auto tracks and implicit trailing rows remain auto.
---@field columnGap? number Grid/gridList/virtualGrid/flow horizontal gap, or horizontal virtualList main-axis gap; defaults to gap.
---@field rowGap? number Grid/gridList/virtualGrid/flow vertical gap, or vertical virtualList main-axis gap; defaults to gap.
---@field gridColumn? integer Explicit 1-based column for a direct grid/gridList child; 1 through 64.
---@field gridRow? integer Explicit 1-based row for a direct grid/gridList child; 1 through 64.
---@field columnSpan? integer Number of equal-width columns occupied by a direct grid/gridList child; 1 through 64, defaults to 1.
---@field rowSpan? integer Number of rows occupied by a direct grid/gridList child; 1 through 64, defaults to 1.
---@field itemCount? integer Required total logical item count for virtualList/virtualGrid; 0 through 1000000.
---@field itemExtent? number Required fixed row height for virtualList/virtualGrid.
---@field estimatedItemSize? number VirtualList-only positive main-axis estimate used instead of itemExtent; materialized heights or widths are measured and cached by the host. Horizontal use also requires view.collection.virtual.orientation.
---@field layoutRevision? integer Variable virtualList measurement generation; bump after reorder or main-axis-size-affecting model changes. Defaults to 0.
---@field sectionHeaderIndices? integer[] VirtualList-only sorted unique 1-based section-header indices; pass the same array to view.virtualRange. Requires view.collection.virtual.stickyHeaders.
---@field stickyHeaderIndex? integer VirtualList-only active section index returned by view.virtualRange; when it is before firstIndex, prepend that one auxiliary listItem before the contiguous window.
---@field firstIndex? integer Required first 1-based materialized item for virtualList/virtualGrid; 0 only when empty.
---@field overscan? integer Virtual collection overscan rows from 0 through 16; defaults to 2.
---@field initialScrollKey? string Scroll-only visible descendant key to reveal with nearest alignment when this stable container key is first accepted.
---@field initialScrollIndex? integer VirtualList/virtualGrid-only 1-based item to reveal with nearest alignment when this stable container key is first accepted; pass the same value to view.virtualRange.
---@field selectionMode? SnowViewSelectionMode Controlled collection selection; defaults to none and probes with view.collection.selection.
---@field selectedKeys? string[] Unique controlled listItem keys; single accepts at most one, none accepts none, and virtual selections may include unmaterialized item keys.
---@field emptyContent? SnowViewNode One visible fallback node used when a collection is empty, or when a manifest-backed slotSurface has no host items after probing view.logicalSlots.emptyContent.
---@field loadingContent? SnowViewNode One visible fallback node used instead of collection items while busy=true.
---@field flexBasis? SnowViewFlexBasis Main-axis base size in row/column/list before free-space distribution; defaults to auto.
---@field flexGrow? number Non-negative positive-space factor; fill keeps an implicit factor of 1 when this is omitted.
---@field flexShrink? number Non-negative overflow factor; defaults to 1, use 0 to preserve the basis.
---@field flexDirection? SnowViewFlexDirection Main axis for row/column; defaults to row for row and column for column.
---@field flexWrap? SnowViewFlexWrap Line wrapping for row/column; defaults to noWrap.
---@field alignContent? SnowViewContentAlignment Distribution of wrapped lines on the cross axis; defaults to stretch.
---@field alignItems? SnowViewAlignment
---@field alignSelf? SnowViewSelfAlignment
---@field justifyContent? 'start'|'center'|'end'|'spaceBetween'|'spaceAround'|'spaceEvenly'
---@field fontSize? number
---@field fontWeight? integer One of 100, 200, ..., 900; overrides the compatibility bold flag.
---@field fontStyle? 'normal'|'italic'
---@field lineHeight? number Uniform line height from 1 through 1024 logical units.
---@field letterSpacing? number Additional spacing from -64 through 256 logical units.
---@field locale? string Bounded BCP 47 language tag used for shaping and font fallback; defaults to the host locale.
---@field textDirection? SnowViewTextDirection Base paragraph direction; auto uses the first strong character and then the locale.
---@field bold? boolean
---@field checked? boolean Required explicit controlled value for toggle and checkbox nodes.
---@field indeterminate? boolean Checkbox controlled mixed state, or host-driven ProgressBar/ProgressRing activity after probing view.progress.indeterminate. Checkbox requires checked=false; indeterminate progress ignores value for paint and never runs Lua per frame.
---@field selected? boolean Generic controlled selection state used by selectedStyle and SelectionItem semantics where the node contract provides them.
---@field sticky? boolean ListItem-only opt-in that pins headers inside the nearest vertical scroll while their eager list remains visible. Requires view.collection.stickyHeaders.
---@field busy? boolean Common host-observable busy state; collection loadingContent becomes active when supplied.
---@field showScrollbar? boolean Scroll or virtual-collection host scrollbar visibility; defaults to true.
---@field textAlign? 'start'|'center'|'end'
---@field verticalAlign? 'start'|'center'|'end' Text block alignment inside the node; defaults to center.
---@field textWrap? SnowViewTextWrap Defaults to noWrap, except styledText defaults to wrap.
---@field maxLines? integer Maximum rendered lines from 0/unlimited through 64.
---@field overflowText? SnowViewTextOverflow Defaults to ellipsis, except styledText defaults to clip.
---@field visible? boolean Compatibility visibility flag; false means collapsed.
---@field visibility? SnowViewVisibility Explicit layout/paint/input visibility; probe view.state.visibility before use.
---@field enabled? boolean
---@field focusable? boolean Override whether the semantic node can receive host pointer/UIA focus; defaults to the node contract.
---@field tabIndex? integer Sequential host focus order from -1 through 32767. -1 skips Tab/spatial traversal; positive values sort before 0/source order.
---@field cursor? string
---@field tooltip? string|SnowTooltipDescriptor Bounded host tooltip; descriptor form requires view.tooltip.rich and also enters semantic help text when no validation message is present.
---@field capturePointer? boolean Keep primary-pointer move/up routed to the pressed stable key until release or host cancellation; requires interaction.pointerCapture plus pointerMove or pointerUp.
---@field accessKey? string One ASCII letter or digit, unique in the tree; Alt+key focuses or activates this node after probing view.keyboard.accessKey.
---@field acceleratorText? string UI Automation shortcut description up to 64 UTF-8 bytes; it does not register a shortcut. Requires view.keyboard.accessKey.
---@field style? SnowViewStyle
---@field hoverStyle? SnowViewStyle
---@field pressedStyle? SnowViewStyle
---@field focusStyle? SnowViewStyle Keyboard/UI Automation focus style; defaults to a visible host outline when omitted.
---@field disabledStyle? SnowViewStyle Applied last when enabled is false.
---@field validationStyle? SnowViewStyle Applied after pressed and before focus/disabled; the host supplies a state-colored border when omitted.
---@field checkedStyle? SnowViewStyle Applied before hover/pressed when a toggle/checkbox or radio option is selected.
---@field selectedStyle? SnowViewStyle Generic selected-node style; also used by MonthCalendar selected date cells.
---@field dropStyle? SnowViewStyle SlotSurface-only accepted-drop overlay. Background and border style the bounded host target; foreground styles its native insertion indicator. Requires view.logicalSlots.dropStyle.
---@field todayStyle? SnowViewStyle MonthCalendar today outline style.
---@field adjacentStyle? SnowViewStyle MonthCalendar adjacent-month date style.
---@field eventStyle? SnowViewStyle MonthCalendar event-marker style.
---@field binding? string Required by a binding slotSurface; mutually exclusive with collection.
---@field collection? string Required by a collection slotSurface; mutually exclusive with binding.
---@field revision? integer Optional exact host slot revision asserted by slotSurface.
---@field reference? string Required opaque reference for slotItem and referenceIcon.
---@field accessibility? SnowViewAccessibility
---@field events? SnowViewEvents
---@field action? SnowInteractionAction Button/link click or controlled selection/value change shorthand.
---@field child? SnowViewNode Exactly one child for slotItem; optional placeholder or bound child for a binding slotSurface.
---@field children? SnowViewNode[] Accepted only by non-leaf node child policies; scroll/listItem/slotItem require one, collections require listItem children outside empty/loading states, and ordinary containers accept bounded composition.

---@class SnowViewNode: SnowViewNodeOptions
---@field type 'box'|'row'|'column'|'grid'|'flow'|'stack'|'scroll'|'list'|'gridList'|'virtualList'|'virtualGrid'|'listItem'|'slotSurface'|'slotItem'|'text'|'styledText'|'textInput'|'textArea'|'searchBox'|'numberInput'|'select'|'image'|'referenceIcon'|'button'|'link'|'toggle'|'checkbox'|'radioGroup'|'slider'|'icon'|'iconButton'|'shape'|'badge'|'divider'|'progressBar'|'progressRing'|'meter'|'sparkline'|'lineChart'|'barChart'|'waveform'|'spectrum'|'monthCalendar'|'spacer'

---@class SnowLogicalSlotItem
---@field id string Stable opaque item ID used by collection remove/move.
---@field reference string Persistent opaque reference accepted by slotItem and the corresponding launch/open task.
---@field kind 'desktop.item'|'app.reference'|'filesystem.reference'
---@field title string Display-only title.
---@field source string Display-only source category.
---@field type string Display-only item type.
---@field availability 'available'|'unavailable'

---@class SnowLogicalSlotChange
---@field slotId string
---@field kind 'binding'|'collection'
---@field revision integer
---@field operation 'unchanged'|'bound'|'replaced'|'cleared'|'added'|'removed'|'moved'|'transferred'|'availability'|'undone'|'redone'
---@field itemIds string[]
---@field relatedSlotId? string Source collection for transferred/undone/redone cross-slot transactions.
---@field relatedRevision? integer Source collection revision after the same transaction.

---@class SnowLogicalBinding
---@field id fun(self: SnowLogicalBinding): string
---@field revision fun(self: SnowLogicalBinding): integer
---@field state fun(self: SnowLogicalBinding): 'empty'|'bound'|'unavailable'
---@field capacity fun(self: SnowLogicalBinding): integer Always 1.
---@field item fun(self: SnowLogicalBinding): SnowLogicalSlotItem?
---@field bind fun(self: SnowLogicalBinding, reference: string): SnowLogicalSlotChange Requires a trusted user gesture.
---@field clear fun(self: SnowLogicalBinding): SnowLogicalSlotChange Requires a trusted user gesture and allowClear=true.
---@field pick fun(self: SnowLogicalBinding): boolean Opens the manifest-filtered host picker; requires a trusted user gesture.

---@class SnowLogicalCollection
---@field id fun(self: SnowLogicalCollection): string
---@field revision fun(self: SnowLogicalCollection): integer
---@field state fun(self: SnowLogicalCollection): 'empty'|'bound'|'unavailable'
---@field capacity fun(self: SnowLogicalCollection): integer
---@field items fun(self: SnowLogicalCollection): SnowLogicalSlotItem[]
---@field add fun(self: SnowLogicalCollection, reference: string): SnowLogicalSlotChange Requires a trusted user gesture.
---@field remove fun(self: SnowLogicalCollection, itemId: string): SnowLogicalSlotChange Requires a trusted user gesture.
---@field move fun(self: SnowLogicalCollection, itemId: string, index: integer): SnowLogicalSlotChange Requires a trusted user gesture; index is 1-based.
---@field pick fun(self: SnowLogicalCollection): boolean Opens the manifest-filtered host picker and appends one item; requires a trusted user gesture.

---@class SnowInteractionShape
---@field type 'rect'|'roundedRect'|'circle'
---@field x number Left coordinate for rectangles; center X for circles.
---@field y number Top coordinate for rectangles; center Y for circles.
---@field width? number Required for rect and roundedRect.
---@field height? number Required for rect and roundedRect.
---@field radius? number Required for circle; optional corner radius for roundedRect.

---@class SnowInteractionEvents
---@field pointerEnter? SnowInteractionAction
---@field pointerLeave? SnowInteractionAction
---@field pointerDown? SnowInteractionAction
---@field pointerUp? SnowInteractionAction
---@field pointerMove? SnowInteractionAction
---@field click? SnowInteractionAction
---@field doubleClick? SnowInteractionAction
---@field wheel? SnowInteractionAction
---@field contextMenu? SnowInteractionAction
---@field keyDown? SnowInteractionAction Focused-region key press observation; requires interaction.keyboard and cannot cancel host behavior.
---@field keyUp? SnowInteractionAction Paired focused-region key release observation; requires interaction.keyboard.

---@class SnowInteractionAccessibility
---@field role? string
---@field label? string
---@field value? string Localized semantic value override.
---@field hint? string Localized UIA HelpText.
---@field headingLevel? integer Heading level from 1 through 9.
---@field live? 'off'|'polite'|'assertive'
---@field positionInSet? integer One-based position from 1 through 32767.
---@field setSize? integer Total set size from 1 through 32767.
---@field hidden? boolean Only valid for a region without controls, actions, key events, or focusability.

---@class SnowInteractionRegion
---@field key string Stable key, 1..128 UTF-8 bytes.
---@field shape SnowInteractionShape
---@field cursor? 'default'|'hand'|'text'|'crosshair'
---@field tooltip? string|SnowTooltipDescriptor Bounded host tooltip; descriptor form additionally requires interaction.tooltip.rich.
---@field capturePointer? boolean Keep primary-pointer move/up routed to this stable key until release or host cancellation; requires interaction.pointerCapture plus pointerMove or pointerUp.
---@field events? SnowInteractionEvents
---@field accessibility? SnowInteractionAccessibility
---@field enabled? boolean
---@field focusable? boolean Explicit keyboard focus participation; requires interaction.keyboard.
---@field tabIndex? integer Sequential order from -1 through 32767; requires interaction.keyboard.

---@class SnowInteractionScrollDescriptor
---@field key string Stable instance-scoped key, 1..128 UTF-8 bytes.
---@field shape SnowInteractionShape Must be a positive rect viewport.
---@field orientation? SnowViewOrientation Defaults to vertical; horizontal requires interaction.scroll.orientation.
---@field contentHeight? integer Required logical content height from 0..1000000 for vertical scrolling; mutually exclusive with contentWidth.
---@field contentWidth? integer Required logical content width from 0..1000000 for horizontal scrolling; mutually exclusive with contentHeight.

---@class SnowInteractionScrollState
---@field offset integer Current logical main-axis offset.
---@field maximum integer Maximum logical main-axis offset.
---@field orientation SnowViewOrientation Resolved axis.
---@field viewportExtent integer Rounded logical main-axis viewport extent.
---@field contentExtent integer Effective main-axis content extent, never below viewportExtent.
---@field viewportHeight? integer Vertical viewport extent when orientation is vertical.
---@field contentHeight? integer Vertical content extent when orientation is vertical.
---@field viewportWidth? integer Horizontal viewport extent when orientation is horizontal.
---@field contentWidth? integer Horizontal content extent when orientation is horizontal.

---@class SnowTextControlShape
---@field type 'rect'
---@field x number
---@field y number
---@field width number
---@field height number

---@class SnowTextInputDescriptor
---@field key string Stable instance-scoped control key, 1..128 UTF-8 bytes.
---@field storageKey string Persistent storage key, 1..128 UTF-8 bytes.
---@field shape SnowTextControlShape Positive logical bounds submitted during render.
---@field placeholder? string Up to 4096 UTF-8 bytes.
---@field fontSize? number 9..96 logical pixels.
---@field textColor? integer RGB color.
---@field placeholderColor? integer RGB color.
---@field backgroundColor? integer RGB color.
---@field borderColor? integer RGB color.
---@field focusedBorderColor? integer RGB color.
---@field backgroundAlpha? number 0..1.
---@field focusedBackgroundAlpha? number 0..1.
---@field borderAlpha? number 0..1.
---@field focusedBorderAlpha? number 0..1.
---@field radius? number 0..4096.
---@field padding? number 0..4096.
---@field borderThickness? number 0.5..64.
---@field selectAll? boolean Select all text when focus is first acquired.
---@field liveUpdate? boolean Persist accepted edits immediately; defaults to true.
---@field maxBytes? integer UTF-8 limit from 1..65536; defaults to 4096.

---@class SnowTextAreaDescriptor: SnowTextInputDescriptor
---@field placeholderWhenWhitespace? boolean Show the placeholder for unfocused whitespace-only values.
---@field maxBytes? integer UTF-8 limit from 1..65536; defaults to 65536.

---@class SnowMenuRequest
---@field id string The region contextMenu binding ID.
---@field value? SnowStateValue The region contextMenu binding payload.
---@field targetKey string
---@field surface 'desktop'|'panel'|'dialog'|'popover'
---@field source 'pointer'
---@field scope 'element'|'component'

---@class SnowMenuItem
---@field id? string Required for actionable leaves; omitted for separators and submenus.
---@field label? string Required except for separators.
---@field type? 'separator'
---@field enabled? boolean
---@field checked? boolean
---@field icon? string Optional host glyph.
---@field iconFont? 'fa'|'fluent'|'fluent-regular'
---@field image? SnowImageResource Optional declared package image; mutually exclusive with icon and requires interaction.contextMenu.resourceImage.
---@field children? SnowMenuItem[] Nested items; requires interaction.contextMenu.submenu and cannot be combined with id.

---@alias SnowMenuModel SnowMenuItem[]

---@class SnowWidgetDefinition
---@field name? string
---@field render? fun(context: SnowWidgetContext, model: any) Exactly one of render or view is required in API v2.
---@field view? fun(context: SnowWidgetContext, model: any): SnowViewNode Exactly one of view or render is required; requires view.tree.core for the current node subset.
---@field panel? fun(context: SnowWidgetContext, model: any): SnowViewNode? Renders the host-owned auxiliary panel surface opened with widget.openPanel. Return a declarative view after probing view.surface.panel, or nil for immediate drawing.
---@field dialog? fun(context: SnowWidgetContext, model: any): SnowViewNode? Renders the non-blocking modal surface opened with widget.openDialog. Return a declarative view after probing view.surface.dialog, or nil for immediate drawing.
---@field popover? fun(context: SnowWidgetContext, model: any): SnowViewNode? Renders the element-anchored surface opened with widget.openPopover. Return a declarative view after probing view.surface.popover, or nil for immediate drawing.
---@field setup? fun(context: SnowWidgetContext): any Runs once and returns the instance model passed to render and dispose.
---@field event? fun(context: SnowWidgetContext, model: any, event: SnowWidgetEvent) Receives host surface and declarative action events.
---@field menu? fun(context: SnowWidgetContext, model: any, request: SnowMenuRequest): SnowMenuModel? Builds an immediate-region context menu synchronously.
---@field dispose? fun(context: SnowWidgetContext, model: any, reason: 'unload'|'hotReload'|'shutdown'|string) Runs at most once before the instance VM is released.
---@field migrateStorage? fun(oldVersion: integer, newVersion: integer) Runs before setup when persisted storage must be upgraded.
---@field useCustomStyle? boolean
---@field followPersonalizationDefault? boolean
---@field showTitle? boolean Enables the host bottom move bar and displays the component title; false reserves only compact lower-left move and lower-right resize handles while hovering and leaves the remaining desktop surface to component content.
---@field bottomBarHover? boolean Shows an enabled host bottom bar only while hovering; defaults to true and has no effect when showTitle is false.
---@field bg? integer
---@field border? integer
---@field alpha? number
---@field borderAlpha? number
---@field gradientEndA? number
---@field glassEnabled? boolean
---@field settings? SnowWidgetSettings

---@class SnowWidgetEvent Lifecycle event. Raw pointer events are emitted only for immediate render surfaces; declarative views use explicit node pointer actions and host-owned visual state.
---@field kind 'visibility'|'resize'|'pointer'|'timer'|'schedule'|'frame'|'action'|'selection'|'environment'|'panel'|'dialog'|'popover'|'data.change'|'task.complete'|'slot.changed'|'notification.delivered'|'notification.action'
---@field action? 'click'|'change'|'selectionChange'|'focus'|'blur'|'submit'|'doubleClick'|'pointerDown'|'pointerMove'|'pointerUp'|'wheel'|'keyDown'|'keyUp'|'opened'|'closed'|string
---@field id? string
---@field name? string
---@field missed? integer
---@field coalesced? boolean
---@field now? integer UTC epoch milliseconds for schedule events; monotonic milliseconds for frame events.
---@field deltaMs? integer Elapsed monotonic milliseconds since this ID's prior frame, or zero for its first frame.
---@field timelineIndex? integer One-based index of the newest due timeline entry.
---@field timelineCount? integer Total entries in the active timeline.
---@field timelineEnded? boolean Whether this event consumed the final timeline entry.
---@field reload? boolean True on the final entry when the timeline requested reload = 'atEnd'.
---@field visible? boolean
---@field selected? boolean
---@field columns? integer
---@field rows? integer
---@field x? integer
---@field y? integer
---@field button? integer
---@field delta? integer
---@field key? string Stable symbolic virtual-key name such as Enter, ArrowLeft, A, or F5; Unidentified when unmapped.
---@field virtualKey? integer Windows virtual-key value for keyDown/keyUp observation; do not interpret it as text input.
---@field repeat? boolean Whether a keyDown was generated while the key was already held.
---@field ctrlKey? boolean
---@field shiftKey? boolean
---@field altKey? boolean
---@field targetKey? string Stable immediate interaction region key.
---@field previousChecked? boolean Current controlled value for toggle/checkbox change events.
---@field checked? boolean Proposed next controlled value for toggle/checkbox change events; the host does not persist it.
---@field previousIndeterminate? boolean Current checkbox mixed state for checkbox change events.
---@field indeterminate? boolean Proposed checkbox mixed state; activation always proposes false and the host does not persist it.
---@field previousSelection? string|SnowViewTextSelection Current radioGroup/select value or prior controlled text selection.
---@field selection? string|SnowViewTextSelection Proposed radioGroup/select value or text selection; input text-change events include the resulting selection when controlled.
---@field previousSelectedKeys? string[] Previous controlled collection keys.
---@field selectedKeys? string[] Proposed controlled collection keys; the host does not persist them.
---@field previousExpanded? boolean Current select expanded state for click events.
---@field expanded? boolean Proposed select expanded state; the host does not persist it.
---@field previousControlValue? number Current slider value for change events.
---@field controlValue? number Proposed slider value or valid numberInput text value; the host does not persist it.
---@field previousText? string Input value before a change proposal.
---@field text? string Proposed input value, or the current value for focus/blur/submit.
---@field numberValid? boolean Whether numberInput text is a complete finite value within min/max.
---@field committed? boolean True for commit-mode or cancellation-reversion change events.
---@field cancelled? boolean True when Escape reverts an input or reports blur cancellation.
---@field clickCount? integer
---@field trustedGesture? boolean
---@field surface? 'desktop'|'panel'|'dialog'|'popover'
---@field reason? string
---@field topic? string Updated data subscription topic for data.change.
---@field revision? integer Monotonic provider revision for data.change.
---@field slotId? string Manifest logical-slot ID for slot.changed.
---@field slotKind? 'binding'|'collection' Logical slot model kind for slot.changed.
---@field operation? 'bound'|'replaced'|'added'|'removed'|'moved'|'transferred'|'cleared'|'availability'|'undone'|'redone' Logical slot transaction for slot.changed.
---@field itemIds? string[] Opaque affected host item IDs for slot.changed.
---@field relatedSlotId? string Source collection ID for an atomic cross-slot transfer, including its undo/redo event.
---@field relatedRevision? integer Revision of relatedSlotId after the same transaction.
---@field source? 'pointer'|'keyboard'|'ime'|'commit'|'host.drop'|'host.picker'|'host.menu'|'host.keyboard'|string Host interaction source; host.* values identify slot.changed transactions.
---@field taskId? integer
---@field task? 'media.play'|'media.pause'|'media.toggle'|'media.stop'|'media.next'|'media.previous'|'media.seek'|'media.setRate'|'media.setShuffle'|'media.setRepeat'|'audio.output.setVolume'|'audio.output.setMute'|'system.openSettings'|'clipboard.read'|'clipboard.write'|'clipboard.clear'|'filesystem.pickOpen'|'filesystem.pickSave'|'filesystem.pickFolder'|'filesystem.stat'|'filesystem.list'|'filesystem.read'|'filesystem.write'|'filesystem.release'|'app.search'|'app.launch'|'desktop.search'|'everything.search'|'shell.openItem'|'shell.revealItem'|'desktop.refresh'|'notification.show'|'notification.update'|'notification.dismiss'|'notification.schedule'|'notification.cancel'|'calendar.create'|'calendar.update'|'calendar.remove'|'network.request'|'shell.openUri'|string
---@field ok? boolean
---@field value? SnowMediaTaskValue|SnowAudioOutputTaskValue|SnowSystemSettingsTaskValue|SnowClipboardReadTaskValue|SnowFilesystemPickerTaskValue|SnowFilesystemMetadata|SnowFilesystemListTaskValue|SnowFilesystemReadTaskValue|SnowFilesystemWriteTaskValue|SnowAppSearchTaskValue|SnowItemSearchTaskValue|SnowNotificationTaskValue|SnowCalendarMutationTaskValue|SnowNetworkTaskValue|SnowStateValue
---@field error? string
---@field notificationId? string Host-issued notification ID for notification.delivered.
---@field actionId? string Declared action ID for notification.action.
---@field currentRevision? integer Latest revision returned by a failed calendar update conflict.
---@field status? integer HTTP status returned by a failed network.request after a response was received.

---@class SnowApiInfo
---@field current integer
---@field supported integer[]
---@field features string[]

---@class SnowFunctionParameter
---@field name string
---@field type string LuaLS-compatible primitive, union, or named type.
---@field optional boolean

---@class SnowCapability
---@field id string
---@field name? string Public function, data topic, or task name.
---@field feature? string Feature gate that owns this API entry.
---@field kind? 'function'|'data'|'task'
---@field hostAvailable? boolean Whether this host build exposes the feature independently of instance authorization.
---@field authorized? boolean Whether the current widget instance has the required permission.
---@field available boolean
---@field version? integer
---@field reason? 'unsupported'|'permissionRequired'|string
---@field permission? string Narrow permission required by this entry.
---@field requiresTrustedGesture? boolean
---@field preview? 'deterministic'|'noSideEffects'
---@field parameters? SnowFunctionParameter[] Positional parameters for a synchronous function.
---@field minimumIntervalMs? integer Data-topic lower refresh bound.
---@field hiddenIntervalMs? integer Data-topic hidden refresh interval.
---@field optionsType? string LuaLS subscription-options type exported for a data topic.
---@field valueType? string LuaLS snapshot-value type exported for a data topic.
---@field maximumPerInstance? integer Task concurrency limit.
---@field argumentsType? string LuaLS arguments type exported for a task; absent for no-argument tasks.
---@field resultType? string LuaLS successful task-completion value type.
---@field apis? SnowCapability[] Entries owned by a queried feature.

---@class SnowCapabilities
---@field apiVersion integer
---@field features SnowCapability[]
---@field capabilities SnowCapability[] Complete v2 system function/data/task contract for the current instance.

---@class SnowSystemInfo
---@field osFamily 'windows'
---@field osBuild? integer
---@field processArchitecture 'x86'|'x64'|'arm64'|'unknown'
---@field nativeArchitecture 'x86'|'x64'|'arm64'|'unknown'
---@field hostVersion string
---@field apiVersion integer
---@field packaged boolean
---@field portable boolean
---@field deploymentMode 'packaged'|'portable'

---@class SnowSystemUptime
---@field milliseconds integer
---@field includesSleep boolean

---@class SnowDateTimeParts
---@field year integer
---@field month integer
---@field day integer
---@field wday integer 1 is Sunday
---@field hour integer
---@field min integer
---@field sec integer
---@field millisecond integer
---@field timeZone string

---@class SnowTimeFormatOptions
---@field timeZone? 'local'|'utc'|string
---@field locale? string
---@field dateStyle? SnowDateStyle
---@field timeStyle? SnowTimeStyle

---@class SnowTimeDelta
---@field years? integer
---@field months? integer
---@field days? integer
---@field hours? integer
---@field minutes? integer
---@field seconds? integer
---@field milliseconds? integer

---@class SnowTimeZoneOptions
---@field timeZone? 'local'|'utc'|string

---@class SnowNumberFormatOptions
---@field locale? string
---@field minimumFractionDigits? integer
---@field maximumFractionDigits? integer
---@field grouping? boolean

---@class SnowBytesFormatOptions
---@field locale? string
---@field base? 1000|1024
---@field maximumFractionDigits? integer

---@class SnowDurationFormatOptions
---@field locale? string
---@field style? SnowDurationStyle

---@class SnowRelativeTimeFormatOptions
---@field locale? string
---@field unit? 'auto'|'second'|'minute'|'hour'|'day'
---@field numeric? 'auto'|'always'

---@class SnowLocaleOptions
---@field locale? string

---@class SnowImageResource

---@class SnowFontResource

---@class SnowWidgetPanelOptions
---@field title? string
---@field width? integer
---@field height? integer

---@class SnowWidgetDialogOptions: SnowWidgetPanelOptions
---@field dismissOnOutside? boolean Defaults to false so an accidental desktop click cannot discard the dialog.
---@field dismissOnEscape? boolean Defaults to true.

---@alias SnowWidgetPopoverPlacement 'auto'|'top'|'bottom'|'left'|'right'|'topStart'|'topEnd'|'bottomStart'|'bottomEnd'

---@class SnowWidgetPopoverOptions
---@field anchorKey string Stable key of an enabled declarative or immediate interaction element on the desktop surface.
---@field title? string When omitted, the host uses compact chrome without a title bar.
---@field placement? SnowWidgetPopoverPlacement Defaults to auto and flips to available work-area space.
---@field width? integer Clamped to 200..720 before work-area constraints.
---@field height? integer Clamped to 120..720 before work-area constraints.
---@field dismissOnOutside? boolean Defaults to true.
---@field dismissOnEscape? boolean Defaults to true.

---@class SnowInlineTextEditOptions
---@field storageKey string
---@field x number
---@field y number
---@field width number
---@field height number
---@field multiline? boolean
---@field initialValue? string
---@field selectAll? boolean
---@field textColor? integer
---@field fontSize? number
---@field backgroundColor? integer

---@class SnowDesktopIcon
---@field path? string
---@field title? string

---@class SnowResourceStatus
---@field state SnowResourceState
---@field type 'image'|'font'
---@field name string
---@field error? 'unavailable' Stable when state is error.

---@class SnowTextMetrics
---@field width number
---@field height number

---@class SnowMarqueeTextOptions
---@field key string Stable 1..128-byte key used to preserve the native scroll phase across data refreshes.
---@field x number Viewport x in desktop render coordinates.
---@field y number Viewport y in desktop render coordinates.
---@field width number Positive viewport width.
---@field height number Positive viewport height; text is vertically centered within it.
---@field text string Non-empty text up to 4096 UTF-8 bytes.
---@field size? number Font size from 1 through 512; defaults to 14.
---@field color? integer RGB color; defaults to white.
---@field bold? boolean
---@field speed? number Scroll speed in logical pixels per second from 1 through 512; defaults to 24.
---@field gap? number Gap between repeated copies from 0 through 4096; defaults to 24.
---@field alpha? number Opacity from 0 through 1.
---@field font? SnowFontResource

---@class SnowDrawPathCommand
---@field op 'move'|'line'|'cubic'|'quadratic'|'close'
---@field x? number Endpoint x for move, line, cubic, or quadratic.
---@field y? number Endpoint y for move, line, cubic, or quadratic.
---@field x1? number First control-point x for cubic or quadratic.
---@field y1? number First control-point y for cubic or quadratic.
---@field x2? number Second control-point x for cubic.
---@field y2? number Second control-point y for cubic.

---@class SnowDrawPathOptions
---@field fillColor? integer RGB fill color.
---@field strokeColor? integer RGB stroke color; defaults to white when neither color is supplied.
---@field thickness? number Positive bounded stroke width; defaults to 1.
---@field alpha? number Shared fill/stroke opacity between 0 and 1.
---@field fillRule? SnowDrawPathFillRule

---@class snow.view
view = {}

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.box(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.row(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.column(options) end

---@param options SnowViewNodeOptions Requires columns; supports equal-width columns or bounded explicit tracks through view.grid.tracks, plus placement/spans through view.grid.placement.
---@return SnowViewNode
function view.grid(options) end

---@param options SnowViewNodeOptions Horizontal wrapping layout; probes with view.flow.wrap.
---@return SnowViewNode
function view.flow(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.stack(options) end

---Host-owned bounded scroll viewport with exactly one visible child. Additional hidden children are rejected. Requires view.scroll.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.scroll(options) end

---Bounded vertical-by-default collection whose direct children are listItem nodes. Horizontal orientation requires view.collection.orientation.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.list(options) end

---Bounded row-major collection whose direct children are listItem nodes. Requires view.collection.basic.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.gridList(options) end

---Return the bounded materialization window for a virtual collection's current host offset. Requires view.collection.virtual.
---@param options SnowViewVirtualRangeOptions
---@return SnowViewVirtualRange
function view.virtualRange(options) end

---Set a committed declarative scroll or virtual-collection offset outside view/render. Requires view.scroll.programmatic.
---@param key string Stable scroll node key.
---@param offset integer Absolute logical offset from 0 through 1000000; clamped to the current maximum.
---@return SnowViewScrollResult? result
---@return string? error
function view.scrollTo(key, offset) end

---Move a committed declarative scroll or virtual-collection offset outside view/render. Requires view.scroll.programmatic.
---@param key string Stable scroll node key.
---@param delta integer Relative logical delta from -1000000 through 1000000.
---@return SnowViewScrollResult? result
---@return string? error
function view.scrollBy(key, delta) end

---Reveal a 1-based item in a committed virtualList/virtualGrid outside view/render. Requires view.scroll.programmatic.
---@param key string Stable virtual collection key.
---@param index integer 1-based logical item index.
---@param alignment? SnowViewScrollAlignment Defaults to nearest.
---@return SnowViewScrollResult? result
---@return string? error
function view.scrollToIndex(key, index, alignment) end

---Virtual list with fixed or host-measured main-axis extents. Children are the contiguous listItem window beginning at firstIndex. Horizontal orientation additionally requires view.collection.virtual.orientation.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.virtualList(options) end

---Fixed-row row-major virtual grid. Children are the contiguous listItem window beginning at firstIndex. Requires view.collection.virtual.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.virtualGrid(options) end

---Stable collection item with exactly one visible child; additional hidden children are rejected. Requires view.collection.basic.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.listItem(options) end

---Host-owned logical slot surface. Requires exactly one binding/collection ID declared in widget.json and probes with view.logicalSlots; dropStyle and emptyContent use their matching view.logicalSlots feature probes.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.slotSurface(options) end

---One host-owned logical slot reference with exactly one visible child and accessibility.label. Probe slots.keyboardNavigation for host focus/navigation; Enter/Space activates only this node's own click action.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.slotItem(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.text(options) end

---Bounded rich text. Probe view.styledText.actions before using stable interactive spans and view.styledText.inlineIcons before using glyph spans.
---@param options SnowViewNodeOptions Requires 1..64 spans; probes with view.styledText.basic.
---@return SnowViewNode
function view.styledText(options) end

---Controlled single-line host input with keyboard, selection, clipboard proxy, and IME. Requires view.inputControls.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.textInput(options) end

---Controlled multiline host input; Enter inserts a line and Ctrl+Enter submits. Requires view.inputControls.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.textArea(options) end

---Controlled search input with searchbox semantics and Enter submit. Requires view.inputControls.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.searchBox(options) end

---Controlled numeric text input; Up/Down apply step and change reports numberValid/controlValue. Requires view.inputControls.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.numberInput(options) end

---Controlled select; click proposes expanded and option change proposes selection. Requires view.inputControls.
---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.select(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.image(options) end

---Host-rendered shell icon for an opaque app/item reference owned by this widget instance. Requires view.referenceIcon and does not expose a path or grant launch/file access.
---@param options SnowViewNodeOptions Requires reference and explicit alt.
---@return SnowViewNode
function view.referenceIcon(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.button(options) end

---@param options SnowViewNodeOptions Requires a non-empty label and click/action; probes with view.actionControls.
---@return SnowViewNode
function view.link(options) end

---@param options SnowViewNodeOptions Requires label, explicit checked, and change/action; probes with view.selectionControls.
---@return SnowViewNode
function view.toggle(options) end

---@param options SnowViewNodeOptions Requires label, explicit checked, and change/action; probes with view.selectionControls.
---@return SnowViewNode
function view.checkbox(options) end

---@param options SnowViewNodeOptions Requires selectedValue, 1..64 options, and change/action; probes with view.actionControls.
---@return SnowViewNode
function view.radioGroup(options) end

---@param options SnowViewNodeOptions Requires value, change/action, and accessibility.label; probes with view.actionControls.
---@return SnowViewNode
function view.slider(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.icon(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.iconButton(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.shape(options) end

---@param options SnowViewNodeOptions Requires non-empty text; probes with view.statusVisuals.
---@return SnowViewNode
function view.badge(options) end

---@param options SnowViewNodeOptions Probes with view.statusVisuals.
---@return SnowViewNode
function view.divider(options) end

---@param options SnowViewNodeOptions Uses a 0..1 value, or indeterminate=true after probing view.progress.indeterminate.
---@return SnowViewNode
function view.progressBar(options) end

---@param options SnowViewNodeOptions Uses a 0..1 value, or indeterminate=true after probing view.progress.indeterminate.
---@return SnowViewNode
function view.progressRing(options) end

---@param options SnowViewNodeOptions Requires a 0..1 value and accessibility.label; probes with view.statusVisuals.
---@return SnowViewNode
function view.meter(options) end

---@param options SnowViewNodeOptions Requires values and accessibility.label; probes with view.dataSeries.
---@return SnowViewNode
function view.sparkline(options) end

---@param options SnowViewNodeOptions Requires values and accessibility.label; probes with view.dataSeries.
---@return SnowViewNode
function view.lineChart(options) end

---@param options SnowViewNodeOptions Requires values and accessibility.label; probes with view.dataSeries.
---@return SnowViewNode
function view.barChart(options) end

---@param options SnowViewNodeOptions Requires values and accessibility.label; defaults to the -1..1 range and probes with view.dataSeries.
---@return SnowViewNode
function view.waveform(options) end

---@param options SnowViewNodeOptions Requires values and accessibility.label; defaults to the 0..1 range and probes with view.dataSeries.
---@return SnowViewNode
function view.spectrum(options) end

---Controlled six-week Gregorian date grid with per-date hover, selection proposal, context menu, and event marker. Requires view.monthCalendar.
---@param options SnowViewNodeOptions Requires year/month/selectedDate/weekdayLabels, change/action, and accessibility.label.
---@return SnowViewNode
function view.monthCalendar(options) end

---@param options SnowViewNodeOptions
---@return SnowViewNode
function view.spacer(options) end

---@class snow.slots
slots = {}

---Open a manifest-declared single-reference logical slot.
---@param id string
---@return SnowLogicalBinding
function slots.binding(id) end

---Open a manifest-declared bounded logical collection.
---@param id string
---@return SnowLogicalCollection
function slots.collection(id) end

---Whether this instance has a logical-slot transaction to undo. Probe with slots.history.
---@return boolean
function slots.canUndo() end

---Whether this instance has an undone logical-slot transaction to redo. Probe with slots.history.
---@return boolean
function slots.canRedo() end

---Undo the most recent logical-slot transaction for this instance. Requires a trusted user gesture.
---@return SnowLogicalSlotChange
function slots.undo() end

---Redo the most recently undone logical-slot transaction for this instance. Requires a trusted user gesture.
---@return SnowLogicalSlotChange
function slots.redo() end

---@class snow.widget
widget = {}

---Validate and freeze an API v2 widget definition.
---@param definition SnowWidgetDefinition
---@return SnowWidgetDefinition
function widget.define(definition) end

---@return SnowApiInfo
function widget.apiInfo() end

---@param feature string
---@return boolean
function widget.hasFeature(feature) end

---@return SnowWidgetContext
function widget.context() end

---@return SnowWidgetInfo
function widget.info() end

---@return SnowWidgetTheme
function widget.theme() end

---@param permission string
---@return boolean
function widget.hasPermission(permission) end

---@param title string
function widget.setTitle(title) end

function widget.openSettings() end

---@param options? SnowWidgetPanelOptions
---The first successful panel scene automatically receives keyboard focus unless the opening action explicitly calls control.focus().
function widget.openPanel(options) end

function widget.closePanel() end

---@param options? SnowWidgetDialogOptions
---The first successful dialog scene automatically receives keyboard focus unless the opening action explicitly calls control.focus().
function widget.openDialog(options) end

function widget.closeDialog() end

---@param options SnowWidgetPopoverOptions
---@return boolean opened False outside a trusted desktop gesture or when anchorKey is not in the current successful desktop scene.
---The first successful popover scene automatically receives keyboard focus unless the opening action explicitly calls control.focus().
function widget.openPopover(options) end

function widget.closePopover() end

function widget.invalidate() end

---@param level 'debug'|'info'|'warn'|'error'
---@param message string
function widget.log(level, message) end

---@class snow.schedule
schedule = {}

---@class SnowScheduleOptions
---@field whenHidden? 'pause'|'throttle'|'continue'

---@class SnowScheduleTimelineEntry
---@field at integer UTC epoch milliseconds, strictly increasing and no more than 366 days in the future.
---@field value? SnowStateValue JSON-like value delivered through the schedule event.

---@class SnowScheduleTimelineOptions: SnowScheduleOptions
---@field reload? 'none'|'atEnd' Request a reload flag on the final event so the widget can publish its next timeline.

---Create or replace a coalescing repeating schedule.
---@param id string
---@param milliseconds integer
---@param options? SnowScheduleOptions
---@return boolean
function schedule.every(id, milliseconds, options) end

---Create or replace a one-shot schedule.
---@param id string
---@param milliseconds integer
---@param options? SnowScheduleOptions
---@return boolean
function schedule.after(id, milliseconds, options) end

---Create or replace a one-shot schedule at a UTC epoch timestamp.
---@param id string
---@param epochMilliseconds integer No more than 366 days in the future.
---@param options? SnowScheduleOptions
---@return boolean
function schedule.at(id, epochMilliseconds, options) end

---Create or replace an absolute timeline. Elapsed entries coalesce to the newest due value.
---@param id string
---@param entries SnowScheduleTimelineEntry[] One through 64 entries.
---@param options? SnowScheduleTimelineOptions
---@return boolean
function schedule.timeline(id, entries, options) end

---@param id string
---@return boolean
function schedule.cancel(id) end

---@class snow.animation
animation = {}

---Request one host-coalesced next-frame event. Call again from the frame event to continue.
---@param id string
---@return boolean accepted
---@return nil|'hidden'|'reducedMotion'|'previewUnavailable'|'quotaExceeded'|'hostUnavailable'|'apiVersion' error
function animation.requestFrame(id) end

---Cancel a pending named next-frame request.
---@param id string
---@return boolean
function animation.cancelFrame(id) end

---@alias SnowDataHiddenPolicy 'pause'|'throttle'|'continue'

---@class SnowDataSubscribeOptions
---@field maxAgeMs? integer Requested sampling interval; stale is confirmed only after the following sampling opportunity is also missed.
---@field whenHidden? SnowDataHiddenPolicy

---@class SnowCalendarEventsSubscribeOptions: SnowDataSubscribeOptions
---@field fromDate? string YYYY-MM-DD; must be paired with toDate.
---@field toDate? string YYYY-MM-DD; range is limited to 366 days.

---@class SnowFilesystemWatchSubscribeOptions: SnowDataSubscribeOptions
---@field handle string Opaque folder handle returned by filesystem.pickFolder.

---@alias SnowAudioAnalysisFeature 'waveform'|'spectrum'|'rms'|'peak'

---@class SnowAudioAnalysisSubscribeOptions: SnowDataSubscribeOptions
---@field features? SnowAudioAnalysisFeature[] One to four unique derived features; defaults to all.
---@field updateHz? integer 1..60; mutually exclusive with maxAgeMs and defaults to approximately 30 Hz.
---@field waveformPoints? integer 16..256; requires the waveform feature and defaults to 128.
---@field spectrumBins? integer 16..128; requires the spectrum feature and defaults to 64.

---@class SnowCpuDataValue
---@field usagePercent number
---@field logicalProcessors integer
---@field name string

---@class SnowMemoryDataValue
---@field totalBytes integer
---@field usedBytes integer
---@field freeBytes integer
---@field commitLimitBytes integer System commit limit in bytes.
---@field commitUsedBytes integer Current system committed bytes.
---@field commitAvailableBytes integer Remaining commit capacity in bytes.
---@field usagePercent number

---@class SnowProcessSummaryEntryDataValue
---@field id string Opaque identity derived from the process lifetime; never a PID or path.
---@field name string Display-only executable base name; never a path or command line.
---@field cpuPercent number Share of total machine CPU capacity, clamped to 0..100.
---@field workingSetBytes integer Current physical working set.
---@field privateBytes integer Current private committed bytes.

---@class SnowProcessSummaryDataValue
---@field processes SnowProcessSummaryEntryDataValue[] At most 12 entries, ordered by CPU then memory.
---@field observedCount integer Number of accessible processes considered before truncation.
---@field truncated boolean True when more accessible processes existed than were returned.

---@class SnowGpuAdapterDataValue
---@field id string Opaque adapter identifier.
---@field name string
---@field usagePercent number
---@field dedicatedMemoryBytes integer
---@field dedicatedUsedBytes integer PDH Dedicated Usage assigned by adapter LUID.
---@field sharedMemoryBytes integer
---@field sharedUsedBytes integer PDH Shared Usage assigned by adapter LUID.

---@class SnowGpuDataValue
---@field adapters SnowGpuAdapterDataValue[]

---@class SnowPowerDataValue
---@field acPower boolean
---@field charging boolean
---@field saver boolean
---@field batteryPercent number
---@field estimatedRemainingSeconds? integer

---@class SnowNetworkStatusDataValue
---@field connectivity 'none'|'local'|'internet'
---@field transport 'none'|'ethernet'|'wifi'|'cellular'|'other'
---@field costKnown boolean
---@field metered boolean
---@field roaming boolean
---@field overLimit boolean

---@class SnowNetworkTrafficDataValue
---@field connected boolean
---@field receivedBytes integer
---@field sentBytes integer
---@field downloadBytesPerSecond integer
---@field uploadBytesPerSecond integer

---@class SnowStorageVolumeDataValue
---@field id string Opaque volume identifier; never a filesystem path.
---@field displayName string
---@field mountPoint string Display-only mount point such as C:\\.
---@field kind 'fixed'|'removable'|'network'|'optical'|'ramdisk'|'unknown'
---@field capacityBytes integer
---@field freeBytes integer Free bytes available to the current user.
---@field capacityAvailable boolean False when capacity lookup is intentionally skipped for a remote or unready volume.
---@field removable boolean
---@field readOnly boolean

---@class SnowStorageVolumesDataValue
---@field volumes SnowStorageVolumeDataValue[]

---@class SnowStorageIoDataValue
---@field readBytesPerSecond integer Aggregate physical-disk read rate.
---@field writeBytesPerSecond integer Aggregate physical-disk write rate.
---@field busyPercent number Aggregate physical-disk busy percentage, clamped to 0..100.

---@class SnowDisplayRect
---@field x number
---@field y number
---@field width number
---@field height number

---@class SnowDisplayPixelRect
---@field x integer
---@field y integer
---@field width integer
---@field height integer

---@class SnowDisplayDataValue
---@field id string Opaque display identifier.
---@field name string User-visible display name when Windows provides one.
---@field primary boolean
---@field bounds SnowDisplayRect Logical bounds.
---@field workArea SnowDisplayRect Logical work area.
---@field pixelBounds SnowDisplayPixelRect Physical-pixel bounds.
---@field pixelWorkArea SnowDisplayPixelRect Physical-pixel work area.
---@field dpiX integer
---@field dpiY integer
---@field scale number Effective DPI divided by 96.
---@field refreshHz number Zero when unavailable.
---@field orientation 'landscape'|'portrait'|'landscapeFlipped'|'portraitFlipped'|'unknown'
---@field hdrKnown boolean
---@field hdrSupported boolean
---@field hdrEnabled boolean

---@class SnowDisplayTopologyDataValue
---@field displays SnowDisplayDataValue[]

---@class SnowDisplayCurrentDataValue
---@field display SnowDisplayDataValue Display containing this widget surface.

---@class SnowAudioOutputDefaultDataValue
---@field id string Opaque default render endpoint identifier.
---@field name string User-visible endpoint name when Windows provides one.
---@field state 'active'|'disabled'|'unplugged'|'notPresent'|'unknown'

---@class SnowAudioOutputVolumeDataValue
---@field endpointId string Opaque endpoint identifier matching audio.output.default.
---@field volume number Master volume scalar in the minimum..maximum range.
---@field muted boolean
---@field minimum number Currently 0.0.
---@field maximum number Currently 1.0.

---@class SnowAudioOutputAnalysisDataValue
---@field waveform? number[] Requested normalized mono points in -1.0..1.0; omitted when not selected.
---@field spectrum? number[] Requested normalized magnitude bins in 0.0..1.0; omitted when not selected.
---@field rms? number Normalized RMS level in 0.0..1.0; omitted when not selected.
---@field peak? number Normalized peak level in 0.0..1.0; omitted when not selected.
---@field silent boolean
---@field deviceChanged boolean
---@field endpointId string Opaque endpoint identifier.
---@field sampleRate integer
---@field channels integer Source mix channel count; waveform is always downmixed.

---@class SnowMediaControlsDataValue
---@field canPlay boolean
---@field canPause boolean
---@field canPlayPause boolean
---@field canStop boolean
---@field canNext boolean
---@field canPrevious boolean
---@field canSeek boolean
---@field canChangePlaybackRate boolean
---@field canToggleShuffle boolean
---@field canChangeRepeatMode boolean

---@class SnowMediaTimelineValue
---@field sessionId string Opaque media session identifier.
---@field positionMs integer Position relative to the session start.
---@field durationMs integer Bounded non-negative duration.
---@field minimumSeekMs integer
---@field maximumSeekMs integer
---@field updatedAtMs integer Epoch milliseconds reported by Windows.

---@class SnowMediaSessionValue
---@field id string Opaque media session identifier.
---@field sourceName string Bounded source display identity supplied by Windows.
---@field title string
---@field artist string
---@field album string
---@field playbackStatus 'closed'|'open'|'changing'|'stopped'|'playing'|'paused'
---@field current boolean
---@field controls SnowMediaControlsDataValue
---@field timeline SnowMediaTimelineValue

---@class SnowMediaSessionsDataValue
---@field currentSessionId string Empty when Windows has no current session.
---@field sessions SnowMediaSessionValue[] At most 32 entries.

---@class SnowMediaCurrentDataValue
---@field session SnowMediaSessionValue

---@class SnowMediaTimelineDataValue
---@field timeline SnowMediaTimelineValue

---@class SnowMediaArtworkDataValue
---@field sessionId string Opaque current media session identifier.
---@field image SnowImageResource Temporary host-decoded image resource handle.
---@field width integer Decoded pixel width, at most 512.
---@field height integer Decoded pixel height, at most 512.

---@class SnowDesktopItemDataValue
---@field id string Stable host reference; never an absolute path.
---@field title string
---@field source string
---@field type string
---@field selected boolean

---@class SnowDesktopItemsDataValue
---@field items SnowDesktopItemDataValue[] At most 2048 entries.
---@field revision integer

---@class SnowDesktopSelectionDataValue
---@field items SnowDesktopItemDataValue[] At most 512 entries.
---@field revision integer

---@class SnowDesktopChangesDataValue
---@field revision integer
---@field reason string Bounded host change reason.

---@class SnowCalendarEventDataValue
---@field id string
---@field revision integer
---@field title string
---@field date string YYYY-MM-DD.
---@field allDay boolean
---@field startMinutes integer
---@field endMinutes integer
---@field notes string
---@field reminderMinutes integer Negative when disabled.

---@class SnowCalendarEventsDataValue
---@field events SnowCalendarEventDataValue[] At most 512 entries.
---@field fromDate string Inclusive range start.
---@field toDate string Inclusive range end.
---@field revision integer
---@field truncated boolean

---@class SnowCalendarSelectedDateDataValue
---@field date string YYYY-MM-DD.
---@field revision integer

---@class SnowAppIndexStatusDataValue
---@field state 'ready'|'indexing'|'error'|'unavailable'
---@field revision integer

---@class SnowFilesystemWatchEvent
---@field kind 'added'|'removed'|'modified'|'renamed'
---@field name string Display-only direct child name.
---@field oldName? string Display-only previous name for renamed events.
---@field handle? string Opaque child handle when the child still exists and can be granted.
---@field itemKind? 'file'|'folder'

---@class SnowFilesystemWatchDataValue
---@field events SnowFilesystemWatchEvent[] At most 256 coalesced direct-child events.
---@field revision integer
---@field overflow boolean True when changes were lost and the caller should run filesystem.list again.

---@class SnowDataSnapshot<T>
---@field available boolean
---@field value? T
---@field timestamp integer Epoch milliseconds, or zero before a sample exists.
---@field stale boolean
---@field warmingUp boolean
---@field error? string

---@class SnowDataSubscription<T>
---@field value fun(self: SnowDataSubscription<T>): SnowDataSnapshot<T>
---@field unsubscribe fun(self: SnowDataSubscription<T>): boolean

---@class snow.data
data = {}

---Subscribe to a host-shared on-demand data topic.
---@overload fun(topic: 'system.cpu', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowCpuDataValue>
---@overload fun(topic: 'system.memory', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowMemoryDataValue>
---@overload fun(topic: 'process.summary', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowProcessSummaryDataValue>
---@overload fun(topic: 'system.gpu', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowGpuDataValue>
---@overload fun(topic: 'system.power', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowPowerDataValue>
---@overload fun(topic: 'system.network.status', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowNetworkStatusDataValue>
---@overload fun(topic: 'system.network.traffic', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowNetworkTrafficDataValue>
---@overload fun(topic: 'system.storage.volumes', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowStorageVolumesDataValue>
---@overload fun(topic: 'system.storage.io', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowStorageIoDataValue>
---@overload fun(topic: 'system.display.topology', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowDisplayTopologyDataValue>
---@overload fun(topic: 'system.display.current', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowDisplayCurrentDataValue>
---@overload fun(topic: 'audio.output.default', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowAudioOutputDefaultDataValue>
---@overload fun(topic: 'audio.output.volume', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowAudioOutputVolumeDataValue>
---@overload fun(topic: 'audio.output.analysis', options?: SnowAudioAnalysisSubscribeOptions): SnowDataSubscription<SnowAudioOutputAnalysisDataValue>
---@overload fun(topic: 'media.sessions', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowMediaSessionsDataValue>
---@overload fun(topic: 'media.current', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowMediaCurrentDataValue>
---@overload fun(topic: 'media.timeline', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowMediaTimelineDataValue>
---@overload fun(topic: 'media.artwork', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowMediaArtworkDataValue>
---@overload fun(topic: 'desktop.items', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowDesktopItemsDataValue>
---@overload fun(topic: 'desktop.selection', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowDesktopSelectionDataValue>
---@overload fun(topic: 'desktop.changes', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowDesktopChangesDataValue>
---@overload fun(topic: 'calendar.events', options?: SnowCalendarEventsSubscribeOptions): SnowDataSubscription<SnowCalendarEventsDataValue>
---@overload fun(topic: 'calendar.selectedDate', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowCalendarSelectedDateDataValue>
---@overload fun(topic: 'app.indexStatus', options?: SnowDataSubscribeOptions): SnowDataSubscription<SnowAppIndexStatusDataValue>
---@overload fun(topic: 'filesystem.watch', options: SnowFilesystemWatchSubscribeOptions): SnowDataSubscription<SnowFilesystemWatchDataValue>
---@param topic string
---@param options? SnowDataSubscribeOptions
---@return SnowDataSubscription<table>
function data.subscribe(topic, options) end

---@class SnowAcceptedTaskValue
---@field accepted boolean Whether the host or OS accepted the requested operation.

---@class SnowMediaTaskValue
---@field accepted boolean The OS media action accepted the request, or true for the deterministic preview mock.

---@class SnowMediaSessionArguments
---@field sessionId? string Opaque ID from media.sessions/current; omit to target the current Windows session.

---@class SnowMediaSeekArguments: SnowMediaSessionArguments
---@field positionMs integer Non-negative position relative to the session timeline start.

---@class SnowMediaRateArguments: SnowMediaSessionArguments
---@field rate number Finite positive playback rate supported by the target session.

---@class SnowMediaShuffleArguments: SnowMediaSessionArguments
---@field shuffle boolean Requested shuffle state.

---@class SnowMediaRepeatArguments: SnowMediaSessionArguments
---@field mode 'none'|'track'|'list' Requested repeat mode.

---@class SnowAudioOutputTaskValue
---@field accepted boolean The default endpoint accepted the request, or true for the deterministic preview mock.

---@class SnowAudioOutputVolumeArguments
---@field volume number Finite scalar clamped by the host to 0.0 through 1.0.

---@class SnowAudioOutputMuteArguments
---@field muted boolean Requested master mute state.

---@class SnowSystemSettingsArguments
---@field page 'notifications'|'audio'|'display'|'network'|'bluetooth'|'power'|'storage'|'apps'|'personalization' Host-maintained settings page name.

---@class SnowSystemSettingsTaskValue
---@field accepted boolean Whether Windows accepted the settings URI, or true for the deterministic preview mock.

---@class SnowClipboardReadArguments
---@field format 'text'|'image'|'file-reference' Explicit bounded clipboard format to read.

---@class SnowClipboardWriteArguments
---@field format 'text' The only clipboard format currently exposed by v2.
---@field text string Valid UTF-8 containing at most 262144 bytes and no NUL.

---@class SnowClipboardTextReadTaskValue
---@field format 'text'
---@field text string Bounded UTF-8 clipboard text.

---@class SnowClipboardImageReadTaskValue
---@field format 'image'
---@field image SnowImageResource Temporary instance-scoped image handle for draw.image or view.image.source; do not persist it.
---@field width integer Decoded width after host scaling, from 1 through 512.
---@field height integer Decoded height after host scaling, from 1 through 512.

---@class SnowClipboardFileReference
---@field ref string Opaque instance-scoped item reference accepted by draw.icon and shell.openItem/revealItem; never a path or file-content grant.
---@field name string Display-only file or folder name.
---@field type 'file'|'folder'

---@class SnowClipboardFileReferenceReadTaskValue
---@field format 'file-reference'
---@field items SnowClipboardFileReference[] At most 32 current clipboard file references.

---@alias SnowClipboardReadTaskValue SnowClipboardTextReadTaskValue|SnowClipboardImageReadTaskValue|SnowClipboardFileReferenceReadTaskValue

---@class SnowFilesystemPickOpenArguments
---@field extensions? string[] Up to 16 safe extension names without wildcards, for example {'png', 'jpg'}.

---@class SnowFilesystemPickSaveArguments: SnowFilesystemPickOpenArguments
---@field suggestedName? string File name only; absolute and relative paths are rejected.

---@class SnowFilesystemPickFolderArguments
---@field access? 'read'|'write'|'readWrite' Defaults to read and requires each corresponding declared permission.

---@class SnowFilesystemPickerTaskValue
---@field handle string Persistent opaque handle scoped to this widget instance and package; never a filesystem path.
---@field kind 'file'|'folder'
---@field access 'read'|'write'|'readWrite'
---@field name string Display-only selected item name.

---@class SnowFilesystemHandleArguments
---@field handle string Opaque handle returned by a filesystem picker or list task.

---@class SnowFilesystemListArguments: SnowFilesystemHandleArguments
---@field offset? integer Entry offset from 0 through 10000; defaults to 0.
---@field limit? integer Entry count from 1 through 100; defaults to 50.

---@class SnowFilesystemReadArguments: SnowFilesystemHandleArguments
---@field encoding? 'utf8'|'binary' Defaults to utf8; binary returns an exact byte string in data.
---@field maxBytes? integer Caller byte ceiling from 1 through 1048576; defaults to 524288.

---@class SnowFilesystemTextWriteArguments: SnowFilesystemHandleArguments
---@field encoding? 'utf8' Defaults to utf8.
---@field text string Valid UTF-8 containing at most 1048576 bytes and no NUL.
---@field expectedRevision? string Revision returned by stat/read/write; a mismatch rejects the write with conflict.

---@class SnowFilesystemBinaryWriteArguments: SnowFilesystemHandleArguments
---@field encoding 'binary'
---@field data string Exact byte string containing at most 1048576 bytes; embedded NUL and non-UTF-8 bytes are preserved.
---@field expectedRevision? string Revision returned by stat/read/write; a mismatch rejects the write with conflict.

---@alias SnowFilesystemWriteArguments SnowFilesystemTextWriteArguments|SnowFilesystemBinaryWriteArguments

---@class SnowFilesystemMetadata
---@field handle string Opaque instance-and-package-scoped handle.
---@field kind 'file'|'folder'
---@field name string Display-only item name; never a path.
---@field size? integer File byte count; absent for folders.
---@field modifiedMs integer Unix epoch milliseconds.
---@field readOnly boolean
---@field revision string Opaque conflict-detection revision.

---@class SnowFilesystemListTaskValue
---@field items SnowFilesystemMetadata[] Direct children only; reparse points are omitted.
---@field nextOffset integer
---@field hasMore boolean

---@class SnowFilesystemTextReadTaskValue
---@field encoding 'utf8'
---@field text string
---@field size integer
---@field revision string

---@class SnowFilesystemBinaryReadTaskValue
---@field encoding 'binary'
---@field data string Exact byte string; Lua length and substring operations are binary-safe.
---@field size integer
---@field revision string

---@alias SnowFilesystemReadTaskValue SnowFilesystemTextReadTaskValue|SnowFilesystemBinaryReadTaskValue

---@class SnowFilesystemWriteTaskValue
---@field accepted boolean
---@field size integer
---@field modifiedMs integer
---@field revision string

---@class SnowAppSearchArguments
---@field query string UTF-8 query containing 1 to 256 bytes.
---@field limit? integer Result count from 1 through 100; defaults to 50.
---@field offset? integer Ranked result offset from 0 through 10000; defaults to 0.

---@class SnowAppSearchItem
---@field ref string Opaque, instance-scoped application reference accepted by app.launch.
---@field title string
---@field source string
---@field type 'application'|string

---@class SnowAppSearchTaskValue
---@field items SnowAppSearchItem[]
---@field nextOffset integer
---@field hasMore boolean
---@field catalogRevision integer

---@class SnowAppLaunchArguments
---@field ref string An opaque ref returned by app.search for this widget instance.

---@class SnowItemSearchArguments
---@field query string UTF-8 query containing 1 to 256 bytes.
---@field limit? integer Result count from 1 through 100; defaults to 50.
---@field offset? integer Result offset from 0 through 100; defaults to 0.

---@class SnowItemSearchItem
---@field ref string Opaque, instance-scoped item reference accepted by shell.openItem and shell.revealItem.
---@field title string
---@field source string
---@field type string

---@class SnowItemSearchTaskValue
---@field items SnowItemSearchItem[]
---@field nextOffset integer
---@field hasMore boolean
---@field revision integer

---@class SnowItemReferenceArguments
---@field ref string An opaque ref returned by desktop.search or everything.search for this widget instance.

---@class SnowNotificationAction
---@field id string Unique action ID containing 1 to 64 bytes of valid UTF-8.
---@field label string Button label containing 1 to 64 bytes of valid UTF-8.

---@class SnowNotificationShowArguments
---@field title string Valid UTF-8 containing 1 to 256 bytes.
---@field message string Valid UTF-8 containing 1 to 2048 bytes.
---@field image? SnowImageResource Package resource.image handle; runtime image handles are not accepted.
---@field progress? number Progress from 0 through 1.
---@field actions? SnowNotificationAction[] Up to two buttons. Activation emits notification.action as a trusted gesture.

---@class SnowNotificationScheduleArguments: SnowNotificationShowArguments
---@field atMs integer Future Unix epoch time in milliseconds, no more than 366 days away.

---@class SnowNotificationUpdateArguments
---@field notificationId string Opaque ID returned by notification.show or notification.schedule.
---@field title? string Replacement title.
---@field message? string Replacement message.
---@field image? SnowImageResource|false Replacement package image, or false to clear it.
---@field progress? number|false Replacement progress from 0 through 1, or false to clear it.
---@field actions? SnowNotificationAction[] Replacement buttons; an empty array clears them. At least one content field is required.

---@class SnowNotificationReferenceArguments
---@field notificationId string Opaque ID returned for this widget instance.

---@class SnowNotificationTaskValue
---@field notificationId string Host-issued opaque notification ID returned by show and schedule.

---@class SnowCalendarEventArguments
---@field title string Valid UTF-8 containing 1 to 512 bytes.
---@field date string Valid YYYY-MM-DD date.
---@field allDay boolean
---@field startMinutes integer 0 through 1439.
---@field endMinutes integer 0 through 1439 and not before startMinutes for timed events.
---@field notes string Valid UTF-8 containing at most 8192 bytes.
---@field reminderMinutes -1|0|5|15|30|60|1440

---@class SnowCalendarUpdateArguments: SnowCalendarEventArguments
---@field id string Host-issued event ID.
---@field expectedRevision integer Positive revision from calendar.events.

---@class SnowCalendarRemoveArguments
---@field id string Host-issued event ID.

---@class SnowCalendarMutationTaskValue
---@field id string Host-issued event ID; preserved for update/remove.
---@field revision integer New revision for create/update; zero for remove.

---@class SnowNetworkRequestArguments
---@field url string Public HTTPS URL; optional widget.json networkDomains narrows it to exact declared hostnames.
---@field method? 'GET'|'HEAD'|'POST'|'PUT'|'PATCH'|'DELETE' Defaults to GET.
---@field headers? table<string, string|SnowNetworkSecretDescriptor> Up to 32 single-line headers and 32 KiB after host injection.
---@field body? string|SnowNetworkSecretDescriptor Raw bytes up to 64 KiB; a descriptor injects one host-managed secret segment.
---@field timeoutMs? integer 1000 through 30000; defaults to 15000.
---@field cacheSeconds? integer 0 through 86400; defaults to 0.
---@field maxBytes? integer 4096 through 1048576; defaults to 524288.

---@class SnowNetworkSecretDescriptor
---@field secretRef string Opaque reference returned by storage.get for a declared password setting in this instance.
---@field prefix? string Host prepends these bytes before the secret. Header affixes must be single-line UTF-8.
---@field suffix? string Host appends these bytes after the secret. No JSON or URL escaping is applied.

---@class SnowNetworkTaskValue
---@field status integer Successful 2xx HTTP status.
---@field body string Response bytes, bounded by maxBytes.
---@field fromCache boolean Whether the response came from the instance-scoped HTTP cache.

---@class SnowShellOpenUriArguments
---@field url string Public HTTPS URL without embedded credentials.

---@class snow.task
task = {}

---Start an asynchronous one-shot task. Search, notification, calendar
---create/update, and network tasks do not require a gesture. Launch, open,
---reveal, refresh, media/audio controls, shell.openUri, and calendar removal do.
---Filesystem pickers also require the current trusted user gesture.
---Runtime rejections return nil plus a stable error code.
---@overload fun(name: 'media.play'|'media.pause'|'media.toggle'|'media.stop'|'media.next'|'media.previous', arguments?: SnowMediaSessionArguments): taskId: integer?, error: string?
---@overload fun(name: 'media.seek', arguments: SnowMediaSeekArguments): taskId: integer?, error: string?
---@overload fun(name: 'media.setRate', arguments: SnowMediaRateArguments): taskId: integer?, error: string?
---@overload fun(name: 'media.setShuffle', arguments: SnowMediaShuffleArguments): taskId: integer?, error: string?
---@overload fun(name: 'media.setRepeat', arguments: SnowMediaRepeatArguments): taskId: integer?, error: string?
---@overload fun(name: 'audio.output.setVolume', arguments: SnowAudioOutputVolumeArguments): taskId: integer?, error: string?
---@overload fun(name: 'audio.output.setMute', arguments: SnowAudioOutputMuteArguments): taskId: integer?, error: string?
---@overload fun(name: 'system.openSettings', arguments: SnowSystemSettingsArguments): taskId: integer?, error: string?
---@overload fun(name: 'clipboard.read', arguments: SnowClipboardReadArguments): taskId: integer?, error: string?
---@overload fun(name: 'clipboard.write', arguments: SnowClipboardWriteArguments): taskId: integer?, error: string?
---@overload fun(name: 'clipboard.clear'): taskId: integer?, error: string?
---@overload fun(name: 'filesystem.pickOpen', arguments?: SnowFilesystemPickOpenArguments): taskId: integer?, error: string?
---@overload fun(name: 'filesystem.pickSave', arguments?: SnowFilesystemPickSaveArguments): taskId: integer?, error: string?
---@overload fun(name: 'filesystem.pickFolder', arguments?: SnowFilesystemPickFolderArguments): taskId: integer?, error: string?
---@overload fun(name: 'filesystem.stat', arguments: SnowFilesystemHandleArguments): taskId: integer?, error: string?
---@overload fun(name: 'filesystem.list', arguments: SnowFilesystemListArguments): taskId: integer?, error: string?
---@overload fun(name: 'filesystem.read', arguments: SnowFilesystemReadArguments): taskId: integer?, error: string?
---@overload fun(name: 'filesystem.write', arguments: SnowFilesystemWriteArguments): taskId: integer?, error: string?
---@overload fun(name: 'filesystem.release', arguments: SnowFilesystemHandleArguments): taskId: integer?, error: string?
---@overload fun(name: 'app.search', arguments: SnowAppSearchArguments): taskId: integer?, error: string?
---@overload fun(name: 'app.launch', arguments: SnowAppLaunchArguments): taskId: integer?, error: string?
---@overload fun(name: 'desktop.search', arguments: SnowItemSearchArguments): taskId: integer?, error: string?
---@overload fun(name: 'everything.search', arguments: SnowItemSearchArguments): taskId: integer?, error: string?
---@overload fun(name: 'shell.openItem', arguments: SnowItemReferenceArguments): taskId: integer?, error: string?
---@overload fun(name: 'shell.revealItem', arguments: SnowItemReferenceArguments): taskId: integer?, error: string?
---@overload fun(name: 'desktop.refresh'): taskId: integer?, error: string?
---@overload fun(name: 'notification.show', arguments: SnowNotificationShowArguments): taskId: integer?, error: string?
---@overload fun(name: 'notification.update', arguments: SnowNotificationUpdateArguments): taskId: integer?, error: string?
---@overload fun(name: 'notification.dismiss', arguments: SnowNotificationReferenceArguments): taskId: integer?, error: string?
---@overload fun(name: 'notification.schedule', arguments: SnowNotificationScheduleArguments): taskId: integer?, error: string?
---@overload fun(name: 'notification.cancel', arguments: SnowNotificationReferenceArguments): taskId: integer?, error: string?
---@overload fun(name: 'calendar.create', arguments: SnowCalendarEventArguments): taskId: integer?, error: string?
---@overload fun(name: 'calendar.update', arguments: SnowCalendarUpdateArguments): taskId: integer?, error: string?
---@overload fun(name: 'calendar.remove', arguments: SnowCalendarRemoveArguments): taskId: integer?, error: string?
---@overload fun(name: 'network.request', arguments: SnowNetworkRequestArguments): taskId: integer?, error: string?
---@overload fun(name: 'shell.openUri', arguments: SnowShellOpenUriArguments): taskId: integer?, error: string?
---@param name 'media.play'|'media.pause'|'media.toggle'|'media.stop'|'media.next'|'media.previous'|'media.seek'|'media.setRate'|'media.setShuffle'|'media.setRepeat'|'audio.output.setVolume'|'audio.output.setMute'|'system.openSettings'|'clipboard.read'|'clipboard.write'|'clipboard.clear'|'filesystem.pickOpen'|'filesystem.pickSave'|'filesystem.pickFolder'|'filesystem.stat'|'filesystem.list'|'filesystem.read'|'filesystem.write'|'filesystem.release'|'app.search'|'app.launch'|'desktop.search'|'everything.search'|'shell.openItem'|'shell.revealItem'|'desktop.refresh'|'notification.show'|'notification.update'|'notification.dismiss'|'notification.schedule'|'notification.cancel'|'calendar.create'|'calendar.update'|'calendar.remove'|'network.request'|'shell.openUri'
---@param arguments? table Strict task-specific argument table.
---@return integer? taskId
---@return string? error
function task.start(name, arguments) end

---Request cancellation of a task owned by the current Lua VM.
---@param taskId integer
---@return boolean canceled
function task.cancel(taskId) end

---@class snow.system
system = {}

---@return SnowSystemInfo
function system.info() end

---@overload fun(featureOrApi: string): SnowCapability
---@return SnowCapabilities
function system.capabilities() end

---@return SnowSystemUptime
function system.uptime() end

---@class snow.time
time = {}

---@return integer epochMilliseconds
function time.now() end

---@return integer monotonicMilliseconds
function time.monotonic() end

---@param epochMilliseconds? integer
---@param timeZone? 'local'|'utc'|string
---@return SnowDateTimeParts
function time.parts(epochMilliseconds, timeZone) end

---@param epochMilliseconds? integer
---@param options? SnowTimeFormatOptions
---@return string
function time.format(epochMilliseconds, options) end

---@param epochMilliseconds integer
---@param delta SnowTimeDelta
---@param options? SnowTimeZoneOptions
---@return integer
function time.add(epochMilliseconds, delta, options) end

---@param left integer
---@param right integer
---@return -1|0|1
function time.compare(left, right) end

---@class SnowCalendarDateInfo
---@field year integer
---@field month integer
---@field day integer
---@field weekday integer 1 is Sunday.
---@field daysInMonth integer

---@class snow.calendar
calendar = {}

---Return Gregorian date fields without reading user calendar data.
---@param date string ISO YYYY-MM-DD.
---@return SnowCalendarDateInfo?
function calendar.dateInfo(date) end

---Add a bounded number of Gregorian days without reading user calendar data.
---@param date string ISO YYYY-MM-DD.
---@param offset integer From -366000 through 366000.
---@return string? date
function calendar.addDays(date, offset) end

---Change SnowDesktop's shared local calendar selection. This does not create,
---modify, or remove a calendar event and requires no calendar.write permission.
---@param date string ISO YYYY-MM-DD.
---@return boolean selected
function calendar.selectDate(date) end

---@class snow.l10n
l10n = {}

---@param key string
---@param ... string|number|boolean
---@return string
function l10n.tr(key, ...) end

---@return string
function l10n.language() end

---@param value number
---@param options? SnowNumberFormatOptions
---@return string
function l10n.formatNumber(value, options) end

---@param bytes number
---@param options? SnowBytesFormatOptions
---@return string
function l10n.formatBytes(bytes, options) end

---@param milliseconds integer
---@param options? SnowDurationFormatOptions
---@return string
function l10n.formatDuration(milliseconds, options) end

---@param deltaMilliseconds integer
---@param options? SnowRelativeTimeFormatOptions
---@return string
function l10n.formatRelativeTime(deltaMilliseconds, options) end

---@param values string[]
---@param options? SnowLocaleOptions
---@return string
function l10n.formatList(values, options) end

---@class snow.module
module = {}

---Load one package-relative .lua module during entry evaluation.
---@generic T
---@param path string
---@return T
function module.require(path) end

---@class snow.resource
resource = {}

---@param name string
---@return boolean
function resource.exists(name) end

---Create a declared image handle synchronously during entry evaluation. Failure raises `resource.image: <SnowResourceLoadError>`.
---@param name string
---@return SnowImageResource
function resource.image(name) end

---Create a declared package-private font handle synchronously during entry evaluation. Failure raises `resource.font: <SnowResourceLoadError>`.
---@param name string
---@return SnowFontResource
function resource.font(name) end

---@param handle SnowImageResource|SnowFontResource Invalid handles raise `resource.status: invalidHandle`.
---@return SnowResourceStatus
function resource.status(handle) end

---@class snow.draw
draw = {}

---@param x number
---@param y number
---@param text string
---@param size? number
---@param color? integer
---@param maxWidth? number
---@param bold? boolean
---@param singleLine? boolean
---@param maxHeight? number
---@param alpha? number
---@param font? SnowFontResource
function draw.text(x, y, text, size, color, maxWidth, bold, singleLine, maxHeight, alpha, font) end

---Draw single-line overflow text with a host-native continuous marquee. Requires draw.marqueeText and a declared required/optional feature. The host caches the remaining immediate drawing and advances visible desktop frames without re-entering Lua.
---@param options SnowMarqueeTextOptions
---@return boolean scrolling True when text exceeds the viewport; reduced-motion and preview surfaces still render it statically.
function draw.marqueeText(options) end

---@param text string
---@param size? number
---@param maxWidth? number
---@param bold? boolean
---@param font? SnowFontResource
---@return SnowTextMetrics
function draw.measureText(text, size, maxWidth, bold, font) end

---@param image SnowImageResource
---@param x number
---@param y number
---@param width number
---@param height number
---@param alpha? number
function draw.image(image, x, y, width, height, alpha) end

---Draw a declared image using bounded aspect-ratio placement. Requires draw.advanced.
---@param image SnowImageResource
---@param x number
---@param y number
---@param width number
---@param height number
---@param fit? SnowDrawImageFit Defaults to contain.
---@param alignment? SnowDrawImageAlignment Applies to both axes; defaults to center.
---@param alpha? number
---@param interpolation? SnowDrawImageInterpolation Defaults to linear.
function draw.imageFit(image, x, y, width, height, fit, alignment, alpha, interpolation) end

---@param x number
---@param y number
---@param width number
---@param height number
---@param color? integer
---@param radius? number
---@param alpha? number
function draw.rect(x, y, width, height, color, radius, alpha) end

---@param x number
---@param y number
---@param width number
---@param height number
---@param color? integer
---@param radius? number
---@param thickness? number
---@param alpha? number
function draw.strokeRect(x, y, width, height, color, radius, thickness, alpha) end

---@param x number
---@param y number
---@param width number
---@param height number
function draw.pushClip(x, y, width, height) end

function draw.popClip() end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param thickness? number
---@param color? integer
---@param alpha? number
function draw.line(x1, y1, x2, y2, thickness, color, alpha) end

---Draw an arc. Zero degrees points right and positive sweeps run clockwise. Requires draw.advanced.
---@param centerX number
---@param centerY number
---@param radius number
---@param startDegrees number
---@param sweepDegrees number Non-zero and at most one turn in either direction.
---@param thickness? number
---@param color? integer
---@param alpha? number
function draw.arc(centerX, centerY, radius, startDegrees, sweepDegrees, thickness, color, alpha) end

---Draw a strict path containing at most 256 commands. Requires draw.advanced.
---@param commands SnowDrawPathCommand[] Must begin with move and contain a drawable segment.
---@param options? SnowDrawPathOptions
function draw.path(commands, options) end

---Fill a bounded rectangle with a two-stop linear gradient. Requires draw.advanced.
---@param x number
---@param y number
---@param width number
---@param height number
---@param startColor? integer
---@param endColor? integer
---@param direction? SnowDrawGradientDirection Defaults to vertical.
---@param radius? number
---@param alpha? number
function draw.gradientRect(x, y, width, height, startColor, endColor, direction, radius, alpha) end

---Draw a bounded soft shadow using at most 16 host falloff layers. Requires draw.advanced.
---@param x number
---@param y number
---@param width number
---@param height number
---@param color? integer
---@param blur? number Between 0 and 64; defaults to 12.
---@param radius? number At most half the shortest side.
---@param offsetX? number
---@param offsetY? number Defaults to 4.
---@param alpha? number
function draw.shadow(x, y, width, height, color, blur, radius, offsetX, offsetY, alpha) end

---Draw 1 to 512 finite samples across a bounded rectangle. Requires draw.advanced.
---@param values number[]
---@param x number
---@param y number
---@param width number
---@param height number
---@param color? integer
---@param thickness? number
---@param minimum? number Must be supplied together with maximum and be smaller.
---@param maximum? number Must be supplied together with minimum and be larger.
---@param alpha? number
function draw.sparkline(values, x, y, width, height, color, thickness, minimum, maximum, alpha) end

---@param centerX number
---@param centerY number
---@param radius number
---@param color? integer
---@param alpha? number
function draw.circle(centerX, centerY, radius, color, alpha) end

---@param glyph string
---@param x number
---@param y number
---@param size? number
---@param color? integer
function draw.fa(glyph, x, y, size, color) end

---@param glyph string
---@param x number
---@param y number
---@param size? number
---@param color? integer
function draw.fluent(glyph, x, y, size, color) end

---Draw the Shell icon for an opaque ref returned by app.search,
---desktop.search, or everything.search. Requires desktop.read.
---@param reference string
---@param x number
---@param y number
---@param size? number
---@param alpha? number
function draw.icon(reference, x, y, size, alpha) end

---@class snow.interaction
interaction = {}

---Submit one semantic hit region for the current successful desktop render.
---The complete active set is atomically replaced after render returns.
---@param region SnowInteractionRegion
function interaction.region(region) end

---@param key string
---@return boolean
function interaction.isHovered(key) end

---@param key string
---@return boolean
function interaction.isPressed(key) end

---Return whether this region owns the current host keyboard focus. Requires interaction.keyboard.
---@param key string
---@return boolean
function interaction.isFocused(key) end

---Register a vertical or horizontal scroll viewport for the current render and
---return its instance-scoped main-axis position. Pair it with
---draw.pushClip/popClip and translate drawing by the returned offset.
---@param descriptor SnowInteractionScrollDescriptor
---@return SnowInteractionScrollState
function interaction.scroll(descriptor) end

---Set a scroll viewport after it has been registered in the current render.
---@param key string
---@param offset integer
---@return integer actualOffset
function interaction.setScrollOffset(key, offset) end

---@class snow.control
control = {}

---Submit one storage-bound Direct2D single-line editor during render. The host
---owns caret, selection, clipboard normalization, IME composition and quota.
---@param descriptor SnowTextInputDescriptor
---@return string value
function control.textInput(descriptor) end

---Submit one storage-bound Direct2D multiline editor during render. Enter adds
---a line, Ctrl+Enter commits, Escape restores the pre-focus value, and wheel
---scrolling remains scoped to the control.
---@param descriptor SnowTextAreaDescriptor
---@return string value
function control.textArea(descriptor) end

---Accept a host focus request from a direct trusted action/menu/open callback.
---With view.focus.request, the key may identify any focusable declarative node;
---otherwise it identifies a submitted text control. A target added by that action
---is focused after the next successful
---render of the same surface. Calls from render, schedules and asynchronous
---completions return false.
---@param key string
---@return boolean accepted
---@return 'trustedGestureRequired'|'controlNotFound'|'hostUnavailable'|nil error
function control.focus(key) end

---Commit and blur the matching focused text control from a direct trusted
---action/menu/open callback. Returns false without changing another control's
---focus when the key or surface does not match.
---@param key string
---@return boolean blurred
---@return 'trustedGestureRequired'|'controlNotFocused'|'hostUnavailable'|nil error
function control.blur(key) end

---@class snow.ui
ui = {}

---Return a synchronous menu model from widget.define.menu.
---@param items SnowMenuModel
---@return SnowMenuModel
function ui.menu(items) end

---@class snow.layout
layout = {}

---@return number
function layout.width() end

---@return number
function layout.height() end

---@return number
function layout.contentWidth() end

---@return number
function layout.contentHeight() end

---@param percent number 0..100 percentage of the root content width.
---@return number
function layout.vw(percent) end

---@param percent number 0..100 percentage of the root content height.
---@return number
function layout.vh(percent) end

---@param percent number 0..100 percentage of the shorter root content axis.
---@return number
function layout.vmin(percent) end

---@param percent number 0..100 percentage of the longer root content axis.
---@return number
function layout.vmax(percent) end

---@return integer
function layout.columns() end

---@return integer
function layout.rows() end

---@return SnowWidgetSizeClass
function layout.sizeClass() end

---@return integer
function layout.cellWidth() end

---@return integer
function layout.cellHeight() end

---@return number
function layout.cellScale() end

---@param value number
---@return integer
function layout.cu(value) end

---@param value number
---@return number
function layout.fontCu(value) end

---@return integer
function layout.cellGap() end

---@return integer
function layout.barHeight() end

---@class snow.storage
storage = {}

---@class SnowStorageTransaction
local SnowStorageTransaction = {}

---Read the current staged typed value. Missing keys and stored null return nil; use keys to distinguish them.
---@param key string
---@return SnowStateValue?
function SnowStorageTransaction:get(key) end

---Stage a bounded JSON-like value. The final snapshot is quota-checked at commit.
---@param key string
---@param value SnowStateValue
---@return boolean changed
function SnowStorageTransaction:set(key, value) end

---Stage removal of a key.
---@param key string
---@return boolean changed
function SnowStorageTransaction:remove(key) end

---@param key string
---@return SnowStateValue?
function storage.get(key) end

---@param key string
---@param value SnowStateValue
function storage.set(key, value) end

---@param key string
function storage.remove(key) end

---@return string[]
function storage.keys() end

---Atomically commit staged typed writes after the callback succeeds.
---The transaction is rolled back on callback error, quota failure, or disk failure.
---@param callback fun(transaction: SnowStorageTransaction)
---@return boolean changed
function storage.transaction(callback) end

---@class snow.state
state = {}

---Return a deep copy of transient instance state or the supplied default.
---@generic T: SnowStateValue
---@param key string
---@param default? T
---@return T?
function state.get(key, default) end

---Store a deep copy. Returns false when the value is unchanged.
---@param key string
---@param value SnowStateValue
---@return boolean changed
function state.set(key, value) end

---@param key string
---@return boolean changed
function state.remove(key) end

---@param key string
---@return boolean
function state.has(key) end

---@return string[]
function state.keys() end

---@return boolean changed
function state.clear() end

---@type string
widgetId = ''
