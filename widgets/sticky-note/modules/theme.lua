local noteTheme = {}

noteTheme.presetTextColors = {
    classic = 0x000000,
    white = 0x000000,
    pink = 0x000000,
    blue = 0x000000,
    green = 0x000000,
    purple = 0x000000,
    dark = 0xFFFFFF,
}

function noteTheme.resolveTextColor(preset, followsPersonalization,
        contentTheme)
    if not followsPersonalization then
        if not preset or preset == "" then preset = "classic" end
        local presetColor = noteTheme.presetTextColors[preset]
        if presetColor then return presetColor end
    end
    return contentTheme == 1 and 0x000000 or 0xFFFFFF
end

return noteTheme
