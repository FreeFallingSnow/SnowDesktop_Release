-- sticky_note.lua - 便签组件
name = l10n.tr("lua_widget.sticky_note.name")
useCustomStyle = true
followPersonalizationDefault = true
showTitle = true
bottomBarHover = false

local fluent = {
    clear = utf8.char(0xE5E4),
    style = utf8.char(0xF592),
}

-- 默认值
bg = 0xFFF7D1
border = 0xD0D0D0
alpha = 1.0
gradientEndA = 0.0
textColor = 0x1E293B

settings = {
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
            }
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
            }
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
            }
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
            }
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
            }
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
            }
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
            }
        }
    },
    fields = {
        { key = "fontSize", label = l10n.tr("lua_widget.common.font_size"), type = "int", default = 15, min = 10, max = 24 },
    }
}

-- 从 storage 加载已保存的值覆盖默认
function loadConfig()
    bg = tonumber(storage.get("bg")) or bg
    border = tonumber(storage.get("border")) or border
    alpha = tonumber(storage.get("alpha")) or alpha
    gradientEndA = tonumber(storage.get("gradientEndA")) or gradientEndA
    local theme = widget.theme()
    if theme then
        textColor = (theme.contentTheme == 1) and 0x000000 or 0xFFFFFF
    end
end

function getFontSize()
    return math.max(10, math.min(24, tonumber(storage.get("fontSize")) or 15))
end

function resetDefaults()
    bg = 0xFFF7D1
    border = 0xD0D0D0
    alpha = 1.0
    gradientEndA = 0.0
    storage.set("bg", tostring(bg))
    storage.set("border", tostring(border))
    storage.set("alpha", tostring(alpha))
    storage.set("borderAlpha", "0.85")
    storage.set("gradientEndA", tostring(gradientEndA))
    storage.set("fontSize", "15")
    storage.set("followPersonalization", "1")
    storage.set("__preset", "classic")
end

function render()
    loadConfig()
    widget.setTitle(l10n.tr("lua_widget.sticky_note.name"))

    local w = layout.width()
    local h = layout.height()
    local pad = layout.cu(14)
    local fontSize = layout.fontCu(getFontSize())
    local maxWidth = w - pad * 2
    local bottomBarH = layout.cu(layout.barHeight())
    local viewportH = h - pad - bottomBarH
    if viewportH <= 0 then viewportH = 1 end

    ui.textArea("note", "text", pad, pad, maxWidth, viewportH, {
        placeholder = l10n.tr("lua_widget.sticky_note.empty_hint"),
        placeholderWhenWhitespace = true,
        fontSize = fontSize,
        textColor = textColor,
        placeholderColor = textColor,
        backgroundColor = textColor,
        borderColor = textColor,
        focusedBorderColor = textColor,
        backgroundAlpha = 0.0,
        focusedBackgroundAlpha = 0.0,
        borderAlpha = 0.0,
        focusedBorderAlpha = 0.0,
        radius = layout.cu(7),
        padding = layout.cu(2),
        borderThickness = layout.cu(1),
        selectAll = false,
        liveUpdate = true,
    })
end

function onDoubleClick(x, y)
    ui.focusInput("note")
end

function getContextMenu()
    return {
        { id = 1, label = l10n.tr("lua_widget.sticky_note.clear"), icon = fluent.clear, iconFont = "fluent" },
        { id = 2, label = l10n.tr("lua_widget.sticky_note.reset_style"), icon = fluent.style, iconFont = "fluent" },
    }
end

function onMenu(id)
    if id == 1 then
        storage.remove("text")
    elseif id == 2 then
        resetDefaults()
    end
end

function imguiRender()
    imgui.text(l10n.tr("lua_widget.sticky_note.content"))

    local text = imgui.input("##note", storage.get("text") or "")
    if text ~= (storage.get("text") or "") then
        storage.set("text", text)
    end
end
