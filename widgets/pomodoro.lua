-- pomodoro.lua - 番茄钟
name = "番茄钟"
useCustomStyle = true
bottomBarHover = false

bg = 0xFFFFFF
border = 0xD0D0D0
alpha = 0.98
gradientEndA = 0.0

local DEFAULT_WORK_COLOR   = 0xFF6347
local DEFAULT_BREAK_COLOR  = 0x4ECDC4
local DEFAULT_TRACK_COLOR  = 0xE8E8E8

local TXT_DARK   = 0x333333
local TXT_MUTED  = 0x888888
local BTN_PAUSE  = 0xFFB347

function updateTickTimer()
    local state = storage.get("state") or "idle"
    if state == "work" or state == "break" then
        widget.setTimer("tick", 1000, true)
    else
        widget.cancelTimer("tick")
    end
end

function onVisible()
    updateTickTimer()
end

function onHidden()
    widget.cancelTimer("tick")
end

function onTimer(name)
    -- 宿主会在定时器回调后自动刷新当前组件。
end

function loadConfig()
    workMin           = tonumber(storage.get("workMin"))           or 25
    breakMin          = tonumber(storage.get("breakMin"))          or 5
    longBreakMin      = tonumber(storage.get("longBreakMin"))      or 15
    longBreakInterval = tonumber(storage.get("longBreakInterval")) or 4
    workColor         = tonumber(storage.get("workColor"))         or DEFAULT_WORK_COLOR
    breakColor        = tonumber(storage.get("breakColor"))        or DEFAULT_BREAK_COLOR
    trackColor        = tonumber(storage.get("trackColor"))        or DEFAULT_TRACK_COLOR

    local savedBg = tonumber(storage.get("bgColor"))
    if savedBg then bg = savedBg end
    local savedBorder = tonumber(storage.get("borderColor"))
    if savedBorder then border = savedBorder end
end

function timeNow()
    local t = sys.getTime()
    return t.hour * 3600 + t.min * 60 + t.sec
end

function elapsedSince(start)
    local now = timeNow()
    if now < start then now = now + 86400 end
    return now - start
end

function getState()           return storage.get("state") or "idle" end
function getPausedRemaining() return tonumber(storage.get("pausedRemaining")) or 0 end
function getSessions()        return tonumber(storage.get("sessions")) or 0 end

function targetForState(st)
    if st == "work" then
        return workMin * 60
    elseif st == "break" then
        local sessions = getSessions()
        if sessions > 0 and sessions % longBreakInterval == 0 then
            return longBreakMin * 60
        else
            return breakMin * 60
        end
    end
    return workMin * 60
end

function targetSeconds() return targetForState(getState()) end

function remainingSeconds()
    local s = getState()
    if s == "idle"    then return workMin * 60 end
    if s == "paused"  then return getPausedRemaining() end
    local rem = targetSeconds() - elapsedSince(tonumber(storage.get("startTime")) or 0)
    return rem > 0 and rem or 0
end

function progress()
    local s = getState()
    if s == "idle" then return 0 end
    local t = targetSeconds()
    if t == 0 then return 0 end
    local p = 1 - remainingSeconds() / t
    return p > 1 and 1 or p
end

function formatTime(sec)
    local m = math.floor(sec / 60)
    local s = math.floor(sec % 60)
    return string.format("%02d:%02d", m, s)
end

function sessionsInSet() return getSessions() % longBreakInterval end

function checkTransition()
    local s = getState()
    if s == "idle" or s == "paused" then return end
    if remainingSeconds() > 0 then return end

    if s == "work" then
        local sessions = getSessions() + 1
        storage.set("sessions", tostring(sessions))
        storage.set("state", "break")
        storage.set("startTime", tostring(timeNow()))
        widget.setTitle("番茄钟 - 休息")
        sys.notify("番茄钟", "专注完成！休息一下吧")
    elseif s == "break" then
        if getSessions() >= longBreakInterval then
            storage.set("sessions", "0")
        end
        storage.set("state", "idle")
        storage.set("startTime", "0")
        widget.setTitle("番茄钟")
        sys.notify("番茄钟", "休息结束，准备下一轮专注")
    end
    updateTickTimer()
end

-- ---- actions ----

function actionStart()
    storage.set("state", "work")
    storage.set("startTime", tostring(timeNow()))
    storage.set("pausedRemaining", "0")
    widget.setTitle("番茄钟 - 专注")
    updateTickTimer()
end

function actionPause()
    storage.set("prevState", getState())
    storage.set("pausedRemaining", tostring(remainingSeconds()))
    storage.set("state", "paused")
    widget.setTitle("番茄钟 - 暂停")
    updateTickTimer()
end

function actionResume()
    local prevState = storage.get("prevState") or "work"
    local target = targetForState(prevState)
    local pausedRem = getPausedRemaining()
    storage.set("state", prevState)
    storage.set("startTime", tostring(timeNow() - (target - pausedRem)))
    storage.set("pausedRemaining", "0")
    storage.set("prevState", "")
    if prevState == "work" then
        widget.setTitle("番茄钟 - 专注")
    else
        widget.setTitle("番茄钟 - 休息")
    end
    updateTickTimer()
end

function actionStop()
    storage.set("state", "idle")
    storage.set("startTime", "0")
    storage.set("pausedRemaining", "0")
    storage.set("prevState", "")
    widget.setTitle("番茄钟")
    updateTickTimer()
end

function actionSkip()
    local s = getState()
    if s == "work" then
        storage.set("sessions", tostring(getSessions() + 1))
        storage.set("state", "break")
        storage.set("startTime", tostring(timeNow()))
        widget.setTitle("番茄钟 - 休息")
        sys.notify("番茄钟", "已跳过专注，开始休息")
    elseif s == "break" then
        if getSessions() >= longBreakInterval then
            storage.set("sessions", "0")
        end
        storage.set("state", "work")
        storage.set("startTime", tostring(timeNow()))
        widget.setTitle("番茄钟 - 专注")
        sys.notify("番茄钟", "已跳过休息，开始下一轮专注")
    end
    updateTickTimer()
end

function actionReset()
    storage.set("state", "idle")
    storage.set("startTime", "0")
    storage.set("pausedRemaining", "0")
    storage.set("sessions", "0")
    storage.set("prevState", "")
    widget.setTitle("番茄钟")
    updateTickTimer()
end

-- ---- drawing ----

local btnHit = {}

function drawBtn(x, y, w, h, label, btnColor, txtColor, id)
    draw.rect(x, y, w, h, btnColor, layout.cu(6), 0.88)
    draw.strokeRect(x, y, w, h, txtColor, layout.cu(6), layout.cu(1.0), 0.12)
    local m = draw.measureText(label, layout.fontCu(13), 0, true)
    draw.text(x + (w - m.width) / 2, y + (h - m.height) / 2 + layout.cu(1), label, layout.fontCu(13), txtColor, 0, true)
    btnHit[#btnHit + 1] = { id = id, x = x, y = y, w = w, h = h }
end

function drawTrackRing(cx, cy, r, thickness, color, alpha)
    local outerR = r + thickness / 2
    local innerR = r - thickness / 2
    draw.circle(cx, cy, outerR, color, alpha)
    draw.circle(cx, cy, innerR, bg, alpha)
end

function drawProgressArc(cx, cy, r, prog, thickness, color, alpha)
    if prog <= 0 then return end
    local n = math.max(80, math.floor(prog * 360))
    local sa = -math.pi / 2
    local sweep = prog * 2 * math.pi
    local innerR = r - thickness / 2
    local outerR = r + thickness / 2
    for i = 0, n do
        local a = sa + sweep * i / n
        draw.line(
            cx + math.cos(a) * innerR,
            cy + math.sin(a) * innerR,
            cx + math.cos(a) * outerR,
            cy + math.sin(a) * outerR,
             layout.cu(1.6), color, alpha)
    end
end

function drawDots(cx, cy, filled, total, color, alpha)
    local dotR = layout.cu(5)
    local gap = layout.cu(16)
    local startX = cx - (total - 1) * gap / 2
    for i = 1, total do
        local dx = startX + (i - 1) * gap
        if i <= filled then
            draw.circle(dx, cy, dotR, color, alpha)
        else
            draw.strokeRect(dx - dotR, cy - dotR, dotR * 2, dotR * 2, color, dotR, layout.cu(1.2), alpha * 0.25)
        end
    end
end

function currentAccent()
    if getState() == "break" then return breakColor end
    return workColor
end

function stateLabelText()
    local s = getState()
    if s == "work"   then return "专注中" end
    if s == "break"  then return "休息"   end
    if s == "paused" then return "已暂停" end
    return "就绪"
end

function render()
    loadConfig()
    checkTransition()
    btnHit = {}

    local w = layout.width()
    local h = layout.height()
    local cx = w / 2
    local ringCY = h * 0.33

    local s     = getState()
    local rem   = remainingSeconds()
    local prog  = progress()
    local accent= currentAccent()
    local label = stateLabelText()
    local inSet = sessionsInSet()

    local btnW = layout.cu(78)
    local btnH = layout.cu(28)
    local btnGap = layout.cu(12)
    local bottomReserved = layout.cu(24)
    local btnY = h - btnH - bottomReserved - layout.cu(4)

    local ringR     = math.min(w, h) * 0.26
    local ringThick = math.max(layout.cu(5), ringR * 0.14)

    drawTrackRing(cx, ringCY, ringR, ringThick, trackColor, 0.5)
    if prog > 0.002 then
        drawProgressArc(cx, ringCY, ringR, prog, ringThick, accent, 1.0)
    end

    local fontSize = math.max(layout.fontCu(18), math.floor(ringR * 0.5))
    local timeStr  = formatTime(rem)
    local tm = draw.measureText(timeStr, fontSize, 0, true)
    draw.text(cx - tm.width / 2, ringCY - tm.height / 2, timeStr, fontSize, TXT_DARK, 0, true)

    local labelY = ringCY + ringR + ringThick + layout.cu(8)
    local sub = ""
    if s == "work" then
        sub = " · 第" .. (inSet + 1) .. "/" .. longBreakInterval .. "轮"
    elseif s == "break" then
        sub = " · 已完成" .. inSet .. "/" .. longBreakInterval .. "轮"
    end
    local lm = draw.measureText(label .. sub, layout.fontCu(12))
    draw.text(cx - lm.width / 2, labelY, label .. sub, layout.fontCu(12), TXT_MUTED)

    local dotsY = math.min(labelY + layout.cu(28), btnY - layout.cu(12))
    if s ~= "paused" and dotsY >= labelY + layout.cu(16) then
        drawDots(cx, dotsY, inSet, longBreakInterval, accent, 1.0)
    end

    -- ---- buttons ----

    if s == "idle" then
        local totalW = btnW * 2 + btnGap
        local bx = (w - totalW) / 2
        drawBtn(bx, btnY, btnW, btnH, "开始", workColor, 0xFFFFFF, 1)
        drawBtn(bx + btnW + btnGap, btnY, btnW, btnH, "重置", 0xE8E8E8, TXT_DARK, 10)
    elseif s == "paused" then
        local totalW = btnW * 2 + btnGap
        local bx = (w - totalW) / 2
        drawBtn(bx, btnY, btnW, btnH, "继续", workColor, 0xFFFFFF, 2)
        drawBtn(bx + btnW + btnGap, btnY, btnW, btnH, "停止", 0xE8E8E8, TXT_DARK, 3)
    else
        local totalW = btnW * 2 + btnGap
        local bx = (w - totalW) / 2
        drawBtn(bx, btnY, btnW, btnH, "暂停", BTN_PAUSE, 0xFFFFFF, 4)
        drawBtn(bx + btnW + btnGap, btnY, btnW, btnH, "跳过", 0xE8E8E8, TXT_DARK, 5)
    end
end

-- ---- input ----

function hitButton(x, y)
    for _, b in ipairs(btnHit) do
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            return b.id
        end
    end
    return nil
end

function dispatchButton(id)
    if id == 1  then actionStart()
    elseif id == 2  then actionResume()
    elseif id == 3  then actionStop()
    elseif id == 4  then actionPause()
    elseif id == 5  then actionSkip()
    elseif id == 10 then actionReset()
    end
end

function onMouseDown(x, y, button, delta)
    local bid = hitButton(x, y)
    if bid then dispatchButton(bid) end
end

function onDoubleClick(x, y)
    local bid = hitButton(x, y)
    if bid then dispatchButton(bid) else actionReset() end
end

-- ---- context menu ----

function getContextMenu()
    loadConfig()
    local s = getState()
    local menu = {}

    if s == "idle" then
        menu[#menu + 1] = { id = 1, label = "开始专注", icon = "" }
    elseif s == "paused" then
        menu[#menu + 1] = { id = 2, label = "继续计时", icon = "" }
        menu[#menu + 1] = { id = 3, label = "停止计时", icon = "" }
    else
        menu[#menu + 1] = { id = 5, label = "跳过当前阶段", icon = "" }
        menu[#menu + 1] = { id = 3, label = "停止计时", icon = "" }
    end
    menu[#menu + 1] = { separator = true }
    menu[#menu + 1] = { id = 10, label = "重置计数", icon = "" }

    return menu
end

function onMenu(id)
    loadConfig()
    if id == 1  then actionStart()
    elseif id == 2  then actionResume()
    elseif id == 3  then actionStop()
    elseif id == 5  then actionSkip()
    elseif id == 10 then actionReset()
    end
end

-- ---- settings ----

function imguiRender()
    loadConfig()

    if imgui.collapsingHeader("时长设置") then
        local wmText = imgui.inputText("专注时长（分钟）", tostring(workMin))
        local wm = tonumber(wmText)
        if wm and wm > 0 and wm <= 120 and wm ~= workMin then
            workMin = wm; storage.set("workMin", tostring(workMin))
        end

        local bmText = imgui.inputText("短休息（分钟）", tostring(breakMin))
        local bm = tonumber(bmText)
        if bm and bm > 0 and bm <= 60 and bm ~= breakMin then
            breakMin = bm; storage.set("breakMin", tostring(breakMin))
        end

        local lbText = imgui.inputText("长休息（分钟）", tostring(longBreakMin))
        local lb = tonumber(lbText)
        if lb and lb > 0 and lb <= 120 and lb ~= longBreakMin then
            longBreakMin = lb; storage.set("longBreakMin", tostring(longBreakMin))
        end

        local lbiText = imgui.inputText("长休息间隔（轮）", tostring(longBreakInterval))
        local lbi = tonumber(lbiText)
        if lbi and lbi >= 1 and lbi <= 10 and lbi ~= longBreakInterval then
            longBreakInterval = lbi; storage.set("longBreakInterval", tostring(longBreakInterval))
        end
    end

    if imgui.collapsingHeader("颜色设置") then
        local wc = imgui.colorEdit3("专注颜色", workColor)
        if wc ~= workColor then workColor = wc; storage.set("workColor", tostring(workColor)) end

        local bc = imgui.colorEdit3("休息颜色", breakColor)
        if bc ~= breakColor then breakColor = bc; storage.set("breakColor", tostring(breakColor)) end

        local bgc = imgui.colorEdit3("背景颜色", bg)
        if bgc ~= bg then storage.set("bgColor", tostring(bgc)) end
    end

    if imgui.button("恢复默认设置") then
        for _, k in ipairs({ "workMin", "breakMin", "longBreakMin", "longBreakInterval",
                             "workColor", "breakColor", "trackColor", "bgColor", "borderColor" }) do
            storage.remove(k)
        end
    end
end
