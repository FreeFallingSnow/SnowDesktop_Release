-- rss-reader/main.lua - API v2 bounded network task and virtual feed list
local descriptor

local fluent = {
    refresh = utf8.char(0xF13D),
    clear = utf8.char(0xF201),
    open = utf8.char(0xF582),
}

local DEFAULT_URL = "https://www.ithome.com/rss/"

local settings = {
    fields = {
        { key = "url", label = l10n.tr("lua_widget.rss_reader.url"),
            type = "text", default = DEFAULT_URL },
        { key = "interval",
            label = l10n.tr("lua_widget.rss_reader.refresh_interval"),
            type = "int", default = 1800, min = 60, max = 3600 },
        { key = "maxItems",
            label = l10n.tr("lua_widget.rss_reader.max_items"),
            type = "int", default = 30, min = 10, max = 100 },
        { key = "fontSize",
            label = l10n.tr("lua_widget.rss_reader.article_font_size"),
            type = "int", default = 15, min = 10, max = 24 },
    },
}

local function config()
    return {
        url = storage.get("url") or DEFAULT_URL,
        interval = math.max(60, math.min(3600,
            tonumber(storage.get("interval")) or 1800)),
        maxItems = math.max(10, math.min(100,
            tonumber(storage.get("maxItems")) or 30)),
        fontSize = math.max(10, math.min(24,
            tonumber(storage.get("fontSize")) or 15)),
    }
end

local function palette(context)
    if context.theme and context.theme.mode == "light" then
        return {
            header = 0x0F172A, count = 0x334155, divider = 0x334155,
            number = 0x475569, title = 0x1E293B, date = 0x64748B,
            status = 0x334155, error = 0xB91C1C, card = 0x000000,
        }
    end
    return {
        header = 0xF8FAFC, count = 0xF1F5F9, divider = 0xFFFFFF,
        number = 0xFFFFFF, title = 0xF1F5F9, date = 0x94A3B8,
        status = 0xF1F5F9, error = 0xFF8B8B, card = 0xFFFFFF,
    }
end

local function decodeText(value)
    return (value or ""):gsub("<!%[CDATA%[(.-)%]%]>", "%1")
        :gsub("<[^>]+>", "")
        :gsub("&lt;", "<"):gsub("&gt;", ">")
        :gsub("&amp;", "&"):gsub("&quot;", "\"")
        :gsub("&#39;", "'")
end

local function parseRssItem(xml)
    return {
        title = decodeText(xml:match("<title>(.-)</title>")),
        link = decodeText(xml:match("<link>(.-)</link>")),
        description = decodeText(xml:match("<description>(.-)</description>")),
        date = decodeText(xml:match("<pubDate>(.-)</pubDate>") or
            xml:match("<dc:date>(.-)</dc:date>")),
    }
end

local function parseAtomEntry(xml)
    local link = xml:match('<link[^>]+href="([^"]*)"') or
        xml:match("<link[^>]+href='([^']*)'") or ""
    return {
        title = decodeText(xml:match("<title[^>]*>(.-)</title>")),
        link = decodeText(link),
        description = decodeText(xml:match("<summary[^>]*>(.-)</summary>") or
            xml:match("<content[^>]*>(.-)</content>")),
        date = decodeText(xml:match("<published>(.-)</published>") or
            xml:match("<updated>(.-)</updated>")),
    }
end

local function parseFeed(body, maximum)
    local title = decodeText(body:match("<channel>.-<title>(.-)</title>") or
        body:match("<feed[^>]*>.-<title[^>]*>(.-)</title>"))
    local items = {}
    local atom = false
    for xml in body:gmatch("<entry[^>]*>(.-)</entry>") do
        atom = true
        local item = parseAtomEntry(xml)
        if item.title ~= "" then items[#items + 1] = item end
        if #items >= maximum then break end
    end
    if not atom then
        for xml in body:gmatch("<item[^>]*>(.-)</item>") do
            local item = parseRssItem(xml)
            if item.title ~= "" then items[#items + 1] = item end
            if #items >= maximum then break end
        end
    end
    return title, items
end

local function loadPreview(model)
    model.feedTitle = storage.get("previewFeedTitle") or ""
    for index = 1, 12 do
        local title = storage.get("previewArticle" .. index .. "Title")
        if not title or title == "" then break end
        model.articles[#model.articles + 1] = {
            title = title,
            date = "",
            displayDate = storage.get(
                "previewArticle" .. index .. "Date") or "",
            link = storage.get("previewArticle" .. index .. "Link") or "",
            description = storage.get(
                "previewArticle" .. index .. "Description") or "",
        }
    end
end

local function fetch(model, bypassCache)
    if model.requestId then return end
    local cfg = config()
    if cfg.url == "" then return end
    local requestId, requestError = task.start("network.request", {
        url = cfg.url,
        timeoutMs = 15000,
        cacheSeconds = bypassCache and 0 or 120,
        maxBytes = 1024 * 1024,
    })
    if requestId then
        model.requestId = requestId
        model.loading = true
        model.lastFetchMs = time.monotonic()
        model.error = nil
    else
        model.loading = false
        model.error = requestError or "requestRejected"
    end
end

local function clear(model)
    model.articles = {}
    model.feedTitle = ""
    model.error = nil
    interaction.setScrollOffset("rss.scroll", 0)
end

local function registerRegion(key, shape, events, label, enabled)
    interaction.region({
        key = key, shape = shape,
        cursor = enabled == false and "default" or "hand",
        enabled = enabled ~= false,
        events = events,
        accessibility = { role = "button", label = label },
    })
end

local function setup(context)
    local model = {
        articles = {}, feedTitle = "", loading = false,
        error = nil, requestId = nil, lastFetchMs = 0,
    }
    widget.setTitle(l10n.tr("lua_widget.rss_reader.name"))
    schedule.every("rss-refresh", 60000, { whenHidden = "pause" })
    if context.preview then loadPreview(model) else fetch(model, false) end
    return model
end

local function render(context, model)
    local cfg = config()
    local colors = palette(context)
    local width = layout.width()
    local height = layout.height()
    local pad = layout.cu(14)
    local headerTop = layout.cu(10)
    local headerFont = layout.fontCu(math.min(28, cfg.fontSize + 2))
    local smallFont = layout.fontCu(math.max(9, cfg.fontSize - 2))
    local title = model.feedTitle ~= "" and model.feedTitle or "RSS"
    widget.setTitle(model.feedTitle ~= "" and model.feedTitle or
        l10n.tr("lua_widget.rss_reader.name"))

    local countText = l10n.tr("lua_widget.rss_reader.article_count",
        tostring(#model.articles))
    local countMetrics = draw.measureText(countText, smallFont, width, false)
    draw.text(pad, headerTop, title, headerFont, colors.header,
        math.max(1, width - pad * 2 - countMetrics.width - layout.cu(10)),
        false, true)
    draw.text(width - pad - countMetrics.width, headerTop + layout.cu(4),
        countText, smallFont, colors.count, countMetrics.width + 1,
        false, true)
    local headerBottom = headerTop + layout.cu(cfg.fontSize + 14)
    draw.line(pad, headerBottom, width - pad, headerBottom,
        layout.cu(1), colors.divider, 0.10)

    local listTop = headerBottom + layout.cu(7)
    local listBottom = height - layout.cu(2)
    local viewportHeight = math.max(1, listBottom - listTop)
    local viewport = { type = "rect", x = pad, y = listTop,
        width = width - pad * 2, height = viewportHeight }
    local scrollViewport = { type = "rect", x = pad, y = listTop,
        width = width - pad, height = viewportHeight }
    interaction.region({
        key = "rss.surface", shape = viewport,
        events = { contextMenu = {
            id = "rss.menu", scope = "component" } },
        accessibility = { role = "list", label = descriptor.name },
    })

    if model.loading and #model.articles == 0 then
        draw.text(pad, listTop + viewportHeight * 0.34,
            l10n.tr("lua_widget.rss_reader.loading"),
            layout.fontCu(13), colors.status, width - pad * 2, true, true)
        return
    end
    if model.error and #model.articles == 0 then
        draw.text(pad, listTop + viewportHeight * 0.27,
            l10n.tr("lua_widget.rss_reader.request_failed"),
            layout.fontCu(12), colors.error, width - pad * 2, false, false)
        draw.text(pad, listTop + viewportHeight * 0.27 + layout.cu(36),
            l10n.tr("lua_widget.rss_reader.settings_hint"),
            layout.fontCu(11), colors.status, width - pad * 2, false, true)
        return
    end
    if #model.articles == 0 then
        draw.text(pad, listTop + layout.cu(22),
            l10n.tr("lua_widget.rss_reader.no_articles"),
            layout.fontCu(12), colors.status, width - pad * 2, true, true)
        return
    end

    local rowHeight = layout.cu(math.max(48, cfg.fontSize * 2 + 22))
    local scroll = interaction.scroll({
        key = "rss.scroll", shape = scrollViewport,
        contentHeight = math.ceil(#model.articles * rowHeight),
    })
    local first = math.max(1, math.floor(scroll.offset / rowHeight) + 1)
    local last = math.min(#model.articles,
        math.ceil((scroll.offset + viewportHeight) / rowHeight))
    local numberWidth = layout.cu(22)
    local textX = pad + numberWidth + layout.cu(6)
    local textWidth = math.max(1, width - textX - pad)
    draw.pushClip(pad, listTop, width - pad * 2, viewportHeight)
    for index = first, last do
        local article = model.articles[index]
        local y = listTop + (index - 1) * rowHeight - scroll.offset
        local key = "rss.article." .. tostring(index)
        if interaction.isHovered(key) then
            draw.rect(pad, y, width - pad * 2, rowHeight - layout.cu(2),
                colors.card, layout.cu(7), 0.07)
        end
        registerRegion(key, { type = "roundedRect", x = pad, y = y,
            width = width - pad * 2, height = rowHeight - layout.cu(2),
            radius = layout.cu(7) }, {
            doubleClick = { id = "rss.open", value = article.link },
            contextMenu = { id = "rss.menu", value = article.link },
        }, article.title, article.link ~= "")
        local number = tostring(index)
        local numberMetrics = draw.measureText(number,
            layout.fontCu(13), numberWidth, true)
        draw.text(pad + math.max(0, (numberWidth - numberMetrics.width) / 2),
            y + layout.cu(14), number, layout.fontCu(13), colors.number,
            numberWidth, true, true)
        draw.text(textX, y + layout.cu(4), article.title,
            layout.fontCu(cfg.fontSize), colors.title, textWidth, false, true)
        local shortDate = article.displayDate or
            article.date:match("(%d%d? .%l%l%l? %d%d%d%d)") or
            article.date:sub(1, 16)
        if shortDate == "" then shortDate = article.link:sub(1, 42) end
        draw.text(textX, y + rowHeight - layout.cu(22), shortDate,
            smallFont, colors.date, textWidth, false, true)
        draw.line(textX, y + rowHeight - layout.cu(1), width - pad,
            y + rowHeight - layout.cu(1), layout.cu(1),
            colors.divider, 0.07)
    end
    draw.popClip()
end

local function openUri(model, url)
    if not url or url == "" or not widget.hasPermission("shell.launch") then
        return
    end
    local taskId, taskError = task.start("shell.openUri", { url = url })
    if taskId then
        model.openTaskId = taskId
    else
        widget.log("warn", "shell.openUri rejected: " .. tostring(taskError))
    end
end

local function event(_context, model, value)
    if value.kind == "environment" then
        widget.setTitle(model.feedTitle ~= "" and model.feedTitle or
            l10n.tr("lua_widget.rss_reader.name"))
        return
    elseif value.kind == "schedule" and value.id == "rss-refresh" then
        local cfg = config()
        if not model.requestId and
            time.monotonic() - model.lastFetchMs >= cfg.interval * 1000 then
            fetch(model, false)
        end
        return
    elseif value.kind == "task.complete" then
        if value.taskId == model.requestId then
            model.requestId = nil
            model.loading = false
            if value.ok and value.value then
                if value.value.body == "" then
                    model.error = "emptyResponse"
                else
                    local feedTitle, articles = parseFeed(
                        value.value.body, config().maxItems)
                    model.feedTitle = feedTitle
                    model.articles = articles
                    model.error = #articles == 0 and "parseFailed" or nil
                    interaction.setScrollOffset("rss.scroll", 0)
                end
            else
                model.error = value.error or "networkError"
            end
        elseif value.taskId == model.openTaskId then
            model.openTaskId = nil
            if not value.ok then
                widget.log("warn", "shell.openUri failed: " ..
                    tostring(value.error))
            end
        end
        return
    elseif value.kind ~= "action" then
        return
    end

    local url = value.value and tostring(value.value) or nil
    if value.id == "rss.refresh" then
        fetch(model, true)
    elseif value.id == "rss.clear" then
        clear(model)
        fetch(model, true)
    elseif value.id == "rss.open" then
        openUri(model, url)
    elseif value.id == "rss.openSource" then
        openUri(model, config().url)
    end
end

local function menu(_context, _model, request)
    if request.id ~= "rss.menu" then return nil end
    local articleUrl = request.value and tostring(request.value) or nil
    local canOpen = widget.hasPermission("shell.launch")
    if articleUrl and articleUrl ~= "" then
        return ui.menu({
            { id = "rss.open",
                label = l10n.tr("lua_widget.rss_reader.open_article"),
                icon = fluent.open, iconFont = "fluent",
                enabled = canOpen },
        })
    end
    local items = {
        { id = "rss.refresh",
            label = l10n.tr("lua_widget.rss_reader.refresh_now"),
            icon = fluent.refresh, iconFont = "fluent" },
        { id = "rss.clear",
            label = l10n.tr("lua_widget.rss_reader.clear_cache"),
            icon = fluent.clear, iconFont = "fluent" },
    }
    items[#items + 1] = { type = "separator" }
    items[#items + 1] = { id = "rss.openSource",
        label = l10n.tr("lua_widget.rss_reader.open_source"),
        icon = fluent.open, iconFont = "fluent", enabled = canOpen }
    return ui.menu(items)
end

local function dispose(_context, model)
    if model.requestId then task.cancel(model.requestId) end
    if model.openTaskId then task.cancel(model.openTaskId) end
    schedule.cancel("rss-refresh")
end

descriptor = {
    name = l10n.tr("lua_widget.rss_reader.name"),
    useCustomStyle = true,
    followPersonalizationDefault = true,
    bottomBarHover = false,
    bg = 0x0F172A,
    border = 0xFFFFFF,
    alpha = 0.38,
    borderAlpha = 0.16,
    gradientEndA = 0.28,
    settings = settings,
    setup = setup,
    render = render,
    event = event,
    menu = menu,
    dispose = dispose,
}

return widget.define(descriptor)
