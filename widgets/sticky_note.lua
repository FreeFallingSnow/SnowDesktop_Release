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

-- 从 storage 加载已保存的值覆盖默认
function autoTextColor(hex)
    local r = (hex >> 16) & 0xFF
    local g = (hex >> 8) & 0xFF
    local b = hex & 0xFF
    local lum = 0.299 * r + 0.587 * g + 0.114 * b
    return lum > 140 and 0x000000 or 0xFFFFFF
end

function loadConfig()
    bg = tonumber(storage.get("bg")) or bg
    border = tonumber(storage.get("border")) or border
    alpha = tonumber(storage.get("alpha")) or alpha
    gradientEndA = tonumber(storage.get("gradientEndA")) or gradientEndA
    textColor = tonumber(storage.get("textColor")) or textColor
    followPersonalization = storage.get("followPersonalization") == "1"
    if followPersonalization then
        local theme = widget.theme()
        if theme and theme.bg then
            textColor = autoTextColor(theme.bg)
        end
    end
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
    storage.set("gradientEndA", tostring(gradientEndA))
    storage.set("textColor", tostring(textColor))
    storage.set("followPersonalization", "0")
    followPersonalization = false
end

function render()
    loadConfig()
    widget.setTitle("便签")

    local w = layout.width()
    local h = layout.height()
    local saved = storage.get("text") or ""
    local pad = layout.cu(14)
    local fontSize = layout.fontCu(15)
    local maxWidth = w - pad * 2
    local bottomBarH = layout.cu(40)
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
    local bottomBarH = layout.cu(40)
    local viewportH = h - pad - bottomBarH
    widget.editText("text", pad, pad, w - pad * 2, viewportH, true, storage.get("text") or "", false, textColor)
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
    loadConfig()
    imgui.text("便签内容")

    local text = imgui.input("##note", storage.get("text") or "")
    if text ~= (storage.get("text") or "") then
        storage.set("text", text)
    end

    if imgui.collapsingHeader("便签设置") then
        local newFp = imgui.checkbox("跟随个性化设置", followPersonalization)
        if newFp ~= followPersonalization then
            followPersonalization = newFp
            storage.set("followPersonalization", followPersonalization and "1" or "0")
        end

        imgui.text("背景色")
        local newBg = imgui.colorEdit3("##bg", bg)
        if newBg ~= bg then bg = newBg; storage.set("bg", tostring(bg)) end

        imgui.text("边框色")
        local newBorder = imgui.colorEdit3("##border", border)
        if newBorder ~= border then border = newBorder; storage.set("border", tostring(border)) end

        imgui.text("文字色")
        local newTc = imgui.colorEdit3("##tc", textColor)
        if newTc ~= textColor then textColor = newTc; storage.set("textColor", tostring(textColor)) end

        local newAlpha = imgui.sliderFloat("不透明度", alpha, 0.0, 1.0)
        if newAlpha ~= alpha then alpha = newAlpha; storage.set("alpha", tostring(alpha)) end

        if imgui.button("恢复默认设置") then
            resetDefaults()
        end
    end
end
