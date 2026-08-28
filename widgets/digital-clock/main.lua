-- digital_clock.lua - API v2 数字时钟
local showWeekday = true
local showDate = true
local showSeconds = true
local use12Hour = false
local textColor = 0xFFFFFF
local textOpacity = 1.0
local clockScale = 1.0
local descriptor

local settings = {
    presets = {
        {
            id = "transparent",
            label = l10n.tr("lua_widget.digital_clock.preset_transparent"),
            default = true,
            values = {
                bg = 0x000000,
                border = 0x000000,
                alpha = 0.0,
                borderAlpha = 0.0,
                gradientEndA = 0.0,
                textColor = 0xFFFFFF,
                textOpacity = 1.0,
            }
        }
    },
    fields = {
        { key = "showWeekday", label = l10n.tr("lua_widget.digital_clock.show_weekday"), type = "bool", default = true },
        { key = "showDate", label = l10n.tr("lua_widget.digital_clock.show_date"), type = "bool", default = true },
        { key = "showSeconds", label = l10n.tr("lua_widget.digital_clock.show_seconds"), type = "bool", default = true },
        { key = "use12Hour", label = l10n.tr("lua_widget.digital_clock.use_12_hour"), type = "bool", default = false },
        { key = "textColor", label = l10n.tr("lua_widget.common.text_color"), type = "color", default = 0xFFFFFF },
        { key = "textOpacity", label = l10n.tr("lua_widget.digital_clock.text_opacity"), type = "float", default = 1.0, min = 0.0, max = 1.0 },
        { key = "scale", label = l10n.tr("lua_widget.common.scale"), type = "float", default = 1.0, min = 0.5, max = 3.0 },
    }
}

local function setup()
    schedule.every("clock", 1000, { whenHidden = "pause" })
end

local function loadConfig()
    descriptor.bg = tonumber(storage.get("bg")) or descriptor.bg
    descriptor.border = descriptor.bg
    descriptor.alpha = tonumber(storage.get("alpha")) or descriptor.alpha
    descriptor.gradientEndA = tonumber(storage.get("gradientEndA")) or descriptor.gradientEndA
    showWeekday = storage.get("showWeekday") ~= "0"
    showDate = storage.get("showDate") ~= "0"
    showSeconds = storage.get("showSeconds") ~= "0"
    local stored12Hour = storage.get("use12Hour")
    use12Hour = stored12Hour == "1" or stored12Hour == "true"
    textColor = tonumber(storage.get("textColor")) or textColor
    textOpacity = math.max(0.0, math.min(1.0, tonumber(storage.get("textOpacity")) or textOpacity))
    clockScale = tonumber(storage.get("scale")) or clockScale
    local followPersonalization = storage.get("followPersonalization") == "1"
    if followPersonalization then
        local theme = widget.theme()
        if theme then
            textColor = (theme.contentTheme == 1) and 0x000000 or 0xFFFFFF
        end
    end
end

local function render()
    loadConfig()
    local t = time.parts(time.now())
    local w = layout.width()
    local h = layout.height()
    local timeStr
    local language = l10n.language()
    local twelveHour = use12Hour
    local displayHour = t.hour
    local period = ""
    if twelveHour then
        if t.hour < 12 then
            period = l10n.tr("lua_widget.digital_clock.am")
        else
            period = l10n.tr("lua_widget.digital_clock.pm")
        end
        displayHour = t.hour % 12
        if displayHour == 0 then displayHour = 12 end
    end
    if showSeconds then
        timeStr = string.format(twelveHour and "%d:%02d:%02d" or
            "%02d:%02d:%02d", displayHour, t.min, t.sec)
    else
        timeStr = string.format(twelveHour and "%d:%02d" or
            "%02d:%02d", displayHour, t.min)
    end
    if period ~= "" then timeStr = timeStr .. " " .. period end
    local padDate = language ~= "zh-CN" and language ~= "zh-TW" and
        language ~= "ja-JP" and language ~= "ko-KR"
    local dateStr = l10n.tr("lua_widget.digital_clock.date_format",
        tostring(t.year), padDate and string.format("%02d", t.month) or
            tostring(t.month), padDate and string.format("%02d", t.day) or
            tostring(t.day))
    local weekDays = {
        l10n.tr("lua_widget.digital_clock.sunday"),
        l10n.tr("lua_widget.digital_clock.monday"),
        l10n.tr("lua_widget.digital_clock.tuesday"),
        l10n.tr("lua_widget.digital_clock.wednesday"),
        l10n.tr("lua_widget.digital_clock.thursday"),
        l10n.tr("lua_widget.digital_clock.friday"),
        l10n.tr("lua_widget.digital_clock.saturday"),
    }
    local weekdayStr = l10n.tr("lua_widget.digital_clock.weekday_format",
        weekDays[t.wday or 1])

    local timeBaseSize = layout.fontCu(28)
    local secondaryBaseSize = layout.fontCu(9)
    local innerWidth = math.max(layout.cu(80), w - layout.cu(24))
    local gap = math.max(layout.cu(2), math.floor(h * 0.015))
    local lines = {
        { text = timeStr, size = timeBaseSize },
    }

    local secondaryParts = {}
    if showDate then table.insert(secondaryParts, dateStr) end
    if showWeekday then table.insert(secondaryParts, weekdayStr) end
    if #secondaryParts > 0 then
        table.insert(lines, {
            text = table.concat(secondaryParts, "  "),
            size = secondaryBaseSize,
        })
    end

    local widest = 1
    local totalBaseHeight = 0
    for i = 1, #lines do
        lines[i].probe = draw.measureText(
            lines[i].text, lines[i].size, 0, true)
        widest = math.max(widest, lines[i].probe.width)
        totalBaseHeight = totalBaseHeight + lines[i].probe.height
    end

    local innerHeight = math.max(layout.cu(40), h - layout.cu(24))
    local widthScale = innerWidth / math.max(1, widest)
    local heightScale =
        (innerHeight - gap * math.max(0, #lines - 1)) /
        math.max(1, totalBaseHeight)
    local scale = math.max(0.7, math.min(widthScale, heightScale)) *
        clockScale

    for i = 1, #lines do
        lines[i].size = lines[i].size * scale
        lines[i].metrics = draw.measureText(
            lines[i].text, lines[i].size, 0, true)
    end

    local blockH = 0
    for i = 1, #lines do
        blockH = blockH + lines[i].metrics.height
        if i > 1 then blockH = blockH + gap end
    end

    local y = (h - blockH) * 0.5
    local secondaryGap = math.max(layout.cu(1), math.floor(gap * 0.35))
    for i = 1, #lines do
        local line = lines[i]
        local drawMaxW = math.max(1, line.metrics.width + 2)
        draw.text((w - line.metrics.width) * 0.5, y, line.text,
            line.size, textColor, drawMaxW, true, false, 0, textOpacity)
        if i == 1 and #lines > 1 then
            y = y + line.metrics.height + secondaryGap
        else
            y = y + line.metrics.height + gap
        end
    end
end

descriptor = {
    useCustomStyle = true,
    bg = 0x000000,
    border = 0x000000,
    alpha = 0.0,
    gradientEndA = 0.0,
    settings = settings,
    setup = setup,
    render = render,
}

return widget.define(descriptor)
