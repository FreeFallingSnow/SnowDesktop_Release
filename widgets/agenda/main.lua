name = l10n.tr("lua_widget.agenda.name")
useCustomStyle = true
followPersonalizationDefault = true
showTitle = false
bottomBarHover = false

bg = 0x151A21
border = 0xFFFFFF
alpha = 0.40
borderAlpha = 0.18
gradientEndA = 0.28

local rows = {}
local rowHits = {}
local rowGeometryGrowth = nil
local rowContentHeight = 0
local headerHits = {}
local editorHits = {}
local eventsById = {}
local eventsDirty = true
local editorError = nil
local focusEditorTitle = false
local datePickerOpen = false
local pickerYear = nil
local pickerMonth = nil
local pickerHits = {}
local wasHostSelected = nil

local DRAFT_TITLE = "agenda_draft_title"
local DRAFT_DATE = "agenda_draft_date"
local DRAFT_ALL_DAY = "agenda_draft_all_day"
local DRAFT_START = "agenda_draft_start"
local DRAFT_END = "agenda_draft_end"
local DRAFT_REMINDER = "agenda_draft_reminder"
local DRAFT_NOTES = "agenda_draft_notes"
local EDITOR_MODE = "agenda_editor_mode"
local EDITOR_ID = "agenda_editor_id"
local EDITOR_REVISION = "agenda_editor_revision"
local SELECTED_ID = "agenda_selected_id"

local reminderValues = { -1, 0, 5, 15, 30, 60, 1440 }

settings = {
    fields = {
        {
            key = "fontSize",
            label = l10n.tr("lua_widget.common.font_size"),
            type = "int",
            default = 15,
            min = 11,
            max = 20,
        },
    }
}

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function palette()
    local theme = widget.theme()
    if theme and theme.contentTheme == 1 then
        return {
            text = 0x000000,
            inverse = 0xFFFFFF,
            completed = 0x666666,
        }
    end
    return {
        text = 0xFFFFFF,
        inverse = 0x000000,
        completed = 0xA8A8A8,
    }
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
        5, columnGrowth + rowGrowth * 1.25)
end

local function rangeDays()
    local value = tonumber(storage.get("rangeDays")) or 7
    if value == 1 or value == 3 or
        value == 7 or value == 30 then
        return value
    end
    return 7
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
    if calendar.selectedDate() ~= today then
        calendar.setSelectedDate(today)
    end
    eventsDirty = true
    storage.remove(SELECTED_ID)
    ui.setScrollOffset("agenda-events", 0)
end

local function formatTime(minutes)
    local value = math.max(
        0, math.min(1439, tonumber(minutes) or 0))
    return string.format(
        "%02d:%02d",
        math.floor(value / 60), value % 60)
end

local function parseTime(value)
    local hour, minute =
        string.match(trim(value), "^(%d%d?):(%d%d)$")
    hour = tonumber(hour)
    minute = tonumber(minute)
    if not hour or not minute or
        hour < 0 or hour > 23 or
        minute < 0 or minute > 59 then
        return nil
    end
    return hour * 60 + minute
end

local function formatDate(date, includeWeekday)
    local info = calendar.dateInfo(date)
    if not info then return date end
    local base = l10n.tr(
        "lua_widget.agenda.date_format",
        tostring(info.month), tostring(info.day))
    if not includeWeekday then return base end
    local weekday
    if info.weekday == 1 then
        weekday = l10n.tr(
            "lua_widget.agenda.weekday_sun")
    elseif info.weekday == 2 then
        weekday = l10n.tr(
            "lua_widget.agenda.weekday_mon")
    elseif info.weekday == 3 then
        weekday = l10n.tr(
            "lua_widget.agenda.weekday_tue")
    elseif info.weekday == 4 then
        weekday = l10n.tr(
            "lua_widget.agenda.weekday_wed")
    elseif info.weekday == 5 then
        weekday = l10n.tr(
            "lua_widget.agenda.weekday_thu")
    elseif info.weekday == 6 then
        weekday = l10n.tr(
            "lua_widget.agenda.weekday_fri")
    else
        weekday = l10n.tr(
            "lua_widget.agenda.weekday_sat")
    end
    return base .. " · " .. weekday
end

local function reminderLabel(value)
    if value == -1 then
        return l10n.tr("lua_widget.agenda.reminder_none")
    elseif value == 0 then
        return l10n.tr("lua_widget.agenda.reminder_now")
    elseif value == 5 then
        return l10n.tr("lua_widget.agenda.reminder_5")
    elseif value == 15 then
        return l10n.tr("lua_widget.agenda.reminder_15")
    elseif value == 30 then
        return l10n.tr("lua_widget.agenda.reminder_30")
    elseif value == 60 then
        return l10n.tr("lua_widget.agenda.reminder_60")
    end
    return l10n.tr("lua_widget.agenda.reminder_1440")
end

local function isEditing()
    local mode = storage.get(EDITOR_MODE)
    return mode == "new" or mode == "edit"
end

local function clearDraft()
    storage.remove(DRAFT_TITLE)
    storage.remove(DRAFT_DATE)
    storage.remove(DRAFT_ALL_DAY)
    storage.remove(DRAFT_START)
    storage.remove(DRAFT_END)
    storage.remove(DRAFT_REMINDER)
    storage.remove(DRAFT_NOTES)
    storage.remove(EDITOR_MODE)
    storage.remove(EDITOR_ID)
    storage.remove(EDITOR_REVISION)
    editorError = nil
    focusEditorTitle = false
    datePickerOpen = false
    pickerYear = nil
    pickerMonth = nil
    ui.setScrollOffset("agenda-editor", 0)
end

local function setDraft(event, mode)
    storage.set(DRAFT_TITLE, event.title or "")
    storage.set(DRAFT_DATE, event.date or calendar.selectedDate())
    storage.set(
        DRAFT_ALL_DAY, event.allDay and "1" or "0")
    storage.set(
        DRAFT_START, formatTime(event.startMinutes or 540))
    storage.set(
        DRAFT_END, formatTime(event.endMinutes or 600))
    storage.set(
        DRAFT_REMINDER,
        tostring(event.reminderMinutes or 15))
    if event.notes and event.notes ~= "" then
        storage.set(DRAFT_NOTES, event.notes)
    else
        storage.remove(DRAFT_NOTES)
    end
    storage.set(EDITOR_MODE, mode)
    if mode == "edit" then
        storage.set(EDITOR_ID, event.id)
        storage.set(
            EDITOR_REVISION, tostring(event.revision))
    else
        storage.remove(EDITOR_ID)
        storage.remove(EDITOR_REVISION)
    end
    editorError = nil
    focusEditorTitle = true
    ui.setScrollOffset("agenda-editor", 0)
end

local function openEditorPanel()
    local panelTitle =
        storage.get(EDITOR_MODE) == "edit" and
        l10n.tr("lua_widget.agenda.edit") or
        l10n.tr("lua_widget.agenda.add")
    widget.openPanel({
        title = panelTitle,
        width = 580,
        height = 580,
    })
end

local function startNew()
    local selected = calendar.selectedDate()
    local startMinutes = 540
    if selected == todayDate() then
        local now = sys.getTime()
        local current = now.hour * 60 + now.min
        startMinutes =
            (math.floor(current / 30) + 1) * 30
        startMinutes = math.min(startMinutes, 1380)
    end
    setDraft({
        title = "",
        date = selected,
        allDay = false,
        startMinutes = startMinutes,
        endMinutes = math.min(startMinutes + 60, 1439),
        notes = "",
        reminderMinutes = 15,
    }, "new")
    openEditorPanel()
end

local function startEdit(event)
    if event then
        setDraft(event, "edit")
        openEditorPanel()
    end
end

local function draftReminder()
    local value = tonumber(storage.get(DRAFT_REMINDER)) or 15
    for _, allowed in ipairs(reminderValues) do
        if value == allowed then return value end
    end
    return 15
end

local function cycleReminder()
    local value = draftReminder()
    local index = 1
    for current, allowed in ipairs(reminderValues) do
        if value == allowed then index = current break end
    end
    index = index % #reminderValues + 1
    storage.set(
        DRAFT_REMINDER,
        tostring(reminderValues[index]))
end

local function saveDraft()
    local title = trim(storage.get(DRAFT_TITLE) or "")
    if title == "" then
        editorError = "title"
        return
    end
    local date = trim(storage.get(DRAFT_DATE) or "")
    if not calendar.dateInfo(date) then
        editorError = "date"
        return
    end
    local allDay = storage.get(DRAFT_ALL_DAY) == "1"
    local startMinutes = parseTime(
        storage.get(DRAFT_START) or "")
    local endMinutes = parseTime(
        storage.get(DRAFT_END) or "")
    if not allDay and
        (not startMinutes or not endMinutes or
            endMinutes < startMinutes) then
        editorError = "time"
        return
    end
    if allDay then
        startMinutes = 0
        endMinutes = 1439
    end
    local event = {
        title = title,
        date = date,
        allDay = allDay,
        startMinutes = startMinutes,
        endMinutes = endMinutes,
        notes = storage.get(DRAFT_NOTES) or "",
        reminderMinutes = draftReminder(),
    }
    local result
    if storage.get(EDITOR_MODE) == "edit" then
        result = calendar.update(
            storage.get(EDITOR_ID) or "",
            tonumber(storage.get(EDITOR_REVISION)) or 0,
            event)
    else
        result = calendar.create(event)
    end
    if result and result.ok then
        storage.set(SELECTED_ID, result.id)
        calendar.setSelectedDate(date)
        eventsDirty = true
        widget.closePanel()
    elseif result and result.error == "conflict" then
        editorError = "conflict"
    else
        editorError = "save"
    end
end

local function editorErrorText()
    if editorError == "title" then
        return l10n.tr("lua_widget.agenda.invalid_title")
    elseif editorError == "date" then
        return l10n.tr("lua_widget.agenda.invalid_date")
    elseif editorError == "time" then
        return l10n.tr("lua_widget.agenda.invalid_time")
    elseif editorError == "conflict" then
        return l10n.tr("lua_widget.agenda.conflict")
    elseif editorError == "save" then
        return l10n.tr("lua_widget.agenda.save_failed")
    end
    return nil
end

local function refreshRows()
    if not eventsDirty then return end
    rows = {}
    eventsById = {}
    local selected = calendar.selectedDate()
    local lastDate =
        calendar.addDays(selected, rangeDays() - 1)
    local lastSection = nil
    for _, event in ipairs(
        calendar.events(selected, lastDate)) do
        eventsById[event.id] = event
        if event.date ~= lastSection then
            rows[#rows + 1] = {
                kind = "section",
                date = event.date,
            }
            lastSection = event.date
        end
        rows[#rows + 1] = {
            kind = "event",
            event = event,
        }
    end
    rowGeometryGrowth = nil
    rowContentHeight = 0
    eventsDirty = false
end

local function rebuildRowGeometry(growth)
    if rowGeometryGrowth == growth then return end
    local sectionH = layout.cu(
        25 + growth * 1.2)
    local eventH = layout.cu(
        50 + growth * 5)
    local top = 0
    for _, row in ipairs(rows) do
        row.top = top
        row.height = row.kind == "section"
            and sectionH or eventH
        top = top + row.height
    end
    rowGeometryGrowth = growth
    rowContentHeight = top
end

local function centeredText(
    text, x, y, width, height,
    size, color, bold, alpha)
    local measured =
        draw.measureText(text, size, width, bold)
    draw.text(
        x + math.max(0, (width - measured.width) / 2),
        y + math.max(0, (height - measured.height) / 2),
        text, size, color, math.max(1, width),
        bold, true, nil, alpha)
end

local function drawOutlineButton(
    id, label, x, y, width, height,
    colors, iconOnly, filled, fontSize,
    iconYOffset)
    if filled then
        draw.rect(
            x, y, width, height, colors.text,
            layout.cu(7), 0.92)
    else
        draw.strokeRect(
            x, y, width, height, colors.text,
            layout.cu(7), layout.cu(1), 0.28)
    end
    if iconOnly then
        draw.fa(
            label,
            x + (width - fontSize) / 2,
            y + (height - fontSize) / 2 +
                (iconYOffset or 0),
            fontSize,
            filled and colors.inverse or colors.text)
    else
        centeredText(
            label, x, y, width, height,
            fontSize,
            filled and colors.inverse or colors.text,
            true, 1.0)
    end
    headerHits[id] = {
        x = x, y = y, w = width, h = height,
    }
end

local function drawPanelButton(
    hit, label, fontSize, colors, filled,
    iconOnly, iconYOffset)
    if filled then
        draw.rect(
            hit.x, hit.y, hit.w, hit.h,
            colors.text, layout.cu(7), 0.92)
    else
        draw.strokeRect(
            hit.x, hit.y, hit.w, hit.h,
            colors.text, layout.cu(7),
            layout.cu(1), 0.28)
    end
    if iconOnly then
        draw.fa(
            label,
            hit.x + (hit.w - fontSize) / 2,
            hit.y + (hit.h - fontSize) / 2 +
                (iconYOffset or 0),
            fontSize,
            filled and colors.inverse or colors.text)
    else
        centeredText(
            label, hit.x, hit.y, hit.w, hit.h,
            fontSize,
            filled and colors.inverse or colors.text,
            true, 1.0)
    end
end

local function renderHeader(colors, pad, width)
    local growth = mainLayoutGrowth()
    local headerH = layout.cu(30 + growth * 1.8)
    local button = layout.cu(26 + growth * 1.6)
    local iconFont = layout.fontCu(14 + growth)
    local labelFont = layout.fontCu(math.max(
        10,
        currentFontSize() - 3 +
            growth * 0.75))
    local y = pad + (headerH - button) / 2
    drawOutlineButton(
        "previous", "", pad, y,
        button, button, colors, true, false,
        iconFont, layout.cu(1.4))
    drawOutlineButton(
        "next", "", pad + button + layout.cu(4), y,
        button, button, colors, true, false,
        iconFont, layout.cu(1.4))
    local addX = width - pad - button
    drawOutlineButton(
        "add", "", addX, y,
        button, button, colors, true, true,
        iconFont, 0)
    local todayText = l10n.tr("lua_widget.agenda.today")
    local todayMeasure = draw.measureText(
        todayText, labelFont, 0, true)
    local todayW = math.max(
        layout.cu(40),
        todayMeasure.width + layout.cu(12))
    local todayX = addX - layout.cu(5) - todayW
    drawOutlineButton(
        "today", todayText, todayX, y,
        todayW, button, colors, false, false,
        labelFont, 0)
    local titleX = pad + button * 2 + layout.cu(12)
    local titleW = math.max(
        1, todayX - titleX - layout.cu(5))
    centeredText(
        formatDate(calendar.selectedDate(), false),
        titleX, pad, titleW, headerH,
        layout.fontCu(
            currentFontSize() + growth),
        colors.text, true, 1.0)
    return pad + headerH +
        layout.cu(7 + growth * 0.8)
end

local function renderEmpty(
    colors, pad, top, width, height)
    local growth = mainLayoutGrowth()
    local font = layout.fontCu(
        currentFontSize() + growth)
    local small = layout.fontCu(
        math.max(
            10,
            currentFontSize() - 3 +
                growth * 0.75))
    local titleH = layout.cu(
        28 + growth * 1.5)
    local hintGap = layout.cu(
        3 + growth * 0.4)
    local hintH = layout.cu(
        25 + growth)
    local blockH = titleH + hintGap + hintH
    local y = top + math.max(0, (height - blockH) / 2)
    centeredText(
        l10n.tr("lua_widget.agenda.empty"),
        pad, y, width - pad * 2, titleH,
        font, colors.text, true, 0.94)
    centeredText(
        l10n.tr("lua_widget.agenda.empty_hint"),
        pad, y + titleH + hintGap,
        width - pad * 2, hintH,
        small, colors.text, false, 0.56)
end

local function renderList(
    colors, pad, top, width, height,
    hostSelected)
    refreshRows()
    rowHits = {}
    if #rows == 0 then
        renderEmpty(colors, pad, top, width, height)
        return
    end
    local growth = mainLayoutGrowth()
    rebuildRowGeometry(growth)
    local offset = ui.scrollArea(
        "agenda-events", pad, top,
        width - pad * 2, height,
        rowContentHeight)
    local selectedId = storage.get(SELECTED_ID)
    local font = layout.fontCu(
        currentFontSize() + growth * 0.55)
    local small = layout.fontCu(
        math.max(
            10,
                currentFontSize() - 3 +
                growth * 0.75))
    local sectionFont = layout.fontCu(
        math.max(
            10,
            currentFontSize() - 4 +
                growth * 0.45))
    local titleLineH =
        draw.measureText("Ag", font, 0, false).height
    local smallLineH =
        draw.measureText("Ag", small, 0, false).height
    local sectionLineH =
        draw.measureText(
            "Ag", sectionFont, 0, true).height
    local first = 1
    local low = 1
    local high = #rows
    while low <= high do
        local middle = math.floor((low + high) / 2)
        local row = rows[middle]
        if row.top + row.height <= offset then
            low = middle + 1
        else
            first = middle
            high = middle - 1
        end
    end
    draw.pushClip(pad, top, width - pad * 2, height)
    for index = first, #rows do
        local row = rows[index]
        if row.top >= offset + height then break end
        local y = top + row.top - offset
        if row.kind == "section" then
            draw.text(
                pad + layout.cu(6),
                y + math.max(
                    0,
                    (row.height - sectionLineH) / 2),
                formatDate(row.date, true),
                sectionFont, colors.text,
                width - pad * 2 - layout.cu(12),
                true, true, nil, 0.58)
        else
            local event = row.event
            local selected =
                hostSelected and event.id == selectedId
            local cardY = y + layout.cu(2)
            local cardH =
                row.height - layout.cu(4)
            draw.rect(
                pad, cardY, width - pad * 2, cardH,
                colors.text, layout.cu(9),
                selected and 0.12 or 0.055)
            if selected then
                local strokeInset = layout.cu(1.2)
                draw.strokeRect(
                    pad + strokeInset,
                    cardY + strokeInset,
                    width - pad * 2 -
                        strokeInset * 2,
                    cardH - strokeInset * 2,
                    colors.text,
                    math.max(
                        0, layout.cu(9) -
                            strokeInset),
                    layout.cu(1), 0.48)
            end
            local timeText = event.allDay and
                l10n.tr("lua_widget.agenda.all_day") or
                (formatTime(event.startMinutes) ..
                    "–" .. formatTime(event.endMinutes))
            local innerPad = layout.cu(
                8 + growth * 0.55)
            local timeW = layout.cu(
                76 + growth * 4)
            local timeY = cardY +
                math.max(
                    innerPad,
                    (cardH - smallLineH) / 2)
            draw.text(
                pad + innerPad,
                timeY,
                timeText, small, colors.text,
                timeW, true, true, nil, 0.66)
            local titleX =
                pad + innerPad + timeW +
                layout.cu(4 + growth * 0.4)
            local title = trim(event.title) ~= "" and
                event.title or
                l10n.tr("lua_widget.agenda.untitled")
            local hasNotes = trim(event.notes) ~= ""
            local lineGap = layout.cu(
                1 + growth * 0.12)
            local textBlockH = titleLineH
            if hasNotes then
                textBlockH = textBlockH +
                    lineGap + smallLineH +
                    layout.cu(5 + growth * 0.4)
            end
            local minimumTextTop = hasNotes
                and layout.cu(
                    4 + growth * 0.15)
                or innerPad
            local textY = cardY +
                math.max(
                    minimumTextTop,
                    (cardH - textBlockH) / 2)
            draw.text(
                titleX, textY,
                title, font, colors.text,
                math.max(
                    1, width - pad - titleX - layout.cu(9)),
                false, true)
            if hasNotes then
                draw.text(
                    titleX,
                    textY + titleLineH + lineGap,
                    event.notes, small, colors.text,
                    math.max(
                        1, width - pad - titleX -
                            layout.cu(9)),
                    false, true, nil, 0.52)
            end
            rowHits[#rowHits + 1] = {
                id = event.id,
                event = event,
                rect = {
                    x = pad, y = cardY,
                    w = width - pad * 2, h = cardH,
                },
            }
        end
    end
    draw.popClip()
end

local function openDatePicker()
    local info = calendar.dateInfo(
        storage.get(DRAFT_DATE) or
            calendar.selectedDate())
    if not info then
        info = calendar.dateInfo(
            calendar.selectedDate())
    end
    pickerYear = info.year
    pickerMonth = info.month
    datePickerOpen = true
end

local function shiftPickerMonth(offset)
    pickerMonth = (pickerMonth or 1) + offset
    while pickerMonth < 1 do
        pickerMonth = pickerMonth + 12
        pickerYear = pickerYear - 1
    end
    while pickerMonth > 12 do
        pickerMonth = pickerMonth - 12
        pickerYear = pickerYear + 1
    end
end

local function pickerWeekday(index)
    if index == 1 then
        return l10n.tr(
            "lua_widget.agenda.weekday_mon")
    elseif index == 2 then
        return l10n.tr(
            "lua_widget.agenda.weekday_tue")
    elseif index == 3 then
        return l10n.tr(
            "lua_widget.agenda.weekday_wed")
    elseif index == 4 then
        return l10n.tr(
            "lua_widget.agenda.weekday_thu")
    elseif index == 5 then
        return l10n.tr(
            "lua_widget.agenda.weekday_fri")
    elseif index == 6 then
        return l10n.tr(
            "lua_widget.agenda.weekday_sat")
    end
    return l10n.tr(
        "lua_widget.agenda.weekday_sun")
end

local function renderDatePicker(colors, width, height)
    pickerHits = { dates = {} }
    if not pickerYear or not pickerMonth then
        openDatePicker()
    end
    local pad = layout.cu(18)
    local button = layout.cu(32)
    local headerH = button
    local panelFontSize = math.max(
        16,
        math.min(
            18, currentFontSize() + 1))
    local titleFont = layout.fontCu(
        panelFontSize + 1)
    local dayFont = layout.fontCu(panelFontSize)
    local small = layout.fontCu(
        math.max(13, panelFontSize - 2))
    local iconFont = layout.fontCu(17)

    pickerHits.back = {
        x = pad, y = pad,
        w = button, h = button,
    }
    drawPanelButton(
        pickerHits.back, "",
        iconFont, colors, false, true,
        layout.cu(1.4))

    local todayText =
        l10n.tr("lua_widget.agenda.today")
    local todayWidth = math.max(
        layout.cu(58),
        draw.measureText(
            todayText, small, 0, true).width +
            layout.cu(16))
    pickerHits.today = {
        x = width - pad - todayWidth,
        y = pad, w = todayWidth, h = button,
    }
    drawPanelButton(
        pickerHits.today, todayText,
        small, colors, false, false, 0)

    local arrowY = pad
    local nextX =
        pickerHits.today.x - layout.cu(8) - button
    pickerHits.next = {
        x = nextX, y = arrowY,
        w = button, h = button,
    }
    pickerHits.previous = {
        x = nextX - layout.cu(4) - button,
        y = arrowY, w = button, h = button,
    }
    drawPanelButton(
        pickerHits.previous, "",
        iconFont, colors, false, true,
        layout.cu(1.4))
    drawPanelButton(
        pickerHits.next, "",
        iconFont, colors, false, true,
        layout.cu(1.4))

    local titleX =
        pickerHits.back.x + button + layout.cu(12)
    local titleW = math.max(
        1, pickerHits.previous.x -
            layout.cu(10) - titleX)
    centeredText(
        l10n.tr(
            "lua_widget.agenda.month_format",
            tostring(pickerYear),
            tostring(pickerMonth)),
        titleX, pad, titleW, button,
        titleFont, colors.text, true, 1.0)

    local weekdayTop =
        pad + headerH + layout.cu(18)
    local weekdayH = layout.cu(26)
    local gridTop = weekdayTop + weekdayH
    local gridHeight = math.max(
        1,
        math.min(
            layout.cu(420),
            height - gridTop - pad))
    local calendarX = pad + layout.cu(2)
    local calendarW =
        width - calendarX * 2
    local cellW = calendarW / 7
    local cellH = gridHeight / 6
    for column = 0, 6 do
        centeredText(
            pickerWeekday(column + 1),
            calendarX + column * cellW,
            weekdayTop, cellW, weekdayH,
            small, colors.text, true, 0.58)
    end

    local first = string.format(
        "%04d-%02d-01",
        pickerYear, pickerMonth)
    local firstInfo = calendar.dateInfo(first)
    local mondayIndex =
        (firstInfo.weekday + 5) % 7
    local gridStart =
        calendar.addDays(first, -mondayIndex)
    local selected =
        storage.get(DRAFT_DATE) or ""
    local today = todayDate()
    for index = 0, 41 do
        local date =
            calendar.addDays(gridStart, index)
        local info = calendar.dateInfo(date)
        local column = index % 7
        local row = math.floor(index / 7)
        local x = calendarX + column * cellW
        local y = gridTop + row * cellH
        local hit = {
            x = x, y = y,
            w = cellW, h = cellH,
            date = date,
        }
        pickerHits.dates[
            #pickerHits.dates + 1] = hit
        local currentMonth =
            info.year == pickerYear and
            info.month == pickerMonth
        local chosen = date == selected
        local isToday = date == today
        local diameter = math.min(
            cellW * 0.60, cellH * 0.60)
        local cx = x + cellW / 2
        local cy = y + cellH / 2
        if chosen then
            draw.circle(
                cx, cy, diameter / 2,
                colors.text, 0.92)
        elseif isToday then
            draw.strokeRect(
                cx - diameter / 2,
                cy - diameter / 2,
                diameter, diameter,
                colors.text, diameter / 2,
                layout.cu(1.2), 0.78)
        end
        centeredText(
            tostring(info.day),
            cx - diameter / 2,
            cy - diameter / 2,
            diameter, diameter, dayFont,
            chosen and
                colors.inverse or colors.text,
            chosen or isToday,
            currentMonth and 1.0 or 0.36)
    end
end

local function drawEditorLabel(
    text, x, y, width, colors, small)
    draw.text(
        x, y, text, small, colors.text,
        width, true, true, nil, 0.65)
end

local function renderEditor(
    colors, pad, top, width, height)
    editorHits = {}
    local toggleOn =
        storage.get(DRAFT_ALL_DAY) == "1"
    local contentH = layout.cu(
        toggleOn and 470 or 540)
    local offset = ui.scrollArea(
        "agenda-editor", pad, top,
        width - pad * 2, height, contentH)
    local panelPad = layout.cu(18)
    local innerX = pad + panelPad
    local innerW =
        width - pad * 2 - panelPad * 2
    local contentTop =
        top + layout.cu(10) - offset
    local panelFontSize = math.max(
        16,
        math.min(
            18, currentFontSize() + 1))
    local font = layout.fontCu(panelFontSize)
    local small = layout.fontCu(
        math.max(14, panelFontSize - 2))
    local fieldH = layout.cu(44)
    local controlStep = layout.cu(56)
    local fieldTextY = layout.cu(11)
    local notesH = layout.cu(96)
    local inputOptions = {
        fontSize = font,
        textColor = colors.text,
        placeholderColor = colors.text,
        backgroundColor = colors.text,
        borderColor = colors.text,
        focusedBorderColor = colors.text,
        backgroundAlpha = 0.055,
        focusedBackgroundAlpha = 0.10,
        borderAlpha = 0.14,
        focusedBorderAlpha = 0.68,
        radius = layout.cu(8),
        padding = layout.cu(10),
        borderThickness = layout.cu(1),
        selectAll = false,
        liveUpdate = true,
    }
    local function visible(y, h)
        return y + h >= top and y <= top + height
    end
    draw.pushClip(pad, top, width - pad * 2, height)
    local y = contentTop

    drawEditorLabel(
        l10n.tr("lua_widget.agenda.title"),
        innerX, y, innerW, colors, small)
    y = y + layout.cu(18)
    if visible(y, fieldH) then
        ui.textInput(
            "agenda-title", DRAFT_TITLE,
            innerX, y, innerW, fieldH, {
                placeholder =
                    l10n.tr(
                        "lua_widget.agenda.title_placeholder"),
                fontSize = inputOptions.fontSize,
                textColor = inputOptions.textColor,
                placeholderColor =
                    inputOptions.placeholderColor,
                backgroundColor =
                    inputOptions.backgroundColor,
                borderColor = inputOptions.borderColor,
                focusedBorderColor =
                    inputOptions.focusedBorderColor,
                backgroundAlpha =
                    inputOptions.backgroundAlpha,
                focusedBackgroundAlpha =
                    inputOptions.focusedBackgroundAlpha,
                borderAlpha = inputOptions.borderAlpha,
                focusedBorderAlpha =
                    inputOptions.focusedBorderAlpha,
                radius = inputOptions.radius,
                padding = inputOptions.padding,
                borderThickness =
                    inputOptions.borderThickness,
                selectAll = false,
                liveUpdate = true,
            })
    end
    if focusEditorTitle then
        ui.focusInput("agenda-title")
        focusEditorTitle = false
    end
    y = y + controlStep

    local dateW = innerW * 0.64
    drawEditorLabel(
        l10n.tr("lua_widget.agenda.date"),
        innerX, y, dateW, colors, small)
    y = y + layout.cu(18)
    if visible(y, fieldH) then
        draw.strokeRect(
            innerX, y, dateW, fieldH,
            colors.text, layout.cu(8),
            layout.cu(1), 0.18)
        draw.text(
            innerX + layout.cu(9),
            y + fieldTextY,
            formatDate(
                storage.get(DRAFT_DATE) or
                    calendar.selectedDate(),
                true),
            font, colors.text,
            math.max(
                1, dateW - layout.cu(34)),
            false, true)
        draw.text(
            innerX + dateW - layout.cu(22),
            y + fieldTextY, "▾",
            small, colors.text,
            layout.cu(14), true, true,
            nil, 0.72)
        editorHits.date = {
            x = innerX, y = y,
            w = dateW, h = fieldH,
        }
    end
    local toggleX = innerX + dateW + layout.cu(8)
    local toggleW = innerW - dateW - layout.cu(8)
    draw.strokeRect(
        toggleX, y, toggleW, fieldH,
        colors.text, layout.cu(8),
        layout.cu(1), 0.16)
    draw.text(
        toggleX + layout.cu(8),
        y + fieldTextY,
        l10n.tr("lua_widget.agenda.all_day"),
        small, colors.text,
        math.max(1, toggleW - layout.cu(38)),
        true, true)
    local switchW = layout.cu(28)
    local switchH = layout.cu(16)
    local switchX =
        toggleX + toggleW - switchW - layout.cu(7)
    local switchY = y + (fieldH - switchH) / 2
    draw.rect(
        switchX, switchY, switchW, switchH,
        colors.text, switchH / 2,
        toggleOn and 0.86 or 0.20)
    draw.circle(
        toggleOn
            and switchX + switchW - switchH / 2
            or switchX + switchH / 2,
        switchY + switchH / 2,
        switchH * 0.36,
        toggleOn and colors.inverse or colors.text,
        1.0)
    editorHits.allDay = {
        x = toggleX, y = y,
        w = toggleW, h = fieldH,
    }
    y = y + controlStep

    if not toggleOn then
        local timeGap = layout.cu(8)
        local timeW =
            (innerW - timeGap) / 2
        drawEditorLabel(
            l10n.tr("lua_widget.agenda.start"),
            innerX, y, timeW, colors, small)
        drawEditorLabel(
            l10n.tr("lua_widget.agenda.end"),
            innerX + timeW + timeGap,
            y, timeW, colors, small)
        y = y + layout.cu(18)
        if visible(y, fieldH) then
            ui.textInput(
                "agenda-start", DRAFT_START,
                innerX, y, timeW, fieldH,
                inputOptions)
            ui.textInput(
                "agenda-end", DRAFT_END,
                innerX + timeW + timeGap,
                y, timeW, fieldH,
                inputOptions)
        end
        y = y + controlStep
    end

    drawEditorLabel(
        l10n.tr("lua_widget.agenda.reminder"),
        innerX, y, innerW, colors, small)
    y = y + layout.cu(18)
    draw.strokeRect(
        innerX, y, innerW, fieldH,
        colors.text, layout.cu(8),
        layout.cu(1), 0.16)
    draw.text(
        innerX + layout.cu(9),
        y + fieldTextY,
        reminderLabel(draftReminder()),
        font, colors.text,
        innerW - layout.cu(28), false, true)
    draw.text(
        innerX + innerW - layout.cu(20),
        y + fieldTextY, "›",
        font, colors.text, layout.cu(14),
        true, true)
    editorHits.reminder = {
        x = innerX, y = y,
        w = innerW, h = fieldH,
    }
    y = y + controlStep

    drawEditorLabel(
        l10n.tr("lua_widget.agenda.notes"),
        innerX, y, innerW, colors, small)
    y = y + layout.cu(18)
    if visible(y, notesH) then
        ui.textArea(
            "agenda-notes", DRAFT_NOTES,
            innerX, y, innerW, notesH, {
                placeholder =
                    l10n.tr(
                        "lua_widget.agenda.notes_placeholder"),
                fontSize = font,
                textColor = colors.text,
                placeholderColor = colors.text,
                backgroundColor = colors.text,
                borderColor = colors.text,
                focusedBorderColor = colors.text,
                backgroundAlpha = 0.045,
                focusedBackgroundAlpha = 0.08,
                borderAlpha = 0.12,
                focusedBorderAlpha = 0.62,
                radius = layout.cu(8),
                padding = layout.cu(10),
                borderThickness = layout.cu(1),
                selectAll = false,
                liveUpdate = true,
            })
    end
    y = y + notesH + layout.cu(12)

    local errorText = editorErrorText()
    if errorText then
        draw.text(
            innerX, y, errorText, small,
            colors.text, innerW, true, false, nil, 0.88)
    end
    y = y + layout.cu(28)
    local buttonGap = layout.cu(8)
    local buttonW = (innerW - buttonGap) / 2
    draw.strokeRect(
        innerX, y, buttonW, fieldH,
        colors.text, layout.cu(8),
        layout.cu(1), 0.30)
    centeredText(
        l10n.tr("lua_widget.agenda.cancel"),
        innerX, y, buttonW, fieldH,
        small, colors.text, true, 1.0)
    editorHits.cancel = {
        x = innerX, y = y,
        w = buttonW, h = fieldH,
    }
    local saveX = innerX + buttonW + buttonGap
    draw.rect(
        saveX, y, buttonW, fieldH,
        colors.text, layout.cu(8), 0.92)
    centeredText(
        l10n.tr("lua_widget.agenda.save"),
        saveX, y, buttonW, fieldH,
        small, colors.inverse, true, 1.0)
    editorHits.save = {
        x = saveX, y = y,
        w = buttonW, h = fieldH,
    }
    draw.popClip()
end

function render()
    widget.setTitle(l10n.tr("lua_widget.agenda.name"))
    headerHits = {}
    local hostSelected =
        widget.info().selected == true
    if wasHostSelected == true and
        not hostSelected and
        not isEditing() then
        returnToToday()
    end
    wasHostSelected = hostSelected
    local colors = palette()
    local width = layout.width()
    local height = layout.height()
    local pad = layout.cu(11)
    local contentTop =
        renderHeader(colors, pad, width)
    local contentBottom =
        height - layout.cu(layout.barHeight()) -
        layout.cu(5)
    local contentH =
        math.max(1, contentBottom - contentTop)
    renderList(
        colors, pad, contentTop, width, contentH,
        hostSelected)
end

function renderPanel()
    local colors = palette()
    local width = layout.width()
    local height = layout.height()
    if datePickerOpen then
        renderDatePicker(colors, width, height)
    elseif isEditing() then
        renderEditor(
            colors, 0, 0, width, height)
    end
end

local function shiftSelectedDate(offset)
    local nextDate = calendar.addDays(
        calendar.selectedDate(), offset)
    if nextDate then
        calendar.setSelectedDate(nextDate)
        eventsDirty = true
        ui.setScrollOffset("agenda-events", 0)
    end
end

local function rowAt(x, y)
    for _, hit in ipairs(rowHits) do
        if pointIn(hit.rect, x, y) then return hit end
    end
    return nil
end

function onClick(x, y)
    if pointIn(headerHits.previous, x, y) then
        shiftSelectedDate(-1)
        return
    elseif pointIn(headerHits.next, x, y) then
        shiftSelectedDate(1)
        return
    elseif pointIn(headerHits.today, x, y) then
        calendar.setSelectedDate(todayDate())
        eventsDirty = true
        ui.setScrollOffset("agenda-events", 0)
        return
    elseif pointIn(headerHits.add, x, y) then
        startNew()
        return
    end

    local hit = rowAt(x, y)
    if hit then
        storage.set(SELECTED_ID, hit.id)
    else
        storage.remove(SELECTED_ID)
    end
end

function onPanelClick(x, y)
    if datePickerOpen then
        if pointIn(pickerHits.back, x, y) then
            datePickerOpen = false
        elseif pointIn(
            pickerHits.previous, x, y) then
            shiftPickerMonth(-1)
        elseif pointIn(
            pickerHits.next, x, y) then
            shiftPickerMonth(1)
        elseif pointIn(
            pickerHits.today, x, y) then
            storage.set(DRAFT_DATE, todayDate())
            datePickerOpen = false
        else
            for _, hit in ipairs(
                pickerHits.dates or {}) do
                if pointIn(hit, x, y) then
                    storage.set(
                        DRAFT_DATE, hit.date)
                    datePickerOpen = false
                    break
                end
            end
        end
        widget.invalidate()
        return
    end
    if pointIn(editorHits.date, x, y) then
        openDatePicker()
    elseif pointIn(editorHits.allDay, x, y) then
        storage.set(
            DRAFT_ALL_DAY,
            storage.get(DRAFT_ALL_DAY) == "1"
                and "0" or "1")
    elseif pointIn(editorHits.reminder, x, y) then
        cycleReminder()
    elseif pointIn(editorHits.cancel, x, y) then
        widget.closePanel()
    elseif pointIn(editorHits.save, x, y) then
        saveDraft()
    end
    widget.invalidate()
end

function onPanelClosed()
    if isEditing() then
        clearDraft()
    end
end

function onDoubleClick(x, y)
    if isEditing() then return end
    local hit = rowAt(x, y)
    if hit then
        storage.set(SELECTED_ID, hit.id)
        startEdit(hit.event)
    end
end

function onCalendarChanged(reason)
    eventsDirty = true
    if reason == "selection" and not isEditing() then
        ui.setScrollOffset("agenda-events", 0)
        storage.remove(SELECTED_ID)
    end
end

function getContextMenu()
    local selectedId = storage.get(SELECTED_ID)
    local selected = selectedId and eventsById[selectedId]
    return {
        {
            id = 1,
            label = l10n.tr("lua_widget.agenda.add"),
            icon = "",
        },
        {
            id = 2,
            label = l10n.tr("lua_widget.agenda.edit"),
            icon = "",
            enabled = selected ~= nil,
        },
        {
            id = 3,
            label = l10n.tr("lua_widget.agenda.delete"),
            icon = "",
            enabled = selected ~= nil,
        },
        { separator = true },
        {
            id = 4,
            label = l10n.tr("lua_widget.agenda.today"),
            icon = "",
        },
        {
            id = 5,
            label = l10n.tr(
                "lua_widget.agenda.previous_day"),
            icon = "",
        },
        {
            id = 6,
            label = l10n.tr(
                "lua_widget.agenda.next_day"),
            icon = "",
        },
    }
end

function onMenu(id)
    if id == 1 then
        startNew()
    elseif id == 2 then
        startEdit(eventsById[storage.get(SELECTED_ID)])
    elseif id == 3 then
        local event = eventsById[storage.get(SELECTED_ID)]
        if event then
            local result = calendar.remove(event.id)
            if result and result.ok then
                storage.remove(SELECTED_ID)
                eventsDirty = true
            end
        end
    elseif id == 4 then
        calendar.setSelectedDate(todayDate())
        eventsDirty = true
        ui.setScrollOffset("agenda-events", 0)
    elseif id == 5 then
        shiftSelectedDate(-1)
    elseif id == 6 then
        shiftSelectedDate(1)
    end
    widget.invalidate()
end

function imguiRender()
    local values = { 1, 3, 7, 30 }
    local labels = {
        l10n.tr("lua_widget.agenda.range_1"),
        l10n.tr("lua_widget.agenda.range_3"),
        l10n.tr("lua_widget.agenda.range_7"),
        l10n.tr("lua_widget.agenda.range_30"),
    }
    local current = rangeDays()
    local selectedIndex = 3
    for index, value in ipairs(values) do
        if value == current then
            selectedIndex = index
            break
        end
    end
    local nextIndex = imgui.combo(
        l10n.tr("lua_widget.agenda.range"),
        selectedIndex, labels)
    if nextIndex ~= selectedIndex then
        storage.set(
            "rangeDays", tostring(values[nextIndex]))
        eventsDirty = true
        ui.setScrollOffset("agenda-events", 0)
    end
end

function onLanguageChanged()
    widget.setTitle(l10n.tr("lua_widget.agenda.name"))
    eventsDirty = true
end
