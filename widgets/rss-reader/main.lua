name = l10n.tr("lua_widget.rss_reader.name")
useCustomStyle = true
followPersonalizationDefault = true
bottomBarHover = false

local fluent = {
    refresh = utf8.char(0xF13D),
    clear = utf8.char(0xF201),
    open = utf8.char(0xF582),
}

bg = 0x0F172A
border = 0xFFFFFF
alpha = 0.38
borderAlpha = 0.16
gradientEndA = 0.28
textColor = 0xFFFFFF
local articles = {}
local feedTitle = ""
local loading = false
local lastError = ""
local lastUrl = nil
local lastInterval = nil
local lastMaxItems = nil

feedTitle = storage.get("previewFeedTitle") or feedTitle
for index = 1, 12 do
    local title = storage.get("previewArticle" .. tostring(index) .. "Title")
    if title and title ~= "" then
        articles[#articles + 1] = {
            title = title,
            date = storage.get("previewArticle" .. tostring(index) .. "Date") or "",
            link = storage.get("previewArticle" .. tostring(index) .. "Link") or "",
            desc = storage.get("previewArticle" .. tostring(index) .. "Description") or "",
        }
    end
end

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
        headerText  = 0xF8FAFC,
        countText   = 0xF1F5F9,
        divColor    = 0xFFFFFF,
        numberText  = 0xFFFFFF,
        titleText   = 0xF1F5F9,
        dateText    = 0x94A3B8,
        loadingText = 0xF1F5F9,
        errorText   = 0xFF8B8B,
        emptyText   = 0xF1F5F9,
    },
    light = {
        headerText  = 0x0F172A,
        countText   = 0x334155,
        divColor    = 0x334155,
        numberText  = 0x475569,
        titleText   = 0x1E293B,
        dateText    = 0x94A3B8,
        loadingText = 0x334155,
        errorText   = 0xDC2626,
        emptyText   = 0x334155,
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
        { key = "url", label = l10n.tr("lua_widget.rss_reader.url"), type = "text", default = "https://www.ithome.com/rss/" },
        { key = "interval", label = l10n.tr("lua_widget.rss_reader.refresh_interval"), type = "int", default = 1800, min = 60, max = 3600 },
        { key = "maxItems", label = l10n.tr("lua_widget.rss_reader.max_items"), type = "int", default = 30, min = 10, max = 100 },
        { key = "fontSize", label = l10n.tr("lua_widget.rss_reader.article_font_size"), type = "int", default = 15, min = 10, max = 24 },
        { key = "textColor", label = l10n.tr("lua_widget.common.text_color"), type = "color", default = 0xFFFFFF },
    }
}

local function readConfig()
    return {
        url = storage.get("url") or "https://www.ithome.com/rss/",
        interval = tonumber(storage.get("interval")) or 1800,
        maxItems = tonumber(storage.get("maxItems")) or 30,
        fontSize = math.max(10, math.min(24, tonumber(storage.get("fontSize")) or 15)),
    }
end

local function articleLayout(fontSize)
    local secondaryFontSize = math.max(9, fontSize - 2)
    local secondaryTop = fontSize + 13
    local itemHeight = math.max(48, secondaryTop + secondaryFontSize + 7)
    return itemHeight, secondaryFontSize, secondaryTop
end

local function headerLayout(fontSize)
    local headerFontSize = math.min(28, fontSize + 2)
    local headerHeight = math.max(24, headerFontSize + 8)
    local listTop = 11 + headerHeight + 8
    return headerFontSize, headerHeight, listTop
end

local function articleListGeometry(fontSize)
    local w = layout.width()
    local h = layout.height()
    local padX = layout.cu(14)
    local _, _, listTopCu = headerLayout(fontSize)
    local itemHeightCu = articleLayout(fontSize)
    local listTop = layout.cu(listTopCu)
    -- The host reserves this area for moving/resizing the widget. Keeping the
    -- list above it makes the visible rows and their clickable area identical.
    local listBottom = h - layout.cu(layout.barHeight() + 2)
    return padX, listTop, w - padX, listBottom, layout.cu(itemHeightCu)
end

local function currentArticleRange(fontSize)
    local listLeft, listTop, listRight, listBottom, itemH =
        articleListGeometry(fontSize)
    local range = ui.virtualList("articles", listLeft, listTop,
        math.max(1, listRight - listLeft),
        math.max(1, listBottom - listTop), itemH, #articles)
    return range, listLeft, listTop, listRight, listBottom, itemH
end

local function clearCache()
    articles = {}
    feedTitle = ""
    lastError = ""
end

local function parseItem(itemXml)
    local title = itemXml:match("<title><!%[CDATA%[(.-)%]%]></title>")
        or itemXml:match("<title>(.-)</title>") or ""
    local link = itemXml:match("<link>(.-)</link>") or ""
    local desc = itemXml:match("<description><!%[CDATA%[(.-)%]%]></description>")
        or itemXml:match("<description>(.-)</description>") or ""
    local date = itemXml:match("<pubDate>(.-)</pubDate>")
        or itemXml:match("<dc:date>(.-)</dc:date>") or ""
    -- Strip HTML tags from description
    desc = desc:gsub("<[^>]+>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&"):gsub("&quot;", "\""):gsub("&#39;", "'")
    -- Clean title
    title = title:gsub("<[^>]+>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&"):gsub("&quot;", "\""):gsub("&#39;", "'")
    return { title = title, link = link, desc = desc, date = date }
end

local function parseAtom(itemXml)
    local title = itemXml:match("<title>(.-)</title>") or ""
    local link = ""
    for href in itemXml:gmatch('<link[^>]+href="([^"]*)"') do link = href; break end
    if link == "" then link = itemXml:match("<link[^>]*href='([^']*)'") or "" end
    local desc = itemXml:match("<summary>(.-)</summary>")
        or itemXml:match("<content[^>]*>(.-)</content>") or ""
    local date = itemXml:match("<published>(.-)</published>")
        or itemXml:match("<updated>(.-)</updated>") or ""
    desc = desc:gsub("<[^>]+>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
    title = title:gsub("<[^>]+>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
    return { title = title, link = link, desc = desc, date = date }
end

local function fetch()
    if loading then return end
    loading = true
    local cfg = readConfig()
    if cfg.url == "" then loading = false; return end
    local id = http.request({
        url = cfg.url,
        method = "GET",
        timeoutMs = 15000,
        cacheSeconds = 120,
        headers = { ["User-Agent"] = "SnowDesktop RSS Reader" }
    })
    if not id then
        loading = false
        lastError = l10n.tr("lua_widget.rss_reader.request_failed")
    end
end

local function syncConfig(startTimer)
    local cfg = readConfig()
    local hadConfig = lastUrl ~= nil
    local urlChanged = hadConfig and cfg.url ~= lastUrl
    local intervalChanged = hadConfig and cfg.interval ~= lastInterval
    local maxItemsChanged = hadConfig and cfg.maxItems ~= lastMaxItems

    lastUrl = cfg.url
    lastInterval = cfg.interval
    lastMaxItems = cfg.maxItems

    if startTimer or intervalChanged then
        widget.cancelTimer("rss-refresh")
        widget.setTimer("rss-refresh", cfg.interval * 1000, true)
    end

    if urlChanged or maxItemsChanged then
        clearCache()
        fetch()
    end

    return cfg
end

function onVisible()
    syncConfig(true)
    if #articles == 0 then fetch() end
end

function onHidden()
    widget.cancelTimer("rss-refresh")
end

function onTimer(name)
    if name == "rss-refresh" then fetch() end
end

function onHttpResponse(id, response)
    loading = false
    if not response.ok then
        lastError = response.error ~= "" and response.error or ("HTTP " .. tostring(response.status))
        return
    end

    local body = response.body
    if body == "" then lastError = l10n.tr("lua_widget.rss_reader.empty_response"); return end

    -- Parse feed channel title
    local ft = body:match("<channel>.-<title>(.-)</title>")
        or body:match("<feed>.-<title>(.-)</title>") or ""
    ft = ft:gsub("<[^>]+>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
    feedTitle = ft

    -- Parse items
    local parsed = {}
    local cfg = readConfig()

    -- Try Atom first (entries)
    local isAtom = false
    for entry in body:gmatch("<entry>(.-)</entry>") do
        isAtom = true
        if #parsed >= cfg.maxItems then break end
        local item = parseAtom(entry)
        if item.title ~= "" then parsed[#parsed + 1] = item end
    end

    -- Try RSS items
    if not isAtom then
        for itemXml in body:gmatch("<item>(.-)</item>") do
            if #parsed >= cfg.maxItems then break end
            local item = parseItem(itemXml)
            if item.title ~= "" then parsed[#parsed + 1] = item end
        end
    end

    articles = parsed
    lastError = #parsed == 0 and l10n.tr("lua_widget.rss_reader.no_articles_parsed") or ""
end

function render()
    local cfg = syncConfig(false)
    widget.setTitle(feedTitle ~= "" and feedTitle or l10n.tr("lua_widget.rss_reader.name"))
    local w = layout.width()
    local h = layout.height()
    local padX = layout.cu(14)
    local headerTop = layout.cu(11)
    local headerFontSize, headerHeightCu = headerLayout(cfg.fontSize)
    local headerHeight = layout.cu(headerHeightCu)
    local _, listTop, _, listBottom, itemH = articleListGeometry(cfg.fontSize)
    local _, secondaryFontSize, secondaryTopCu = articleLayout(cfg.fontSize)
    local numberW = layout.cu(20)
    local textX = padX + numberW + layout.cu(5)
    local textW = math.max(layout.cu(40), w - textX - padX)
    local pal = getPalette()

    if loading and #articles == 0 then
        draw.text(padX, h * 0.34, l10n.tr("lua_widget.rss_reader.loading"), layout.fontCu(13), pal.loadingText,
            w - padX * 2, true, true)
        return
    end
    if lastError ~= "" and #articles == 0 then
        draw.text(padX, h * 0.27, lastError, layout.fontCu(12), pal.errorText,
            w - padX * 2, false, false)
        draw.text(padX, h * 0.27 + layout.cu(34), l10n.tr("lua_widget.rss_reader.settings_hint"),
            layout.fontCu(11), pal.loadingText, w - padX * 2, false, true)
        return
    end

    local countText = l10n.tr("lua_widget.rss_reader.article_count", #articles)
    local countFontSize = secondaryFontSize
    local countMetrics = draw.measureText(countText, layout.fontCu(countFontSize), w, false)
    local countW = math.max(layout.cu(52), math.ceil(countMetrics.width))
    draw.text(padX, headerTop, feedTitle ~= "" and feedTitle or "RSS",
        layout.fontCu(headerFontSize), pal.headerText,
        w - padX * 2 - countW - layout.cu(6), false, true)
    local countTop = headerTop + layout.cu(math.max(0, (headerFontSize - countFontSize) / 2))
    draw.text(w - layout.cu(14) - countMetrics.width, countTop, countText,
        layout.fontCu(countFontSize), pal.countText, countMetrics.width + 1, false, true)
    draw.line(padX, headerTop + headerHeight, w - padX,
        headerTop + headerHeight, layout.cu(1), pal.divColor, 0.10)

    local visible = currentArticleRange(cfg.fontSize)

    draw.pushClip(padX, listTop, w - padX * 2, math.max(1, listBottom - listTop))
    for i = visible.first, visible.last do
        local a = articles[i]
        if a then
            local y = listTop + (i - 1) * itemH - visible.offset
            local numberText = tostring(i)
            local numberMetrics = draw.measureText(numberText, layout.fontCu(13), numberW, true)
            draw.text(padX + (numberW - numberMetrics.width) / 2,
                y + (itemH - numberMetrics.height) / 2,
                numberText, layout.fontCu(13), pal.numberText, numberW, true, true)
            draw.text(textX, y + layout.cu(4), a.title, layout.fontCu(cfg.fontSize), pal.titleText,
                textW, false, true)
            local dateShort = a.date:match("(%d%d? .%l%l%l? %d%d%d%d)") or a.date:sub(1, 16)
            if dateShort == "" then dateShort = a.date:sub(1, 10) end
            draw.text(textX, y + layout.cu(secondaryTopCu),
                dateShort ~= "" and dateShort or a.link:sub(1, 36),
                layout.fontCu(secondaryFontSize), pal.dateText, textW, false, true)
            draw.line(textX, y + itemH - layout.cu(1), w - padX,
                y + itemH - layout.cu(1), layout.cu(1), pal.divColor, 0.07)
        end
    end
    draw.popClip()

    if #articles == 0 then
        draw.text(padX, listTop + layout.cu(22), l10n.tr("lua_widget.rss_reader.no_articles"),
            layout.fontCu(12), pal.emptyText, w - padX * 2, true, true)
    end
end

function onDoubleClick(x, y)
    local cfg = readConfig()
    local range, listLeft, listTop, listRight, listBottom, itemH =
        currentArticleRange(cfg.fontSize)
    if x < listLeft or x >= listRight or
        y < listTop or y >= listBottom or itemH <= 0 then
        return
    end

    local offset = tonumber(range.offset) or 0
    local index = math.floor((y - listTop + offset) / itemH) + 1
    if index < (range.first or 1) or
        index > (range.last or 0) then
        return
    end

    local itemTop = listTop + (index - 1) * itemH - offset
    if y < itemTop or y >= math.min(itemTop + itemH, listBottom) then
        return
    end

    local article = articles[index]
    if article and article.link ~= "" then
        desktop.open(article.link)
    end
end

function imguiRender()
    syncConfig(false)
    if imgui.button(l10n.tr("lua_widget.rss_reader.refresh_now")) then fetch() end

    imgui.sameLine()
    if imgui.button(l10n.tr("lua_widget.rss_reader.clear_cache")) then
        clearCache()
        fetch()
    end
end

function getContextMenu()
    return {
        { id = 1, label = l10n.tr("lua_widget.rss_reader.refresh_now"), icon = fluent.refresh, iconFont = "fluent" },
        { id = 2, label = l10n.tr("lua_widget.rss_reader.clear_cache"), icon = fluent.clear, iconFont = "fluent" },
        { separator = true },
        { id = 3, label = l10n.tr("lua_widget.rss_reader.open_source"), icon = fluent.open, iconFont = "fluent" },
    }
end

function onMenu(id)
    if id == 1 then fetch()
    elseif id == 2 then clearCache(); fetch()
    elseif id == 3 then
        local cfg = readConfig()
        if cfg.url ~= "" then desktop.open(cfg.url) end
    end
end
