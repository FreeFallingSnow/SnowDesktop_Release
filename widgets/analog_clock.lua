-- analog_clock.lua - 指针时钟
name = "指针时钟"
useCustomStyle = true

bg = 0x000000
border = 0x000000
alpha = 0
gradientEndA = 0

function render()
    local t = sys.getTime()
    local w = layout.width()
    local h = layout.height()
    local cx = w / 2
    local cy = h / 2
    local r = math.min(w, h) / 2 - layout.cu(8)

    -- 白色不透明表盘
    draw.circle(cx, cy, r, 0xFFFFFF, 1.0)

    -- 中心点
    draw.circle(cx, cy, layout.cu(3), 0x333333)

    -- 刻度
    for i = 0, 59 do
        local a = i * math.pi / 30 - math.pi / 2
        local len = (i % 5 == 0) and layout.cu(6) or layout.cu(3)
        local thick = (i % 5 == 0) and layout.cu(2.5) or layout.cu(0.8)
        local col = (i % 5 == 0) and 0x333333 or 0xBBBBBB
        local x1 = cx + math.cos(a) * (r - len)
        local y1 = cy + math.sin(a) * (r - len)
        local x2 = cx + math.cos(a) * r
        local y2 = cy + math.sin(a) * r
        draw.line(x1, y1, x2, y2, thick, col, 0.9)
    end

    -- 时针
    local ha = ((t.hour % 12) + t.min / 60) * math.pi / 6 - math.pi / 2
    draw.line(cx, cy, cx + math.cos(ha) * r * 0.4, cy + math.sin(ha) * r * 0.4, layout.cu(3.5), 0x222222)

    -- 分针
    local ma = (t.min + t.sec / 60) * math.pi / 30 - math.pi / 2
    draw.line(cx, cy, cx + math.cos(ma) * r * 0.6, cy + math.sin(ma) * r * 0.6, layout.cu(2.5), 0x444444)

    -- 秒针
    local sa = t.sec * math.pi / 30 - math.pi / 2
    draw.line(cx, cy, cx + math.cos(sa) * r * 0.78, cy + math.sin(sa) * r * 0.78, layout.cu(1), 0xFF3333)
end
