-- ~/.config/nvim/lua/plugins/which-key.lua
-- Override the which-key config that LazyVim ships with.
-- Do NOT reinstall the plugin here -- just tweak its opts.
 
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- Popup style: "classic" | "modern" | "helix"
    preset = "modern",
 
    -- IMPORTANT: delay (ms) before the popup shows up.
    -- In which-key v3 this is what controls responsiveness,
    -- NOT 'timeoutlen' anymore. Keep it small so it pops fast.
    delay = 200,
 
    -- Popup window tweaks
    win = {
      border = "rounded",  -- "none" | "single" | "double" | "rounded"
      padding = { 1, 2 },  -- vertical, horizontal
    },
 
    -- Grid layout
    layout = {
      spacing = 6,
    },
 
    -- Name the prefix groups (shows readable labels)
    spec = {
      { "<leader>f", group = "file/find" },
      { "<leader>g", group = "git" },
      { "<leader>s", group = "search" },
      { "<leader>b", group = "buffer" },
      { "<C-w>",     group = "window/split" },  -- hint for Ctrl-w
    },
  },
 
  keys = {
    -- Show keymaps local to the current buffer
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
