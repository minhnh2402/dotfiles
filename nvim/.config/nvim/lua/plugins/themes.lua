-- Themes to cycle through with <leader>ct
local themes = {
  "tokyonight",
  "accent",           -- the one that's easy on my eyes
  "catppuccin-mocha", -- default (index 3)
  "rose-pine",
  "kanagawa",
  "gruvbox",
  "everforest",
}
local current = 3     -- startup theme = catppuccin-mocha
 
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,       -- load at startup, not on demand
    priority = 1000,    -- colorschemes should load before other UI plugins
    -- Force ALL other themes to finish loading before the config below runs:
    dependencies = {
      "folke/tokyonight.nvim",
      { "rose-pine/neovim", name = "rose-pine" },
      "rebelot/kanagawa.nvim",
      "ellisonleao/gruvbox.nvim",
      "sainnhe/everforest",
      "alligator/accent.vim",
    },
    config = function()
      -- Set the default theme
      vim.cmd.colorscheme(themes[current])
 
      -- <leader>ct: jump to the next theme, wrapping back to the first
      vim.keymap.set("n", "<leader>ct", function()
        current = current % #themes + 1   -- compact wrap-around instead of an if block
        vim.cmd.colorscheme(themes[current])
        vim.notify("Theme: " .. themes[current])
      end, { desc = "Cycle colorscheme" })
    end,
  },
}
