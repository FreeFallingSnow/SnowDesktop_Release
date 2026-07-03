name = "系统状态"
useCustomStyle = true
showTitle = true
bottomBarHover = true

bg = 0x0F172A
border = 0xFFFFFF
alpha = 0.34
borderAlpha = 0.16
gradientEndA = 0.30
shadowAlpha = 0.12
shadowBlur = 16
shadowOffsetY = 5
highlightAlpha = 0.10
noiseAlpha = 0.014

local prevCols = 0
local prevRows = 0
local scrollGen = 0
local subLineIdx = 0
local timerStarted = false

local wrappedLineCache = {}

settings = {
    presets = {
        {
            id = "default",
            label = "默认卡片",
            default = true,
            values = {
                bg = 0x0F172A,
                border = 0xFFFFFF,
                alpha = 0.34,
                borderAlpha = 0.16,
                gradientEndA = 0.30,
                shadowAlpha = 0.12,
                shadowBlur = 16,
                shadowOffsetY = 5,
                highlightAlpha = 0.10,
                noiseAlpha = 0.014,
                followPersonalization = true,
                cardBgColor = 0x000000,
                cardBgAlpha = 0.08,
                cardBdColor = 0xFFFFFF,
                cardBdAlpha = 0.10,
                cardTextColor = 0xFFFFFF,
                cardSubColor = 0x94A3B8,
            }
        },
        {
            id = "clean",
            label = "轻透卡片",
            values = {
                bg = 0x111827,
                border = 0xFFFFFF,
                alpha = 0.24,
                borderAlpha = 0.14,
                gradientEndA = 0.26,
                shadowAlpha = 0.10,
                shadowBlur = 18,
                shadowOffsetY = 5,
                highlightAlpha = 0.12,
                noiseAlpha = 0.016,
                followPersonalization = false,
                cardBgColor = 0xFFFFFF,
                cardBgAlpha = 0.05,
                cardBdColor = 0xFFFFFF,
                cardBdAlpha = 0.08,
                cardTextColor = 0xFFFFFF,
                cardSubColor = 0xB8C4D6,
            }
        },
        {
            id = "solid",
            label = "深色卡片",
            values = {
                bg = 0x0B1020,
                border = 0xFFFFFF,
                alpha = 0.62,
                borderAlpha = 0.14,
                gradientEndA = 0.12,
                shadowAlpha = 0.10,
                shadowBlur = 14,
                shadowOffsetY = 4,
                highlightAlpha = 0.06,
                noiseAlpha = 0.0,
                followPersonalization = false,
                cardBgColor = 0x0F172A,
                cardBgAlpha = 0.24,
                cardBdColor = 0xFFFFFF,
                cardBdAlpha = 0.14,
                cardTextColor = 0xFFFFFF,
                cardSubColor = 0xA7B4C7,
            }
        }
    },
    fields = {
        { key = "show_cpu", label = "显示 CPU", type = "bool", default = true },
        { key = "show_memory", label = "显示内存", type = "bool", default = true },
        { key = "show_gpu", label = "显示 GPU", type = "bool", default = true },
        { key = "show_vram", label = "显示显存", type = "bool", default = true },
        { key = "show_network", label = "显示网络", type = "bool", default = true },
        { key = "show_battery", label = "显示电池", type = "bool", default = true },
        { key = "cardBgColor", label = "卡片背景色", type = "color", default = 0x000000 },
        { key = "cardBgAlpha", label = "卡片背景不透明度", type = "float", default = 0.08, min = 0, max = 1 },
        { key = "cardBdColor", label = "卡片边框色", type = "color", default = 0xFFFFFF },
        { key = "cardBdAlpha", label = "卡片边框不透明度", type = "float", default = 0.10, min = 0, max = 1 },
        { key = "cardTextColor", label = "卡片文字色", type = "color", default = 0xFFFFFF },
        { key = "cardSubColor", label = "卡片副文字色", type = "color", default = 0x94A3B8 },
    }
}

local function clamp(v)
    return math.max(0, math.min(100, v or 0))
end

local function usageColor(pct)
    if pct >= 90 then return 0xFF6B6B
    elseif pct >= 70 then return 0xFFD166
    else return 0x4ECB71 end
end

local function formatRate(bytes)
    if bytes >= 1024 * 1024 then return string.format("%.1f MB/s", bytes / 1024 / 1024) end
    if bytes >= 1024 then return string.format("%.0f KB/s", bytes / 1024) end
    return tostring(math.floor(bytes or 0)) .. " B/s"
end

local function showCard(name)
    return storage.get("show_" .. name) ~= "0"
end

local function readConfig()
    return {
        cardBgColor   = tonumber(storage.get("cardBgColor"))   or 0x000000,
        cardBgAlpha   = tonumber(storage.get("cardBgAlpha"))   or 0.08,
        cardBdColor   = tonumber(storage.get("cardBdColor"))   or 0xFFFFFF,
        cardBdAlpha   = tonumber(storage.get("cardBdAlpha"))   or 0.10,
        cardTextColor = tonumber(storage.get("cardTextColor")) or 0xFFFFFF,
        cardSubColor  = tonumber(storage.get("cardSubColor"))  or 0x94A3B8,
    }
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

local function drawCard(x, y, w, h, info, theme, cfg)
    draw.rect(x, y, w, h, cfg.cardBgColor, layout.cu(10), cfg.cardBgAlpha)
    draw.strokeRect(x, y, w, h, cfg.cardBdColor, layout.cu(10), layout.cu(1.0), cfg.cardBdAlpha)

    local ipad = layout.cu(8)
    draw.text(x + ipad, y + layout.cu(6), info.title, layout.fontCu(11), cfg.cardSubColor, w - ipad * 2, true, true)

    if info.lines then
        local lineY = y + h * 0.32
        local lineH = math.max(layout.cu(12), math.floor(h * 0.11))
        for _, line in ipairs(info.lines) do
            draw.text(x + ipad, lineY, line.text, lineH, line.color or cfg.cardTextColor, w - ipad * 2, false, true)
            lineY = lineY + lineH + layout.cu(2)
        end
    else
        local valFont = math.max(layout.fontCu(14), math.min(layout.fontCu(24), math.floor(h * 0.18)))
        local vm = draw.measureText(info.value, valFont, 0, true)
        local vx = x + (w - vm.width) / 2
        local vy = y + h * 0.42 - vm.height / 2
        draw.text(vx, vy, info.value, valFont, cfg.cardTextColor, 0, true)
    end

    if info.progress then
        local barPad = layout.cu(8)
        local barH = layout.cu(4)
        local barY = y + h - layout.cu(16)
        draw.rect(x + barPad, barY, w - barPad * 2, barH, 0x1E293B, layout.cu(2), 1.0)
        draw.rect(x + barPad, barY, (w - barPad * 2) * info.progress, barH, info.color, layout.cu(2), 1.0)
    end

    if info.sub then
        local subY = info.progress and (y + h - layout.cu(30)) or (y + h - layout.cu(16))
        if info.rotateLines then
            local subW = w - layout.cu(16)
            local cacheKey = info.sub .. "\n" .. tostring(subW)
            local lines = wrappedLineCache[cacheKey]
            if not lines then
                lines = splitWrap(info.sub, layout.fontCu(10), subW)
                wrappedLineCache[cacheKey] = lines
            end
            if #lines > 1 then
                local line = lines[(subLineIdx % #lines) + 1]
                draw.text(x + layout.cu(8), subY, line, layout.fontCu(10), cfg.cardSubColor, subW, false, true)
                return
            end
        end
        draw.text(x + layout.cu(8), subY, info.sub, layout.fontCu(10), cfg.cardSubColor, w - layout.cu(16), false, false)
    end
end

function render()
    widget.setTitle("系统状态")

    local cpu = sys.cpu()
    local memory = sys.memory()
    local battery = sys.battery()
    local network = sys.network()
    local gpu = sys.gpu and sys.gpu() or nil
    local w = layout.width()
    local h = layout.height()

    local cards = {}

    if showCard("cpu") then
        local pct = clamp(cpu.usagePercent)
        table.insert(cards, {
            title = "CPU",
            value = string.format("%.0f%%", pct),
            progress = pct / 100,
            color = usageColor(pct),
            sub = cpu.name ~= "" and cpu.name or (cpu.logicalProcessors and cpu.logicalProcessors > 0 and (cpu.logicalProcessors .. " 线程") or nil),
            rotateLines = true
        })
    end

    if showCard("memory") then
        local pct = clamp(memory.usagePercent)
        table.insert(cards, {
            title = "内存",
            value = string.format("%.0f%%", pct),
            progress = pct / 100,
            color = usageColor(pct),
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
            color = usageColor(pct),
            sub = gpu.name or "",
            rotateLines = true
        })
    end

    if showCard("vram") and gpu and gpu.available then
        local vramUsed = (gpu.vramUsedBytes or 0) / 1024 / 1024 / 1024
        local vramTotal = (gpu.vramTotalBytes or 1) / 1024 / 1024 / 1024
        local vramPct = vramTotal > 0 and math.min(100, vramUsed / vramTotal * 100) or 0
        table.insert(cards, {
            title = "显存",
            value = string.format("%.0f%%", vramPct),
            progress = vramPct / 100,
            color = usageColor(vramPct),
            sub = string.format("%.1f / %.1f GB", vramUsed, vramTotal)
        })
    end

    if showCard("network") then
        table.insert(cards, {
            title = "网络",
            color = 0x67D5B5,
            lines = {
                { text = "↓ " .. (network.connected and formatRate(network.downloadBytesPerSec) or "—"),
                  color = 0x67D5B5 },
                { text = "↑ " .. (network.connected and formatRate(network.uploadBytesPerSec) or "—"),
                  color = 0xFFB56B },
            }
        })
    end

    if showCard("battery") and battery.available then
        local batPct = battery.percent or 100
        local status = nil
        if battery.charging then status = "充电中"
        elseif battery.pluggedIn then status = "已接通"
        elseif batPct <= 20 then status = "电量低"
        end
        table.insert(cards, {
            title = "电池",
            value = string.format("%.0f%%", clamp(batPct)),
            progress = clamp(batPct) / 100,
            color = usageColor(100 - batPct),
            sub = status
        })
    end

    local cols = math.max(1, layout.columns())
    local rows = #cards > 0 and math.ceil(#cards / cols) or 0
    if rows == 0 then
        draw.text(layout.cu(10), layout.cu(10), "无可见卡片", layout.fontCu(12), 0x94A3B8)
        return
    end

    local inset = layout.cu(4)
    local hGap = layout.cu(4)
    local vGap = layout.cu(4)
    local availW = w - inset * 2
    local cardW = math.floor((availW - hGap * (cols - 1)) / cols)
    local cardH = layout.cellHeight()
    if rows * (cardH + vGap) - vGap + inset * 2 < h then
        cardH = math.floor((h - inset * 2 - vGap * (rows - 1)) / rows)
    end
    local totalH = math.ceil(inset + rows * cardH + (rows - 1) * vGap + inset)

    if cols ~= prevCols or rows ~= prevRows then
        scrollGen = scrollGen + 1
        prevCols = cols
        prevRows = rows
    end
    local scrollId = "s" .. tostring(scrollGen)
    local scroll = ui.scrollArea(scrollId, 0, 0, w, h, totalH)

    local theme = widget.theme()
    if not theme or not theme.bg then
        theme = { bg = 0x151A21, border = 0xFFFFFF, alpha = 0.36, gradientEndA = 0.65 }
    end
    local cfg = readConfig()

    for i, card in ipairs(cards) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = inset + col * (cardW + hGap)
        local cy = inset + row * (cardH + vGap) - scroll

        if cy + cardH > 0 and cy < h then
            drawCard(cx, cy, cardW, cardH, card, theme, cfg)
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
        { id = 1, label = "刷新数据", icon = "" },
        { separator = true },
        { id = 2, label = "恢复默认样式", icon = "" },
    }
end

function onMenu(id)
    if id == 1 then
        widget.invalidate()
    elseif id == 2 then
        for _, k in ipairs({ "cardBgColor", "cardBgAlpha", "cardBdColor", "cardBdAlpha", "cardTextColor", "cardSubColor" }) do
            storage.remove(k)
        end
        widget.invalidate()
    end
end
