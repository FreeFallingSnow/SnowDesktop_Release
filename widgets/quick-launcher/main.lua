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
local cachedQuery = nil
local cachedItems = {}
local cachedRows = {}
local resultsDirty = true
local searchPending = false
local searchDelayMs = 140
local desktopResultLimit = 160

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
        noResult   = 0xFFFFFF,
        inputText  = 0xFFFFFF,
        inputPlaceholder = 0xFFFFFF,
        inputBg    = 0xFFFFFF,
        selBg      = 0xFFFFFF,
        selBorder  = 0xFFFFFF,
        inputBorder = 0xFFFFFF,
        inputFocusBorder = 0xFFFFFF,
        inputBorderAlpha = 0.20,
        inputFocusBorderAlpha = 0.62,
        inputFocusBgAlpha = 0.12,
    },
    light = {
        itemText   = 0x000000,
        noResult   = 0x000000,
        inputText  = 0x000000,
        inputPlaceholder = 0x000000,
        inputBg    = 0x000000,
        selBg      = 0x000000,
        selBorder  = 0x000000,
        inputBorder = 0x000000,
        inputFocusBorder = 0x000000,
        inputBorderAlpha = 0.14,
        inputFocusBorderAlpha = 0.52,
        inputFocusBgAlpha = 0.10,
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
    fields = {
        { key = "query", label = l10n.tr("lua_widget.quick_launcher.query"), type = "text", default = "" },
        { key = "fontSize", label = l10n.tr("lua_widget.common.font_size"), type = "int", default = 15, min = 10, max = 24 },
        { key = "textColor", label = l10n.tr("lua_widget.common.text_color"), type = "color", default = 0xFFFFFF },
    }
}

function currentQuery()
    return storage.get("query") or ""
end

function currentFontSize()
    return math.max(10, math.min(24, tonumber(storage.get("fontSize")) or 15))
end

function pageMetrics()
    local fontSize = currentFontSize()
    local searchTopCu = 12
    local searchHeightCu = 31
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

function setSelectedIndex(value)
    local nextValue = math.max(1, value)
    if selectedIndex() ~= nextValue then
        storage.set("selectedIndex", tostring(nextValue))
    end
end

function listGeometry(metrics)
    metrics = metrics or pageMetrics()
    local y = metrics.listTop
    local rowH = metrics.rowHeight
    local h = layout.height()
    local bottomBarH = layout.cu(layout.barHeight())
    local bottom = math.max(y + 1, h - bottomBarH - layout.cu(8))
    return y, rowH, bottom - y
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

function orderMatches(results, query)
    local buckets = { {}, {}, {}, {} }
    for _, item in ipairs(results) do
        local rank = math.max(0, math.min(3, matchRank(item, query)))
        local bucket = buckets[rank + 1]
        bucket[#bucket + 1] = item
    end

    local ordered = {}
    for _, bucket in ipairs(buckets) do
        for _, item in ipairs(bucket) do
            ordered[#ordered + 1] = item
        end
    end
    return ordered
end

function appendResultSection(results, rows, items, title)
    if #items == 0 then return end
    rows[#rows + 1] = {
        kind = "header",
        title = title,
    }
    for _, item in ipairs(items) do
        results[#results + 1] = item
        rows[#rows + 1] = {
            kind = "item",
            item = item,
            itemIndex = #results,
        }
    end
end

function refreshMatches(query)
    query = query or currentQuery()
    local results = {}
    local rows = {}
    if query ~= "" then
        local desktopResults = orderMatches(
            desktop.find(query, desktopResultLimit), query)
        local applicationResults = {}
        if desktop.findApplications then
            applicationResults = orderMatches(
                desktop.findApplications(query, 40),
                query)
        end
        local everythingResults = {}
        local seen = {}
        for _, item in ipairs(desktopResults) do
            seen[string.lower(item.path or item.id or "")] = true
        end
        for _, item in ipairs(applicationResults) do
            local key = string.lower(
                item.path or item.id or "")
            if key ~= "" then seen[key] = true end
        end
        if everything and everything.search then
            for _, item in ipairs(everything.search(query, 40)) do
                local key = string.lower(item.path or item.id or "")
                if key ~= "" and not seen[key] then
                    everythingResults[#everythingResults + 1] = item
                    seen[key] = true
                end
            end
        end
        everythingResults = orderMatches(everythingResults, query)
        appendResultSection(results, rows, desktopResults,
            l10n.tr(
                "lua_widget.quick_launcher.desktop_results",
                #desktopResults))
        appendResultSection(results, rows, applicationResults,
            l10n.tr(
                "lua_widget.quick_launcher.application_results",
                #applicationResults))
        appendResultSection(results, rows, everythingResults,
            l10n.tr(
                "lua_widget.quick_launcher.everything_results",
                #everythingResults))
    end

    cachedQuery = query
    cachedItems = results
    cachedRows = rows
    resultsDirty = false
    return cachedItems, cachedRows
end

function matches()
    local query = currentQuery()
    if not resultsDirty and cachedQuery == query then
        return cachedItems, cachedRows
    end
    if searchPending and cachedQuery ~= nil and
        cachedQuery ~= query then
        return cachedItems, cachedRows
    end
    return refreshMatches(query)
end

function syncQueryState()
    local query = currentQuery()
    if lastQuery == nil then
        lastQuery = query
        return
    end
    if query ~= lastQuery then
        setSelectedIndex(1)
        ui.setScrollOffset("results", 0)
        resultsDirty = true
        if query == "" then
            widget.cancelTimer("search")
            searchPending = false
            refreshMatches("")
        else
            searchPending = true
            widget.setTimer("search", searchDelayMs, false)
        end
        lastQuery = query
    end
end

function render()
    syncQueryState()
    widget.setTitle(l10n.tr("lua_widget.quick_launcher.name"))
    local w = layout.width()
    local pad = layout.cu(12)
    local metrics = pageMetrics()
    local items, rows = matches()
    local selected = math.min(
        math.max(1, selectedIndex()), math.max(1, #items))
    local listY, rowH, viewportH = listGeometry(metrics)
    local pal = getPalette()

    ui.textInput("search", "query", pad, metrics.searchTop,
        w - pad * 2, metrics.searchHeight, {
            placeholder = l10n.tr("lua_widget.quick_launcher.search_placeholder"),
            fontSize = layout.fontCu(15),
            textColor = pal.inputText,
            placeholderColor = pal.inputPlaceholder,
            backgroundColor = pal.inputBg,
            borderColor = pal.inputBorder,
            focusedBorderColor = pal.inputFocusBorder,
            backgroundAlpha = 0.04,
            focusedBackgroundAlpha = pal.inputFocusBgAlpha,
            borderAlpha = pal.inputBorderAlpha,
            focusedBorderAlpha = pal.inputFocusBorderAlpha,
            radius = layout.cu(8),
            padding = layout.cu(10),
            borderThickness = layout.cu(1),
            selectAll = false,
            liveUpdate = true,
        })

    local range = ui.virtualList(
        "results", pad, listY, w - pad * 2,
        viewportH, rowH, #rows)

    if #rows > 0 then
        draw.pushClip(pad, listY, w - pad * 2, viewportH)
        for rowIndex = range.first, range.last do
            local row = rows[rowIndex]
            if row then
                local y = listY + (rowIndex - 1) * rowH -
                    range.offset
                if row.kind == "header" then
                    draw.text(pad + layout.cu(4),
                        y + metrics.itemTextOffsetY, row.title,
                        layout.fontCu(metrics.fontSize),
                        pal.itemText,
                        w - pad * 2 - layout.cu(8),
                        true, true, nil, 0.72)
                    draw.line(pad + layout.cu(4),
                        y + rowH - layout.cu(5),
                        w - pad - layout.cu(4),
                        y + rowH - layout.cu(5),
                        layout.cu(1), pal.itemText, 0.16)
                else
                    local item = row.item
                    local isSelected =
                        row.itemIndex == selected
                    if isSelected then
                        draw.rect(pad, y - layout.cu(2),
                            w - pad * 2,
                            rowH - layout.cu(2),
                            pal.selBg, layout.cu(6), 0.28)
                        draw.strokeRect(
                            pad, y - layout.cu(2),
                            w - pad * 2,
                            rowH - layout.cu(2),
                            pal.selBorder, layout.cu(6),
                            layout.cu(1.0), 0.65)
                    end
                    draw.icon(item, pad + layout.cu(4),
                        y + math.max(0,
                            (rowH - metrics.iconSize) / 2 -
                                layout.cu(1)),
                        metrics.iconSize)
                    local textX =
                        pad + metrics.iconSize +
                        layout.cu(12)
                    draw.text(textX,
                        y + metrics.itemTextOffsetY,
                        item.title or
                            l10n.tr(
                                "lua_widget.common.untitled"),
                        layout.fontCu(metrics.fontSize),
                        pal.itemText,
                        w - pad - textX - layout.cu(12),
                        false, true)
                end
            end
        end
        draw.popClip()
    end

    if #rows == 0 then
        local emptyText = currentQuery() == ""
            and l10n.tr(
                "lua_widget.quick_launcher.empty_prompt")
            or l10n.tr(
                "lua_widget.quick_launcher.no_matches")
        local emptyMetrics = draw.measureText(
            emptyText, layout.fontCu(metrics.fontSize),
            w - pad * 2, false)
        local emptyX = pad + math.max(
            0, (w - pad * 2 - emptyMetrics.width) / 2)
        local emptyY = listY + math.max(
            0, (viewportH - emptyMetrics.height) / 2)
        draw.text(emptyX, emptyY, emptyText,
            layout.fontCu(metrics.fontSize),
            pal.noResult, w - pad * 2,
            false, true, nil, 0.72)
    end
end

function openSelected(reveal)
    if cachedQuery ~= currentQuery() then return end
    local items = matches()
    if #items == 0 then return end
    local selected = math.min(selectedIndex(), #items)
    if reveal then
        desktop.reveal(items[selected])
    else
        desktop.open(items[selected])
    end
end

function itemIndexAtPoint(x, y)
    if cachedQuery ~= currentQuery() then return nil end
    local items, rows = matches()
    if #items == 0 then return nil end
    local pad = layout.cu(12)
    local listY, rowH, viewportH = listGeometry()
    if x < pad or x >= layout.width() - pad or
        y < listY or y >= listY + viewportH then
        return nil
    end
    local range = ui.virtualList(
        "results", pad, listY, layout.width() - pad * 2,
        viewportH, rowH, #rows)
    local rowIndex =
        math.floor((y - listY + range.offset) / rowH) + 1
    if rowIndex < range.first or rowIndex > range.last or
        rowIndex > #rows then
        return nil
    end
    local row = rows[rowIndex]
    return row and row.kind == "item"
        and row.itemIndex or nil
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

function onDesktopChanged(reason)
    if currentQuery() == "" then
        refreshMatches("")
    else
        resultsDirty = true
        widget.invalidate()
    end
end

function onTimer(timerName)
    if timerName ~= "search" then return end
    searchPending = false
    resultsDirty = true
    refreshMatches(currentQuery())
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
        resultsDirty = true
        desktop.refresh()
    end
end

function imguiRender()
    syncQueryState()

    local items = matches()
    imgui.text(l10n.tr("lua_widget.quick_launcher.match_count", #items))
    local selected = math.min(
        math.max(1, selectedIndex()), math.max(1, #items))
    for i = 1, math.min(#items, 8) do
        local clicked = imgui.selectable(
            items[i].title or l10n.tr("lua_widget.common.untitled"),
            i == selected)
        if clicked then
            setSelectedIndex(i)
        end
    end
end
