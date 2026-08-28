-- Copy this directory as a complete SnowDesktop API v2 widget package.

local function readConfig()
    return {
        color = tonumber(storage.get("color")) or 0xFFFFFF,
    }
end

local function render(context, _model)
    local config = readConfig()
    local width = layout.contentWidth()
    local height = layout.contentHeight()
    local padding = math.max(layout.cu(8), math.min(
        layout.cu(12), layout.vmin(4)))
    local fontSize = context.sizeClass == "small"
        and layout.fontCu(14) or layout.fontCu(16)
    local message = storage.get("message")
        or l10n.tr("lua_widget.template.preview_message")

    draw.text(padding, padding, message, fontSize, config.color,
        width - padding * 2, false, false,
        height - padding * 2, 1.0)
end

return widget.define({
    name = l10n.tr("lua_widget.template.name"),
    useCustomStyle = true,
    bg = 0x18202A,
    border = 0x5F7691,
    alpha = 0.92,
    borderAlpha = 0.80,
    gradientEndA = 0.0,
    glassEnabled = false,
    settings = {
        presets = {
            {
                id = "default",
                label = l10n.tr("lua_widget.template.preset"),
                default = true,
                values = {
                    bg = 0x18202A,
                    border = 0x5F7691,
                    alpha = 0.92,
                    borderAlpha = 0.80,
                    gradientEndA = 0.0,
                    glassEnabled = false,
                },
            },
        },
        fields = {
            {
                key = "color",
                label = l10n.tr("lua_widget.common.text_color"),
                type = "color",
                default = 0xFFFFFF,
            },
        },
    },
    render = render,
})
