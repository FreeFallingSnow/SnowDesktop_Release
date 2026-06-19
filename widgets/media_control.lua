name = "媒体控制"
bottomBarHover = true

local btnRects = {}
local pendState = nil

local function readConfig()
    return {
        launcher = storage.get("launcher") or "",
    }
end

local function drawBtn(id, glyph, x, y, sz, enabled)
    local fg = enabled and 0xFFFFFF or 0x3D4555
    draw.rect(x, y, sz, sz, 0xFFFFFF, sz * 0.22, enabled and 0.10 or 0.04)
    draw.fa(glyph, x + sz * 0.12, y + sz * 0.12, sz * 0.76, fg)
    btnRects[id] = { x = x, y = y, w = sz, h = sz }
end

function render()
    local current = media.current()
    local w = layout.width()
    local h = layout.height()
    btnRects = {}

    local available = current.available and current.playbackStatus ~= "closed"
    local title = available and current.title ~= "" and current.title or "未在播放"
    local artist = available and current.artist ~= "" and current.artist or (available and current.sourceApp or "")
    if not available then
        artist = "双击打开播放器"
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
    draw.text(18, titleY, title, 14, 0xFFFFFF, w - 36, true, true)
    if artist ~= "" then
        draw.text(18, titleY + 22, artist, 12, 0x94A3B8, w - 36, true, true)
    end

    local btnSz = 40
    local btnGap = 12
    local total = btnSz * 3 + btnGap * 2
    local btnY = h - btnSz - 12
    local bx = (w - total) / 2

    drawBtn("previous", "", bx, btnY, btnSz, available and current.canPrevious)
    drawBtn("playPause", isPlaying and "" or "",
        bx + btnSz + btnGap, btnY, btnSz, available and current.canPlayPause)
    drawBtn("next", "", bx + (btnSz + btnGap) * 2, btnY, btnSz, available and current.canNext)
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
    imgui.text("无播放时双击打开")
    imgui.spacing()

    local path = imgui.inputText("##launcher", cfg.launcher)
    if path ~= cfg.launcher then
        storage.set("launcher", path)
    end

    imgui.spacing()
    imgui.text("或从桌面选择：")

    local items = desktop.items()
    local labels = { "（不设置）" }
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

    imgui.spacing()
    if imgui.button("清除设置") then
        storage.remove("launcher")
    end
end

function getContextMenu()
    return {
        { id = 1, label = "设置启动项", icon = "" },
    }
end

function onMenu(id)
    if id == 1 then widget.invalidate() end
end
