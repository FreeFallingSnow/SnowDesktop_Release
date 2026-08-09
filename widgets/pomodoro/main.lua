-- pomodoro.lua - 番茄钟
name = l10n.tr("lua_widget.pomodoro.name")
useCustomStyle = true
followPersonalizationDefault = true
bottomBarHover = false

local fluent = {
    play = utf8.char(0xF605),
    stop = utf8.char(0xF72A),
    next = utf8.char(0xF569),
    reset = utf8.char(0xF19F),
}

bg = 0x151A21
border = 0xFFFFFF
alpha = 0.42
gradientEndA = 0.30

local DEFAULT_WORK_COLOR   = 0xFF6347
local DEFAULT_BREAK_COLOR  = 0x4ECDC4

local function getPalette()
    local theme = widget.theme()
    if theme and theme.contentTheme == 1 then
        return {
            txtDark    = 0x1E293B,
            txtMuted   = 0x334155,
            trackColor = 0xE2E8F0,
            btnBg      = 0xE2E8F0,
            btnPause   = 0xD97706,
        }
    end
    return {
        txtDark    = 0xF1F5F9,
        txtMuted   = 0xF1F5F9,
        trackColor = 0x1E293B,
        btnBg      = 0x1E293B,
        btnPause   = 0xFFB347,
    }
end

settings = {
    fields = {
        { key = "workMin", label = l10n.tr("lua_widget.pomodoro.work_minutes"), type = "int", default = 25, min = 1, max = 120 },
        { key = "breakMin", label = l10n.tr("lua_widget.pomodoro.short_break_minutes"), type = "int", default = 5, min = 1, max = 60 },
        { key = "longBreakMin", label = l10n.tr("lua_widget.pomodoro.long_break_minutes"), type = "int", default = 15, min = 1, max = 120 },
        { key = "longBreakInterval", label = l10n.tr("lua_widget.pomodoro.long_break_interval"), type = "int", default = 4, min = 1, max = 10 },
        { key = "workColor", label = l10n.tr("lua_widget.pomodoro.work_color"), type = "color", default = DEFAULT_WORK_COLOR },
        { key = "breakColor", label = l10n.tr("lua_widget.pomodoro.break_color"), type = "color", default = DEFAULT_BREAK_COLOR },
    }
}

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
end

function loadConfig()
    workMin           = tonumber(storage.get("workMin"))           or 25
    breakMin          = tonumber(storage.get("breakMin"))          or 5
    longBreakMin      = tonumber(storage.get("longBreakMin"))      or 15
    longBreakInterval = tonumber(storage.get("longBreakInterval")) or 4
    workColor         = tonumber(storage.get("workColor"))         or DEFAULT_WORK_COLOR
    breakColor        = tonumber(storage.get("breakColor"))        or DEFAULT_BREAK_COLOR

    local savedBg = tonumber(storage.get("bg")) or tonumber(storage.get("bgColor"))
    if savedBg then bg = savedBg end
    local savedBorder = tonumber(storage.get("border")) or tonumber(storage.get("borderColor"))
    if savedBorder then border = savedBorder end
    alpha = tonumber(storage.get("alpha")) or alpha
    gradientEndA = tonumber(storage.get("gradientEndA")) or gradientEndA
    followPersonalization = storage.get("followPersonalization") == "1"
    if followPersonalization then
        local theme = widget.theme()
        if theme and theme.bg then
            bg = theme.bg
            border = theme.border or border
            alpha = theme.alpha or alpha
            gradientEndA = theme.gradientEndA or gradientEndA
        end
    end
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

function updateTitleForState()
    local state = getState()
    if state == "work" then
        widget.setTitle(l10n.tr("lua_widget.pomodoro.title_work"))
    elseif state == "break" then
        widget.setTitle(l10n.tr("lua_widget.pomodoro.title_break"))
    elseif state == "paused" then
        widget.setTitle(l10n.tr("lua_widget.pomodoro.title_paused"))
    else
        widget.setTitle(l10n.tr("lua_widget.pomodoro.name"))
    end
end

function onLanguageChanged()
    updateTitleForState()
end

function checkTransition()
    local s = getState()
    if s == "idle" or s == "paused" then return end
    if remainingSeconds() > 0 then return end

    if s == "work" then
        local sessions = getSessions() + 1
        storage.set("sessions", tostring(sessions))
        storage.set("state", "break")
        storage.set("startTime", tostring(timeNow()))
        widget.setTitle(l10n.tr("lua_widget.pomodoro.title_break"))
        sys.notify(l10n.tr("lua_widget.pomodoro.name"), l10n.tr("lua_widget.pomodoro.work_complete"))
    elseif s == "break" then
        if getSessions() >= longBreakInterval then
            storage.set("sessions", "0")
        end
        storage.set("state", "idle")
        storage.set("startTime", "0")
        widget.setTitle(l10n.tr("lua_widget.pomodoro.name"))
        sys.notify(l10n.tr("lua_widget.pomodoro.name"), l10n.tr("lua_widget.pomodoro.break_complete"))
    end
    updateTickTimer()
end

-- ---- actions ----

function actionStart()
    storage.set("state", "work")
    storage.set("startTime", tostring(timeNow()))
    storage.set("pausedRemaining", "0")
    widget.setTitle(l10n.tr("lua_widget.pomodoro.title_work"))
    updateTickTimer()
end

function actionPause()
    storage.set("prevState", getState())
    storage.set("pausedRemaining", tostring(remainingSeconds()))
    storage.set("state", "paused")
    widget.setTitle(l10n.tr("lua_widget.pomodoro.title_paused"))
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
        widget.setTitle(l10n.tr("lua_widget.pomodoro.title_work"))
    else
        widget.setTitle(l10n.tr("lua_widget.pomodoro.title_break"))
    end
    updateTickTimer()
end

function actionStop()
    storage.set("state", "idle")
    storage.set("startTime", "0")
    storage.set("pausedRemaining", "0")
    storage.set("prevState", "")
    widget.setTitle(l10n.tr("lua_widget.pomodoro.name"))
    updateTickTimer()
end

function actionSkip()
    local s = getState()
    if s == "work" then
        storage.set("sessions", tostring(getSessions() + 1))
        storage.set("state", "break")
        storage.set("startTime", tostring(timeNow()))
        widget.setTitle(l10n.tr("lua_widget.pomodoro.title_break"))
        sys.notify(l10n.tr("lua_widget.pomodoro.name"), l10n.tr("lua_widget.pomodoro.work_skipped"))
    elseif s == "break" then
        if getSessions() >= longBreakInterval then
            storage.set("sessions", "0")
        end
        storage.set("state", "work")
        storage.set("startTime", tostring(timeNow()))
        widget.setTitle(l10n.tr("lua_widget.pomodoro.title_work"))
        sys.notify(l10n.tr("lua_widget.pomodoro.name"), l10n.tr("lua_widget.pomodoro.break_skipped"))
    end
    updateTickTimer()
end

function actionReset()
    storage.set("state", "idle")
    storage.set("startTime", "0")
    storage.set("pausedRemaining", "0")
    storage.set("sessions", "0")
    storage.set("prevState", "")
    widget.setTitle(l10n.tr("lua_widget.pomodoro.name"))
    updateTickTimer()
end

-- ---- drawing ----

local btnHit = {}

function drawBtn(cx, cy, r, icon, bgColor, iconColor, id)
    draw.circle(cx, cy, r, bgColor, 0.88)
    local sz = r * 1.1
    draw.fa(icon, cx - sz / 2, cy - sz / 2, sz, iconColor)
    btnHit[#btnHit + 1] = { id = id, x = cx - r, y = cy - r, w = r * 2, h = r * 2 }
end

function drawTrackRing(cx, cy, r, thickness, color, alpha)
    local innerR = r - thickness / 2
    local outerR = r + thickness / 2
    local step = 2 * math.pi / math.max(360, math.floor(4 * math.pi * r))
    local i = 0
    while i < 2 * math.pi do
        draw.line(
            cx + math.cos(i) * innerR,
            cy + math.sin(i) * innerR,
            cx + math.cos(i) * outerR,
            cy + math.sin(i) * outerR,
            thickness, color, alpha)
        i = i + step
    end
end

function drawProgressArc(cx, cy, r, prog, thickness, color, alpha)
    if prog <= 0 then return end
    local innerR = r - thickness / 2
    local outerR = r + thickness / 2
    local step = 2 * math.pi / math.max(360, math.floor(4 * math.pi * r))
    local sweep = prog * 2 * math.pi
    local sa = -math.pi / 2
    local a = sa
    while a < sa + sweep do
        draw.line(
            cx + math.cos(a) * innerR,
            cy + math.sin(a) * innerR,
            cx + math.cos(a) * outerR,
            cy + math.sin(a) * outerR,
            thickness, color, alpha)
        a = a + step
    end
end

function drawDots(cx, cy, filled, total, color, alpha, dotR, gap)
    local startX = cx - (total - 1) * gap / 2
    for i = 1, total do
        local dx = startX + (i - 1) * gap
        if i <= filled then
            draw.circle(dx, cy, dotR, color, alpha)
        else
            draw.circle(dx, cy, dotR, 0xFFFFFF, alpha * 0.30)
        end
    end
end

function currentAccent()
    if getState() == "break" then return breakColor end
    return workColor
end

function stateLabelText()
    local s = getState()
    if s == "work"   then return l10n.tr("lua_widget.pomodoro.state_work") end
    if s == "break"  then return l10n.tr("lua_widget.pomodoro.state_break") end
    if s == "paused" then return l10n.tr("lua_widget.pomodoro.state_paused") end
    return l10n.tr("lua_widget.pomodoro.state_idle")
end

function render()
    loadConfig()
    updateTitleForState()
    checkTransition()
    btnHit = {}
    local pal = getPalette()

    local w = layout.width()
    local h = layout.height()
    local cx = w / 2
    local rows = layout.rows()
    local bottomBarH = layout.cu(layout.barHeight())

    local function scu(value, minimum)
        return math.max(minimum or 0, layout.cu(value * rows))
    end
    local function fontCu(value)
        return layout.fontCu(value * rows)
    end

    local s     = getState()
    local rem   = remainingSeconds()
    local prog  = progress()
    local accent= currentAccent()
    local label = stateLabelText()
    local inSet = sessionsInSet()

    local ringThick  = scu(5, layout.cu(7))
    local labelFont  = fontCu(6)
    local timeFont   = fontCu(18)
    local dotR       = scu(2.5)
    local dotGap     = scu(8)
    local btnR       = scu(9)
    local btnGap     = scu(12)
    local gap        = scu(5)
    local margin     = scu(6)
    local ringPad    = scu(18)

    local sub = ""
    if s == "work" then
        sub = l10n.tr("lua_widget.pomodoro.round_current", inSet + 1, longBreakInterval)
    elseif s == "break" then
        sub = l10n.tr("lua_widget.pomodoro.round_completed", inSet, longBreakInterval)
    end
    local labelStr = label .. sub
    local lm = draw.measureText(labelStr, labelFont, 0, true)
    local timeStr = formatTime(rem)
    local tm = draw.measureText(timeStr, timeFont, 0, true)

    local labelH = lm.height
    local dotsH  = dotR * 2 + gap
    local btnsH  = btnR * 2 + gap
    local belowH = labelH + gap + dotsH + gap + btnsH

    local ringR = math.min(w, h - belowH) / 2 - ringPad
    if ringR < scu(28) then
        ringR = math.min(w, h - belowH) / 2 - ringPad / 2
    end
    local edgeInset = math.max(margin, bottomBarH)
    local maxBalancedRingR =
        (h - belowH - ringThick * 1.5 - edgeInset * 2) / 2
    ringR = math.min(ringR, maxBalancedRingR)
    if ringR <= 0 then return end

    local visualContentH = ringR * 2 + ringThick * 2 + belowH
    local curY = (h - visualContentH - ringThick / 2) / 2
    local ringCY = curY + ringR + ringThick

    drawTrackRing(cx, ringCY, ringR, ringThick, pal.trackColor, 0.5)
    if prog > 0.002 then
        drawProgressArc(cx, ringCY, ringR, prog, ringThick, accent, 1.0)
    end
    draw.text(cx - tm.width / 2, ringCY - tm.height / 2, timeStr, timeFont, pal.txtDark, 0, true)

    curY = ringCY + ringR + ringThick + gap
    draw.text(cx - lm.width / 2, curY, labelStr, labelFont, pal.txtMuted)

    curY = curY + labelH + gap
    if s ~= "paused" then
        drawDots(cx, curY + dotR, inSet, longBreakInterval, accent, 1.0, dotR, dotGap)
    end

    curY = curY + dotsH + gap
    local btnCY = curY + btnR

    if s == "idle" then
        local totalW = btnR * 4 + btnGap
        local bx = cx - totalW / 2 + btnR
        drawBtn(bx, btnCY, btnR, "", workColor, 0xFFFFFF, 1)
        drawBtn(bx + btnR * 2 + btnGap, btnCY, btnR, "", pal.btnBg, pal.txtDark, 10)
    elseif s == "paused" then
        local totalW = btnR * 4 + btnGap
        local bx = cx - totalW / 2 + btnR
        drawBtn(bx, btnCY, btnR, "", workColor, 0xFFFFFF, 2)
        drawBtn(bx + btnR * 2 + btnGap, btnCY, btnR, "", pal.btnBg, pal.txtDark, 3)
    else
        local totalW = btnR * 4 + btnGap
        local bx = cx - totalW / 2 + btnR
        drawBtn(bx, btnCY, btnR, "", pal.btnPause, 0xFFFFFF, 4)
        drawBtn(bx + btnR * 2 + btnGap, btnCY, btnR, "", pal.btnBg, pal.txtDark, 5)
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
        menu[#menu + 1] = { id = 1, label = l10n.tr("lua_widget.pomodoro.start"), icon = fluent.play, iconFont = "fluent" }
    elseif s == "paused" then
        menu[#menu + 1] = { id = 2, label = l10n.tr("lua_widget.pomodoro.resume"), icon = fluent.play, iconFont = "fluent" }
        menu[#menu + 1] = { id = 3, label = l10n.tr("lua_widget.pomodoro.stop"), icon = fluent.stop, iconFont = "fluent" }
    else
        menu[#menu + 1] = { id = 5, label = l10n.tr("lua_widget.pomodoro.skip"), icon = fluent.next, iconFont = "fluent" }
        menu[#menu + 1] = { id = 3, label = l10n.tr("lua_widget.pomodoro.stop"), icon = fluent.stop, iconFont = "fluent" }
    end
    menu[#menu + 1] = { separator = true }
    menu[#menu + 1] = { id = 10, label = l10n.tr("lua_widget.pomodoro.reset_count"), icon = fluent.reset, iconFont = "fluent" }

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
