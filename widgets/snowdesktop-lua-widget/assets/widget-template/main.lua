-- Copy this directory as a complete SnowDesktop widget package.
name = l10n.tr("lua_widget.template.name")
useCustomStyle = true

local fluentReset = utf8.char(0xF19F)

bg = 0x18202A
border = 0x5F7691
alpha = 0.92
gradientEndA = 0.0
glassEnabled = false

settings = {
    presets = {
        {
            id = "default",
            label = l10n.tr("lua_widget.template.preset"),
            default = true,
            values = {
                bg = 0x18202A,
                border = 0x5F7691,
                alpha = 0.92,
                borderAlpha = 0.80,
                gradientEndA = 0.0,
                glassEnabled = false,
            }
        }
    },
    fields = {
        { key = "color", label = l10n.tr("lua_widget.common.text_color"), type = "color", default = 0xFFFFFF },
    }
}

local function readConfig()
    return {
        color = tonumber(storage.get("color")) or 0xFFFFFF
    }
end

function render()
    local config = readConfig()
    local w = layout.width()
    local h = layout.height()
    local pad = layout.cu(12)

    ui.textArea("message", "message", pad, pad, w - pad * 2,
        h - pad * 2, {
            placeholder = l10n.tr("lua_widget.template.empty_hint"),
            placeholderWhenWhitespace = true,
            fontSize = layout.fontCu(15),
            textColor = config.color,
            placeholderColor = config.color,
            backgroundColor = config.color,
            borderColor = config.color,
            focusedBorderColor = config.color,
            backgroundAlpha = 0.0,
            focusedBackgroundAlpha = 0.035,
            borderAlpha = 0.0,
            focusedBorderAlpha = 0.18,
            radius = layout.cu(7),
            padding = layout.cu(2),
            borderThickness = layout.cu(1),
            selectAll = false,
            liveUpdate = true,
        })
end

function onDoubleClick(x, y)
    ui.focusInput("message")
end

function getContextMenu()
    return {
        { id = 1, label = l10n.tr("lua_widget.template.reset_text"),
            icon = fluentReset, iconFont = "fluent" }
    }
end

function onMenu(id)
    if id == 1 then
        storage.set("message", "Hello, SnowDesktop!")
    end
end

function imguiRender()
    local config = readConfig()

    local saved = storage.get("message") or ""
    local message = imgui.input("##message", saved)
    if message ~= saved then
        storage.set("message", message)
    end

end
