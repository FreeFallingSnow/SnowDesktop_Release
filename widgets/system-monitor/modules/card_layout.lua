local cardLayout = {}

local function overflowShift(rows, visibleRows, cardHeight, gap, inset,
        viewportHeight)
    if rows <= visibleRows then return 0 end
    local firstOverflowTop = inset + visibleRows * (cardHeight + gap)
    return math.max(0, viewportHeight - firstOverflowTop)
end

function cardLayout.cardHeight(rows, visibleRows, baseHeight,
        viewportHeight, gap, inset)
    rows = math.max(0, math.floor(rows or 0))
    visibleRows = math.max(1, math.floor(visibleRows or 1))
    baseHeight = math.max(1, math.floor(baseHeight or 1))
    if rows == 0 then return baseHeight end
    local fittedRows = math.min(rows, visibleRows)
    local fillHeight = math.floor((viewportHeight - inset * 2 -
        gap * (fittedRows - 1)) / fittedRows)
    if fillHeight <= baseHeight then return baseHeight end
    return math.min(fillHeight,
        baseHeight + math.max(1, math.floor(baseHeight * 0.10)))
end

function cardLayout.rowTop(row, visibleRows, cardHeight, gap, inset,
        viewportHeight)
    local top = inset + row * (cardHeight + gap)
    if row < visibleRows then return top end
    return top + math.max(0, viewportHeight -
        (inset + visibleRows * (cardHeight + gap)))
end

function cardLayout.contentHeight(rows, visibleRows, cardHeight, gap,
        inset, viewportHeight)
    rows = math.max(0, math.floor(rows or 0))
    visibleRows = math.max(1, math.floor(visibleRows or 1))
    viewportHeight = math.max(1, math.ceil(viewportHeight or 1))
    if rows == 0 then return viewportHeight end
    local measured = math.ceil(inset + rows * cardHeight +
        (rows - 1) * gap + inset + overflowShift(rows, visibleRows,
            cardHeight, gap, inset, viewportHeight))
    return math.max(viewportHeight, measured)
end

function cardLayout.maximumOffset(contentHeight, viewportHeight)
    return math.max(0, contentHeight - viewportHeight)
end

return cardLayout
