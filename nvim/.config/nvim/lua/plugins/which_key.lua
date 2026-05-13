return {
    "folke/which-key.nvim",
    enabled = false,
    event = "VeryLazy",
    config = function()
        local wk = require("which-key")
        wk.setup({})

        wk.register({
            s = { "<cmd>w<cr>", "Save File" },
        }, { prefix = "<leader>" })
    end,
}
