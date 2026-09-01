-- File: lua/plugins/toggleterm.lua
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<leader>tf", mode = { "n", "t" }, desc = "Terminal: Floating" },
    { "<leader>th", mode = { "n", "t" }, desc = "Terminal: Horizontal" },
  },
  config = function()
    require("toggleterm").setup({
      direction = "horizontal",
      size = function(term)
        if term.direction == "horizontal" then
          return math.floor(vim.o.lines * 0.30)
        end
        return 20
      end,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      persist_mode = true,
      persist_size = true,
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "rounded",
        width = function() return math.floor(vim.o.columns * 0.90) end,
        height = function() return math.floor(vim.o.lines * 0.90) end,
        winblend = 0,
      },
    })
 
    local Terminal = require("toggleterm.terminal").Terminal
 
    -- Single shared terminal instance.
    -- Both <leader>tf and <leader>th drive THIS one terminal,
    -- so they always show the same shell/session.
    local term = Terminal:new({
      hidden = true, -- keep the process alive while hidden
    })
 
    -- Toggle helper: open in the requested direction, or hide it if it's
    -- already open in that same direction. If it's open in a different
    -- direction, just switch the layout (same shell, no new process).
    local function toggle_term(direction)
      if term:is_open() then
        if term.direction == direction then
          term:close()
        else
          term:close()
          term:open(nil, direction)
        end
      else
        term:open(nil, direction)
      end
    end
 
    vim.keymap.set({ "n", "t" }, "<leader>tf", function()
      toggle_term("float")
    end, { desc = "Terminal: Floating" })
 
    vim.keymap.set({ "n", "t" }, "<leader>th", function()
      toggle_term("horizontal")
    end, { desc = "Terminal: Horizontal" })
 
    -- Shared keymaps for ANY terminal buffer (toggleterm, :terminal, etc.)
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*",
      callback = function(args)
        local opts = { buffer = args.buf }
        -- Esc: leave terminal mode -> Normal mode
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
        -- <leader>q: close the current terminal (press in Normal mode)
        vim.keymap.set("n", "<leader>q", "<cmd>close<CR>",
          vim.tbl_extend("force", opts, { desc = "Terminal: quit" }))
      end,
    })
  end,
}
