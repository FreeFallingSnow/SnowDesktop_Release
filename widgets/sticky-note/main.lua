-- sticky-note/main.lua - API v2 storage-bound Direct2D note editor
local descriptor
local noteTheme = module.require("modules/theme.lua")

local fluent = {
    clear = utf8.char(0xE5E4),
    style = utf8.char(0xF592),
}

local presetTextColors = noteTheme.presetTextColors

local settings = {
    presets = {
        {
            id = "classic",
            label = l10n.tr("lua_widget.sticky_note.preset_yellow"),
            default = true,
            values = {
                bg = 0xFFF7D1,
                border = 0xD0D0D0,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
            },
        },
        {
            id = "white",
            label = l10n.tr("lua_widget.sticky_note.preset_white"),
            values = {
                bg = 0xFFFFFF,
                border = 0xD6D6D6,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
            },
        },
        {
            id = "pink",
            label = l10n.tr("lua_widget.sticky_note.preset_pink"),
            values = {
                bg = 0xFFE1EC,
                border = 0xE8AFC2,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
            },
        },
        {
            id = "blue",
            label = l10n.tr("lua_widget.sticky_note.preset_blue"),
            values = {
                bg = 0xDCEBFF,
                border = 0x9DBBE6,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
            },
        },
        {
            id = "green",
            label = l10n.tr("lua_widget.sticky_note.preset_green"),
            values = {
                bg = 0xDFF7E7,
                border = 0x9ACDAA,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
            },
        },
        {
            id = "purple",
            label = l10n.tr("lua_widget.sticky_note.preset_purple"),
            values = {
                bg = 0xEDE2FF,
                border = 0xBFA7E8,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
            },
        },
        {
            id = "dark",
            label = l10n.tr("lua_widget.sticky_note.preset_dark"),
            values = {
                bg = 0x20242C,
                border = 0x3E4654,
                alpha = 1.0,
                borderAlpha = 0.95,
                gradientEndA = 0.0,
            },
        },
    },
    fields = {
        {
            key = "fontSize",
            label = l10n.tr("lua_widget.common.font_size"),
            type = "int",
            default = 15,
            min = 10,
            max = 24,
        },
    },
}

local function loadStyle()
    descriptor.bg = tonumber(storage.get("bg")) or 0xFFF7D1
    descriptor.border = tonumber(storage.get("border")) or 0xD0D0D0
    descriptor.alpha = tonumber(storage.get("alpha")) or 1.0
    descriptor.borderAlpha = tonumber(storage.get("borderAlpha")) or 0.85
    descriptor.gradientEndA = tonumber(storage.get("gradientEndA")) or 0.0
    if storage.get("followPersonalization") == "1" then
        local theme = widget.theme()
        if theme and theme.bg then
            descriptor.bg = theme.bg
            descriptor.border = theme.border or descriptor.border
            descriptor.alpha = theme.alpha or descriptor.alpha
            descriptor.borderAlpha = theme.borderAlpha or
                descriptor.borderAlpha
            descriptor.gradientEndA = theme.gradientEndA or
                descriptor.gradientEndA
        end
    end
end

local function textColor()
    local theme = widget.theme()
    return noteTheme.resolveTextColor(storage.get("__preset"),
        storage.get("followPersonalization") == "1",
        theme and theme.contentTheme or nil)
end

local function fontSize()
    return math.max(10, math.min(24,
        tonumber(storage.get("fontSize")) or 15))
end

local function resetDefaults()
    storage.set("bg", tostring(0xFFF7D1))
    storage.set("border", tostring(0xD0D0D0))
    storage.set("alpha", "1")
    storage.set("borderAlpha", "0.85")
    storage.set("gradientEndA", "0")
    storage.set("fontSize", "15")
    storage.set("followPersonalization", "1")
    storage.set("__preset", "classic")
end

local function setup()
    widget.setTitle(l10n.tr("lua_widget.sticky_note.name"))
end

local function render()
    loadStyle()
    local width = layout.width()
    local height = layout.height()
    local padding = layout.cu(14)
    local bottomBarHeight = layout.cu(layout.barHeight())
    local shape = {
        type = "rect",
        x = padding,
        y = padding,
        width = math.max(1, width - padding * 2),
        height = math.max(1, height - padding - bottomBarHeight),
    }
    local color = textColor()
    control.textArea({
        key = "note",
        storageKey = "text",
        shape = shape,
        placeholder = l10n.tr("lua_widget.sticky_note.empty_hint"),
        placeholderWhenWhitespace = true,
        fontSize = layout.fontCu(fontSize()),
        textColor = color,
        placeholderColor = color,
        backgroundColor = color,
        borderColor = color,
        focusedBorderColor = color,
        backgroundAlpha = 0.0,
        focusedBackgroundAlpha = 0.0,
        borderAlpha = 0.0,
        focusedBorderAlpha = 0.0,
        radius = layout.cu(7),
        padding = layout.cu(2),
        borderThickness = layout.cu(1),
        selectAll = false,
        liveUpdate = true,
        maxBytes = 65536,
    })
    interaction.region({
        key = "note.surface",
        shape = shape,
        cursor = "text",
        events = {
            doubleClick = { id = "note.focus" },
            contextMenu = { id = "note.menu", scope = "component" },
        },
        accessibility = {
            role = "group",
            label = l10n.tr("lua_widget.sticky_note.content"),
        },
    })
end

local function event(_context, _model, value)
    if value.kind == "environment" then
        widget.setTitle(l10n.tr("lua_widget.sticky_note.name"))
        return
    end
    if value.kind ~= "action" then return end
    if value.id == "note.focus" then
        control.focus("note")
    elseif value.id == "note.clear" then
        control.blur("note")
        storage.remove("text")
        widget.invalidate()
    elseif value.id == "note.resetStyle" then
        resetDefaults()
        widget.invalidate()
    end
end

local function menu(_context, _model, request)
    if request.id ~= "note.menu" then return nil end
    return ui.menu({
        {
            id = "note.clear",
            label = l10n.tr("lua_widget.sticky_note.clear"),
            icon = fluent.clear,
            iconFont = "fluent",
        },
        {
            id = "note.resetStyle",
            label = l10n.tr("lua_widget.sticky_note.reset_style"),
            icon = fluent.style,
            iconFont = "fluent",
        },
    })
end

descriptor = {
    name = l10n.tr("lua_widget.sticky_note.name"),
    useCustomStyle = true,
    followPersonalizationDefault = true,
    showTitle = true,
    bottomBarHover = false,
    bg = 0xFFF7D1,
    border = 0xD0D0D0,
    alpha = 1.0,
    borderAlpha = 0.85,
    gradientEndA = 0.0,
    settings = settings,
    setup = setup,
    render = render,
    event = event,
    menu = menu,
}

return widget.define(descriptor)
