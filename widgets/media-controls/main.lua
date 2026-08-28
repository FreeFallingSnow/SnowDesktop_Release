-- media-controls/main.lua - API v2 media session controls and app launcher
local mediaCurrent
local mediaArtwork
local launcherBinding

local fluent = {
    settings = utf8.char(0xF6A9),
}

local palettes = {
    dark = {
        title = 0xFFFFFF,
        subtitle = 0xF1F5F9,
        btnText = 0xFFFFFF,
        btnDisabled = 0x64748B,
        btnBg = 0xFFFFFF,
    },
    light = {
        title = 0x1E293B,
        subtitle = 0x334155,
        btnText = 0x1E293B,
        btnDisabled = 0x94A3B8,
        btnBg = 0x000000,
    },
}

local settings = {
    fields = {
        {
            key = "showArtwork",
            label = l10n.tr("lua_widget.media_control.show_artwork"),
            type = "bool",
            default = true,
        },
        {
            key = "launcherReference",
            label = l10n.tr("lua_widget.media_control.select_launcher"),
            type = "appReference",
            binding = "idlePlayer",
            emptyLabel = l10n.tr("lua_widget.media_control.not_set"),
            noResultsLabel =
                l10n.tr("lua_widget.media_control.no_search_results"),
        },
    },
}

local function getPalette()
    local theme = widget.theme()
    if theme and theme.contentTheme == 1 then
        return palettes.light
    end
    return palettes.dark
end

local function currentSession()
    if not mediaCurrent then return nil end
    local snapshot = mediaCurrent:value()
    if not snapshot.available or not snapshot.value then return nil end
    local session = snapshot.value.session
    if not session or session.playbackStatus == "closed" then return nil end
    return session
end

local function currentArtwork(session)
    if not session or not mediaArtwork or
        storage.get("showArtwork") == "0" then
        return nil
    end
    local snapshot = mediaArtwork:value()
    if not snapshot.available or not snapshot.value then return nil end
    local artwork = snapshot.value
    if artwork.sessionId ~= session.id or not artwork.image then return nil end
    return artwork
end

local function currentLauncher()
    if not launcherBinding then return nil end
    return launcherBinding:item()
end

local function chooseLauncher()
    if launcherBinding then
        launcherBinding:pick()
    else
        widget.openSettings()
    end
end

local function startMediaAction(model, taskName, pendingState)
    if not widget.hasPermission("media.action") then return end
    local session = currentSession()
    if not session then return end
    local taskId, err = task.start(taskName, {
        sessionId = session.id,
    })
    if taskId then
        model.mediaTasks[tostring(taskId)] = taskName
        model.pendingState = pendingState
    else
        model.pendingState = nil
        widget.log("warn", taskName .. " rejected: " .. tostring(err))
    end
end

local function startLauncher(model)
    local launcher = currentLauncher()
    if not launcher then
        chooseLauncher()
        return
    end
    if launcher.availability ~= "available" then
        widget.log("warn", "bound launcher is unavailable")
        return
    end
    if not widget.hasFeature("task.app.launch") or
        not widget.hasPermission("app.launch") then
        widget.openSettings()
        return
    end
    local taskId, err = task.start("app.launch", {
        ref = launcher.reference,
    })
    if taskId then
        model.launchTask = taskId
    else
        widget.log("warn", "app.launch rejected: " .. tostring(err))
    end
end

local function setup()
    launcherBinding = slots.binding("idlePlayer")
    mediaCurrent = data.subscribe("media.current", {
        maxAgeMs = 500,
        whenHidden = "throttle",
    })
    mediaArtwork = data.subscribe("media.artwork", {
        maxAgeMs = 500,
        whenHidden = "throttle",
    })

    return {
        pendingState = nil,
        mediaTasks = {},
        launchTask = nil,
    }
end

local function drawButton(model, id, taskName, glyph, label,
    x, y, size, enabled, palette, pendingState)
    local hovered = enabled and interaction.isHovered(id)
    local pressed = enabled and interaction.isPressed(id)
    local alpha = enabled and (pressed and 0.22 or (hovered and 0.16 or 0.10)) or 0.04
    local foreground = enabled and palette.btnText or palette.btnDisabled
    draw.rect(x, y, size, size, palette.btnBg, size * 0.22, alpha)
    draw.fa(glyph, x + size * 0.12, y + size * 0.12,
        size * 0.76, foreground)
    if not enabled then return end

    interaction.region({
        key = id,
        shape = {
            type = "roundedRect",
            x = x,
            y = y,
            width = size,
            height = size,
            radius = size * 0.22,
        },
        cursor = "hand",
        events = {
            click = {
                id = taskName,
                value = { pendingState = pendingState or "" },
            },
        },
        accessibility = {
            role = "button",
            label = label,
        },
    })
end

local function render(_context, model)
    local width = layout.width()
    local height = layout.height()
    local palette = getPalette()
    local session = currentSession()
    local available = session ~= nil
    local controls = available and session.controls or {}
    local canControl = widget.hasPermission("media.action")
    local artwork = currentArtwork(session)
    local launcher = currentLauncher()

    local isPlaying = available and session.playbackStatus == "playing"
    if model.pendingState == "playing" then
        if isPlaying then model.pendingState = nil end
        isPlaying = true
    elseif model.pendingState == "paused" then
        if not isPlaying then model.pendingState = nil end
        isPlaying = false
    end

    local title = available and session.title ~= "" and session.title or
        l10n.tr("lua_widget.media_control.not_playing")
    local subtitle = ""
    if available then
        subtitle = session.artist ~= "" and session.artist or session.sourceName
    elseif launcher then
        subtitle = launcher.title
    else
        subtitle = l10n.tr("lua_widget.media_control.configure_launcher")
    end

    local interactiveHeight = math.max(1, height)
    interaction.region({
        key = "media.surface",
        shape = {
            type = "rect",
            x = 0,
            y = 0,
            width = width,
            height = interactiveHeight,
        },
        events = {
            doubleClick = { id = "launcher.open" },
            contextMenu = { id = "media.menu", scope = "component" },
        },
        accessibility = {
            role = "group",
            label = l10n.tr("lua_widget.media_control.name"),
        },
    })

    local buttonSize = layout.cu(40)
    local buttonGap = layout.cu(12)
    local total = buttonSize * 3 + buttonGap * 2
    local buttonY = height - buttonSize - layout.cu(8)
    local buttonX = (width - total) / 2

    local textX = layout.cu(18)
    if artwork then
        local artworkSize = math.min(layout.cu(52),
            buttonY - layout.cu(16))
        if artworkSize >= layout.cu(24) then
            local artworkY = math.max(layout.cu(8),
                (buttonY - artworkSize) / 2)
            draw.imageFit(artwork.image, textX, artworkY,
                artworkSize, artworkSize, "cover", "center", 1.0, "linear")
            draw.strokeRect(textX, artworkY, artworkSize, artworkSize,
                palette.btnText, layout.cu(5), layout.cu(1), 0.16)
            textX = textX + artworkSize + layout.cu(12)
        end
    end

    local titleY = subtitle ~= "" and height * 0.14 or height * 0.25
    local textWidth = math.max(layout.cu(24),
        width - textX - layout.cu(18))
    draw.text(textX, titleY, title, layout.fontCu(15),
        palette.title, textWidth, true, true)
    if subtitle ~= "" then
        draw.text(textX, titleY + layout.cu(22), subtitle,
            layout.fontCu(12), palette.subtitle,
            textWidth, true, true)
    end

    drawButton(model, "media.previous", "media.previous", "",
        l10n.tr("lua_widget.media_control.previous"),
        buttonX, buttonY, buttonSize,
        available and canControl and controls.canPrevious,
        palette)
    drawButton(model, "media.toggle", "media.toggle",
        isPlaying and "" or "",
        l10n.tr(isPlaying and "lua_widget.media_control.pause" or
            "lua_widget.media_control.play"),
        buttonX + buttonSize + buttonGap, buttonY, buttonSize,
        available and canControl and controls.canPlayPause,
        palette, isPlaying and "paused" or "playing")
    drawButton(model, "media.next", "media.next", "",
        l10n.tr("lua_widget.media_control.next"),
        buttonX + (buttonSize + buttonGap) * 2, buttonY, buttonSize,
        available and canControl and controls.canNext,
        palette)
end

local function event(_context, model, value)
    if value.kind == "task.complete" then
        if value.taskId == model.launchTask then
            model.launchTask = nil
            if not value.ok then
                widget.log("warn", "app.launch failed: " ..
                    tostring(value.error))
            end
            return
        end
        local mediaTask = model.mediaTasks[tostring(value.taskId)]
        if mediaTask then
            model.mediaTasks[tostring(value.taskId)] = nil
            if not value.ok then
                model.pendingState = nil
                widget.log("warn", mediaTask .. " failed: " ..
                    tostring(value.error))
            end
        end
        return
    end

    if value.kind ~= "action" then return end
    if value.id == "media.previous" then
        startMediaAction(model, "media.previous")
    elseif value.id == "media.toggle" then
        local pendingState = value.value and value.value.pendingState or nil
        startMediaAction(model, "media.toggle", pendingState)
    elseif value.id == "media.next" then
        startMediaAction(model, "media.next")
    elseif value.id == "launcher.open" then
        if not currentSession() then startLauncher(model) end
    elseif value.id == "launcher.configure" then
        chooseLauncher()
    elseif value.id == "launcher.clear" then
        if currentLauncher() then launcherBinding:clear() end
    end
end

local function menu(_context, _model, request)
    if request.id ~= "media.menu" then return nil end
    local launcher = currentLauncher()
    local items = {
        {
            id = "launcher.configure",
            label = l10n.tr("lua_widget.media_control.configure_launcher"),
            icon = fluent.settings,
            iconFont = "fluent",
        },
    }
    items[#items + 1] = { type = "separator" }
    items[#items + 1] = {
        id = "launcher.current",
        label = launcher and launcher.title or
            l10n.tr("lua_widget.media_control.not_set"),
        checked = true,
        enabled = false,
    }
    if launcher then
        items[#items + 1] = { type = "separator" }
        items[#items + 1] = {
            id = "launcher.clear",
            label = l10n.tr("lua_widget.media_control.clear_launcher"),
        }
    end
    return ui.menu(items)
end

local function migrateStorage(oldVersion, newVersion)
    if oldVersion >= 3 or newVersion < 3 then return end
    storage.remove("launcher")
    storage.remove("launcherSearch")
    storage.remove("launcherTitle")
end

return widget.define({
    name = l10n.tr("lua_widget.media_control.name"),
    useCustomStyle = true,
    followPersonalizationDefault = true,
    bottomBarHover = true,
    bg = 0x0F172A,
    border = 0xFFFFFF,
    alpha = 0.42,
    borderAlpha = 0.16,
    gradientEndA = 0.30,
    settings = settings,
    setup = setup,
    render = render,
    event = event,
    menu = menu,
    migrateStorage = migrateStorage,
})
