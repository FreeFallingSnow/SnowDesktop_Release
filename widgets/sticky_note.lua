-- sticky_note.lua - 便签组件
name = "便签"
useCustomStyle = true
showTitle = true
bottomBarHover = false

-- 默认值
bg = 0xFFF7D1
border = 0xD0D0D0
alpha = 1.0
gradientEndA = 0.0
textColor = 0x000000

settings = {
    presets = {
        {
            id = "classic",
            label = "浅黄",
            default = true,
            values = {
                bg = 0xFFF7D1,
                border = 0xD0D0D0,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
                shadowAlpha = 0.0,
                highlightAlpha = 0.0,
                noiseAlpha = 0.0,
                followPersonalization = false,
                textColor = 0x000000,
            }
        },
        {
            id = "white",
            label = "纯白",
            values = {
                bg = 0xFFFFFF,
                border = 0xD6D6D6,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
                shadowAlpha = 0.0,
                highlightAlpha = 0.0,
                noiseAlpha = 0.0,
                followPersonalization = false,
                textColor = 0x000000,
            }
        },
        {
            id = "pink",
            label = "浅粉",
            values = {
                bg = 0xFFE1EC,
                border = 0xE8AFC2,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
                shadowAlpha = 0.0,
                highlightAlpha = 0.0,
                noiseAlpha = 0.0,
                followPersonalization = false,
                textColor = 0x2A111A,
            }
        },
        {
            id = "blue",
            label = "浅蓝",
            values = {
                bg = 0xDCEBFF,
                border = 0x9DBBE6,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
                shadowAlpha = 0.0,
                highlightAlpha = 0.0,
                noiseAlpha = 0.0,
                followPersonalization = false,
                textColor = 0x102033,
            }
        },
        {
            id = "green",
            label = "浅绿",
            values = {
                bg = 0xDFF7E7,
                border = 0x9ACDAA,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
                shadowAlpha = 0.0,
                highlightAlpha = 0.0,
                noiseAlpha = 0.0,
                followPersonalization = false,
                textColor = 0x102818,
            }
        },
        {
            id = "purple",
            label = "浅紫",
            values = {
                bg = 0xEDE2FF,
                border = 0xBFA7E8,
                alpha = 1.0,
                borderAlpha = 0.85,
                gradientEndA = 0.0,
                shadowAlpha = 0.0,
                highlightAlpha = 0.0,
                noiseAlpha = 0.0,
                followPersonalization = false,
                textColor = 0x211330,
            }
        },
        {
            id = "dark",
            label = "深色",
            values = {
                bg = 0x20242C,
                border = 0x3E4654,
                alpha = 1.0,
                borderAlpha = 0.95,
                gradientEndA = 0.0,
                shadowAlpha = 0.0,
                highlightAlpha = 0.0,
                noiseAlpha = 0.0,
                followPersonalization = false,
                textColor = 0xFFFFFF,
            }
        }
    },
    fields = {
        { key = "textColor", label = "文字颜色", type = "color", default = 0x000000 },
        { key = "fontSize", label = "文字字号", type = "int", default = 15, min = 10, max = 24 },
    }
}

-- 从 storage 加载已保存的值覆盖默认
function autoTextColor(hex)
    local r = (hex >> 16) & 0xFF
    local g = (hex >> 8) & 0xFF
    local b = hex & 0xFF
    local lum = 0.299 * r + 0.587 * g + 0.114 * b
    return lum > 140 and 0x000000 or 0xFFFFFF
end

function syncFollowTextColor()
    local follows = storage.get("followPersonalization") == "1"
        or storage.get("followPersonalization") == "true"
    local state = follows and "1" or "0"
    local previous = storage.get("__followPersonalizationState")

    if previous == nil then
        storage.set("__followPersonalizationState", state)
        storage.remove("__followTextColorPending")
        return
    end
    if previous ~= state then
        storage.set("__followPersonalizationState", state)
        storage.set("__followTextColorPending", state)
        return
    end
    if storage.get("__followTextColorPending") ~= state then return end

    local background = nil
    if follows then
        local theme = widget.theme()
        background = theme and theme.bg or nil
    else
        background = tonumber(storage.get("bg"))
        if background == nil then
            local theme = widget.theme()
            background = theme and theme.bg or nil
        end
    end
    if background ~= nil then
        textColor = autoTextColor(background)
        storage.set("textColor", tostring(textColor))
        storage.remove("__followTextColorPending")
    end
end

function loadConfig()
    bg = tonumber(storage.get("bg")) or bg
    border = tonumber(storage.get("border")) or border
    alpha = tonumber(storage.get("alpha")) or alpha
    gradientEndA = tonumber(storage.get("gradientEndA")) or gradientEndA
    textColor = tonumber(storage.get("textColor")) or textColor
    syncFollowTextColor()
end

function getFontSize()
    return math.max(10, math.min(24, tonumber(storage.get("fontSize")) or 15))
end

function resetDefaults()
    bg = 0xFFF7D1
    border = 0xD0D0D0
    alpha = 1.0
    gradientEndA = 0.0
    textColor = 0x000000
    storage.set("bg", tostring(bg))
    storage.set("border", tostring(border))
    storage.set("alpha", tostring(alpha))
    storage.set("borderAlpha", "0.85")
    storage.set("gradientEndA", tostring(gradientEndA))
    storage.set("shadowAlpha", "0.0")
    storage.set("highlightAlpha", "0.0")
    storage.set("noiseAlpha", "0.0")
    storage.set("textColor", tostring(textColor))
    storage.set("fontSize", "15")
    storage.set("followPersonalization", "0")
    storage.set("__followPersonalizationState", "0")
    storage.remove("__followTextColorPending")
    storage.set("__preset", "classic")
end

function render()
    loadConfig()
    widget.setTitle("便签")

    local w = layout.width()
    local h = layout.height()
    local saved = storage.get("text") or ""
    local pad = layout.cu(14)
    local fontSize = layout.fontCu(getFontSize())
    local maxWidth = w - pad * 2
    local bottomBarH = layout.cu(layout.barHeight())
    local viewportH = h - pad - bottomBarH
    if viewportH <= 0 then viewportH = 1 end

    local textContent = saved ~= "" and saved or "双击编辑..."
    local textMeasured = draw.measureText(textContent, fontSize, maxWidth)
    local contentH = math.ceil(textMeasured.height) + pad * 2

    local scrollOffset = ui.scrollArea("text", pad, pad, maxWidth, viewportH, contentH)

    draw.pushClip(pad, pad, maxWidth, viewportH)
    draw.text(pad, pad - scrollOffset, textContent, fontSize, textColor, maxWidth)
    draw.popClip()
end

function onClick(x, y)
end

function onDoubleClick(x, y)
    local w = layout.width()
    local h = layout.height()
    loadConfig()
    local pad = layout.cu(14)
    local bottomBarH = layout.cu(layout.barHeight())
    local viewportH = h - pad - bottomBarH
    widget.editText("text", pad, pad, w - pad * 2, viewportH, true,
        storage.get("text") or "", false, textColor, layout.fontCu(getFontSize()))
end

function getContextMenu()
    return {
        { id = 1, label = "清空便签", icon = "" },
        { id = 2, label = "恢复便签默认样式", icon = "" },
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
    imgui.text("便签内容")

    local text = imgui.input("##note", storage.get("text") or "")
    if text ~= (storage.get("text") or "") then
        storage.set("text", text)
    end
end
