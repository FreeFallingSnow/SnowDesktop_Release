-- Copy this file to widgets/my_widget.lua.
name = "示例组件"
useCustomStyle = true

bg = 0x18202A
border = 0x5F7691
alpha = 0.92
gradientEndA = 0.0

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
    draw.text(pad, h - layout.cu(24), "双击编辑", layout.fontCu(11), 0xAFC2D6, w - pad * 2, false, true)
end

function onDoubleClick(x, y)
    local config = readConfig()
    widget.editText("message", layout.cu(10), layout.cu(10), layout.width() - layout.cu(20),
        layout.height() - layout.cu(20), true, config.message, true, config.color)
end

function getContextMenu()
    return {
        { id = 1, label = "恢复默认文字", icon = "" }
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

    local color = imgui.colorEdit3("文字颜色", config.color)
    if color ~= config.color then
        storage.set("color", tostring(color))
    end
end
