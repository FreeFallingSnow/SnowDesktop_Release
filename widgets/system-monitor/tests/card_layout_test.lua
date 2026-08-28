local cardLayout = module.require("modules/card_layout.lua")

local function finalRowBottom(rows, visibleRows, cardHeight, gap, inset,
        viewport, offset)
    return cardLayout.rowTop(rows - 1, visibleRows, cardHeight, gap,
        inset, viewport) - offset + cardHeight
end

return {
    ["seven cards keep the same height as six cards"] = function()
        local viewport = 240
        local six = cardLayout.cardHeight(2, 2, 104, viewport, 4, 4)
        local seven = cardLayout.cardHeight(3, 2, 104, viewport, 4, 4)
        assert(six == 114)
        assert(seven == six)
    end,

    ["the first overflow row starts outside the viewport"] = function()
        local viewport = 240
        local height = cardLayout.cardHeight(3, 2, 104,
            viewport, 4, 4)
        assert(cardLayout.rowTop(2, 2, height, 4, 4, viewport) >=
            viewport)
    end,

    ["short overflow aligns the final row to the bottom inset"] = function()
        local viewport = 240
        local height = cardLayout.cardHeight(3, 2, 104,
            viewport, 4, 4)
        local content = cardLayout.contentHeight(3, 2, height, 4, 4,
            viewport)
        local offset = cardLayout.maximumOffset(content, viewport)
        assert(finalRowBottom(3, 2, height, 4, 4, viewport, offset) ==
            viewport - 4)
    end,

    ["content that fits does not create a scroll offset"] = function()
        local viewport = 360
        local content = cardLayout.contentHeight(2, 3, 104, 4, 4,
            viewport)
        assert(content == viewport)
        assert(cardLayout.maximumOffset(content, viewport) == 0)
    end,

    ["an empty grid uses the viewport height"] = function()
        assert(cardLayout.contentHeight(0, 2, 104, 4, 4, 240) == 240)
    end,
}
