-- analog_clock.lua - API v2 指针时钟
local settings = {
    presets = {
        {
            id = "transparent",
            label = l10n.tr("lua_widget.analog_clock.preset_transparent"),
            default = true,
            values = {
                bg = 0x000000,
                border = 0x000000,
                alpha = 0,
                borderAlpha = 0,
                gradientEndA = 0,
            }
        }
    },
    fields = {
        { key = "showSecondHand", label = l10n.tr("lua_widget.analog_clock.show_second_hand"), type = "bool", default = true },
        { key = "showNumbers", label = l10n.tr("lua_widget.analog_clock.show_numbers"), type = "bool", default = true },
    }
}

local function setup()
    schedule.every("clock", 1000, { whenHidden = "pause" })
end

local function render()
    local t = time.parts(time.now())
    local showSecondHand = storage.get("showSecondHand") ~= "0"
    local showNumbers = storage.get("showNumbers") ~= "0"
    local w = layout.width()
    local h = layout.height()
    local cx = w / 2
    local cy = h / 2
    local size = math.min(w, h)
    local minSpan = math.max(1, math.min(layout.columns(), layout.rows()))

    local function scu(value)
        return layout.cu(value * minSpan)
    end

    local r = size / 2 - scu(10)
    if r < scu(24) then r = size / 2 - scu(5) end
    if r <= 0 then return end

    local function su(value, minimum)
        return math.max(minimum or 1, scu(value))
    end

    local outerStroke = su(1.4)
    local innerStroke = su(0.8)
    local hourTickLen = su(9)
    local minuteTickLen = su(4)
    local hourTickWidth = su(1.6)
    local quarterTickWidth = su(2.2)
    local minuteTickWidth = su(0.75)
    local hourHandWidth = su(4.0, 2)
    local minuteHandWidth = su(2.8, 2)
    local secondHandWidth = su(1.1)

    local function point(angle, radius)
        return cx + math.cos(angle) * radius, cy + math.sin(angle) * radius
    end

    local function hand(angle, front, back, width, color, alpha)
        local x1, y1 = point(angle + math.pi, back)
        local x2, y2 = point(angle, front)
        draw.line(x1, y1, x2, y2, width, color, alpha or 1.0)
    end

    -- 多层表盘，用填充圆模拟描边，避免依赖额外 stroke API。
    draw.circle(cx, cy + su(1.5), r + outerStroke + su(1.2), 0x000000, 0.10)
    draw.circle(cx, cy, r + outerStroke, 0xD7DEE8, 0.95)
    draw.circle(cx, cy, r, 0xFFFFFF, 1.0)
    local innerR = math.max(su(8), r - su(5) - innerStroke)
    draw.circle(cx, cy, innerR + innerStroke, 0xF6F8FB, 0.72)
    draw.circle(cx, cy, innerR, 0xFFFFFF, 1.0)

    -- 刻度：主刻度更稳，副刻度更轻。
    for i = 0, 59 do
        local a = i * math.pi / 30 - math.pi / 2
        local major = i % 5 == 0
        local quarter = i % 15 == 0
        local len = major and hourTickLen or minuteTickLen
        local thick = quarter and quarterTickWidth or (major and hourTickWidth or minuteTickWidth)
        local col = major and 0x1F2937 or 0xAEB7C5
        local alphaTick = major and 0.86 or 0.46
        local x1, y1 = point(a, r - len)
        local x2, y2 = point(a, r - su(2))
        draw.line(x1, y1, x2, y2, thick, col, alphaTick)
    end

    if showNumbers then
        local numberFont = math.max(8, layout.fontCu(10.5 * minSpan))
        local numberRadius = math.max(su(14), r - su(16))
        for hour = 1, 12 do
            local a = hour * math.pi / 6 - math.pi / 2
            local label = tostring(hour)
            local metrics = draw.measureText(label, numberFont, 0, true)
            local tx, ty = point(a, numberRadius)
            draw.text(tx - metrics.width / 2, ty - metrics.height / 2,
                label, numberFont, 0x1F2937, 0, true, true)
        end
    end

    local ha = ((t.hour % 12) + t.min / 60) * math.pi / 6 - math.pi / 2
    local ma = (t.min + t.sec / 60) * math.pi / 30 - math.pi / 2

    -- 指针和中心帽按跨格缩放单位计算，跨多格时比例保持一致。
    hand(ha, r * 0.45, su(7), hourHandWidth + su(1.0), 0xFFFFFF, 0.45)
    hand(ma, r * 0.65, su(8), minuteHandWidth + su(0.8), 0xFFFFFF, 0.35)
    hand(ha, r * 0.43, su(6), hourHandWidth, 0x111827, 0.96)
    hand(ma, r * 0.63, su(7), minuteHandWidth, 0x374151, 0.96)
    if showSecondHand then
        local sa = t.sec * math.pi / 30 - math.pi / 2
        hand(sa, r * 0.76, su(13), secondHandWidth, 0xEF4444, 0.96)
    end

    draw.circle(cx, cy, su(6.4), 0xFFFFFF, 1.0)
    draw.circle(cx, cy, su(4.8), 0x111827, 0.98)
    if showSecondHand then
        draw.circle(cx, cy, su(2.1), 0xEF4444, 1.0)
    end
end

return widget.define({
    useCustomStyle = true,
    bg = 0x000000,
    border = 0x000000,
    alpha = 0,
    gradientEndA = 0,
    settings = settings,
    setup = setup,
    render = render,
})
