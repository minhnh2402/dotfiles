-- ~/.config/nvim/lua/plugins/virtcolumn.lua
return {
    "xiyaowong/virtcolumn.nvim",
    event = { "BufReadPre", "BufNewFile" },
    init = function()
        -- character used to draw the line (default is "▕")
        vim.g.virtcolumn_char = " ┆"
        vim.g.virtcolumn_priority = 10
    end,
    config = function()
        -- change the line color (optional, remove to use the default)
        vim.api.nvim_set_hl(0, "VirtColumn", { fg = "white" })
    end,
}
