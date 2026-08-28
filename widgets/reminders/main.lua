-- reminders/main.lua - API v2 transactional local ToDo list
local descriptor

local fluent = {
    addTask = utf8.char(0xF788),
    delete = utf8.char(0xF34C),
    clear = utf8.char(0xF201),
    complete = utf8.char(0xE309),
    reset = utf8.char(0xF19F),
    edit = utf8.char(0xE70F),
}

local MAX_TASKS = 200

local settings = {
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
    },
}

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function taskTextKey(id)
    return "task_" .. id .. "_text"
end

local function legacyTaskDoneKey(id)
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

local function loadDoneIds()
    local done = {}
    local raw = storage.get("doneIds") or ""
    for id in string.gmatch(raw, "[^,]+") do
        if string.match(id, "^%d+$") then done[id] = true end
    end
    return done
end

local function setOrRemove(tx, key, value)
    if value == "" then tx:remove(key) else tx:set(key, value) end
end

local function saveOrder(tx, ids)
    setOrRemove(tx, "order", table.concat(ids, ","))
end

local function saveDoneIds(tx, ids, done)
    local ordered = {}
    for _, id in ipairs(ids) do
        if done[id] then ordered[#ordered + 1] = id end
    end
    setOrRemove(tx, "doneIds", table.concat(ordered, ","))
end

local function loadTasks(includeCompleted)
    local pending = {}
    local completed = {}
    local done = loadDoneIds()
    for _, id in ipairs(loadOrder()) do
        local text = storage.get(taskTextKey(id))
        if text ~= nil then
            local task = { id = id, text = text, done = done[id] == true }
            if task.done then
                if includeCompleted then completed[#completed + 1] = task end
            else
                pending[#pending + 1] = task
            end
        end
    end
    for _, task in ipairs(completed) do pending[#pending + 1] = task end
    return pending
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
    if text == "" or #ids >= MAX_TASKS then return false end

    local nextId = math.max(1, tonumber(storage.get("nextId")) or 1)
    local id = tostring(nextId)
    while storage.get(taskTextKey(id)) ~= nil do
        nextId = nextId + 1
        id = tostring(nextId)
    end
    ids[#ids + 1] = id
    storage.transaction(function(tx)
        tx:set(taskTextKey(id), text)
        saveOrder(tx, ids)
        tx:set("nextId", tostring(nextId + 1))
        tx:remove("draft")
    end)
    return true
end

local function toggleTask(id)
    local ids = loadOrder()
    local done = loadDoneIds()
    done[id] = not done[id]
    storage.transaction(function(tx)
        saveDoneIds(tx, ids, done)
    end)
end

local function deleteTask(id)
    local ids = loadOrder()
    local done = loadDoneIds()
    local kept = {}
    for _, current in ipairs(ids) do
        if current ~= id then kept[#kept + 1] = current end
    end
    done[id] = nil
    storage.transaction(function(tx)
        tx:remove(taskTextKey(id))
        saveOrder(tx, kept)
        saveDoneIds(tx, kept, done)
    end)
end

local function clearCompleted()
    local ids = loadOrder()
    local done = loadDoneIds()
    local kept = {}
    local removed = {}
    for _, id in ipairs(ids) do
        if done[id] then
            removed[#removed + 1] = id
        else
            kept[#kept + 1] = id
        end
    end
    storage.transaction(function(tx)
        for _, id in ipairs(removed) do tx:remove(taskTextKey(id)) end
        saveOrder(tx, kept)
        tx:remove("doneIds")
    end)
end

local function setAllCompleted(doneValue)
    local ids = loadOrder()
    local done = {}
    if doneValue then
        for _, id in ipairs(ids) do done[id] = true end
    end
    storage.transaction(function(tx)
        saveDoneIds(tx, ids, done)
    end)
end

local function migrateStorage(oldVersion, newVersion)
    local migrateDoneState = oldVersion < 2 and newVersion >= 2
    local migrateSelectionState = oldVersion < 3 and newVersion >= 3
    if not migrateDoneState and not migrateSelectionState then return end

    local ids = {}
    local done = {}
    if migrateDoneState then
        ids = loadOrder()
        for _, id in ipairs(ids) do
            if storage.get(legacyTaskDoneKey(id)) == "1" then
                done[id] = true
            end
        end
    end
    storage.transaction(function(tx)
        if migrateDoneState then
            for _, id in ipairs(ids) do
                tx:remove(legacyTaskDoneKey(id))
            end
            saveDoneIds(tx, ids, done)
        end
        if migrateSelectionState then tx:remove("selectedId") end
    end)
end

local function getPalette()
    local theme = widget.theme()
    if theme and theme.contentTheme == 1 then
        return {
            text = 0x000000, muted = 0x000000, completed = 0x6F6F6F,
            accent = 0x000000, add = 0x000000, card = 0x000000,
            inputText = 0x000000, placeholder = 0x000000,
            inputBg = 0x000000, inputBorder = 0x000000,
            inputFocus = 0x000000, delete = 0x000000,
        }
    end
    return {
        text = 0xFFFFFF, muted = 0xFFFFFF, completed = 0xA8A8A8,
        accent = 0xFFFFFF, add = 0xFFFFFF, card = 0xFFFFFF,
        inputText = 0xFFFFFF, placeholder = 0xFFFFFF,
        inputBg = 0xFFFFFF, inputBorder = 0xFFFFFF,
        inputFocus = 0xFFFFFF, delete = 0xFFFFFF,
    }
end

local function currentFontSize()
    return math.max(11, math.min(20, tonumber(storage.get("fontSize")) or 15))
end

local function showCompleted()
    return storage.get("showCompleted") ~= "0"
end

local function setup()
    widget.setTitle(l10n.tr("lua_widget.reminders.name"))
    return { editingTaskId = nil, selectedId = nil }
end

local function registerRegion(key, shape, cursor, events, accessibility,
    enabled)
    interaction.region({
        key = key,
        shape = shape,
        cursor = cursor,
        events = events,
        accessibility = accessibility,
        enabled = enabled ~= false,
    })
end

local function render(context, model)
    if not context.selected then
        model.selectedId = nil
        model.editingTaskId = nil
    end
    local w = layout.width()
    local h = layout.height()
    local pad = layout.cu(14)
    local gap = layout.cu(7)
    local palette = getPalette()
    local fontSize = layout.fontCu(currentFontSize())
    local smallFont = layout.fontCu(math.max(10, currentFontSize() - 3))
    local total = taskCounts()

    local inputY = pad
    local inputH = layout.cu(34)
    local addSize = layout.cu(36)
    local inputW = math.max(layout.cu(28), w - pad * 2 - addSize - gap)
    control.textInput({
        key = "new-task",
        storageKey = "draft",
        shape = { type = "rect", x = pad, y = inputY,
            width = inputW, height = inputH },
        placeholder = l10n.tr("lua_widget.reminders.add_placeholder"),
        fontSize = fontSize,
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
        maxBytes = 4096,
    })

    local addEnabled = trim(storage.get("draft") or "") ~= "" and
        total < MAX_TASKS
    local addX = pad + inputW + gap
    local addY = inputY + (inputH - addSize) / 2
    local addKey = "task.add"
    local addHovered = interaction.isHovered(addKey)
    if addHovered and addEnabled then
        draw.circle(addX + addSize / 2, addY + addSize / 2,
            addSize / 2, palette.add, 0.10)
    end
    local addCx = addX + addSize / 2
    local addCy = addY + addSize / 2
    draw.line(addCx - addSize * 0.27, addCy,
        addCx + addSize * 0.27, addCy, layout.cu(3), palette.add,
        addEnabled and 1.0 or 0.28)
    draw.line(addCx, addCy - addSize * 0.27,
        addCx, addCy + addSize * 0.27, layout.cu(3), palette.add,
        addEnabled and 1.0 or 0.28)
    registerRegion(addKey, {
        type = "circle", x = addCx, y = addCy, radius = addSize / 2,
    }, "hand", { click = { id = "task.add" } }, {
        role = "button", label = l10n.tr("lua_widget.reminders.add_task"),
    }, addEnabled)

    local listTop = inputY + inputH + layout.cu(12)
    local listBottom = h - layout.cu(7)
    local viewportH = math.max(1, listBottom - listTop)
    local viewportShape = { type = "rect", x = pad, y = listTop,
        width = w - pad * 2, height = viewportH }
    registerRegion("tasks.background", viewportShape, "default", {
        click = { id = "task.clearSelection" },
        contextMenu = { id = "task.menu", scope = "component" },
    }, { role = "list", label = l10n.tr("lua_widget.reminders.name") })

    local rowH = layout.cu(math.max(43, currentFontSize() + 27))
    local rowGap = layout.cu(5)
    local cardH = rowH - rowGap
    local tasks = loadTasks(showCompleted())
    if #tasks == 0 then
        local hint = total > 0 and
            l10n.tr("lua_widget.reminders.completed_hidden") or
            l10n.tr("lua_widget.reminders.empty_hint")
        local emptyTitle = total > 0 and
            l10n.tr("lua_widget.reminders.all_done") or
            l10n.tr("lua_widget.reminders.empty")
        local emptyIconSize = layout.cu(42)
        local emptyBlockH = layout.cu(88)
        local emptyTop = listTop + math.max(0, (viewportH - emptyBlockH) / 2)
        local emptyCy = emptyTop + emptyIconSize / 2
        draw.circle(w / 2, emptyCy, emptyIconSize / 2, palette.accent, 0.13)
        draw.line(w / 2 - emptyIconSize * 0.22, emptyCy,
            w / 2 - emptyIconSize * 0.05, emptyCy + emptyIconSize * 0.17,
            layout.cu(2.0), palette.accent, 0.82)
        draw.line(w / 2 - emptyIconSize * 0.05,
            emptyCy + emptyIconSize * 0.17,
            w / 2 + emptyIconSize * 0.27,
            emptyCy - emptyIconSize * 0.22,
            layout.cu(2.0), palette.accent, 0.82)
        local titleMetrics = draw.measureText(emptyTitle, fontSize, 0, true)
        local hintMetrics = draw.measureText(hint, smallFont, 0, false)
        draw.text(math.max(pad, (w - titleMetrics.width) / 2),
            emptyCy + layout.cu(29), emptyTitle, fontSize, palette.text,
            math.min(w - pad * 2, titleMetrics.width + layout.cu(2)), true,
            true)
        draw.text(math.max(pad, (w - hintMetrics.width) / 2),
            emptyCy + layout.cu(53), hint, smallFont, palette.muted,
            math.min(w - pad * 2, hintMetrics.width + layout.cu(2)), false,
            true)
        return
    end

    local scroll = interaction.scroll({
        key = "tasks.scroll",
        shape = viewportShape,
        contentHeight = math.ceil(#tasks * rowH),
    })
    local first = math.max(1, math.floor(scroll.offset / rowH) + 1)
    local last = math.min(#tasks,
        math.ceil((scroll.offset + viewportH) / rowH))
    local selectedId = model.selectedId

    draw.pushClip(pad, listTop, w - pad * 2, viewportH)
    for index = first, last do
        local task = tasks[index]
        local cardY = listTop + (index - 1) * rowH - scroll.offset
        local cardW = w - pad * 2
        local rowKey = "task.row." .. task.id
        local selected = task.id == selectedId
        local rowHovered = interaction.isHovered(rowKey)
        draw.rect(pad, cardY, cardW, cardH, palette.card, layout.cu(10),
            selected and 0.105 or (rowHovered and 0.08 or 0.055))
        if selected then
            local inset = layout.cu(1.2)
            draw.strokeRect(pad + inset, cardY + inset,
                cardW - inset * 2, cardH - inset * 2, palette.accent,
                math.max(0, layout.cu(10) - inset), layout.cu(1), 0.42)
        end
        registerRegion(rowKey, {
            type = "roundedRect", x = pad, y = cardY,
            width = cardW, height = cardH, radius = layout.cu(10),
        }, "hand", {
            click = { id = "task.select", value = task.id },
            doubleClick = { id = "task.edit", value = task.id },
            contextMenu = { id = "task.menu", value = task.id },
        }, { role = "listitem", label = task.text })

        local checkboxSize = math.min(layout.cu(22), cardH - layout.cu(10))
        local checkboxX = pad + layout.cu(11)
        local checkboxY = cardY + (cardH - checkboxSize) / 2
        local checkboxKey = "task.toggle." .. task.id
        local checkboxHovered = interaction.isHovered(checkboxKey)
        draw.strokeRect(checkboxX, checkboxY, checkboxSize, checkboxSize,
            palette.accent, checkboxSize / 2, layout.cu(1.5),
            checkboxHovered and 1.0 or (task.done and 1.0 or 0.62))
        if task.done then
            local cx = checkboxX + checkboxSize / 2
            local cy = checkboxY + checkboxSize / 2
            draw.line(cx - checkboxSize * 0.24, cy,
                cx - checkboxSize * 0.06, cy + checkboxSize * 0.20,
                layout.cu(1.5), palette.accent, 1.0)
            draw.line(cx - checkboxSize * 0.06, cy + checkboxSize * 0.20,
                cx + checkboxSize * 0.28, cy - checkboxSize * 0.22,
                layout.cu(1.5), palette.accent, 1.0)
        end
        registerRegion(checkboxKey, {
            type = "circle", x = checkboxX + checkboxSize / 2,
            y = checkboxY + checkboxSize / 2,
            radius = checkboxSize / 2 + layout.cu(4),
        }, "hand", { click = { id = "task.toggle", value = task.id } }, {
            role = "checkbox", label = task.text,
        })

        local deleteSize = layout.cu(16)
        local deleteX = w - pad - deleteSize - layout.cu(11)
        local textX = checkboxX + checkboxSize + layout.cu(10)
        local textW = math.max(1, deleteX - textX - layout.cu(8))
        local displayText = task.text ~= "" and task.text or
            l10n.tr("lua_widget.reminders.untitled")
        local measured = draw.measureText(displayText, fontSize, 0, false)
        local textY = cardY + math.max(0, (cardH - measured.height) / 2)
        local editing = selected and model.editingTaskId == task.id
        if editing then
            control.textInput({
                key = "edit-task-" .. task.id,
                storageKey = taskTextKey(task.id),
                shape = { type = "rect", x = textX,
                    y = cardY, width = textW, height = cardH },
                fontSize = fontSize,
                textColor = palette.inputText,
                placeholder = l10n.tr("lua_widget.reminders.untitled"),
                placeholderColor = palette.placeholder,
                backgroundColor = palette.inputBg,
                borderColor = palette.inputBorder,
                focusedBorderColor = palette.inputFocus,
                backgroundAlpha = 0.0,
                focusedBackgroundAlpha = 0.0,
                borderAlpha = 0.0,
                focusedBorderAlpha = 0.0,
                radius = 0,
                padding = 0,
                borderThickness = layout.cu(1),
                selectAll = true,
                liveUpdate = true,
                maxBytes = 4096,
            })
        else
            draw.text(textX, textY, displayText, fontSize,
                task.done and palette.completed or palette.text,
                textW, false, true)
            if task.done then
                draw.line(textX, cardY + cardH / 2,
                    textX + math.min(textW, measured.width),
                    cardY + cardH / 2, layout.cu(1),
                    palette.completed, 0.72)
            end
        end

        if selected then
            local deleteKey = "task.delete." .. task.id
            local deleteHovered = interaction.isHovered(deleteKey)
            if deleteHovered then
                draw.circle(deleteX + deleteSize / 2,
                    cardY + cardH / 2, deleteSize * 0.85,
                    palette.delete, 0.09)
            end
            draw.fluent(fluent.delete, deleteX,
                cardY + (cardH - deleteSize) / 2,
                deleteSize, palette.delete)
            registerRegion(deleteKey, {
                type = "rect", x = deleteX - layout.cu(5), y = cardY,
                width = deleteSize + layout.cu(10), height = cardH,
            }, "hand", {
                click = { id = "task.delete", value = task.id },
            }, { role = "button",
                label = l10n.tr("lua_widget.reminders.delete_selected") })
        end
    end
    draw.popClip()
end

local function event(_context, model, value)
    if value.kind == "environment" then
        widget.setTitle(l10n.tr("lua_widget.reminders.name"))
        return
    end
    if value.kind ~= "action" then return end
    local id = value.value and tostring(value.value) or nil
    if value.id == "task.add" then
        if addDraft() then
            model.selectedId = nil
            model.editingTaskId = nil
        end
    elseif value.id == "task.clearSelection" then
        model.selectedId = nil
        model.editingTaskId = nil
    elseif value.id == "task.select" and id then
        model.selectedId = id
        model.editingTaskId = nil
    elseif value.id == "task.edit" and id then
        model.selectedId = id
        model.editingTaskId = id
        control.focus("edit-task-" .. id)
    elseif value.id == "task.toggle" and id then
        model.editingTaskId = nil
        toggleTask(id)
    elseif value.id == "task.delete" and id then
        model.selectedId = nil
        model.editingTaskId = nil
        deleteTask(id)
    elseif value.id == "task.focusAdd" then
        control.focus("new-task")
    elseif value.id == "task.clearCompleted" then
        model.selectedId = nil
        model.editingTaskId = nil
        clearCompleted()
    elseif value.id == "task.setAll" then
        model.editingTaskId = nil
        local total, completed = taskCounts()
        if total > 0 then setAllCompleted(completed < total) end
    end
end

local function menu(_context, _model, request)
    if request.id ~= "task.menu" then return nil end
    local total, completed = taskCounts()
    local taskId = request.value and tostring(request.value) or nil
    if taskId and storage.get(taskTextKey(taskId)) ~= nil then
        return ui.menu({
            {
                id = "task.edit",
                label = l10n.tr("lua_widget.reminders.edit_selected"),
                icon = fluent.edit,
                iconFont = "fluent",
            },
            {
                id = "task.delete",
                label = l10n.tr("lua_widget.reminders.delete_selected"),
                icon = fluent.delete,
                iconFont = "fluent",
            },
        })
    end
    local items = {
        {
            id = "task.focusAdd",
            label = l10n.tr("lua_widget.reminders.add_task"),
            icon = fluent.addTask,
            iconFont = "fluent",
        },
    }
    items[#items + 1] = { type = "separator" }
    items[#items + 1] = {
        id = "task.clearCompleted",
        label = l10n.tr("lua_widget.reminders.clear_completed"),
        icon = fluent.clear,
        iconFont = "fluent",
        enabled = completed > 0,
    }
    items[#items + 1] = {
        id = "task.setAll",
        label = completed < total and
            l10n.tr("lua_widget.reminders.complete_all") or
            l10n.tr("lua_widget.reminders.reopen_all"),
        icon = completed < total and fluent.complete or fluent.reset,
        iconFont = "fluent",
        enabled = total > 0,
    }
    return ui.menu(items)
end

descriptor = {
    name = l10n.tr("lua_widget.reminders.name"),
    useCustomStyle = true,
    followPersonalizationDefault = true,
    showTitle = false,
    bottomBarHover = false,
    bg = 0x151A21,
    border = 0xFFFFFF,
    alpha = 0.42,
    borderAlpha = 0.18,
    gradientEndA = 0.28,
    settings = settings,
    setup = setup,
    render = render,
    event = event,
    menu = menu,
    migrateStorage = migrateStorage,
}

return widget.define(descriptor)
