name = "快速启动"
useCustomStyle = true
showTitle = true
bottomBarHover = false

bg = 0x151A21
border = 0xFFFFFF
alpha = 0.40
borderAlpha = 0.22
gradientEndA = 0.32
shadowAlpha = 0.12
shadowBlur = 16
shadowOffsetY = 5
highlightAlpha = 0.10
noiseAlpha = 0.014

local lastQuery = nil

settings = {
    presets = {
        {
            id = "default",
            label = "默认外观",
            default = true,
            values = {
                bg = 0x151A21,
                border = 0xFFFFFF,
                alpha = 0.40,
                borderAlpha = 0.22,
                gradientEndA = 0.32,
                shadowAlpha = 0.12,
                shadowBlur = 16,
                shadowOffsetY = 5,
                highlightAlpha = 0.10,
                noiseAlpha = 0.014,
                followPersonalization = true,
            }
        },
        {
            id = "accent",
            label = "清透搜索",
            values = {
                bg = 0x0B141A,
                border = 0x67D5B5,
                alpha = 0.34,
                borderAlpha = 0.28,
                gradientEndA = 0.28,
                shadowAlpha = 0.10,
                shadowBlur = 18,
                shadowOffsetY = 5,
                highlightAlpha = 0.12,
                noiseAlpha = 0.015,
                followPersonalization = false,
            }
        }
    },
    fields = {
        { key = "query", label = "搜索词", type = "text", default = "" },
        { key = "fontSize", label = "字号", type = "int", default = 14, min = 10, max = 24 },
    }
}

function currentQuery()
    return storage.get("query") or ""
end

function currentFontSize()
    return math.max(10, math.min(24, tonumber(storage.get("fontSize")) or 14))
end

function pageMetrics()
    local fontSize = currentFontSize()
    local searchTopCu = 12
    local searchHeightCu = math.max(28, fontSize + 16)
    local listTopCu = searchTopCu + searchHeightCu + 12
    local rowHeightCu = math.max(34, fontSize + 20)
    return {
        fontSize = fontSize,
        searchTop = layout.cu(searchTopCu),
        searchHeight = layout.cu(searchHeightCu),
        listTop = layout.cu(listTopCu),
        rowHeight = layout.cu(rowHeightCu),
        iconSize = layout.cu(math.max(22, fontSize + 10)),
        itemTextOffsetY = layout.cu(3 + math.max(0, fontSize - 12) * 0.35),
    }
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

function listMetrics(metrics)
    metrics = metrics or pageMetrics()
    local y = metrics.listTop
    local rowH = metrics.rowHeight
    local h = layout.height()
    local bottomBarH = layout.cu(layout.barHeight())
    local maxRows = math.max(1, math.floor((h - y - bottomBarH - layout.cu(8)) / rowH))
    return y, rowH, maxRows
end

function clampViewport(count, metrics)
    local listY, rowH, maxRows = listMetrics(metrics)
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

function matchRank(item, query)
    local q = string.lower(query or "")
    if q == "" then return 0 end
    local title = string.lower(item.title or "")
    if title == q then return 0 end
    local stem = title:gsub("%.[^%.]+$", "")
    if stem == q then return 0 end
    if string.sub(title, 1, #q) == q or string.sub(stem, 1, #q) == q then return 1 end
    if string.find(title, q, 1, true) then return 2 end
    return 3
end

function sortMatches(results, query)
    table.sort(results, function(a, b)
        local ar = matchRank(a, query)
        local br = matchRank(b, query)
        if ar ~= br then return ar < br end
        return string.lower(a.title or "") < string.lower(b.title or "")
    end)
end

function matches()
    local query = currentQuery()
    if query == "" then
        return desktop.items()
    end
    local results = desktop.find(query)
    if everything and everything.search then
        local extra = everything.search(query, 40)
        local seen = {}
        for _, item in ipairs(results) do
            seen[string.lower(item.path or item.id or "")] = true
        end
        for _, item in ipairs(extra) do
            local key = string.lower(item.path or item.id or "")
            if key ~= "" and not seen[key] then
                table.insert(results, item)
                seen[key] = true
            end
        end
    end
    sortMatches(results, query)
    return results
end

function syncQueryState()
    local query = currentQuery()
    if lastQuery == nil then
        lastQuery = query
        return
    end
    if query ~= lastQuery then
        setSelectedIndex(1)
        setTopIndex(1)
        lastQuery = query
    end
end

function currentTheme()
    local theme = widget.theme()
    theme.bg = theme.bg or 0x151A21
    theme.border = theme.border or 0xFFFFFF
    theme.alpha = theme.alpha or 0.36
    return theme
end

function render()
    syncQueryState()
    widget.setTitle("快速启动")
    local w = layout.width()
    local pad = layout.cu(12)
    local metrics = pageMetrics()
    local items = matches()
    local top, selected, listY, rowH, maxRows = clampViewport(#items, metrics)
    local theme = currentTheme()

    ui.textInput("search", "query", pad, metrics.searchTop,
        w - pad * 2, metrics.searchHeight, {
            placeholder = "单击输入搜索关键字",
            fontSize = layout.fontCu(metrics.fontSize),
            textColor = 0xD7FFFA,
            placeholderColor = 0x8FA3B8,
            backgroundColor = 0xFFFFFF,
            borderColor = 0xFFFFFF,
            focusedBorderColor = 0x64A8FF,
            backgroundAlpha = 0.05,
            focusedBackgroundAlpha = 0.12,
            borderAlpha = 0.12,
            focusedBorderAlpha = 0.70,
            radius = layout.cu(7),
            padding = layout.cu(8),
            borderThickness = layout.cu(1.2),
            selectAll = false,
            liveUpdate = true,
        })

    local y = listY
    for row = 0, math.min(#items - top + 1, maxRows) - 1 do
        local i = top + row
        local item = items[i]
        local isSelected = i == selected
        if isSelected then
            draw.rect(pad, y - layout.cu(2), w - pad * 2, rowH - layout.cu(2),
                theme.border, layout.cu(6), 0.28)
            draw.strokeRect(pad, y - layout.cu(2), w - pad * 2, rowH - layout.cu(2),
                theme.border, layout.cu(6), layout.cu(1.0), 0.65)
        end
        draw.icon(item, pad + layout.cu(4),
            y + math.max(0, (rowH - metrics.iconSize) / 2 - layout.cu(1)), metrics.iconSize)
        local textX = pad + metrics.iconSize + layout.cu(12)
        draw.text(textX, y + metrics.itemTextOffsetY, item.title or "(未命名)",
            layout.fontCu(metrics.fontSize), 0xFFFFFF,
            w - pad - textX - layout.cu(6), false, true)
        y = y + rowH
    end

    if #items == 0 then
        draw.text(pad, y, "没有匹配项目", layout.fontCu(metrics.fontSize),
            0x8FA3B8, w - pad * 2, false, true)
    elseif #items > maxRows then
        local barH = math.max(layout.cu(12), math.floor((maxRows / #items) * (maxRows * rowH)))
        local barY = listY + math.floor(((top - 1) / math.max(1, #items - maxRows)) * (maxRows * rowH - barH))
        draw.rect(w - pad - layout.cu(4), barY, layout.cu(3), barH, 0xFFFFFF, layout.cu(2), 0.82)
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
    local idx = itemIndexAtPoint(x, y)
    if idx then
        setSelectedIndex(idx)
    end
end

function onSelected()
    ui.focusInput("search")
end

function onDoubleClick(x, y)
    local idx = itemIndexAtPoint(x, y)
    if idx then
        setSelectedIndex(idx)
        openSelected(false)
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
        ui.focusInput("search")
    elseif id == 1 then
        openSelected(false)
    elseif id == 2 then
        openSelected(true)
    elseif id == 3 then
        desktop.refresh()
    end
end

function imguiRender()
    syncQueryState()

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
