name = l10n.tr("lua_widget.month_calendar.name")
useCustomStyle = true
followPersonalizationDefault = true
showTitle = false
bottomBarHover = false

local fluent = {
    today = utf8.char(0xF23C),
    previous = utf8.char(0xF15B),
    next = utf8.char(0xF181),
}

bg = 0x151A21
border = 0xFFFFFF
alpha = 0.40
borderAlpha = 0.18
gradientEndA = 0.28

local viewYear = nil
local viewMonth = nil
local dateHits = {}
local headerHits = {}
local eventCounts = {}
local eventCacheKey = nil
local calendarDirty = true
local wasHostSelected = nil
local AGENDA_PACKAGE_ID =
    "4a1577fc-1fe4-4a91-9fa5-8ce400ede1e3"

settings = {
    fields = {
        {
            key = "showAdjacent",
            label = l10n.tr(
                "lua_widget.month_calendar.show_adjacent"),
            type = "bool",
            default = true,
        },
        {
            key = "fontSize",
            label = l10n.tr(
                "lua_widget.common.font_size"),
            type = "int",
            default = 15,
            min = 11,
            max = 20,
        },
    }
}

local function palette()
    local theme = widget.theme()
    if theme and theme.contentTheme == 1 then
        return {
            text = 0x000000,
            inverse = 0xFFFFFF,
        }
    end
    return {
        text = 0xFFFFFF,
        inverse = 0x000000,
    }
end

local function pointIn(rect, x, y)
    return rect and x >= rect.x and
        x <= rect.x + rect.w and
        y >= rect.y and y <= rect.y + rect.h
end

local function todayDate()
    local now = sys.getTime()
    return string.format(
        "%04d-%02d-%02d",
        now.year, now.month, now.day)
end

local function returnToToday()
    local today = todayDate()
    local info = calendar.dateInfo(today)
    if not info then return end
    viewYear = info.year
    viewMonth = info.month
    if calendar.selectedDate() ~= today then
        calendar.setSelectedDate(today)
    end
    calendarDirty = true
end

local function ensureView()
    if viewYear and viewMonth then return end
    local selected = calendar.selectedDate()
    local info = calendar.dateInfo(selected)
    if not info then
        selected = todayDate()
        info = calendar.dateInfo(selected)
    end
    viewYear = info.year
    viewMonth = info.month
end

local function monthDate(year, month)
    return string.format("%04d-%02d-01", year, month)
end

local function shiftMonth(delta)
    ensureView()
    viewMonth = viewMonth + delta
    while viewMonth < 1 do
        viewMonth = viewMonth + 12
        viewYear = viewYear - 1
    end
    while viewMonth > 12 do
        viewMonth = viewMonth - 12
        viewYear = viewYear + 1
    end
    calendarDirty = true
end

local function effectiveWeekStart()
    local mode = tonumber(storage.get("weekStart")) or 0
    if mode == 1 then return 2 end
    if mode == 2 then return 1 end
    return l10n.language() == "zh-CN" and 2 or 1
end

local function currentFontSize()
    return math.max(
        11,
        math.min(
            20,
            tonumber(storage.get("fontSize")) or 15))
end

local function mainLayoutGrowth()
    local columnGrowth =
        math.max(0, layout.columns() - 3)
    local rowGrowth =
        math.max(0, layout.rows() - 2)
    return math.min(
        4, columnGrowth + rowGrowth * 1.5)
end

local function showAdjacent()
    return storage.get("showAdjacent") ~= "0"
end

local function loadMonthCells()
    ensureView()
    local first = monthDate(viewYear, viewMonth)
    local firstInfo = calendar.dateInfo(first)
    local leading =
        (firstInfo.weekday - effectiveWeekStart() + 7) % 7
    local gridStart = calendar.addDays(first, -leading)
    local gridEnd = calendar.addDays(gridStart, 41)
    local key = gridStart .. ":" .. gridEnd
    if calendarDirty or eventCacheKey ~= key then
        eventCounts = {}
        for _, event in ipairs(
            calendar.events(gridStart, gridEnd)) do
            eventCounts[event.date] =
                (eventCounts[event.date] or 0) + 1
        end
        eventCacheKey = key
        calendarDirty = false
    end
    local cells = {}
    for index = 0, 41 do
        local date = calendar.addDays(gridStart, index)
        local info = calendar.dateInfo(date)
        cells[#cells + 1] = {
            date = date,
            info = info,
            currentMonth =
                info.year == viewYear and
                info.month == viewMonth,
        }
    end
    return cells
end

local function centeredText(
    text, x, y, width, height,
    size, color, bold, alpha)
    local measured = draw.measureText(
        text, size, width, bold)
    draw.text(
        x + math.max(0, (width - measured.width) / 2),
        y + math.max(0, (height - measured.height) / 2),
        text, size, color,
        math.max(1, width), bold, true, nil, alpha)
end

local function drawHeaderButton(
    hit, label, fontSize, colors, iconOnly,
    iconYOffset)
    draw.strokeRect(
        hit.x, hit.y, hit.w, hit.h,
        colors.text, layout.cu(7),
        layout.cu(1), 0.28)
    if iconOnly then
        draw.fa(
            label,
            hit.x + (hit.w - fontSize) / 2,
            hit.y + (hit.h - fontSize) / 2 +
                (iconYOffset or 0),
            fontSize, colors.text)
    else
        centeredText(
            label, hit.x, hit.y, hit.w, hit.h,
            fontSize, colors.text, true, 1.0)
    end
end

function render()
    widget.setTitle(
        l10n.tr("lua_widget.month_calendar.name"))
    local info = widget.info()
    local hostSelected = info.selected == true
    if wasHostSelected == true and
        not hostSelected and
        info.selectedPackageId ~=
            AGENDA_PACKAGE_ID then
        returnToToday()
    end
    wasHostSelected = hostSelected
    ensureView()
    dateHits = {}
    headerHits = {}

    local colors = palette()
    local w = layout.width()
    local h = layout.height()
    local pad = layout.cu(11)
    local bottom = h -
        layout.cu(layout.barHeight()) - layout.cu(5)
    local growth = mainLayoutGrowth()
    local headerH = layout.cu(30 + growth * 1.8)
    local calendarGap = layout.cu(7 + growth)
    local weekdayH = layout.cu(22 + growth)
    local weekdayTop = pad + headerH + calendarGap
    local gridTop = weekdayTop + weekdayH
    local gridH = math.max(
        layout.cu(90), bottom - gridTop)
    local cellW = (w - pad * 2) / 7
    local cellH = gridH / 6
    local font = layout.fontCu(
        currentFontSize() + growth)
    local smallFont = layout.fontCu(
        math.max(
            10,
            currentFontSize() - 3 +
                growth * 0.75))

    local button = layout.cu(
        26 + growth * 1.6)
    local buttonY = pad + (headerH - button) / 2
    local iconFont =
        layout.fontCu(14 + growth)
    headerHits.previous = {
        x = pad, y = buttonY,
        w = button, h = button,
    }
    headerHits.next = {
        x = pad + button + layout.cu(4),
        y = buttonY,
        w = button, h = button,
    }
    drawHeaderButton(
        headerHits.previous, "",
        iconFont, colors, true,
        layout.cu(1.4))
    drawHeaderButton(
        headerHits.next, "",
        iconFont, colors, true,
        layout.cu(1.4))

    local todayText =
        l10n.tr("lua_widget.month_calendar.today")
    local todayMetrics = draw.measureText(
        todayText, smallFont, 0, true)
    local todayW = math.max(
        layout.cu(40),
        todayMetrics.width + layout.cu(12))
    headerHits.today = {
        x = w - pad - todayW,
        y = buttonY,
        w = todayW,
        h = button,
    }
    drawHeaderButton(
        headerHits.today, todayText,
        smallFont, colors, false)

    local title = l10n.tr(
        "lua_widget.month_calendar.month_format",
        tostring(viewYear), tostring(viewMonth))
    local titleX =
        headerHits.next.x + headerHits.next.w +
        layout.cu(8)
    local titleW = math.max(
        1, headerHits.today.x - titleX - layout.cu(5))
    centeredText(
        title, titleX, pad, titleW, headerH,
        font, colors.text, true, 1.0)

    local weekdayKeys = {
        "sun", "mon", "tue", "wed",
        "thu", "fri", "sat",
    }
    local weekStart = effectiveWeekStart()
    for column = 0, 6 do
        local weekday =
            ((weekStart - 1 + column) % 7) + 1
        local key = weekdayKeys[weekday]
        local text
        if key == "sun" then
            text = l10n.tr(
                "lua_widget.month_calendar.sun")
        elseif key == "mon" then
            text = l10n.tr(
                "lua_widget.month_calendar.mon")
        elseif key == "tue" then
            text = l10n.tr(
                "lua_widget.month_calendar.tue")
        elseif key == "wed" then
            text = l10n.tr(
                "lua_widget.month_calendar.wed")
        elseif key == "thu" then
            text = l10n.tr(
                "lua_widget.month_calendar.thu")
        elseif key == "fri" then
            text = l10n.tr(
                "lua_widget.month_calendar.fri")
        else
            text = l10n.tr(
                "lua_widget.month_calendar.sat")
        end
        centeredText(
            text, pad + column * cellW,
            weekdayTop, cellW, weekdayH,
            smallFont, colors.text, true, 0.60)
    end

    local selected = calendar.selectedDate()
    local today = todayDate()
    local cells = loadMonthCells()
    for index, cell in ipairs(cells) do
        local zero = index - 1
        local column = zero % 7
        local row = math.floor(zero / 7)
        local x = pad + column * cellW
        local y = gridTop + row * cellH
        local visible =
            cell.currentMonth or showAdjacent()
        dateHits[#dateHits + 1] = {
            x = x, y = y, w = cellW, h = cellH,
            date = cell.date,
        }
        if visible then
            local isSelected = cell.date == selected
            local isToday = cell.date == today
            local circleRatio =
                0.72 + math.min(0.06, growth * 0.015)
            local diameter = math.min(
                cellW * circleRatio,
                cellH * circleRatio)
            local cx = x + cellW / 2
            local cy = y + cellH * 0.44
            if isSelected then
                draw.circle(
                    cx, cy, diameter / 2,
                    colors.text, 0.92)
            elseif isToday then
                draw.strokeRect(
                    cx - diameter / 2,
                    cy - diameter / 2,
                    diameter, diameter,
                    colors.text, diameter / 2,
                    layout.cu(1.3), 0.82)
            end
            local dayText = tostring(cell.info.day)
            centeredText(
                dayText,
                cx - diameter / 2,
                cy - diameter / 2,
                diameter, diameter,
                font,
                isSelected
                    and colors.inverse or colors.text,
                isToday or isSelected,
                cell.currentMonth and 1.0 or 0.38)
            if eventCounts[cell.date] then
                draw.circle(
                    cx,
                    y + cellH -
                        layout.cu(4 + growth * 0.3),
                    math.max(
                        layout.cu(1.4 + growth * 0.18),
                        cellW * 0.035),
                    isSelected
                        and colors.inverse or colors.text,
                    cell.currentMonth and 0.86 or 0.34)
            end
        end
    end
end

function onClick(x, y)
    if pointIn(headerHits.previous, x, y) then
        shiftMonth(-1)
        widget.invalidate()
        return
    end
    if pointIn(headerHits.next, x, y) then
        shiftMonth(1)
        widget.invalidate()
        return
    end
    if pointIn(headerHits.today, x, y) then
        returnToToday()
        widget.invalidate()
        return
    end
    for _, hit in ipairs(dateHits) do
        if pointIn(hit, x, y) then
            local info = calendar.dateInfo(hit.date)
            viewYear = info.year
            viewMonth = info.month
            calendar.setSelectedDate(hit.date)
            calendarDirty = true
            widget.invalidate()
            return
        end
    end
end

function onCalendarChanged(reason)
    calendarDirty = true
    if reason == "selection" then
        local info =
            calendar.dateInfo(calendar.selectedDate())
        if info then
            viewYear = info.year
            viewMonth = info.month
        end
    end
end

function getContextMenu()
    return {
        {
            id = 1,
            label = l10n.tr(
                "lua_widget.month_calendar.today"),
            icon = fluent.today,
            iconFont = "fluent",
        },
        {
            id = 2,
            label = l10n.tr(
                "lua_widget.month_calendar.previous_month"),
            icon = fluent.previous,
            iconFont = "fluent",
        },
        {
            id = 3,
            label = l10n.tr(
                "lua_widget.month_calendar.next_month"),
            icon = fluent.next,
            iconFont = "fluent",
        },
    }
end

function onMenu(id)
    if id == 1 then
        returnToToday()
    elseif id == 2 then
        shiftMonth(-1)
    elseif id == 3 then
        shiftMonth(1)
    end
    calendarDirty = true
    widget.invalidate()
end

function imguiRender()
    local mode =
        math.max(0, math.min(
            2,
            tonumber(storage.get("weekStart")) or 0))
    local labels = {
        l10n.tr(
            "lua_widget.month_calendar.week_start_locale"),
        l10n.tr(
            "lua_widget.month_calendar.week_start_monday"),
        l10n.tr(
            "lua_widget.month_calendar.week_start_sunday"),
    }
    local nextMode = imgui.combo(
        l10n.tr(
            "lua_widget.month_calendar.week_start"),
        mode + 1, labels) - 1
    if nextMode ~= mode then
        storage.set("weekStart", tostring(nextMode))
        calendarDirty = true
    end
end
