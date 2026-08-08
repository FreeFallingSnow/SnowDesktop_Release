name = l10n.tr("lua_widget.system_monitor.name")
useCustomStyle = true
followPersonalizationDefault = true
showTitle = true
bottomBarHover = true

local fluent = {
    refresh = utf8.char(0xF13D),
    style = utf8.char(0xF592),
}

bg = 0x0F172A
border = 0xFFFFFF
alpha = 0.34
borderAlpha = 0.16
gradientEndA = 0.30
local prevCols = 0
local prevRows = 0
local scrollGen = 0
local subLineIdx = 0
local timerStarted = false

local wrappedLineCache = {}

local function getPalette()
    local theme = widget.theme()
    if theme and theme.contentTheme == 1 then
        return {
            cardBg     = 0xFFFFFF,
            cardBgA    = 0.14,
            cardBd     = 0x334155,
            cardBdA    = 0.12,
            cardText   = 0x1E293B,
            cardSub    = 0x334155,
            trackBg    = 0xE2E8F0,
            netDown    = 0x0D9488,
            netUp      = 0xEA580C,
            usageHigh  = 0xDC2626,
            usageMed   = 0xD97706,
            usageLow   = 0x059669,
        }
    end
    return {
        cardBg     = 0x000000,
        cardBgA    = 0.08,
        cardBd     = 0xFFFFFF,
        cardBdA    = 0.10,
        cardText   = 0xFFFFFF,
        cardSub    = 0xF1F5F9,
        trackBg    = 0x1E293B,
        netDown    = 0x67D5B5,
        netUp      = 0xFFB56B,
        usageHigh  = 0xFF6B6B,
        usageMed   = 0xFFD166,
        usageLow   = 0x4ECB71,
    }
end

settings = {
    fields = {
        { key = "show_cpu", label = l10n.tr("lua_widget.system_monitor.show_cpu"), type = "bool", default = true },
        { key = "show_memory", label = l10n.tr("lua_widget.system_monitor.show_memory"), type = "bool", default = true },
        { key = "show_gpu", label = l10n.tr("lua_widget.system_monitor.show_gpu"), type = "bool", default = true },
        { key = "show_vram", label = l10n.tr("lua_widget.system_monitor.show_vram"), type = "bool", default = true },
        { key = "show_network", label = l10n.tr("lua_widget.system_monitor.show_network"), type = "bool", default = true },
        { key = "show_battery", label = l10n.tr("lua_widget.system_monitor.show_battery"), type = "bool", default = true },
    }
}

local function clamp(v)
    return math.max(0, math.min(100, v or 0))
end

local function usageColor(pct, pal)
    if pct >= 90 then return pal.usageHigh
    elseif pct >= 70 then return pal.usageMed
    else return pal.usageLow end
end

local function formatRate(bytes)
    if bytes >= 1024 * 1024 then return string.format("%.1f MB/s", bytes / 1024 / 1024) end
    if bytes >= 1024 then return string.format("%.0f KB/s", bytes / 1024) end
    return tostring(math.floor(bytes or 0)) .. " B/s"
end

local function showCard(name)
    return storage.get("show_" .. name) ~= "0"
end

local function splitWrap(text, fontSize, maxWidth)
    local lines = {}
    local line = ""
    for _, codepoint in utf8.codes(text) do
        local char = utf8.char(codepoint)
        local candidate = line .. char
        local metrics = draw.measureText(candidate, fontSize, 0, false)
        if line ~= "" and metrics.width > maxWidth then
            lines[#lines + 1] = line
            line = char
        else
            line = candidate
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

local function drawCard(x, y, w, h, info, pal)
    draw.rect(x, y, w, h, pal.cardBg, layout.cu(10), pal.cardBgA)
    draw.strokeRect(x, y, w, h, pal.cardBd, layout.cu(10), layout.cu(1.0), pal.cardBdA)

    local ipad = layout.cu(8)
    local subFontSize = 12
    local subFont = layout.fontCu(subFontSize)
    draw.text(x + ipad, y + layout.cu(6), info.title, subFont, pal.cardSub, w - ipad * 2, true, true)

    if info.lines then
        local lineY = y + h * 0.32
        local lineH = math.max(layout.cu(12), math.floor(h * 0.11))
        for _, line in ipairs(info.lines) do
            draw.text(x + ipad, lineY, line.text, lineH, line.color or pal.cardText, w - ipad * 2, false, true)
            lineY = lineY + lineH + layout.cu(2)
        end
    else
        local valFont = math.max(layout.fontCu(15), math.min(layout.fontCu(24), math.floor(h * 0.18)))
        local vm = draw.measureText(info.value, valFont, 0, true)
        local vx = x + (w - vm.width) / 2
        local vy = y + h * 0.42 - vm.height / 2
        draw.text(vx, vy, info.value, valFont, pal.cardText, 0, true)
    end

    local barY = nil
    if info.progress then
        local barPad = layout.cu(8)
        local barH = layout.cu(4)
        barY = y + h - layout.cu(16)
        draw.rect(x + barPad, barY, w - barPad * 2, barH, pal.trackBg, layout.cu(2), 1.0)
        draw.rect(x + barPad, barY, (w - barPad * 2) * info.progress, barH, info.color, layout.cu(2), 1.0)
    end

    if info.sub then
        local subW = w - layout.cu(16)
        local subText = info.sub
        if info.rotateLines then
            local cacheKey = info.sub .. "\n" .. tostring(subW) .. "\n" .. tostring(subFontSize)
            local lines = wrappedLineCache[cacheKey]
            if not lines then
                lines = splitWrap(info.sub, subFont, subW)
                wrappedLineCache[cacheKey] = lines
            end
            if #lines > 1 then
                subText = lines[(subLineIdx % #lines) + 1]
            end
        end
        local subMetrics = draw.measureText(subText, subFont, subW, false)
        local subBottom = barY and (barY - layout.cu(4)) or (y + h - layout.cu(6))
        local subY = subBottom - subMetrics.height
        draw.text(x + layout.cu(8), subY, subText, subFont, pal.cardSub, subW, false, info.rotateLines == true)
    end
end

function render()
    widget.setTitle(l10n.tr("lua_widget.system_monitor.name"))

    local cpu = sys.cpu()
    local memory = sys.memory()
    local battery = sys.battery()
    local network = sys.network()
    local gpu = sys.gpu and sys.gpu() or nil
    local w = layout.width()
    local h = layout.height()
    local pal = getPalette()

    local cards = {}

    if showCard("cpu") then
        local pct = clamp(cpu.usagePercent)
        table.insert(cards, {
            title = "CPU",
            value = string.format("%.0f%%", pct),
            progress = pct / 100,
            color = usageColor(pct, pal),
            sub = cpu.name ~= "" and cpu.name or (cpu.logicalProcessors and cpu.logicalProcessors > 0 and
                l10n.tr("lua_widget.system_monitor.threads", cpu.logicalProcessors) or nil),
            rotateLines = true
        })
    end

    if showCard("memory") then
        local pct = clamp(memory.usagePercent)
        table.insert(cards, {
            title = l10n.tr("lua_widget.system_monitor.memory"),
            value = string.format("%.0f%%", pct),
            progress = pct / 100,
            color = usageColor(pct, pal),
            sub = memory.totalBytes and memory.totalBytes > 0 and
                string.format("%.1f / %.1f GB",
                    memory.usedBytes / 1024 / 1024 / 1024,
                    memory.totalBytes / 1024 / 1024 / 1024) or nil
        })
    end

    if showCard("gpu") and gpu and gpu.available then
        local pct = clamp(gpu.usagePercent)
        table.insert(cards, {
            title = "GPU",
            value = string.format("%.0f%%", pct),
            progress = pct / 100,
            color = usageColor(pct, pal),
            sub = gpu.name or "",
            rotateLines = true
        })
    end

    if showCard("vram") and gpu and gpu.available then
        local vramUsed = (gpu.vramUsedBytes or 0) / 1024 / 1024 / 1024
        local vramTotal = (gpu.vramTotalBytes or 1) / 1024 / 1024 / 1024
        local vramPct = vramTotal > 0 and math.min(100, vramUsed / vramTotal * 100) or 0
        table.insert(cards, {
            title = l10n.tr("lua_widget.system_monitor.vram"),
            value = string.format("%.0f%%", vramPct),
            progress = vramPct / 100,
            color = usageColor(vramPct, pal),
            sub = string.format("%.1f / %.1f GB", vramUsed, vramTotal)
        })
    end

    if showCard("network") then
        table.insert(cards, {
            title = l10n.tr("lua_widget.system_monitor.network"),
            color = pal.netDown,
            lines = {
                { text = "↓ " .. (network.connected and formatRate(network.downloadBytesPerSec) or "—"),
                  color = pal.netDown },
                { text = "↑ " .. (network.connected and formatRate(network.uploadBytesPerSec) or "—"),
                  color = pal.netUp },
            }
        })
    end

    if showCard("battery") and battery.available then
        local batPct = battery.percent or 100
        local status = nil
        if battery.charging then status = l10n.tr("lua_widget.system_monitor.charging")
        elseif battery.pluggedIn then status = l10n.tr("lua_widget.system_monitor.plugged_in")
        elseif batPct <= 20 then status = l10n.tr("lua_widget.system_monitor.low_battery")
        end
        table.insert(cards, {
            title = l10n.tr("lua_widget.system_monitor.battery"),
            value = string.format("%.0f%%", clamp(batPct)),
            progress = clamp(batPct) / 100,
            color = usageColor(100 - batPct, pal),
            sub = status
        })
    end

    local cols = math.max(1, layout.columns())
    local rows = #cards > 0 and math.ceil(#cards / cols) or 0
    if rows == 0 then
        draw.text(layout.cu(10), layout.cu(10), l10n.tr("lua_widget.system_monitor.no_visible_cards"),
            layout.fontCu(12), pal.cardSub)
        return
    end

    local inset = layout.cu(4)
    local hGap = layout.cu(4)
    local vGap = layout.cu(4)
    local availW = w - inset * 2
    local cardW = math.floor((availW - hGap * (cols - 1)) / cols)
    local cardH = layout.cellHeight()
    local fillCardH = math.floor((h - inset * 2 - vGap * (rows - 1)) / rows)
    if fillCardH > cardH then
        local maxCardH = cardH + math.max(1, math.floor(cardH * 0.10))
        cardH = math.min(fillCardH, maxCardH)
    end
    local totalH = math.ceil(inset + rows * cardH + (rows - 1) * vGap + inset)

    if cols ~= prevCols or rows ~= prevRows then
        scrollGen = scrollGen + 1
        prevCols = cols
        prevRows = rows
    end
    local scrollId = "s" .. tostring(scrollGen)
    local scroll = ui.scrollArea(scrollId, 0, 0, w, h, totalH)

    for i, card in ipairs(cards) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = inset + col * (cardW + hGap)
        local cy = inset + row * (cardH + vGap) - scroll

        if cy + cardH > 0 and cy < h then
            drawCard(cx, cy, cardW, cardH, card, pal)
        end
    end
end

function onVisible()
    if not timerStarted then
        widget.setTimer("subLine", 3000, true)
        timerStarted = true
    end
end

function onHidden()
    widget.cancelTimer("subLine")
    timerStarted = false
end

function onTimer(name)
    if name == "subLine" then
        subLineIdx = subLineIdx + 1
        widget.invalidate()
    end
end

function getContextMenu()
    return {
        { id = 1, label = l10n.tr("lua_widget.system_monitor.refresh"), icon = fluent.refresh, iconFont = "fluent" },
        { separator = true },
        { id = 2, label = l10n.tr("lua_widget.common.reset_style"), icon = fluent.style, iconFont = "fluent" },
    }
end

function onMenu(id)
    if id == 1 then
        widget.invalidate()
    elseif id == 2 then
        storage.set("bg", tostring(bg))
        storage.set("border", tostring(border))
        storage.set("alpha", tostring(alpha))
        storage.set("borderAlpha", tostring(borderAlpha))
        storage.set("gradientEndA", tostring(gradientEndA))
        storage.set("followPersonalization", "1")
        widget.invalidate()
    end
end
