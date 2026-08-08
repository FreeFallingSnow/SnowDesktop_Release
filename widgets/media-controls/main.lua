name = l10n.tr("lua_widget.media_control.name")
useCustomStyle = true
followPersonalizationDefault = true
bottomBarHover = true

local fluent = {
    settings = utf8.char(0xF6A9),
}

bg = 0x0F172A
border = 0xFFFFFF
alpha = 0.42
borderAlpha = 0.16
gradientEndA = 0.30
local btnRects = {}
local pendState = nil
local launcherSearchQuery = nil
local launcherSearchResults = {}

local palettes = {
    dark = {
        title   = 0xFFFFFF,
        subtitle = 0xF1F5F9,
        btnText = 0xFFFFFF,
        btnDisabled = 0x64748B,
        btnBg   = 0xFFFFFF,
    },
    light = {
        title   = 0x1E293B,
        subtitle = 0x334155,
        btnText = 0x1E293B,
        btnDisabled = 0x94A3B8,
        btnBg   = 0x000000,
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
        { key = "launcher", label = l10n.tr("lua_widget.media_control.launcher"), type = "text", default = "" },
    }
}

local function readConfig()
    return {
        launcher = storage.get("launcher") or "",
    }
end

local function drawBtn(id, glyph, x, y, sz, enabled, pal)
    local fg = enabled and pal.btnText or pal.btnDisabled
    draw.rect(x, y, sz, sz, pal.btnBg, sz * 0.22, enabled and 0.10 or 0.04)
    draw.fa(glyph, x + sz * 0.12, y + sz * 0.12, sz * 0.76, fg)
    btnRects[id] = { x = x, y = y, w = sz, h = sz }
end

function render()
    local current = media.current()
    local w = layout.width()
    local h = layout.height()
    btnRects = {}
    local pal = getPalette()

    local available = current.available and current.playbackStatus ~= "closed"
    local title = available and current.title ~= "" and current.title or l10n.tr("lua_widget.media_control.not_playing")
    local artist = available and current.artist ~= "" and current.artist or (available and current.sourceApp or "")
    if not available then
        artist = l10n.tr("lua_widget.media_control.double_click_player")
    end

    local isPlaying = available and current.playbackStatus == "playing"
    if pendState == "playing" then
        if isPlaying then pendState = nil end
        isPlaying = true
    elseif pendState == "paused" then
        if not isPlaying then pendState = nil end
        isPlaying = false
    elseif pendState then
        pendState = nil
    end

    local titleY = artist ~= "" and h * 0.18 or h * 0.30
    draw.text(layout.cu(18), titleY, title, layout.fontCu(15), pal.title, w - layout.cu(36), true, true)
    if artist ~= "" then
        draw.text(layout.cu(18), titleY + layout.cu(22), artist, layout.fontCu(12), pal.subtitle, w - layout.cu(36), true, true)
    end

    local btnSz = layout.cu(40)
    local btnGap = layout.cu(12)
    local total = btnSz * 3 + btnGap * 2
    local btnY = h - btnSz - layout.cu(12)
    local bx = (w - total) / 2

    drawBtn("previous", "", bx, btnY, btnSz, available and current.canPrevious, pal)
    drawBtn("playPause", isPlaying and "" or "",
        bx + btnSz + btnGap, btnY, btnSz, available and current.canPlayPause, pal)
    drawBtn("next", "", bx + (btnSz + btnGap) * 2, btnY, btnSz, available and current.canNext, pal)
end

function onClick(x, y)
    for id, r in pairs(btnRects) do
        if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            if id == "previous" then media.previous()
            elseif id == "playPause" then
                local current = media.current()
                local effective = current.playbackStatus == "playing"
                if pendState == "playing" then effective = true
                elseif pendState == "paused" then effective = false end
                pendState = effective and "paused" or "playing"
                media.playPause()
            elseif id == "next" then media.next()
            end
            widget.invalidate()
            return
        end
    end
end

function onDoubleClick(x, y)
    local current = media.current()
    if not current.available or current.playbackStatus == "closed" then
        local cfg = readConfig()
        if cfg.launcher ~= "" then
            desktop.open(cfg.launcher)
        else
            widget.openSettings()
        end
    end
end

function imguiRender()
    local cfg = readConfig()
    local query = storage.get("launcherSearch") or ""
    imgui.settingRow(l10n.tr("lua_widget.media_control.select_launcher"))
    local nextQuery = imgui.inputText("##launcherSearch", query)
    if nextQuery ~= query then
        query = nextQuery
        storage.set("launcherSearch", query)
        launcherSearchQuery = nil
    end

    if imgui.selectable(l10n.tr("lua_widget.media_control.not_set"), cfg.launcher == "") then
        if cfg.launcher ~= "" then
            storage.set("launcher", "")
        end
        return
    end

    if query == "" then return end

    if launcherSearchQuery ~= query then
        local results = {}
        local seen = {}
        local function append(items)
            for _, item in ipairs(items or {}) do
                local key = string.lower(item.path or item.id or "")
                if key ~= "" and not seen[key] then
                    seen[key] = true
                    results[#results + 1] = item
                end
            end
        end
        append(desktop.find(query, 40))
        if desktop.findApplications then
            append(desktop.findApplications(query, 40))
        end
        launcherSearchQuery = query
        launcherSearchResults = results
    end

    if #launcherSearchResults == 0 then
        imgui.text(l10n.tr("lua_widget.media_control.no_search_results"))
        return
    end

    for _, item in ipairs(launcherSearchResults) do
        local label = (item.title or "") .. " (" .. (item.type or "") .. ")"
        if imgui.selectable(label, item.path == cfg.launcher) then
            storage.set("launcher", item.path or "")
        end
    end
end

function onDesktopChanged(reason)
    launcherSearchQuery = nil
end

function getContextMenu()
    return {
        { id = 1, label = l10n.tr("lua_widget.media_control.configure_launcher"), icon = fluent.settings, iconFont = "fluent" },
    }
end

function onMenu(id)
    if id == 1 then widget.openSettings() end
end
