name = "快速启动"
bottomBarHover = false

function currentQuery()
    return storage.get("query") or ""
end

function selectedIndex()
    return tonumber(storage.get("selectedIndex")) or 1
end

function topIndex()
    return tonumber(storage.get("topIndex")) or 1
end

function setSelectedIndex(value)
    storage.set("selectedIndex", tostring(math.max(1, value)))
end

function setTopIndex(value)
    storage.set("topIndex", tostring(math.max(1, value)))
end

function listMetrics()
    local y = 82
    local rowH = 30
    local h = layout.height()
    local maxRows = math.max(1, math.floor((h - y - 8) / rowH))
    return y, rowH, maxRows
end

function clampViewport(count)
    local listY, rowH, maxRows = listMetrics()
    local maxTop = math.max(1, count - maxRows + 1)
    local top = math.min(topIndex(), maxTop)
    setTopIndex(top)
    local selected = math.min(math.max(1, selectedIndex()), math.max(1, count))
    if count > 0 then
        if selected < top then
            selected = top
            setSelectedIndex(selected)
        elseif selected >= top + maxRows then
            selected = top + maxRows - 1
            setSelectedIndex(selected)
        end
    end
    return top, selected, listY, rowH, maxRows
end

function matches()
    local query = currentQuery()
    if query == "" then
        return desktop.items()
    end
    return desktop.find(query)
end

function currentTheme()
    local theme = widget.theme()
    theme.bg = theme.bg or 0x151A21
    theme.border = theme.border or 0xFFFFFF
    theme.alpha = theme.alpha or 0.36
    return theme
end

function render()
    local w = layout.width()
    local h = layout.height()
    local pad = 12
    local query = currentQuery()
    local items = matches()
    local top, selected, listY, rowH, maxRows = clampViewport(#items)
    local theme = currentTheme()

    draw.text(pad, pad, "快速启动", 18, 0xFFFFFF, w - pad * 2, true, true)
    draw.rect(pad, 42, w - pad * 2, 28, theme.bg, 6, math.min(0.55, theme.alpha + 0.18))
    draw.strokeRect(pad, 42, w - pad * 2, 28, theme.border, 6, 1.2, math.min(0.95, theme.alpha + 0.35))
    local shownQuery = query
    if shownQuery == "" then shownQuery = "单击输入搜索关键字" end
    draw.text(pad + 10, 48, shownQuery, 12, 0xD7FFFA, w - pad * 2 - 20, false, true)

    local y = listY
    for row = 0, math.min(#items - top + 1, maxRows) - 1 do
        local i = top + row
        local item = items[i]
        local isSelected = i == selected
        if isSelected then
            draw.rect(pad, y - 2, w - pad * 2, 28, theme.border, 6, 0.28)
            draw.strokeRect(pad, y - 2, w - pad * 2, 28, theme.border, 6, 1.0, 0.65)
        end
        draw.icon(item, pad + 4, y, 22)
        draw.text(pad + 34, y + 3, item.title or "(未命名)", 12, 0xFFFFFF, w - pad * 2 - 40, false, true)
        y = y + rowH
    end

    if #items == 0 then
        draw.text(pad, y, "没有匹配项目", 12, 0x8FA3B8, w - pad * 2, false, true)
    elseif #items > maxRows then
        local barH = math.max(12, math.floor((maxRows / #items) * (maxRows * rowH)))
        local barY = listY + math.floor(((top - 1) / math.max(1, #items - maxRows)) * (maxRows * rowH - barH))
        draw.rect(w - pad - 4, barY, 3, barH, 0xFFFFFF, 2, 0.82)
    end
end

function openSelected(reveal)
    local items = matches()
    if #items == 0 then return end
    local selected = math.min(selectedIndex(), #items)
    if reveal then
        desktop.reveal(items[selected])
    else
        desktop.open(items[selected])
    end
end

function onWheel(x, y, button, delta)
    local items = matches()
    local count = #items
    if count == 0 then return end
    local top, selected, listY, rowH, maxRows = clampViewport(count)
    local step = delta > 0 and -1 or 1
    local maxTop = math.max(1, count - maxRows + 1)
    local newTop = math.min(maxTop, math.max(1, top + step))
    setTopIndex(newTop)
    if selected < newTop then
        setSelectedIndex(newTop)
    elseif selected >= newTop + maxRows then
        setSelectedIndex(newTop + maxRows - 1)
    end
end

function itemIndexAtPoint(x, y)
    local items = matches()
    if #items == 0 then return nil end
    local top, selected, listY, rowH, maxRows = clampViewport(#items)
    if y < listY or y >= listY + maxRows * rowH then return nil end
    local row = math.floor((y - listY) / rowH)
    local idx = top + row
    if idx < 1 or idx > #items then return nil end
    return idx
end

function onClick(x, y)
    local w = layout.width()
    if y >= 42 and y <= 70 then
        widget.editText("query", 12, 42, w - 24, 28, false, currentQuery(), true, 0xD7FFFA)
        return
    end
    local idx = itemIndexAtPoint(x, y)
    if idx then
        setSelectedIndex(idx)
    end
end

function onDoubleClick(x, y)
    local w = layout.width()
    if y >= 42 and y <= 70 then
        widget.editText("query", 12, 42, w - 24, 28, false, currentQuery(), true, 0xD7FFFA)
    else
        local idx = itemIndexAtPoint(x, y)
        if idx then
            setSelectedIndex(idx)
            openSelected(false)
        end
    end
end

function getContextMenu()
    return {
        { id = 4, label = "编辑搜索词", icon = "" },
        { id = 1, label = "打开当前匹配项", icon = "" },
        { id = 2, label = "定位当前匹配项", icon = "" },
        { id = 3, label = "刷新桌面", icon = "" },
    }
end

function onMenu(id)
    if id == 4 then
        widget.editText("query", 12, 42, layout.width() - 24, 28, false, currentQuery(), true, 0xD7FFFA)
    elseif id == 1 then
        openSelected(false)
    elseif id == 2 then
        openSelected(true)
    elseif id == 3 then
        desktop.refresh()
    end
end

function imguiRender()
    imgui.text("搜索")
    local query = imgui.inputText("##query", currentQuery())
    if query ~= currentQuery() then
        storage.set("query", query)
        setSelectedIndex(1)
        setTopIndex(1)
    end

    local items = matches()
    imgui.text("匹配项: " .. tostring(#items))
    local top, selected = clampViewport(#items)
    for i = top, math.min(#items, top + 7) do
        local clicked = imgui.selectable(items[i].title or "(未命名)", i == selectedIndex())
        if clicked then
            setSelectedIndex(i)
        end
    end
end
