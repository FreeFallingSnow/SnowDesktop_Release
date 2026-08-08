name = l10n.tr("lua_widget.reminders.name")
useCustomStyle = true
followPersonalizationDefault = true
showTitle = false
bottomBarHover = false

local fluent = {
    addTask = utf8.char(0xF788),
    delete = utf8.char(0xF34C),
    clear = utf8.char(0xF201),
    complete = utf8.char(0xE309),
    reset = utf8.char(0xF19F),
}

bg = 0x151A21
border = 0xFFFFFF
alpha = 0.42
borderAlpha = 0.18
gradientEndA = 0.28

local MAX_TASKS = 200
local rowHits = {}
local addHit = nil
local editingTaskId = nil
local focusEditingTaskId = nil

settings = {
    fields = {
        {
            key = "showCompleted",
            label = l10n.tr("lua_widget.reminders.show_completed"),
            type = "bool",
            default = true,
        },
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

local function taskTextKey(id)
    return "task_" .. id .. "_text"
end

local function taskDoneKey(id)
    return "task_" .. id .. "_done"
end

local function loadOrder()
    local ids = {}
    local raw = storage.get("order") or ""
    for id in string.gmatch(raw, "[^,]+") do
        if string.match(id, "^%d+$") then
            ids[#ids + 1] = id
        end
    end
    return ids
end

local function saveOrder(ids)
    local value = table.concat(ids, ",")
    if value == "" then
        storage.remove("order")
    else
        storage.set("order", value)
    end
end

local function loadTasks(includeCompleted)
    local tasks = {}
    for _, id in ipairs(loadOrder()) do
        local text = storage.get(taskTextKey(id))
        if text ~= nil then
            local done = storage.get(taskDoneKey(id)) == "1"
            if includeCompleted or not done then
                tasks[#tasks + 1] = {
                    id = id,
                    text = text,
                    done = done,
                }
            end
        end
    end
    return tasks
end

local function taskCounts()
    local total = 0
    local completed = 0
    for _, task in ipairs(loadTasks(true)) do
        total = total + 1
        if task.done then completed = completed + 1 end
    end
    return total, completed
end

local function addDraft()
    local text = trim(storage.get("draft") or "")
    local ids = loadOrder()
    if text == "" or #ids >= MAX_TASKS then return end

    local nextId = math.max(1, tonumber(storage.get("nextId")) or 1)
    local id = tostring(nextId)
    while storage.get(taskTextKey(id)) ~= nil do
        nextId = nextId + 1
        id = tostring(nextId)
    end

    storage.set(taskTextKey(id), text)
    storage.set(taskDoneKey(id), "0")
    ids[#ids + 1] = id
    saveOrder(ids)
    storage.set("nextId", tostring(nextId + 1))
    storage.remove("draft")
    storage.remove("selectedId")
end

local function toggleTask(id)
    local key = taskDoneKey(id)
    storage.set(key, storage.get(key) == "1" and "0" or "1")
end

local function deleteTask(id)
    local kept = {}
    for _, current in ipairs(loadOrder()) do
        if current ~= id then kept[#kept + 1] = current end
    end
    storage.remove(taskTextKey(id))
    storage.remove(taskDoneKey(id))
    if storage.get("selectedId") == id then
        storage.remove("selectedId")
    end
    saveOrder(kept)
end

local function clearCompleted()
    local kept = {}
    for _, id in ipairs(loadOrder()) do
        if storage.get(taskDoneKey(id)) == "1" then
            storage.remove(taskTextKey(id))
            storage.remove(taskDoneKey(id))
            if storage.get("selectedId") == id then
                storage.remove("selectedId")
            end
        else
            kept[#kept + 1] = id
        end
    end
    saveOrder(kept)
end

local function setAllCompleted(done)
    for _, id in ipairs(loadOrder()) do
        storage.set(taskDoneKey(id), done and "1" or "0")
    end
end

local function getPalette()
    local theme = widget.theme()
    if theme and theme.contentTheme == 1 then
        return {
            text = 0x000000,
            muted = 0x000000,
            completed = 0x6F6F6F,
            accent = 0x000000,
            add = 0x000000,
            card = 0x000000,
            divider = 0x000000,
            inputText = 0x000000,
            placeholder = 0x000000,
            inputBg = 0x000000,
            inputBorder = 0x000000,
            inputFocus = 0x000000,
            delete = 0x000000,
        }
    end
    return {
        text = 0xFFFFFF,
        muted = 0xFFFFFF,
        completed = 0xA8A8A8,
        accent = 0xFFFFFF,
        add = 0xFFFFFF,
        card = 0xFFFFFF,
        divider = 0xFFFFFF,
        inputText = 0xFFFFFF,
        placeholder = 0xFFFFFF,
        inputBg = 0xFFFFFF,
        inputBorder = 0xFFFFFF,
        inputFocus = 0xFFFFFF,
        delete = 0xFFFFFF,
    }
end

local function currentFontSize()
    return math.max(11, math.min(20, tonumber(storage.get("fontSize")) or 15))
end

local function showCompleted()
    return storage.get("showCompleted") ~= "0"
end

local function pointIn(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.w
        and y >= rect.y and y <= rect.y + rect.h
end

local function findRowHit(x, y)
    for _, hit in ipairs(rowHits) do
        if pointIn(hit.row, x, y) then return hit end
    end
    return nil
end

function render()
    widget.setTitle(l10n.tr("lua_widget.reminders.name"))
    rowHits = {}
    addHit = nil

    local w = layout.width()
    local h = layout.height()
    local pad = layout.cu(14)
    local gap = layout.cu(7)
    local palette = getPalette()
    local accent = palette.accent
    local fontSize = layout.fontCu(currentFontSize())
    local smallFont = layout.fontCu(math.max(10, currentFontSize() - 3))
    local total = taskCounts()
    local hostSelected = widget.info().selected == true
    if not hostSelected then
        editingTaskId = nil
        focusEditingTaskId = nil
    end

    local inputY = pad
    local inputH = layout.cu(34)
    local addSize = layout.cu(36)
    local inputW = math.max(layout.cu(28),
        w - pad * 2 - addSize - gap)
    ui.textInput("new-task", "draft", pad, inputY, inputW, inputH, {
        placeholder = l10n.tr("lua_widget.reminders.add_placeholder"),
        fontSize = layout.fontCu(currentFontSize()),
        textColor = palette.inputText,
        placeholderColor = palette.placeholder,
        backgroundColor = palette.inputBg,
        borderColor = palette.inputBorder,
        focusedBorderColor = palette.inputFocus,
        backgroundAlpha = 0.065,
        focusedBackgroundAlpha = 0.11,
        borderAlpha = 0.10,
        focusedBorderAlpha = 0.75,
        radius = layout.cu(10),
        padding = layout.cu(10),
        borderThickness = layout.cu(1),
        selectAll = false,
        liveUpdate = true,
    })

    local addEnabled = trim(storage.get("draft") or "") ~= ""
        and total < MAX_TASKS
    local addX = pad + inputW + gap
    local addY = inputY + (inputH - addSize) / 2
    local addCx = addX + addSize / 2
    local addCy = addY + addSize / 2
    draw.line(addCx - addSize * 0.27, addCy,
        addCx + addSize * 0.27, addCy,
        layout.cu(3), palette.add, 1.0)
    draw.line(addCx, addCy - addSize * 0.27,
        addCx, addCy + addSize * 0.27,
        layout.cu(3), palette.add, 1.0)
    addHit = {
        x = addX - layout.cu(3),
        y = addY - layout.cu(3),
        w = addSize + layout.cu(6),
        h = addSize + layout.cu(6),
        enabled = addEnabled,
    }

    local listTop = inputY + inputH + layout.cu(12)
    local bottomBarH = layout.cu(layout.barHeight())
    local listBottom = h - bottomBarH - layout.cu(7)
    local viewportH = math.max(1, listBottom - listTop)
    local rowH = layout.cu(math.max(43, currentFontSize() + 27))
    local rowGap = layout.cu(5)
    local cardH = rowH - rowGap
    local tasks = loadTasks(showCompleted())

    if #tasks == 0 then
        local hint = total > 0
            and l10n.tr("lua_widget.reminders.completed_hidden")
            or l10n.tr("lua_widget.reminders.empty_hint")
        local emptyTitle = total > 0
            and l10n.tr("lua_widget.reminders.all_done")
            or l10n.tr("lua_widget.reminders.empty")
        local emptyIconSize = layout.cu(42)
        local emptyBlockH = layout.cu(88)
        local emptyTop = listTop + math.max(0,
            (viewportH - emptyBlockH) / 2)
        local emptyCy = emptyTop + emptyIconSize / 2
        draw.circle(w / 2, emptyCy, emptyIconSize / 2, accent, 0.13)
        draw.line(w / 2 - emptyIconSize * 0.22, emptyCy,
            w / 2 - emptyIconSize * 0.05, emptyCy + emptyIconSize * 0.17,
            layout.cu(2.0), accent, 0.82)
        draw.line(w / 2 - emptyIconSize * 0.05,
            emptyCy + emptyIconSize * 0.17,
            w / 2 + emptyIconSize * 0.27,
            emptyCy - emptyIconSize * 0.22,
            layout.cu(2.0), accent, 0.82)

        local emptyTitleMetrics = draw.measureText(emptyTitle, fontSize, 0, true)
        local hintMetrics = draw.measureText(hint, smallFont, 0, false)
        draw.text(math.max(pad, (w - emptyTitleMetrics.width) / 2),
            emptyCy + layout.cu(29), emptyTitle, fontSize,
            palette.text, math.min(w - pad * 2, emptyTitleMetrics.width + layout.cu(2)),
            true, true)
        draw.text(math.max(pad, (w - hintMetrics.width) / 2),
            emptyCy + layout.cu(53), hint, smallFont,
            palette.muted, math.min(w - pad * 2, hintMetrics.width + layout.cu(2)),
            false, true)
        return
    end

    local range = ui.virtualList("tasks", pad, listTop, w - pad * 2,
        viewportH, rowH, #tasks)
    local selectedId = storage.get("selectedId")

    draw.pushClip(pad, listTop, w - pad * 2, viewportH)
    for index = range.first, range.last do
        local task = tasks[index]
        local y = listTop + (index - 1) * rowH - range.offset
        local cardY = y
        local cardW = w - pad * 2
        local selected = hostSelected and
            task.id == selectedId
        draw.rect(pad, cardY, cardW, cardH, palette.card,
            layout.cu(10), selected and 0.105 or 0.055)
        if selected then
            local strokeInset = layout.cu(1.2)
            draw.strokeRect(
                pad + strokeInset,
                cardY + strokeInset,
                cardW - strokeInset * 2,
                cardH - strokeInset * 2,
                accent,
                math.max(
                    0, layout.cu(10) -
                        strokeInset),
                layout.cu(1), 0.42)
        end

        local checkboxSize = math.min(layout.cu(22), cardH - layout.cu(10))
        local checkboxX = pad + layout.cu(11)
        local checkboxY = cardY + (cardH - checkboxSize) / 2
        local deleteSize = layout.cu(16)
        local deleteX = w - pad - deleteSize - layout.cu(11)
        local textX = checkboxX + checkboxSize + layout.cu(10)
        local textW = math.max(1,
            deleteX - textX - (selected and layout.cu(8) or 0))

        if task.done then
            draw.strokeRect(checkboxX, checkboxY, checkboxSize, checkboxSize,
                accent, checkboxSize / 2, layout.cu(1.5), 1.0)
            local cx = checkboxX + checkboxSize / 2
            local cy = checkboxY + checkboxSize / 2
            draw.line(cx - checkboxSize * 0.24, cy,
                cx - checkboxSize * 0.06, cy + checkboxSize * 0.20,
                layout.cu(1.5), accent, 1.0)
            draw.line(cx - checkboxSize * 0.06, cy + checkboxSize * 0.20,
                cx + checkboxSize * 0.28, cy - checkboxSize * 0.22,
                layout.cu(1.5), accent, 1.0)
        else
            draw.strokeRect(checkboxX, checkboxY, checkboxSize, checkboxSize,
                accent, checkboxSize / 2, layout.cu(1.5), 0.62)
        end

        local displayText = task.text ~= ""
            and task.text or l10n.tr("lua_widget.reminders.untitled")
        local textColor = task.done and
            palette.completed or palette.text
        local measured = draw.measureText(
            displayText, fontSize, 0, false)
        local textY = cardY +
            math.max(0, (cardH - measured.height) / 2)
        local editing = selected and
            editingTaskId == task.id
        if editing then
            local editId = "edit-task-" .. task.id
            ui.textInput(editId, taskTextKey(task.id),
                textX, cardY + layout.cu(4), textW,
                cardH - layout.cu(8), {
                    fontSize = fontSize,
                    textColor = palette.inputText,
                    placeholderColor = palette.placeholder,
                    backgroundColor = palette.inputBg,
                    borderColor = palette.inputBorder,
                    focusedBorderColor = palette.inputFocus,
                    backgroundAlpha = 0.0,
                    focusedBackgroundAlpha = 0.08,
                    borderAlpha = 0.0,
                    focusedBorderAlpha = 0.50,
                    radius = layout.cu(6),
                    padding = layout.cu(5),
                    borderThickness = layout.cu(1),
                    selectAll = true,
                    liveUpdate = true,
                })
            if focusEditingTaskId == task.id then
                ui.focusInput(editId)
                focusEditingTaskId = nil
            end
        else
            draw.text(textX, textY, displayText, fontSize,
                textColor, textW, false, true)
        end
        if task.done and not editing then
            local lineW = math.min(textW, measured.width)
            draw.line(textX, cardY + cardH / 2,
                textX + lineW, cardY + cardH / 2,
                layout.cu(1), palette.completed, 0.72)
        end

        local deleteRect = nil
        if selected then
            draw.fa("", deleteX, cardY + (cardH - deleteSize) / 2,
                deleteSize, palette.delete)
            deleteRect = {
                x = deleteX - layout.cu(5),
                y = cardY,
                w = deleteSize + layout.cu(10),
                h = cardH,
            }
        end

        rowHits[#rowHits + 1] = {
            id = task.id,
            row = { x = pad, y = cardY, w = cardW, h = cardH },
            checkbox = {
                x = checkboxX - layout.cu(4),
                y = checkboxY - layout.cu(4),
                w = checkboxSize + layout.cu(8),
                h = checkboxSize + layout.cu(8),
            },
            delete = deleteRect,
            edit = {
                x = textX,
                y = cardY + layout.cu(2),
                w = textW,
                h = cardH - layout.cu(4),
            },
        }
    end
    draw.popClip()
end

function onClick(x, y)
    if addHit and pointIn(addHit, x, y) then
        if addHit.enabled then addDraft() end
        return
    end

    local hit = findRowHit(x, y)
    if not hit then
        editingTaskId = nil
        focusEditingTaskId = nil
        storage.remove("selectedId")
        return
    end

    if hit.delete and pointIn(hit.delete, x, y) then
        deleteTask(hit.id)
    elseif pointIn(hit.checkbox, x, y) then
        editingTaskId = nil
        focusEditingTaskId = nil
        toggleTask(hit.id)
    elseif storage.get("selectedId") ~= hit.id then
        editingTaskId = nil
        focusEditingTaskId = nil
        storage.set("selectedId", hit.id)
    end
end

function onDoubleClick(x, y)
    local hit = findRowHit(x, y)
    if not hit or not pointIn(hit.edit, x, y) then return end
    editingTaskId = hit.id
    focusEditingTaskId = hit.id
    storage.set("selectedId", hit.id)
    widget.invalidate()
end

function getContextMenu()
    local total, completed = taskCounts()
    local selectedId = storage.get("selectedId")
    return {
        {
            id = 1,
            label = l10n.tr("lua_widget.reminders.add_task"),
            icon = fluent.addTask,
            iconFont = "fluent",
        },
        {
            id = 4,
            label = l10n.tr("lua_widget.reminders.delete_selected"),
            icon = fluent.delete,
            iconFont = "fluent",
            enabled = selectedId ~= nil
                and storage.get(taskTextKey(selectedId)) ~= nil,
        },
        { separator = true },
        {
            id = 2,
            label = l10n.tr("lua_widget.reminders.clear_completed"),
            icon = fluent.clear,
            iconFont = "fluent",
            enabled = completed > 0,
        },
        {
            id = 3,
            label = completed < total
                and l10n.tr("lua_widget.reminders.complete_all")
                or l10n.tr("lua_widget.reminders.reopen_all"),
            icon = completed < total and fluent.complete or fluent.reset,
            iconFont = "fluent",
            enabled = total > 0,
        },
    }
end

function onMenu(id)
    if id == 1 then
        ui.focusInput("new-task")
    elseif id == 2 then
        clearCompleted()
    elseif id == 3 then
        local total, completed = taskCounts()
        if total > 0 then setAllCompleted(completed < total) end
    elseif id == 4 then
        local selectedId = storage.get("selectedId")
        if selectedId then deleteTask(selectedId) end
    end
end

function onLanguageChanged()
    widget.setTitle(l10n.tr("lua_widget.reminders.name"))
end
