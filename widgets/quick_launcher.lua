name = l10n.tr("lua_widget.quick_launcher.name")
useCustomStyle = true
followPersonalizationDefault = true
showTitle = true
bottomBarHover = false

bg = 0x151A21
border = 0xFFFFFF
alpha = 0.40
borderAlpha = 0.22
gradientEndA = 0.32
textColor = 0xFFFFFF
local lastQuery = nil

local function resolveTextColor()
    local tc = tonumber(storage.get("textColor")) or textColor
    local follows = storage.get("followPersonalization") == "1"
        or storage.get("followPersonalization") == "true"
    if follows then
        local theme = widget.theme()
        if theme then
            tc = (theme.contentTheme == 1) and 0x000000 or 0xFFFFFF
        end
    end
    return tc
end

local palettes = {
    dark = {
        itemText   = 0xFFFFFF,
        noResult   = 0xF1F5F9,
        inputText  = 0xD7FFFA,
        inputPlaceholder = 0xF1F5F9,
        inputBg    = 0xFFFFFF,
        scrollBar  = 0xFFFFFF,
        selBg      = 0xFFFFFF,
        selBorder  = 0xFFFFFF,
        inputBorder = 0xFFFFFF,
        inputFocusBorder = 0x64A8FF,
    },
    light = {
        itemText   = 0x1E293B,
        noResult   = 0x334155,
        inputText  = 0x0F172A,
        inputPlaceholder = 0x334155,
        inputBg    = 0x000000,
        scrollBar  = 0x334155,
        selBg      = 0x000000,
        selBorder  = 0x000000,
        inputBorder = 0x000000,
        inputFocusBorder = 0x2563EB,
    },
}

local function getPalette()
    local theme = widget.theme()
    if theme and theme.contentTheme == 1 then
        return palettes.light
    end
    return palettes.dark
end

settings = {
    presets = {
        {
            id = "default",
            label = l10n.tr("lua_widget.quick_launcher.preset_dark"),
            default = true,
            values = {
                bg = 0x151A21,
                border = 0xFFFFFF,
                alpha = 0.40,
                borderAlpha = 0.22,
                gradientEndA = 0.32,
            }
        }
    },
    fields = {
        { key = "query", label = l10n.tr("lua_widget.quick_launcher.query"), type = "text", default = "" },
        { key = "fontSize", label = l10n.tr("lua_widget.common.font_size"), type = "int", default = 14, min = 10, max = 24 },
        { key = "textColor", label = l10n.tr("lua_widget.common.text_color"), type = "color", default = 0xFFFFFF },
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
    widget.setTitle(l10n.tr("lua_widget.quick_launcher.name"))
    local w = layout.width()
    local pad = layout.cu(12)
    local metrics = pageMetrics()
    local items = matches()
    local top, selected, listY, rowH, maxRows = clampViewport(#items, metrics)
    local theme = currentTheme()
    local pal = getPalette()

    ui.textInput("search", "query", pad, metrics.searchTop,
        w - pad * 2, metrics.searchHeight, {
            placeholder = l10n.tr("lua_widget.quick_launcher.search_placeholder"),
            fontSize = layout.fontCu(metrics.fontSize),
            textColor = pal.inputText,
            placeholderColor = pal.inputPlaceholder,
            backgroundColor = pal.inputBg,
            borderColor = pal.inputBorder,
            focusedBorderColor = pal.inputFocusBorder,
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
                pal.selBg, layout.cu(6), 0.28)
            draw.strokeRect(pad, y - layout.cu(2), w - pad * 2, rowH - layout.cu(2),
                pal.selBorder, layout.cu(6), layout.cu(1.0), 0.65)
        end
        draw.icon(item, pad + layout.cu(4),
            y + math.max(0, (rowH - metrics.iconSize) / 2 - layout.cu(1)), metrics.iconSize)
        local textX = pad + metrics.iconSize + layout.cu(12)
        draw.text(textX, y + metrics.itemTextOffsetY, item.title or l10n.tr("lua_widget.common.untitled"),
            layout.fontCu(metrics.fontSize), pal.itemText,
            w - pad - textX - layout.cu(6), false, true)
        y = y + rowH
    end

    if #items == 0 then
        draw.text(pad, y, l10n.tr("lua_widget.quick_launcher.no_matches"), layout.fontCu(metrics.fontSize),
            pal.noResult, w - pad * 2, false, true)
    elseif #items > maxRows then
        local barH = math.max(layout.cu(12), math.floor((maxRows / #items) * (maxRows * rowH)))
        local barY = listY + math.floor(((top - 1) / math.max(1, #items - maxRows)) * (maxRows * rowH - barH))
        draw.rect(w - pad - layout.cu(4), barY, layout.cu(3), barH, pal.scrollBar, layout.cu(2), 0.82)
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
        { id = 4, label = l10n.tr("lua_widget.quick_launcher.edit_query"), icon = "" },
        { id = 1, label = l10n.tr("lua_widget.quick_launcher.open_match"), icon = "" },
        { id = 2, label = l10n.tr("lua_widget.quick_launcher.reveal_match"), icon = "" },
        { id = 3, label = l10n.tr("lua_widget.quick_launcher.refresh_desktop"), icon = "" },
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
    imgui.text(l10n.tr("lua_widget.quick_launcher.match_count", #items))
    local top, selected = clampViewport(#items)
    for i = top, math.min(#items, top + 7) do
        local clicked = imgui.selectable(items[i].title or l10n.tr("lua_widget.common.untitled"), i == selectedIndex())
        if clicked then
            setSelectedIndex(i)
        end
    end
end
