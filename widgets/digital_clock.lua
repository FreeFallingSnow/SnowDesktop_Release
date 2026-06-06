-- digital_clock.lua - 数字时钟
name = "数字时钟"
useCustomStyle = true

bg = 0x000000
border = 0x000000
alpha = 0.0

showWeekday = true
showDate = true
textColor = 0xFFFFFF

function loadConfig()
    bg = tonumber(storage.get("bg")) or bg
    border = bg
    alpha = tonumber(storage.get("alpha")) or alpha
    gradientEndA = tonumber(storage.get("gradientEndA")) or gradientEndA
    showWeekday = storage.get("showWeekday") ~= "0"
    showDate = storage.get("showDate") ~= "0"
    textColor = tonumber(storage.get("textColor")) or textColor
end

function saveBool(key, value)
    storage.set(key, value and "1" or "0")
end

function resetDefaults()
    bg = 0x000000
    border = bg
    alpha = 0.0
    gradientEndA = 0.0
    showWeekday = true
    showDate = true
    textColor = 0xFFFFFF
    storage.set("bg", tostring(bg))
    storage.set("alpha", tostring(alpha))
    storage.set("gradientEndA", tostring(gradientEndA))
    saveBool("showWeekday", showWeekday)
    saveBool("showDate", showDate)
    storage.set("textColor", tostring(textColor))
end


function render()
    loadConfig()
    local t = sys.getTime()
    local w = layout.width()
    local h = layout.height()
    local timeStr = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
    local dateStr = string.format("%d年%02d月%02d日", t.year, t.month, t.day)
    local weekDays = { "日", "一", "二", "三", "四", "五", "六" }
    local weekdayStr = "星期" .. weekDays[t.wday or 1]

    local timeBaseSize = 28
    local secondaryBaseSize = 9
    local innerWidth = math.max(80, w - 24)
    local gap = math.max(2, math.floor(h * 0.015))
    local lines = {
        { text = timeStr, size = timeBaseSize },
    }

    local secondaryParts = {}
    if showDate then table.insert(secondaryParts, dateStr) end
    if showWeekday then table.insert(secondaryParts, weekdayStr) end
    if #secondaryParts > 0 then
        table.insert(lines, { text = table.concat(secondaryParts, "  "), size = secondaryBaseSize })
    end

    local widest = 1
    local totalBaseHeight = 0
    for i = 1, #lines do
        lines[i].probe = draw.measureText(lines[i].text, lines[i].size, 0, true)
        widest = math.max(widest, lines[i].probe.width)
        totalBaseHeight = totalBaseHeight + lines[i].probe.height
    end

    local innerHeight = math.max(40, h - 24)
    local widthScale = innerWidth / math.max(1, widest)
    local heightScale = (innerHeight - gap * math.max(0, #lines - 1)) / math.max(1, totalBaseHeight)
    local scale = math.max(0.7, math.min(widthScale, heightScale))

    for i = 1, #lines do
        lines[i].size = lines[i].size * scale
        lines[i].metrics = draw.measureText(lines[i].text, lines[i].size, 0, true)
    end

    local blockH = 0
    for i = 1, #lines do
        blockH = blockH + lines[i].metrics.height
        if i > 1 then blockH = blockH + gap end
    end

    local top = (h - blockH) * 0.5
    local y = top
    local secondaryGap = math.max(1, math.floor(gap * 0.35))

    for i = 1, #lines do
        local line = lines[i]
        local drawMaxW = math.max(1, line.metrics.width + 2)
        draw.text((w - line.metrics.width) * 0.5, y, line.text, line.size, textColor, drawMaxW, true)
        if i == 1 and #lines > 1 then
            y = y + line.metrics.height + secondaryGap
        else
            y = y + line.metrics.height + gap
        end
    end
end

function imguiRender()
    loadConfig()
    imgui.text("显示设置")
    local newShowWeekday = imgui.checkbox("显示星期", showWeekday)
    if newShowWeekday ~= showWeekday then showWeekday = newShowWeekday; saveBool("showWeekday", showWeekday) end

    local newShowDate = imgui.checkbox("显示日期", showDate)
    if newShowDate ~= showDate then showDate = newShowDate; saveBool("showDate", showDate) end

    imgui.text("文字颜色")
    local newTextColor = imgui.colorEdit3("##textColor", textColor)
    if newTextColor ~= textColor then textColor = newTextColor; storage.set("textColor", tostring(textColor)) end

    imgui.text("背景颜色")
    local newBg = imgui.colorEdit3("##bg", bg)
    if newBg ~= bg then bg = newBg; border = bg; storage.set("bg", tostring(bg)) end

    local newAlpha = imgui.sliderFloat("透明度", alpha, 0.0, 1.0)
    if newAlpha ~= alpha then alpha = newAlpha; storage.set("alpha", tostring(alpha)) end

    if imgui.button("恢复默认设置") then resetDefaults() end

end
