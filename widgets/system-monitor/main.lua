-- system-monitor/main.lua - API v2 system data subscriptions
local subscriptions = {}
local cardLayout = module.require("modules/card_layout.lua")

local fluent = {
    refresh = utf8.char(0xF13D),
    style = utf8.char(0xF592),
}

local style = {
    bg = 0x0F172A,
    border = 0xFFFFFF,
    alpha = 0.34,
    borderAlpha = 0.16,
    gradientEndA = 0.30,
}

local settings = {
    fields = {
        { key = "show_cpu", label = l10n.tr("lua_widget.system_monitor.show_cpu"), type = "bool", default = true },
        { key = "show_memory", label = l10n.tr("lua_widget.system_monitor.show_memory"), type = "bool", default = true },
        { key = "show_gpu", label = l10n.tr("lua_widget.system_monitor.show_gpu"), type = "bool", default = true },
        { key = "show_vram", label = l10n.tr("lua_widget.system_monitor.show_vram"), type = "bool", default = true },
        { key = "show_network", label = l10n.tr("lua_widget.system_monitor.show_network"), type = "bool", default = true },
        { key = "show_battery", label = l10n.tr("lua_widget.system_monitor.show_battery"), type = "bool", default = true },
        { key = "show_storage", label = l10n.tr("lua_widget.system_monitor.show_storage"), type = "bool", default = true },
        { key = "show_disk_io", label = l10n.tr("lua_widget.system_monitor.show_disk_io"), type = "bool", default = false },
        { key = "show_uptime", label = l10n.tr("lua_widget.system_monitor.show_uptime"), type = "bool", default = false },
    },
}

local function getPalette()
    local theme = widget.theme()
    if theme and theme.contentTheme == 1 then
        return {
            cardBg = 0xFFFFFF,
            cardBgA = 0.14,
            cardBd = 0x334155,
            cardBdA = 0.12,
            cardText = 0x1E293B,
            cardSub = 0x334155,
            trackBg = 0xE2E8F0,
            netDown = 0x0D9488,
            netUp = 0xEA580C,
            usageHigh = 0xDC2626,
            usageMed = 0xD97706,
            usageLow = 0x059669,
        }
    end
    return {
        cardBg = 0x000000,
        cardBgA = 0.08,
        cardBd = 0xFFFFFF,
        cardBdA = 0.10,
        cardText = 0xFFFFFF,
        cardSub = 0xF1F5F9,
        trackBg = 0x1E293B,
        netDown = 0x67D5B5,
        netUp = 0xFFB56B,
        usageHigh = 0xFF6B6B,
        usageMed = 0xFFD166,
        usageLow = 0x4ECB71,
    }
end

local function clamp(value)
    return math.max(0, math.min(100, value or 0))
end

local function usageColor(percent, palette)
    if percent >= 90 then return palette.usageHigh end
    if percent >= 70 then return palette.usageMed end
    return palette.usageLow
end

local function formatBytes(bytes)
    return l10n.formatBytes(math.max(0, bytes or 0), {
        base = 1024,
        maximumFractionDigits = 1,
    })
end

local function formatRate(bytes)
    return formatBytes(bytes) .. "/s"
end

local function formatPercent(value)
    return l10n.formatNumber(clamp(value), {
        maximumFractionDigits = 0,
    }) .. "%"
end

local function formatUptime(milliseconds)
    local dayMs = 24 * 60 * 60 * 1000
    if milliseconds >= dayMs then
        local days = math.floor(milliseconds / dayMs)
        local hours = math.floor((milliseconds % dayMs) / (60 * 60 * 1000))
        return l10n.tr("lua_widget.system_monitor.days_hours",
            days, hours)
    end
    return l10n.formatDuration(milliseconds, { style = "short" })
end

local function showCard(name)
    local value = storage.get("show_" .. name)
    if type(value) == "boolean" then return value end
    return value ~= "0" and value ~= "false"
end

local function subscriptionValue(handle, permissionGranted)
    if permissionGranted == false then return nil, "permission" end
    if not handle then return nil, "unavailable" end
    local snapshot = handle:value()
    if snapshot.available then
        return snapshot.value, snapshot.stale and "stale" or nil
    end
    if snapshot.warmingUp then return nil, "waiting" end
    if snapshot.error == "permissionDenied" then
        return nil, "permission"
    end
    if snapshot.error == "notPresent" then return nil, "notPresent" end
    return nil, "unavailable"
end

local function statusText(status)
    if not status then return nil end
    local keys = {
        waiting = "lua_widget.system_monitor.waiting",
        stale = "lua_widget.system_monitor.stale",
        unavailable = "lua_widget.system_monitor.unavailable",
        permission = "lua_widget.system_monitor.permission_required",
        notPresent = "lua_widget.system_monitor.not_present",
    }
    return l10n.tr(keys[status] or keys.unavailable)
end

local function detailsWithStatus(details, status)
    local values = {}
    if details and details ~= "" then values[#values + 1] = details end
    local statusValue = statusText(status)
    if statusValue then values[#values + 1] = statusValue end
    if #values == 0 then return nil end
    return l10n.formatList(values)
end

local function summarizeGpu(value)
    if not value or not value.adapters or #value.adapters == 0 then
        return nil
    end
    local summary = {
        usagePercent = 0,
        dedicatedMemoryBytes = 0,
        dedicatedUsedBytes = 0,
        sharedMemoryBytes = 0,
        sharedUsedBytes = 0,
        names = {},
    }
    for _, adapter in ipairs(value.adapters) do
        summary.usagePercent = math.max(summary.usagePercent,
            adapter.usagePercent or 0)
        local dedicatedTotal = math.max(0,
            adapter.dedicatedMemoryBytes or 0)
        summary.dedicatedMemoryBytes = math.max(
            summary.dedicatedMemoryBytes, dedicatedTotal)
        summary.dedicatedUsedBytes = summary.dedicatedUsedBytes +
            math.max(0, adapter.dedicatedUsedBytes or 0)
        summary.sharedMemoryBytes = summary.sharedMemoryBytes +
            math.max(0, adapter.sharedMemoryBytes or 0)
        summary.sharedUsedBytes = summary.sharedUsedBytes +
            math.max(0, adapter.sharedUsedBytes or 0)
        if adapter.name and adapter.name ~= "" then
            summary.names[#summary.names + 1] = adapter.name
        end
    end
    summary.name = table.concat(summary.names, " · ")
    return summary
end

local function summarizeStorage(value)
    if not value or not value.volumes then return nil end
    local result = { totalBytes = 0, usedBytes = 0, names = {} }
    for _, volume in ipairs(value.volumes) do
        if volume.capacityAvailable and (volume.capacityBytes or 0) > 0 then
            local total = math.max(0, volume.capacityBytes)
            local free = math.max(0, math.min(total,
                volume.freeBytes or 0))
            result.totalBytes = result.totalBytes + total
            result.usedBytes = result.usedBytes + total - free
            if volume.displayName and volume.displayName ~= "" then
                result.names[#result.names + 1] = volume.displayName
            end
        end
    end
    if result.totalBytes <= 0 then return nil end
    return result
end

local function fitFontSize(text, fontSize, minimum, maxWidth, bold)
    local fitted = fontSize
    local metrics = draw.measureText(text, fitted, 0, bold == true)
    while fitted > minimum and metrics.width > maxWidth do
        fitted = fitted - 1
        metrics = draw.measureText(text, fitted, 0, bold == true)
    end
    return fitted, metrics
end

local function drawMarqueeText(key, x, y, text, fontSize, color,
        viewportWidth)
    local metrics = draw.measureText(text, fontSize, 0, false)
    return draw.marqueeText({
        key = key,
        x = x,
        y = y,
        width = viewportWidth,
        height = metrics.height,
        text = text,
        size = fontSize,
        color = color,
        speed = 24,
        gap = layout.cu(24),
    })
end

local function drawCard(x, y, width, height, info, palette)
    draw.rect(x, y, width, height, palette.cardBg,
        layout.cu(10), palette.cardBgA)
    draw.strokeRect(x, y, width, height, palette.cardBd,
        layout.cu(10), layout.cu(1.0), palette.cardBdA)

    local inset = layout.cu(8)
    local subFont = layout.fontCu(12)
    draw.text(x + inset, y + layout.cu(6), info.title, subFont,
        palette.cardSub, width - inset * 2, true, true)

    if info.lines then
        local lineY = y + height * 0.32
        local lineHeight = math.max(layout.cu(12),
            math.floor(height * 0.11))
        for _, line in ipairs(info.lines) do
            local lineFont = fitFontSize(line.text, lineHeight,
                layout.fontCu(9), width - inset * 2, false)
            draw.text(x + inset, lineY, line.text, lineFont,
                line.color or palette.cardText,
                width - inset * 2, false, true)
            lineY = lineY + lineHeight + layout.cu(2)
        end
    else
        local valueFont = math.max(layout.fontCu(15),
            math.min(layout.fontCu(24), math.floor(height * 0.18)))
        local metrics = nil
        valueFont, metrics = fitFontSize(info.value, valueFont,
            layout.fontCu(10), width - inset * 2, true)
        draw.text(x + (width - metrics.width) / 2,
            y + height * 0.42 - metrics.height / 2,
            info.value, valueFont, palette.cardText, 0, true)
    end

    local barY = nil
    if info.progress ~= nil then
        local barInset = layout.cu(8)
        local barHeight = layout.cu(4)
        barY = y + height - layout.cu(16)
        draw.rect(x + barInset, barY, width - barInset * 2,
            barHeight, palette.trackBg, layout.cu(2), 1.0)
        draw.rect(x + barInset, barY,
            (width - barInset * 2) * info.progress,
            barHeight, info.color, layout.cu(2), 1.0)
    end

    if info.sub then
        local subWidth = width - layout.cu(16)
        local metrics = draw.measureText(info.sub, subFont, 0, false)
        local subBottom = barY and (barY - layout.cu(4)) or
            (y + height - layout.cu(6))
        drawMarqueeText(info.id, x + layout.cu(8),
            subBottom - metrics.height, info.sub, subFont,
            palette.cardSub, subWidth)
    end
end

local function setup()
    subscriptions.cpu = data.subscribe("system.cpu", {
        maxAgeMs = 1000,
        whenHidden = "throttle",
    })
    subscriptions.memory = data.subscribe("system.memory", {
        maxAgeMs = 1000,
        whenHidden = "throttle",
    })
    subscriptions.gpu = data.subscribe("system.gpu", {
        maxAgeMs = 1000,
        whenHidden = "pause",
    })
    if widget.hasFeature("data.system.power") and
        widget.hasPermission("system.power.read") then
        subscriptions.power = data.subscribe("system.power", {
            maxAgeMs = 2000,
            whenHidden = "throttle",
        })
    end
    if widget.hasFeature("data.system.network.traffic") and
        widget.hasPermission("system.network.read") then
        subscriptions.network = data.subscribe("system.network.traffic", {
            maxAgeMs = 1000,
            whenHidden = "throttle",
        })
    end
    if widget.hasFeature("data.system.network.status") and
        widget.hasPermission("system.network.read") then
        subscriptions.networkStatus = data.subscribe(
            "system.network.status", {
                maxAgeMs = 2000,
                whenHidden = "throttle",
            })
    end
    if widget.hasFeature("data.system.storage.volumes") and
        widget.hasPermission("system.storage.read") then
        subscriptions.storage = data.subscribe(
            "system.storage.volumes", {
                maxAgeMs = 5000,
                whenHidden = "throttle",
            })
    end
    if widget.hasFeature("data.system.storage.io") and
        widget.hasPermission("system.storage.read") then
        subscriptions.diskIo = data.subscribe("system.storage.io", {
            maxAgeMs = 1000,
            whenHidden = "pause",
        })
    end
    return {
        previousColumns = 0,
        previousRows = 0,
    }
end

local function buildCards()
    local palette = getPalette()
    local cpu, cpuState = subscriptionValue(subscriptions.cpu)
    local memory, memoryState = subscriptionValue(subscriptions.memory)
    local gpuValue, gpuState = subscriptionValue(subscriptions.gpu)
    local gpu = summarizeGpu(gpuValue)
    if not gpu and not gpuState then gpuState = "notPresent" end
    local powerPermission = widget.hasPermission("system.power.read")
    local networkPermission = widget.hasPermission("system.network.read")
    local storagePermission = widget.hasPermission("system.storage.read")
    local power, powerState = subscriptionValue(subscriptions.power,
        powerPermission)
    local network, networkState = subscriptionValue(subscriptions.network,
        networkPermission)
    local networkStatus, networkStatusState = subscriptionValue(
        subscriptions.networkStatus, networkPermission)
    local storageValue, storageState = subscriptionValue(
        subscriptions.storage, storagePermission)
    local storageSummary = summarizeStorage(storageValue)
    if not storageSummary and not storageState then
        storageState = "notPresent"
    end
    local diskIo, diskIoState = subscriptionValue(subscriptions.diskIo,
        storagePermission)
    local cards = {}

    if showCard("cpu") then
        local percent = cpu and clamp(cpu.usagePercent) or nil
        cards[#cards + 1] = {
            id = "cpu",
            title = "CPU",
            value = percent and formatPercent(percent) or "—",
            progress = percent and percent / 100 or nil,
            color = usageColor(percent or 0, palette),
            sub = detailsWithStatus(
                cpu and cpu.name ~= "" and cpu.name or
                (cpu and cpu.logicalProcessors and cpu.logicalProcessors > 0 and
                    l10n.tr("lua_widget.system_monitor.threads",
                        cpu.logicalProcessors) or nil), cpuState),
        }
    end

    if showCard("memory") then
        local percent = memory and clamp(memory.usagePercent) or nil
        cards[#cards + 1] = {
            id = "memory",
            title = l10n.tr("lua_widget.system_monitor.memory"),
            value = percent and formatPercent(percent) or "—",
            progress = percent and percent / 100 or nil,
            color = usageColor(percent or 0, palette),
            sub = detailsWithStatus(memory and memory.totalBytes and
                memory.totalBytes > 0 and
                    (formatBytes(memory.usedBytes) .. " / " ..
                        formatBytes(memory.totalBytes)) or nil,
                memoryState),
        }
    end

    if showCard("gpu") then
        local percent = gpu and clamp(gpu.usagePercent) or nil
        cards[#cards + 1] = {
            id = "gpu",
            title = "GPU",
            value = percent and formatPercent(percent) or "—",
            progress = percent and percent / 100 or nil,
            color = usageColor(percent or 0, palette),
            sub = detailsWithStatus(gpu and gpu.name ~= "" and
                gpu.name or nil, gpuState),
        }
    end

    if showCard("vram") then
        local total = gpu and gpu.dedicatedMemoryBytes or 0
        local used = gpu and gpu.dedicatedUsedBytes or 0
        local percent = total > 0 and clamp(used / total * 100) or nil
        cards[#cards + 1] = {
            id = "vram",
            title = l10n.tr("lua_widget.system_monitor.vram"),
            value = percent and formatPercent(percent) or "—",
            progress = percent and percent / 100 or nil,
            color = usageColor(percent or 0, palette),
            sub = detailsWithStatus(total > 0 and
                (formatBytes(used) .. " / " .. formatBytes(total)) or nil,
                gpuState),
        }
    end

    if showCard("network") then
        local connectivity = networkStatus and
            networkStatus.connectivity or nil
        local networkDetails = nil
        if connectivity == "internet" then
            networkDetails = l10n.tr("lua_widget.system_monitor.online")
        elseif connectivity == "local" then
            networkDetails = l10n.tr(
                "lua_widget.system_monitor.local_only")
        elseif connectivity == "none" then
            networkDetails = l10n.tr("lua_widget.system_monitor.offline")
        end
        if networkStatus and networkStatus.costKnown and
            networkStatus.metered then
            networkDetails = networkDetails and l10n.formatList({
                networkDetails,
                l10n.tr("lua_widget.system_monitor.metered"),
            }) or l10n.tr("lua_widget.system_monitor.metered")
        end
        local effectiveNetworkState = networkState or networkStatusState
        cards[#cards + 1] = {
            id = "network",
            title = l10n.tr("lua_widget.system_monitor.network"),
            lines = {
                {
                    text = "↓ " .. (network and network.connected and
                        formatRate(network.downloadBytesPerSecond) or "—"),
                    color = palette.netDown,
                },
                {
                    text = "↑ " .. (network and network.connected and
                        formatRate(network.uploadBytesPerSecond) or "—"),
                    color = palette.netUp,
                },
            },
            sub = detailsWithStatus(networkDetails,
                effectiveNetworkState),
        }
    end

    if showCard("battery") then
        local percent = power and clamp(power.batteryPercent) or nil
        local status = nil
        if power and power.charging then
            status = l10n.tr("lua_widget.system_monitor.charging")
        elseif power and power.acPower then
            status = l10n.tr("lua_widget.system_monitor.plugged_in")
        elseif percent and percent <= 20 then
            status = l10n.tr("lua_widget.system_monitor.low_battery")
        end
        if power and not power.acPower and
            (power.estimatedRemainingSeconds or 0) > 0 then
            local remaining = l10n.tr(
                "lua_widget.system_monitor.remaining",
                l10n.formatDuration(
                    power.estimatedRemainingSeconds * 1000,
                    { style = "short" }))
            status = status and l10n.formatList({ status, remaining }) or
                remaining
        end
        cards[#cards + 1] = {
            id = "battery",
            title = l10n.tr("lua_widget.system_monitor.battery"),
            value = percent and formatPercent(percent) or "—",
            progress = percent and percent / 100 or nil,
            color = usageColor(100 - (percent or 100), palette),
            sub = detailsWithStatus(status, powerState),
        }
    end

    if showCard("storage") then
        local percent = storageSummary and clamp(
            storageSummary.usedBytes / storageSummary.totalBytes * 100) or
            nil
        local details = storageSummary and
            (formatBytes(storageSummary.usedBytes) .. " / " ..
                formatBytes(storageSummary.totalBytes)) or nil
        if storageSummary and #storageSummary.names > 0 then
            details = l10n.formatList({
                details,
                l10n.formatList(storageSummary.names),
            })
        end
        cards[#cards + 1] = {
            id = "storage",
            title = l10n.tr("lua_widget.system_monitor.storage"),
            value = percent and formatPercent(percent) or "—",
            progress = percent and percent / 100 or nil,
            color = usageColor(percent or 0, palette),
            sub = detailsWithStatus(details, storageState),
        }
    end

    if showCard("disk_io") then
        local percent = diskIo and clamp(diskIo.busyPercent) or nil
        cards[#cards + 1] = {
            id = "disk_io",
            title = l10n.tr("lua_widget.system_monitor.disk_io"),
            lines = {
                {
                    text = "↓ " .. (diskIo and
                        formatRate(diskIo.readBytesPerSecond) or "—"),
                    color = palette.netDown,
                },
                {
                    text = "↑ " .. (diskIo and
                        formatRate(diskIo.writeBytesPerSecond) or "—"),
                    color = palette.netUp,
                },
            },
            progress = percent and percent / 100 or nil,
            color = usageColor(percent or 0, palette),
            sub = detailsWithStatus(percent and formatPercent(percent) or
                nil, diskIoState),
        }
    end

    if showCard("uptime") then
        local uptime = system.uptime()
        cards[#cards + 1] = {
            id = "uptime",
            title = l10n.tr("lua_widget.system_monitor.uptime"),
            value = formatUptime(uptime.milliseconds),
            color = palette.usageLow,
        }
    end
    return cards, palette
end

local function render(_context, model)
    local width = layout.contentWidth()
    local height = layout.contentHeight()
    local viewportHeight = math.max(1, height)
    local cards, palette = buildCards()
    local columns = math.max(1, layout.columns())
    local visibleRows = math.max(1, layout.rows())
    local rows = #cards > 0 and math.ceil(#cards / columns) or 0
    local inset = layout.cu(4)
    local horizontalGap = layout.cu(4)
    local verticalGap = layout.cu(4)
    local availableWidth = width - inset * 2
    local cardWidth = math.floor((availableWidth -
        horizontalGap * (columns - 1)) / columns)
    local cardHeight = cardLayout.cardHeight(rows, visibleRows,
        layout.cellHeight(), viewportHeight, verticalGap, inset)
    -- The trailing inset makes the native maximum scroll offset place the
    -- final row at the same inset from the viewport bottom.
    local contentHeight = cardLayout.contentHeight(
        rows, visibleRows, cardHeight, verticalGap, inset,
        viewportHeight)

    local resetScroll = columns ~= model.previousColumns or
        rows ~= model.previousRows
    model.previousColumns = columns
    model.previousRows = rows
    local scroll = interaction.scroll({
        key = "system.cards",
        shape = {
            type = "rect",
            x = 0,
            y = 0,
            width = width,
            height = viewportHeight,
        },
        contentHeight = contentHeight,
    })
    if resetScroll then
        scroll.offset = interaction.setScrollOffset("system.cards", 0)
    end
    draw.pushClip(0, 0, width, viewportHeight)
    if rows == 0 then
        draw.text(layout.cu(10), layout.cu(10),
            l10n.tr("lua_widget.system_monitor.no_visible_cards"),
            layout.fontCu(12), palette.cardSub)
    else
        for index, card in ipairs(cards) do
            local column = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            local x = inset + column * (cardWidth + horizontalGap)
            local y = cardLayout.rowTop(row, visibleRows, cardHeight,
                verticalGap, inset, viewportHeight) - scroll.offset
            if y + cardHeight > 0 and y < viewportHeight then
                drawCard(x, y, cardWidth, cardHeight,
                    card, palette)
            end
        end
    end
    draw.popClip()

    interaction.region({
        key = "system.surface",
        shape = {
            type = "rect",
            x = 0,
            y = 0,
            width = width,
            height = viewportHeight,
        },
        events = {
            contextMenu = { id = "system.menu", scope = "component" },
        },
        accessibility = {
            role = "group",
            label = l10n.tr("lua_widget.system_monitor.name"),
        },
    })
end

local function event(_context, _model, value)
    if value.kind ~= "action" then return end
    if value.id == "system.refresh" then
        widget.invalidate()
    elseif value.id == "system.resetStyle" then
        storage.set("bg", tostring(style.bg))
        storage.set("border", tostring(style.border))
        storage.set("alpha", tostring(style.alpha))
        storage.set("borderAlpha", tostring(style.borderAlpha))
        storage.set("gradientEndA", tostring(style.gradientEndA))
        storage.set("followPersonalization", "1")
    end
end

local function menu(_context, _model, request)
    if request.id ~= "system.menu" then return nil end
    return ui.menu({
        {
            id = "system.refresh",
            label = l10n.tr("lua_widget.system_monitor.refresh"),
            icon = fluent.refresh,
            iconFont = "fluent",
        },
        { type = "separator" },
        {
            id = "system.resetStyle",
            label = l10n.tr("lua_widget.common.reset_style"),
            icon = fluent.style,
            iconFont = "fluent",
        },
    })
end

local function dispose(_context, _model)
    for _, handle in pairs(subscriptions) do
        handle:unsubscribe()
    end
    subscriptions = {}
end

return widget.define({
    name = l10n.tr("lua_widget.system_monitor.name"),
    useCustomStyle = true,
    followPersonalizationDefault = true,
    showTitle = true,
    bottomBarHover = true,
    bg = style.bg,
    border = style.border,
    alpha = style.alpha,
    borderAlpha = style.borderAlpha,
    gradientEndA = style.gradientEndA,
    settings = settings,
    setup = setup,
    render = render,
    event = event,
    menu = menu,
    dispose = dispose,
})
