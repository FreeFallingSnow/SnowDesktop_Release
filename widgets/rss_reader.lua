name = "RSS 阅读器"
bottomBarHover = false

local articles = {}
local feedTitle = ""
local loading = false
local lastError = ""
local visibleRange = { first = 0, last = 0, offset = 0 }

local function readConfig()
    return {
        url = storage.get("url") or "https://www.ithome.com/rss/",
        interval = tonumber(storage.get("interval")) or 1800,
        maxItems = tonumber(storage.get("maxItems")) or 30,
    }
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
        lastError = "请求失败，请检查 URL 和网络"
    end
end

function onVisible()
    local cfg = readConfig()
    widget.setTimer("rss-refresh", cfg.interval * 1000, true)
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
    if body == "" then lastError = "响应为空"; return end

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
    lastError = #parsed == 0 and "未解析到文章" or ""
end

function render()
    widget.setTitle(feedTitle ~= "" and feedTitle or "RSS 阅读器")
    local w = layout.width()
    local h = layout.height()
    local padX = 14
    local headerTop = 11
    local headerHeight = 24
    local listTop = 43
    local listBottom = h - 16
    local itemH = 48
    local numberW = 20
    local textX = padX + numberW + 5
    local textW = math.max(40, w - textX - padX)

    if loading and #articles == 0 then
        draw.text(padX, h * 0.34, "正在获取订阅…", 13, 0x94A3B8,
            w - padX * 2, true, true)
        return
    end
    if lastError ~= "" and #articles == 0 then
        draw.text(padX, h * 0.27, lastError, 12, 0xFF8B8B,
            w - padX * 2, false, false)
        draw.text(padX, h * 0.27 + 34, "可在“详细设置”中修改 RSS 地址",
            11, 0x94A3B8, w - padX * 2, false, true)
        return
    end

    local countW = 52
    local countText = tostring(#articles) .. " 篇"
    local countMetrics = draw.measureText(countText, 10, countW, false)
    draw.text(padX, headerTop, feedTitle ~= "" and feedTitle or "RSS",
        14, 0xF8FAFC, w - padX * 2 - countW, false, true)
    draw.text(w - 14 - countMetrics.width, headerTop + 2, countText,
        10, 0x8291A3, countMetrics.width + 1, false, true)
    draw.line(padX, headerTop + headerHeight, w - padX,
        headerTop + headerHeight, 1, 0xFFFFFF, 0.10)

    local visible = ui.virtualList("articles", padX, listTop,
        w - padX * 2, math.max(1, listBottom - listTop), itemH, #articles)
    visibleRange = visible

    draw.pushClip(padX, listTop, w - padX * 2, math.max(1, listBottom - listTop))
    for i = visible.first, visible.last do
        local a = articles[i]
        if a then
            local y = listTop + (i - 1) * itemH - visible.offset
            local numberText = tostring(i)
            local numberMetrics = draw.measureText(numberText, 13, numberW, true)
            draw.text(padX + (numberW - numberMetrics.width) / 2,
                y + (itemH - numberMetrics.height) / 2,
                numberText, 13, 0xFFFFFF, numberW, true, true)
            draw.text(textX, y + 4, a.title, 12, 0xF1F5F9,
                textW, false, true)
            local dateShort = a.date:match("(%d%d? .%l%l%l? %d%d%d%d)") or a.date:sub(1, 16)
            if dateShort == "" then dateShort = a.date:sub(1, 10) end
            draw.text(textX, y + 25,
                dateShort ~= "" and dateShort or a.link:sub(1, 36),
                10, 0x7E8C9D, textW, false, true)
            draw.line(textX, y + itemH - 1, w - padX,
                y + itemH - 1, 1, 0xFFFFFF, 0.07)
        end
    end
    draw.popClip()

    if #articles == 0 then
        draw.text(padX, listTop + 22, "暂无文章，等待刷新…",
            12, 0x94A3B8, w - padX * 2, true, true)
    end
end

function onDoubleClick(x, y)
    local itemH = 48
    local listTop = 43
    local listBottom = layout.height() - 16

    if y < listTop or y >= listBottom then return end
    for i = visibleRange.first, visibleRange.last do
        local itemY = listTop + (i - 1) * itemH - visibleRange.offset
        if y >= itemY and y < itemY + itemH then
            local a = articles[i]
            if a and a.link ~= "" then
                desktop.open(a.link)
            end
            return
        end
    end
end

function imguiRender()
    local cfg = readConfig()

    local url = imgui.inputText("RSS 地址", cfg.url)
    if url ~= cfg.url then
        storage.set("url", url)
        articles = {}
        feedTitle = ""
        lastError = ""
    end

    local interval = imgui.sliderInt("刷新间隔（秒）", cfg.interval, 60, 3600)
    if interval ~= cfg.interval then
        storage.set("interval", tostring(interval))
        widget.cancelTimer("rss-refresh")
        widget.setTimer("rss-refresh", interval * 1000, true)
    end

    local maxItems = imgui.sliderInt("最大条目数", cfg.maxItems, 10, 100)
    if maxItems ~= cfg.maxItems then
        storage.set("maxItems", tostring(maxItems))
    end

    imgui.spacing()
    if imgui.button("立即刷新") then fetch() end

    imgui.sameLine()
    if imgui.button("清除缓存") then
        articles = {}
        feedTitle = ""
        lastError = ""
        fetch()
    end
end

function getContextMenu()
    return {
        { id = 1, label = "立即刷新", icon = "" },
        { id = 2, label = "清除缓存", icon = "" },
        { separator = true },
        { id = 3, label = "打开源地址", icon = "" },
    }
end

function onMenu(id)
    if id == 1 then fetch()
    elseif id == 2 then articles = {}; feedTitle = ""; lastError = ""; fetch()
    elseif id == 3 then
        local cfg = readConfig()
        if cfg.url ~= "" then desktop.open(cfg.url) end
    end
end
