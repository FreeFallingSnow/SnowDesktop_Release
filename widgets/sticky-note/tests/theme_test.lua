local noteTheme = module.require("modules/theme.lua")

return {
    ["light presets use black text"] = function()
        for _, preset in ipairs({
            "classic", "white", "pink", "blue", "green", "purple",
        }) do
            assert(noteTheme.presetTextColors[preset] == 0x000000)
            assert(noteTheme.resolveTextColor(preset, false, 0) ==
                0x000000)
        end
    end,

    ["dark preset uses white text"] = function()
        assert(noteTheme.presetTextColors.dark == 0xFFFFFF)
        assert(noteTheme.resolveTextColor("dark", false, 1) == 0xFFFFFF)
    end,

    ["missing preset falls back to classic black text"] = function()
        assert(noteTheme.resolveTextColor(nil, false, 0) == 0x000000)
        assert(noteTheme.resolveTextColor("", false, 0) == 0x000000)
    end,

    ["global personalization overrides component presets"] = function()
        assert(noteTheme.resolveTextColor("dark", true, 1) == 0x000000)
        assert(noteTheme.resolveTextColor("classic", true, 0) == 0xFFFFFF)
        assert(noteTheme.resolveTextColor("__global_dark", false, 0) ==
            0xFFFFFF)
    end,
}
