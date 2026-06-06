-- sticky_note.lua - 便签组件
name = "便签"
useCustomStyle = true

-- 默认值
bg = 0xFFF7D1
border = 0xD0D0D0
alpha = 1.0
gradientEndA = 0.0
textColor = 0x000000

-- 从 storage 加载已保存的值覆盖默认
function loadConfig()
    bg = tonumber(storage.get("bg")) or bg
    border = tonumber(storage.get("border")) or border
    alpha = tonumber(storage.get("alpha")) or alpha
    gradientEndA = tonumber(storage.get("gradientEndA")) or gradientEndA
    textColor = tonumber(storage.get("textColor")) or textColor
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
end

function render()
    loadConfig()
    local w = layout.width()
    local h = layout.height()
    local saved = storage.get("text") or ""
    local pad = 14

    if saved ~= "" then
        draw.text(pad, pad, saved, 15, textColor, w - pad * 2)
    else
        draw.text(pad, pad, "双击编辑...", 15, textColor, w - pad * 2)
    end

    local t = sys.getTime()
    draw.text(pad, h - 16, string.format("便签 | %02d:%02d", t.hour, t.min), 10, textColor)
end

function onClick(x, y)
end

function onDoubleClick(x, y)
    local w = layout.width()
    local h = layout.height()
    loadConfig()
    widget.editText("text", 12, 12, w - 24, h - 36, true, storage.get("text") or "", false, textColor)
end

function getContextMenu()
    return {
        { id = 1, label = "清空便签" },
        { id = 2, label = "恢复便签默认样式" },
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
