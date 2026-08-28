-- agenda/main.lua - API v2 subscribed calendar with an editable panel
local descriptor

local fluent = {
    add = utf8.char(0xF211),
    edit = utf8.char(0xE246),
    delete = utf8.char(0xF34C),
    today = utf8.char(0xF23C),
    previous = utf8.char(0xF15B),
    next = utf8.char(0xF181),
}

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

local settings = {
    fields = {
        {
            key = "rangeDays",
            label = l10n.tr("lua_widget.agenda.range"),
            type = "select",
            default = "7",
            options = { "1", "3", "7", "30" },
            optionLabels = {
                l10n.tr("lua_widget.agenda.range_1"),
                l10n.tr("lua_widget.agenda.range_3"),
                l10n.tr("lua_widget.agenda.range_7"),
                l10n.tr("lua_widget.agenda.range_30"),
            },
        },
        {
            key = "fontSize",
            label = l10n.tr("lua_widget.common.font_size"),
            type = "int",
            default = 15,
            min = 11,
            max = 20,
        },
    },
}

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function todayDate()
    local now = time.parts()
    return string.format("%04d-%02d-%02d", now.year, now.month, now.day)
end

local function formatTime(minutes)
    local value = math.max(0, math.min(1439, tonumber(minutes) or 0))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end

local function parseTime(value)
    local hour, minute = string.match(trim(value), "^(%d%d?):(%d%d)$")
    hour = tonumber(hour)
    minute = tonumber(minute)
    if not hour or not minute or hour < 0 or hour > 23 or
        minute < 0 or minute > 59 then
        return nil
    end
    return hour * 60 + minute
end

local function rangeDays()
    local value = tonumber(storage.get("rangeDays")) or 7
    if value == 1 or value == 3 or value == 7 or value == 30 then
        return value
    end
    return 7
end

local function fontSize()
    return math.max(11, math.min(20,
        tonumber(storage.get("fontSize")) or 15))
end

local function palette(context)
    local light = context.theme and context.theme.mode == "light"
    return light and {
        text = 0x000000, muted = 0x4F4F4F, secondary = 0x303030,
        card = 0x000000,
        accent = 0x000000, inverse = 0xFFFFFF, danger = 0x8A1C1C,
    } or {
        text = 0xFFFFFF, muted = 0xB7B7B7, secondary = 0xE0E0E0,
        card = 0xFFFFFF,
        accent = 0xFFFFFF, inverse = 0x000000, danger = 0xFFB5B5,
    }
end

local function formatDate(date, includeWeekday)
    local info = calendar.dateInfo(date)
    if not info then return date end
    local base = l10n.tr("lua_widget.agenda.date_format",
        tostring(info.month), tostring(info.day))
    if not includeWeekday then return base end
    local keys = {
        "lua_widget.agenda.weekday_sun",
        "lua_widget.agenda.weekday_mon",
        "lua_widget.agenda.weekday_tue",
        "lua_widget.agenda.weekday_wed",
        "lua_widget.agenda.weekday_thu",
        "lua_widget.agenda.weekday_fri",
        "lua_widget.agenda.weekday_sat",
    }
    return base .. " · " .. l10n.tr(keys[info.weekday])
end

local function reminderLabel(value)
    local keys = {
        [-1] = "lua_widget.agenda.reminder_none",
        [0] = "lua_widget.agenda.reminder_now",
        [5] = "lua_widget.agenda.reminder_5",
        [15] = "lua_widget.agenda.reminder_15",
        [30] = "lua_widget.agenda.reminder_30",
        [60] = "lua_widget.agenda.reminder_60",
        [1440] = "lua_widget.agenda.reminder_1440",
    }
    return l10n.tr(keys[tonumber(value) or 15] or keys[15])
end

local function selectedDate(model)
    if model.selectedSubscription then
        local snapshot = model.selectedSubscription:value()
        if snapshot.available and snapshot.value and snapshot.value.date then
            model.selectedDate = snapshot.value.date
        end
    end
    return model.selectedDate or todayDate()
end

local function rebuildEventSubscription(model)
    local first = selectedDate(model)
    if model.eventSubscription then
        model.eventSubscription:unsubscribe()
    end
    model.eventSubscription = data.subscribe("calendar.events", {
        fromDate = first,
        toDate = calendar.addDays(first, 29),
        whenHidden = "pause",
        maxAgeMs = 86400000,
    })
    model.subscriptionStart = first
end

local function events(model)
    local result = {}
    model.eventsById = {}
    if not model.eventSubscription then return result end
    local snapshot = model.eventSubscription:value()
    if not snapshot.available or not snapshot.value then return result end
    local first = selectedDate(model)
    local last = calendar.addDays(first, rangeDays() - 1)
    for _, item in ipairs(snapshot.value.events or {}) do
        if item.date >= first and item.date <= last then
            result[#result + 1] = item
            model.eventsById[item.id] = item
        end
    end
    return result
end

local function clearDraftTransaction(tx)
    tx:remove(DRAFT_TITLE)
    tx:remove(DRAFT_DATE)
    tx:remove(DRAFT_ALL_DAY)
    tx:remove(DRAFT_START)
    tx:remove(DRAFT_END)
    tx:remove(DRAFT_REMINDER)
    tx:remove(DRAFT_NOTES)
    tx:remove(EDITOR_MODE)
    tx:remove(EDITOR_ID)
    tx:remove(EDITOR_REVISION)
end

local function clearDraft(model)
    if model.pendingPanelTask then task.cancel(model.pendingPanelTask) end
    storage.transaction(clearDraftTransaction)
    model.editorError = nil
    model.pendingPanelTask = nil
    model.datePickerOpen = false
end

local function openEditor(model)
    local title = storage.get(EDITOR_MODE) == "edit" and
        l10n.tr("lua_widget.agenda.edit") or
        l10n.tr("lua_widget.agenda.add")
    model.editorError = nil
    widget.openPanel({
        title = title,
        width = math.min(720, math.max(460, layout.cu(460))),
        height = math.min(820, math.max(520, layout.cu(540))),
    })
    model.panelOpen = true
end

local function startNew(model)
    if not widget.hasPermission("calendar.write") then return end
    if model.panelOpen then
        widget.closePanel()
        return
    end
    local date = selectedDate(model)
    local startMinutes = 540
    if date == todayDate() then
        local now = time.parts()
        startMinutes = math.min(1410,
            math.floor((now.hour * 60 + now.min + 29) / 30) * 30)
    end
    storage.transaction(function(tx)
        clearDraftTransaction(tx)
        tx:set(DRAFT_TITLE, "")
        tx:set(DRAFT_DATE, date)
        tx:set(DRAFT_ALL_DAY, "0")
        tx:set(DRAFT_START, formatTime(startMinutes))
        tx:set(DRAFT_END, formatTime(math.min(1439, startMinutes + 60)))
        tx:set(DRAFT_REMINDER, "15")
        tx:set(EDITOR_MODE, "new")
    end)
    openEditor(model)
end

local function startEdit(model, item)
    if not item or not widget.hasPermission("calendar.write") then return end
    if model.panelOpen then
        widget.closePanel()
        return
    end
    storage.transaction(function(tx)
        clearDraftTransaction(tx)
        tx:set(DRAFT_TITLE, item.title or "")
        tx:set(DRAFT_DATE, item.date)
        tx:set(DRAFT_ALL_DAY, item.allDay and "1" or "0")
        tx:set(DRAFT_START, formatTime(item.startMinutes))
        tx:set(DRAFT_END, formatTime(item.endMinutes))
        tx:set(DRAFT_REMINDER, tostring(item.reminderMinutes or -1))
        if item.notes and item.notes ~= "" then tx:set(DRAFT_NOTES, item.notes) end
        tx:set(EDITOR_MODE, "edit")
        tx:set(EDITOR_ID, item.id)
        tx:set(EDITOR_REVISION, tostring(item.revision))
    end)
    openEditor(model)
end

local function saveDraft(model)
    if model.pendingPanelTask then return end
    local title = trim(storage.get(DRAFT_TITLE) or "")
    if title == "" then model.editorError = "invalidTitle" return end
    local date = trim(storage.get(DRAFT_DATE) or "")
    if not calendar.dateInfo(date) then
        model.editorError = "invalidDate"
        return
    end
    local allDay = storage.get(DRAFT_ALL_DAY) == "1"
    local startMinutes = parseTime(storage.get(DRAFT_START) or "")
    local endMinutes = parseTime(storage.get(DRAFT_END) or "")
    if not allDay and (not startMinutes or not endMinutes or
        endMinutes < startMinutes) then
        model.editorError = "invalidTime"
        return
    end
    local arguments = {
        title = title,
        date = date,
        allDay = allDay,
        startMinutes = allDay and 0 or startMinutes,
        endMinutes = allDay and 0 or endMinutes,
        notes = storage.get(DRAFT_NOTES) or "",
        reminderMinutes = tonumber(storage.get(DRAFT_REMINDER)) or 15,
    }
    local taskName = "calendar.create"
    if storage.get(EDITOR_MODE) == "edit" then
        taskName = "calendar.update"
        arguments.id = storage.get(EDITOR_ID) or ""
        arguments.expectedRevision =
            tonumber(storage.get(EDITOR_REVISION)) or 0
    end
    local taskId, taskError = task.start(taskName, arguments)
    if taskId then
        model.pendingPanelTask = taskId
        model.editorError = nil
    else
        model.editorError = taskError == "permissionDenied" and
            "permissionDenied" or "saveFailed"
    end
end

local function deleteEvent(model, item)
    if not item or model.pendingDeleteTask then return end
    local taskId, taskError = task.start("calendar.remove", { id = item.id })
    if taskId then
        model.pendingDeleteTask = taskId
    else
        widget.log("warn", "calendar.remove rejected: " .. tostring(taskError))
    end
end

local function editorErrorText(error)
    if error == "invalidTitle" then
        return l10n.tr("lua_widget.agenda.invalid_title")
    elseif error == "invalidDate" then
        return l10n.tr("lua_widget.agenda.invalid_date")
    elseif error == "invalidTime" then
        return l10n.tr("lua_widget.agenda.invalid_time")
    elseif error == "conflict" then
        return l10n.tr("lua_widget.agenda.conflict")
    elseif error then
        return l10n.tr("lua_widget.agenda.save_failed")
    end
    return nil
end

local function registerRegion(key, shape, eventsValue, label, enabled)
    interaction.region({
        key = key,
        shape = shape,
        cursor = enabled == false and "default" or "hand",
        enabled = enabled ~= false,
        events = eventsValue,
        accessibility = { role = "button", label = label },
    })
end

local function centeredText(text, x, y, width, height, size, color, bold, alpha)
    local measured = draw.measureText(text, size, width, bold)
    draw.text(x + math.max(0, (width - measured.width) / 2),
        y + math.max(0, (height - measured.height) / 2), text, size,
        color, math.max(1, width), bold, true, 0, alpha or 1.0)
end

local function drawHeaderButton(key, glyph, label, shape, colors, enabled)
    local hovered = enabled and interaction.isHovered(key)
    local pressed = enabled and interaction.isPressed(key)
    if hovered then
        draw.rect(shape.x, shape.y, shape.width, shape.height,
            colors.accent, layout.cu(7), pressed and 0.16 or 0.10)
    end
    draw.fluent(glyph,
        shape.x + (shape.width - layout.cu(16)) / 2,
        shape.y + (shape.height - layout.cu(16)) / 2,
        layout.cu(16), colors.accent, enabled and 1.0 or 0.28)
    registerRegion(key, { type = "roundedRect", x = shape.x, y = shape.y,
        width = shape.width, height = shape.height, radius = layout.cu(7) },
        { click = { id = key }, contextMenu = {
            id = "agenda.menu", scope = "component" } },
        label, enabled)
end

local function drawHeaderTextButton(key, label, shape, colors, enabled)
    local hovered = enabled and interaction.isHovered(key)
    local pressed = enabled and interaction.isPressed(key)
    draw.rect(shape.x, shape.y, shape.width, shape.height,
        colors.accent, layout.cu(7),
        pressed and 0.16 or (hovered and 0.10 or 0.055))
    centeredText(label, shape.x, shape.y, shape.width, shape.height,
        layout.fontCu(11), colors.accent, true,
        enabled and 0.92 or 0.28)
    registerRegion(key, { type = "roundedRect", x = shape.x, y = shape.y,
        width = shape.width, height = shape.height, radius = layout.cu(7) },
        { click = { id = key }, contextMenu = {
            id = "agenda.menu", scope = "component" } },
        label, enabled)
end

local function render(context, model)
    local width = layout.width()
    local height = layout.height()
    local pad = layout.cu(11)
    local colors = palette(context)
    local mainFont = layout.fontCu(fontSize())
    local smallFont = layout.fontCu(math.max(10, fontSize() - 3))
    local selected = selectedDate(model)
    local canWrite = widget.hasPermission("calendar.write") and not context.preview

    local button = layout.cu(28)
    local gap = layout.cu(3)
    local headerY = pad
    drawHeaderButton("agenda.previous", fluent.previous,
        l10n.tr("lua_widget.agenda.previous_day"),
        { x = pad, y = headerY, width = button, height = button },
        colors, true)
    drawHeaderButton("agenda.next", fluent.next,
        l10n.tr("lua_widget.agenda.next_day"),
        { x = pad + button + gap, y = headerY,
            width = button, height = button }, colors, true)
    local addX = width - pad - button
    drawHeaderButton("agenda.add", fluent.add,
        l10n.tr("lua_widget.agenda.add"),
        { x = addX, y = headerY,
            width = button, height = button }, colors, canWrite)
    local todayLabel = l10n.tr("lua_widget.agenda.today")
    local todayMetrics = draw.measureText(todayLabel,
        layout.fontCu(11), 0, true)
    local todayWidth = math.max(button, math.min(width * 0.25,
        todayMetrics.width + layout.cu(14)))
    local todayX = addX - gap - todayWidth
    drawHeaderTextButton("agenda.today", todayLabel,
        { x = todayX, y = headerY,
            width = todayWidth, height = button }, colors, true)
    local titleX = pad + button * 2 + gap * 2
    local titleRight = todayX - gap
    centeredText(formatDate(selected, false), titleX, headerY,
        math.max(1, titleRight - titleX), button,
        mainFont, colors.text, true)

    local listTop = headerY + button + layout.cu(9)
    local listBottom = height - layout.cu(6)
    local viewportHeight = math.max(1, listBottom - listTop)
    local viewport = { type = "rect", x = pad, y = listTop,
        width = width - pad * 2, height = viewportHeight }
    interaction.region({
        key = "agenda.surface",
        shape = viewport,
        events = {
            click = { id = "agenda.clearSelection" },
            contextMenu = { id = "agenda.menu", scope = "component" },
        },
        accessibility = { role = "list", label = descriptor.name },
    })

    local items = events(model)
    if #items == 0 then
        centeredText(l10n.tr("lua_widget.agenda.empty"),
            pad, listTop + viewportHeight * 0.34,
            width - pad * 2, layout.cu(26), mainFont,
            colors.text, true, 0.78)
        centeredText(l10n.tr("lua_widget.agenda.empty_hint"),
            pad, listTop + viewportHeight * 0.34 + layout.cu(28),
            width - pad * 2, layout.cu(22), smallFont,
            colors.muted, false, canWrite and 0.72 or 0.38)
        return
    end

    local rowHeight = layout.cu(math.max(52, fontSize() + 35))
    local rowGap = layout.cu(5)
    local scroll = interaction.scroll({
        key = "agenda.scroll",
        shape = viewport,
        contentHeight = math.ceil(#items * rowHeight),
    })
    local first = math.max(1, math.floor(scroll.offset / rowHeight) + 1)
    local last = math.min(#items,
        math.ceil((scroll.offset + viewportHeight) / rowHeight))
    local selectedId = storage.get(SELECTED_ID)
    draw.pushClip(pad, listTop, width - pad * 2, viewportHeight)
    for index = first, last do
        local item = items[index]
        local y = listTop + (index - 1) * rowHeight - scroll.offset
        local cardHeight = rowHeight - rowGap
        local key = "agenda.event." .. item.id
        local highlighted = context.selected and selectedId == item.id
        local hovered = interaction.isHovered(key)
        draw.rect(pad, y, width - pad * 2, cardHeight,
            colors.card, layout.cu(9),
            highlighted and 0.12 or (hovered and 0.085 or 0.05))
        if highlighted then
            draw.strokeRect(pad + layout.cu(1), y + layout.cu(1),
                width - pad * 2 - layout.cu(2), cardHeight - layout.cu(2),
                colors.accent, layout.cu(8), layout.cu(1), 0.40)
        end
        registerRegion(key, { type = "roundedRect", x = pad, y = y,
            width = width - pad * 2, height = cardHeight,
            radius = layout.cu(9) }, {
            click = { id = "agenda.select", value = item.id },
            doubleClick = { id = "agenda.edit", value = item.id },
            contextMenu = { id = "agenda.menu", value = item.id },
        }, item.title or l10n.tr("lua_widget.agenda.untitled"), true)

        local textX = pad + layout.cu(11)
        local textWidth = width - pad * 2 - layout.cu(22)
        draw.text(textX, y + layout.cu(7),
            item.title ~= "" and item.title or
                l10n.tr("lua_widget.agenda.untitled"),
            mainFont, colors.text, textWidth, true, true)
        local timing = item.allDay and l10n.tr("lua_widget.agenda.all_day") or
            (formatTime(item.startMinutes) .. " – " .. formatTime(item.endMinutes))
        draw.text(textX, y + cardHeight - layout.cu(23),
            formatDate(item.date, true) .. " · " .. timing,
            smallFont, colors.secondary, textWidth, false, true, 0, 0.92)
    end
    draw.popClip()
end

local function panelLabel(text, x, y, width, font, color)
    draw.text(x, y, text, font, color, width, true, true)
end

local function panelButton(model, id, label, x, y, width, height,
    colors, primary, enabled)
    local key = "agenda.panel." .. id
    local hovered = enabled ~= false and interaction.isHovered(key)
    local pressed = enabled ~= false and interaction.isPressed(key)
    local alpha = enabled == false and 0.22 or
        (primary and (pressed and 0.76 or (hovered and 0.96 or 0.88)) or
            (pressed and 0.16 or (hovered and 0.12 or 0.08)))
    draw.rect(x, y, width, height,
        primary and colors.accent or colors.card, layout.cu(8), alpha)
    draw.strokeRect(x, y, width, height, colors.accent,
        layout.cu(8), layout.cu(1), enabled == false and 0.18 or 0.38)
    centeredText(label, x, y, width, height, layout.fontCu(14),
        primary and colors.inverse or colors.text, true,
        enabled == false and 0.38 or 1.0)
    interaction.region({
        key = key,
        shape = {
            type = "roundedRect", x = x, y = y,
            width = width, height = height, radius = layout.cu(8),
        },
        cursor = enabled == false and "default" or "hand",
        enabled = enabled ~= false,
        events = {
            click = { id = "agenda.panel", value = id },
        },
        accessibility = { role = "button", label = label },
    })
end

local function openDatePicker(model)
    if model.datePickerOpen then
        model.datePickerOpen = false
        interaction.setScrollOffset("agenda.panel.scroll", 0)
        return
    end
    local info = calendar.dateInfo(storage.get(DRAFT_DATE) or "") or
        calendar.dateInfo(todayDate())
    model.pickerYear = info.year
    model.pickerMonth = info.month
    model.datePickerOpen = true
    interaction.setScrollOffset("agenda.panel.scroll", 0)
end

local function shiftPickerMonth(model, offset)
    local month = model.pickerMonth + offset
    local year = model.pickerYear
    if month < 1 then month = 12 year = year - 1 end
    if month > 12 then month = 1 year = year + 1 end
    model.pickerYear = year
    model.pickerMonth = month
end

local function renderDatePicker(model, pad, top, fieldWidth, colors)
    local headerHeight = layout.cu(32)
    local arrowWidth = layout.cu(34)
    panelButton(model, "picker.previous", "‹", pad, top,
        arrowWidth, headerHeight, colors, false, true)
    panelButton(model, "picker.next", "›",
        pad + arrowWidth + layout.cu(5), top,
        arrowWidth, headerHeight, colors, false, true)
    local todayWidth = layout.cu(58)
    panelButton(model, "picker.today", l10n.tr("lua_widget.agenda.today"),
        pad + fieldWidth - todayWidth, top,
        todayWidth, headerHeight, colors, false, true)
    local titleX = pad + arrowWidth * 2 + layout.cu(14)
    local titleRight = pad + fieldWidth - todayWidth - layout.cu(8)
    centeredText(l10n.tr("lua_widget.agenda.month_format",
        tostring(model.pickerYear), tostring(model.pickerMonth)),
        titleX, top, math.max(1, titleRight - titleX), headerHeight,
        layout.fontCu(14), colors.text, true)

    local weekdayKeys = {
        "lua_widget.agenda.weekday_mon",
        "lua_widget.agenda.weekday_tue",
        "lua_widget.agenda.weekday_wed",
        "lua_widget.agenda.weekday_thu",
        "lua_widget.agenda.weekday_fri",
        "lua_widget.agenda.weekday_sat",
        "lua_widget.agenda.weekday_sun",
    }
    local weekdaysY = top + headerHeight + layout.cu(8)
    local cellWidth = fieldWidth / 7
    local cellHeight = layout.cu(31)
    for index, key in ipairs(weekdayKeys) do
        centeredText(l10n.tr(key), pad + (index - 1) * cellWidth,
            weekdaysY, cellWidth, layout.cu(22), layout.fontCu(11),
            colors.muted, true, 0.72)
    end
    local first = string.format("%04d-%02d-01",
        model.pickerYear, model.pickerMonth)
    local firstInfo = calendar.dateInfo(first)
    local gridStart = calendar.addDays(first, -((firstInfo.weekday + 5) % 7))
    local selected = storage.get(DRAFT_DATE) or ""
    local gridY = weekdaysY + layout.cu(23)
    for zero = 0, 41 do
        local date = calendar.addDays(gridStart, zero)
        local info = calendar.dateInfo(date)
        local column = zero % 7
        local row = math.floor(zero / 7)
        local x = pad + column * cellWidth
        local y = gridY + row * cellHeight
        local currentMonth = info.year == model.pickerYear and
            info.month == model.pickerMonth
        if date == selected then
            draw.circle(x + cellWidth / 2, y + cellHeight / 2,
                math.min(cellWidth, cellHeight) * 0.39,
                colors.accent, 0.88)
        end
        centeredText(tostring(info.day), x, y, cellWidth, cellHeight,
            layout.fontCu(12), date == selected and colors.inverse or
                colors.text, date == selected,
            currentMonth and 1.0 or 0.34)
        local id = "picker.date:" .. date
        interaction.region({
            key = "agenda.panel." .. id,
            shape = {
                type = "rect", x = x, y = y,
                width = cellWidth, height = cellHeight,
            },
            cursor = "hand",
            events = {
                click = { id = "agenda.panel", value = id },
            },
            accessibility = { role = "button", label = date },
        })
    end
end

local function panel(context, model)
    local width = layout.width()
    local height = layout.height()
    local pad = layout.cu(20)
    local colors = palette(context)
    local labelFont = layout.fontCu(12)
    local inputFont = layout.fontCu(14)
    local fieldWidth = width - pad * 2
    local inputHeight = layout.cu(38)
    local allDay = storage.get(DRAFT_ALL_DAY) == "1"
    local desiredHeight = model.datePickerOpen and layout.cu(500) or
        (allDay and layout.cu(430) or layout.cu(510))
    local contentHeight = math.max(height, desiredHeight)
    local scroll = interaction.scroll({
        key = "agenda.panel.scroll",
        shape = { type = "rect", x = 0, y = 0,
            width = width, height = height },
        contentHeight = math.ceil(contentHeight),
    })
    local originY = -scroll.offset
    draw.pushClip(0, 0, width, height)

    panelLabel(l10n.tr("lua_widget.agenda.title"), pad,
        layout.cu(16) + originY,
        fieldWidth, labelFont, colors.muted)
    control.textInput({
        key = "agenda-title", storageKey = DRAFT_TITLE,
        shape = { type = "rect", x = pad,
            y = layout.cu(38) + originY,
            width = fieldWidth, height = inputHeight },
        placeholder = l10n.tr("lua_widget.agenda.title_placeholder"),
        fontSize = inputFont, textColor = colors.text,
        placeholderColor = colors.muted, backgroundColor = colors.card,
        borderColor = colors.muted, focusedBorderColor = colors.accent,
        backgroundAlpha = 0.055, focusedBackgroundAlpha = 0.09,
        borderAlpha = 0.24, focusedBorderAlpha = 0.78,
        radius = layout.cu(7), padding = layout.cu(9),
        borderThickness = layout.cu(1), selectAll = false,
        liveUpdate = true, maxBytes = 512,
    })

    local dateY = layout.cu(88) + originY
    panelLabel(l10n.tr("lua_widget.agenda.date"), pad, dateY,
        fieldWidth * 0.58, labelFont, colors.muted)
    local dateInputWidth = fieldWidth * 0.43
    local pickerGap = layout.cu(7)
    local pickerWidth = fieldWidth * 0.14
    control.textInput({
        key = "agenda-date", storageKey = DRAFT_DATE,
        shape = { type = "rect", x = pad, y = dateY + layout.cu(22),
            width = dateInputWidth, height = inputHeight },
        placeholder = "YYYY-MM-DD", fontSize = inputFont,
        textColor = colors.text, placeholderColor = colors.muted,
        backgroundColor = colors.card, borderColor = colors.muted,
        focusedBorderColor = colors.accent, backgroundAlpha = 0.055,
        focusedBackgroundAlpha = 0.09, borderAlpha = 0.24,
        focusedBorderAlpha = 0.78, radius = layout.cu(7),
        padding = layout.cu(9), borderThickness = layout.cu(1),
        selectAll = true, liveUpdate = true, maxBytes = 10,
    })
    panelButton(model, "openDatePicker", "…",
        pad + dateInputWidth + pickerGap, dateY + layout.cu(22),
        pickerWidth, inputHeight, colors, false, true)
    local allDayX = pad + dateInputWidth + pickerGap + pickerWidth + pickerGap
    panelButton(model, "toggleAllDay", l10n.tr("lua_widget.agenda.all_day"),
        allDayX, dateY + layout.cu(22),
        pad + fieldWidth - allDayX, inputHeight, colors,
        storage.get(DRAFT_ALL_DAY) == "1", true)

    if model.datePickerOpen then
        renderDatePicker(model, pad, layout.cu(166) + originY,
            fieldWidth, colors)
        panelButton(model, "cancel", l10n.tr("lua_widget.agenda.cancel"),
            pad, contentHeight - layout.cu(57) + originY,
            fieldWidth, layout.cu(38),
            colors, false, true)
        draw.popClip()
        return
    end

    local timeY = layout.cu(162) + originY
    if not allDay then
        local half = (fieldWidth - layout.cu(10)) / 2
        panelLabel(l10n.tr("lua_widget.agenda.start"), pad, timeY,
            half, labelFont, colors.muted)
        panelLabel(l10n.tr("lua_widget.agenda.end"),
            pad + half + layout.cu(10), timeY,
            half, labelFont, colors.muted)
        control.textInput({
            key = "agenda-start", storageKey = DRAFT_START,
            shape = { type = "rect", x = pad, y = timeY + layout.cu(22),
                width = half, height = inputHeight },
            placeholder = "09:00", fontSize = inputFont,
            textColor = colors.text, placeholderColor = colors.muted,
            backgroundColor = colors.card, borderColor = colors.muted,
            focusedBorderColor = colors.accent, backgroundAlpha = 0.055,
            focusedBackgroundAlpha = 0.09, borderAlpha = 0.24,
            focusedBorderAlpha = 0.78, radius = layout.cu(7),
            padding = layout.cu(9), borderThickness = layout.cu(1),
            selectAll = true, liveUpdate = true, maxBytes = 5,
        })
        control.textInput({
            key = "agenda-end", storageKey = DRAFT_END,
            shape = { type = "rect", x = pad + half + layout.cu(10),
                y = timeY + layout.cu(22), width = half,
                height = inputHeight },
            placeholder = "10:00", fontSize = inputFont,
            textColor = colors.text, placeholderColor = colors.muted,
            backgroundColor = colors.card, borderColor = colors.muted,
            focusedBorderColor = colors.accent, backgroundAlpha = 0.055,
            focusedBackgroundAlpha = 0.09, borderAlpha = 0.24,
            focusedBorderAlpha = 0.78, radius = layout.cu(7),
            padding = layout.cu(9), borderThickness = layout.cu(1),
            selectAll = true, liveUpdate = true, maxBytes = 5,
        })
    end

    local reminderY = (allDay and layout.cu(162) or layout.cu(236)) +
        originY
    panelLabel(l10n.tr("lua_widget.agenda.reminder"), pad, reminderY,
        fieldWidth, labelFont, colors.muted)
    panelButton(model, "cycleReminder",
        reminderLabel(storage.get(DRAFT_REMINDER)), pad,
        reminderY + layout.cu(22), fieldWidth, inputHeight,
        colors, false, true)

    local notesY = reminderY + layout.cu(72)
    panelLabel(l10n.tr("lua_widget.agenda.notes"), pad, notesY,
        fieldWidth, labelFont, colors.muted)
    control.textArea({
        key = "agenda-notes", storageKey = DRAFT_NOTES,
        shape = { type = "rect", x = pad, y = notesY + layout.cu(22),
            width = fieldWidth, height = layout.cu(86) },
        placeholder = l10n.tr("lua_widget.agenda.notes_placeholder"),
        placeholderWhenWhitespace = true, fontSize = inputFont,
        textColor = colors.text, placeholderColor = colors.muted,
        backgroundColor = colors.card, borderColor = colors.muted,
        focusedBorderColor = colors.accent, backgroundAlpha = 0.055,
        focusedBackgroundAlpha = 0.09, borderAlpha = 0.24,
        focusedBorderAlpha = 0.78, radius = layout.cu(7),
        padding = layout.cu(9), borderThickness = layout.cu(1),
        selectAll = false, liveUpdate = true, maxBytes = 8192,
    })

    local errorText = editorErrorText(model.editorError)
    if errorText then
        draw.text(pad, contentHeight - layout.cu(91) + originY,
            errorText, labelFont,
            colors.danger, fieldWidth, false, true)
    end
    local buttonY = contentHeight - layout.cu(57) + originY
    local actionWidth = (fieldWidth - layout.cu(10)) / 2
    panelButton(model, "cancel", l10n.tr("lua_widget.agenda.cancel"),
        pad, buttonY, actionWidth, layout.cu(38), colors, false, true)
    panelButton(model, "save", l10n.tr("lua_widget.agenda.save"),
        pad + actionWidth + layout.cu(10), buttonY,
        actionWidth, layout.cu(38), colors, true,
        model.pendingPanelTask == nil)
    draw.popClip()
end

local function setup()
    widget.setTitle(l10n.tr("lua_widget.agenda.name"))
    local model = {
        selectedDate = todayDate(), eventsById = {},
        pendingPanelTask = nil, pendingDeleteTask = nil,
        editorError = nil, datePickerOpen = false, panelOpen = false,
    }
    model.selectedSubscription = data.subscribe("calendar.selectedDate", {
        whenHidden = "pause", maxAgeMs = 86400000,
    })
    selectedDate(model)
    rebuildEventSubscription(model)
    return model
end

local function shiftSelectedDate(model, offset)
    local date = calendar.addDays(selectedDate(model), offset)
    if date and calendar.selectDate(date) then
        model.selectedDate = date
        rebuildEventSubscription(model)
        interaction.setScrollOffset("agenda.scroll", 0)
        storage.remove(SELECTED_ID)
    end
end

local function handlePanelAction(model, id)
    if id == "cancel" then
        widget.closePanel()
    elseif id == "save" then
        saveDraft(model)
    elseif id == "toggleAllDay" then
        storage.set(DRAFT_ALL_DAY,
            storage.get(DRAFT_ALL_DAY) == "1" and "0" or "1")
        widget.invalidate()
    elseif id == "openDatePicker" then
        openDatePicker(model)
        widget.invalidate()
    elseif id == "picker.previous" then
        shiftPickerMonth(model, -1)
        widget.invalidate()
    elseif id == "picker.next" then
        shiftPickerMonth(model, 1)
        widget.invalidate()
    elseif id == "picker.today" then
        storage.set(DRAFT_DATE, todayDate())
        model.datePickerOpen = false
        widget.invalidate()
    elseif string.sub(id, 1, 12) == "picker.date:" then
        storage.set(DRAFT_DATE, string.sub(id, 13))
        model.datePickerOpen = false
        widget.invalidate()
    elseif id == "cycleReminder" then
        local current = tonumber(storage.get(DRAFT_REMINDER)) or 15
        local nextValue = reminderValues[1]
        for index, value in ipairs(reminderValues) do
            if value == current then
                nextValue = reminderValues[index % #reminderValues + 1]
                break
            end
        end
        storage.set(DRAFT_REMINDER, tostring(nextValue))
        widget.invalidate()
    end
end

local function event(_context, model, value)
    if value.kind == "environment" then
        widget.setTitle(l10n.tr("lua_widget.agenda.name"))
        return
    elseif value.kind == "data.change" then
        if value.topic == "calendar.selectedDate" then
            selectedDate(model)
            rebuildEventSubscription(model)
            interaction.setScrollOffset("agenda.scroll", 0)
            storage.remove(SELECTED_ID)
        end
        return
    elseif value.kind == "panel" then
        if value.action == "opened" then
            model.panelOpen = true
        elseif value.action == "closed" then
            model.panelOpen = false
            clearDraft(model)
        end
        return
    elseif value.kind == "action" and value.surface == "panel" and
        value.id == "agenda.panel" then
        handlePanelAction(model, tostring(value.value or ""))
        return
    elseif value.kind == "task.complete" then
        if value.taskId == model.pendingPanelTask then
            model.pendingPanelTask = nil
            if value.ok and value.value then
                local date = storage.get(DRAFT_DATE) or selectedDate(model)
                local id = value.value.id
                storage.transaction(function(tx)
                    clearDraftTransaction(tx)
                    if id and id ~= "" then tx:set(SELECTED_ID, id) end
                end)
                calendar.selectDate(date)
                model.selectedDate = date
                widget.closePanel()
            else
                model.editorError = value.error == "conflict" and
                    "conflict" or "saveFailed"
            end
        elseif value.taskId == model.pendingDeleteTask then
            model.pendingDeleteTask = nil
            if value.ok then storage.remove(SELECTED_ID) end
        end
        return
    elseif value.kind ~= "action" then
        return
    end

    local id = value.value and tostring(value.value) or nil
    if value.id == "agenda.previous" then
        shiftSelectedDate(model, -1)
    elseif value.id == "agenda.next" then
        shiftSelectedDate(model, 1)
    elseif value.id == "agenda.today" then
        local today = todayDate()
        calendar.selectDate(today)
        model.selectedDate = today
        rebuildEventSubscription(model)
        interaction.setScrollOffset("agenda.scroll", 0)
        storage.remove(SELECTED_ID)
    elseif value.id == "agenda.add" then
        startNew(model)
    elseif value.id == "agenda.clearSelection" then
        storage.remove(SELECTED_ID)
    elseif value.id == "agenda.select" and id then
        storage.set(SELECTED_ID, id)
    elseif value.id == "agenda.edit" and id then
        storage.set(SELECTED_ID, id)
        startEdit(model, model.eventsById[id])
    elseif value.id == "agenda.delete" and id then
        deleteEvent(model, model.eventsById[id])
    end
end

local function menu(_context, model, request)
    if request.id ~= "agenda.menu" then return nil end
    local id = request.value and tostring(request.value) or
        storage.get(SELECTED_ID)
    local item = id and model.eventsById[id] or nil
    local canWrite = widget.hasPermission("calendar.write")
    if item then
        return ui.menu({
            {
                id = "agenda.edit",
                label = l10n.tr("lua_widget.agenda.edit"),
                icon = fluent.edit, iconFont = "fluent",
                enabled = canWrite,
            },
            {
                id = "agenda.delete",
                label = l10n.tr("lua_widget.agenda.delete"),
                icon = fluent.delete, iconFont = "fluent",
                enabled = canWrite,
            },
        })
    end
    return ui.menu({
        {
            id = "agenda.add", label = l10n.tr("lua_widget.agenda.add"),
            icon = fluent.add, iconFont = "fluent", enabled = canWrite,
        },
        { type = "separator" },
        {
            id = "agenda.today", label = l10n.tr("lua_widget.agenda.today"),
            icon = fluent.today, iconFont = "fluent",
        },
        {
            id = "agenda.previous",
            label = l10n.tr("lua_widget.agenda.previous_day"),
            icon = fluent.previous, iconFont = "fluent",
        },
        {
            id = "agenda.next", label = l10n.tr("lua_widget.agenda.next_day"),
            icon = fluent.next, iconFont = "fluent",
        },
    })
end

local function dispose(_context, model)
    if model.selectedSubscription then
        model.selectedSubscription:unsubscribe()
    end
    if model.eventSubscription then model.eventSubscription:unsubscribe() end
end

descriptor = {
    name = l10n.tr("lua_widget.agenda.name"),
    useCustomStyle = true,
    followPersonalizationDefault = true,
    showTitle = false,
    bottomBarHover = false,
    bg = 0x151A21,
    border = 0xFFFFFF,
    alpha = 0.40,
    borderAlpha = 0.18,
    gradientEndA = 0.28,
    settings = settings,
    setup = setup,
    render = render,
    panel = panel,
    event = event,
    menu = menu,
    dispose = dispose,
}

return widget.define(descriptor)
