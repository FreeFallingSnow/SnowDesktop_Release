name = l10n.tr("lua_widget.media_control.name")
useCustomStyle = true
followPersonalizationDefault = true
bottomBarHover = true

bg = 0x0F172A
border = 0xFFFFFF
alpha = 0.42
borderAlpha = 0.16
gradientEndA = 0.30
textColor = 0xFFFFFF
local btnRects = {}
local pendState = nil

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
        { key = "textColor", label = l10n.tr("lua_widget.common.text_color"), type = "color", default = 0xFFFFFF },
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
    imgui.text(l10n.tr("lua_widget.media_control.select_launcher"))

    local items = desktop.items()
    local labels = { l10n.tr("lua_widget.media_control.not_set") }
    local selIdx = 1
    for i, item in ipairs(items) do
        labels[#labels + 1] = (item.title or "") .. " (" .. (item.type or "") .. ")"
        if item.path == cfg.launcher then selIdx = i + 1 end
    end

    local nv = imgui.combo("##item", selIdx, labels)
    if nv ~= selIdx then
        if nv == 1 then
            storage.set("launcher", "")
        else
            local item = items[nv - 1]
            if item and item.path then
                storage.set("launcher", item.path)
            end
        end
    end
end

function getContextMenu()
    return {
        { id = 1, label = l10n.tr("lua_widget.media_control.configure_launcher"), icon = "" },
    }
end

function onMenu(id)
    if id == 1 then widget.invalidate() end
end
