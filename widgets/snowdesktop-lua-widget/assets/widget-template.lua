-- Copy this file to SnowDesktop's active widgets/my_widget.lua.
name = l10n.tr("lua_widget.template.name")
useCustomStyle = true

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
        message = storage.get("message") or "Hello, SnowDesktop!",
        color = tonumber(storage.get("color")) or 0xFFFFFF
    }
end

function render()
    local config = readConfig()
    local w = layout.width()
    local h = layout.height()
    local pad = layout.cu(12)

    draw.text(pad, pad, config.message, layout.fontCu(14), config.color, w - pad * 2, true)
    draw.text(pad, h - layout.cu(24), l10n.tr("lua_widget.template.double_click_edit"),
        layout.fontCu(11), 0xAFC2D6, w - pad * 2, false, true)
end

function onDoubleClick(x, y)
    local config = readConfig()
    widget.editText("message", layout.cu(10), layout.cu(10), layout.width() - layout.cu(20),
        layout.height() - layout.cu(20), true, config.message, true, config.color)
end

function getContextMenu()
    return {
        { id = 1, label = l10n.tr("lua_widget.template.reset_text"), icon = "" }
    }
end

function onMenu(id)
    if id == 1 then
        storage.set("message", "Hello, SnowDesktop!")
    end
end

function imguiRender()
    local config = readConfig()

    local message = imgui.input("##message", config.message)
    if message ~= config.message then
        storage.set("message", message)
    end

end
