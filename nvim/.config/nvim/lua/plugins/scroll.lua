-- ~/.config/nvim/lua/plugins/neoscroll.lua
-- NeoScroll configuration for lazy.nvim
-- Place this file in your lua/plugins/ directory (standard lazy.nvim layout)
 
return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy", -- lazy-load for faster startup
  config = function()
    local neoscroll = require("neoscroll")
 
    neoscroll.setup({
      -- Default keys that get the smooth-scroll effect
      mappings = {
        "<C-u>", "<C-d>",
        "<C-b>", "<C-f>",
        "<C-y>", "<C-e>",
        "zt", "zz", "zb",
      },
      hide_cursor = true,          -- hide cursor while scrolling
      stop_eof = true,             -- stop at end of file
      respect_scrolloff = false,   -- do not stop early because of scrolloff
      cursor_scrolls_alone = true, -- cursor keeps scrolling even if window can't
      duration_multiplier = 1.0,   -- time multiplier (higher = slower scroll)
      easing = "linear",           -- easing: linear/quadratic/cubic/quartic/quintic/circular/sine
      performance_mode = false,    -- enable for very large files to keep scrolling smooth
    })
 
    -- (Optional) Define keys with a custom duration per command.
    -- Uncomment if you want to control the duration of each key.
    -- local keymap = {
    --   ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 250 }) end,
    --   ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 250 }) end,
    --   ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 450 }) end,
    --   ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 450 }) end,
    --   ["<C-y>"] = function() neoscroll.scroll(-0.1, { move_cursor = false, duration = 100 }) end,
    --   ["<C-e>"] = function() neoscroll.scroll(0.1,  { move_cursor = false, duration = 100 }) end,
    --   ["zt"]    = function() neoscroll.zt({ half_win_duration = 250 }) end,
    --   ["zz"]    = function() neoscroll.zz({ half_win_duration = 250 }) end,
    --   ["zb"]    = function() neoscroll.zb({ half_win_duration = 250 }) end,
    -- }
    -- local modes = { "n", "v", "x" }
    -- for key, func in pairs(keymap) do
    --   vim.keymap.set(modes, key, func)
    -- end
  end,
}
