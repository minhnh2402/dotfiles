vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")

vim.g.mapleader = " "

-- View clearly
vim.cmd("set number")
vim.cmd("set relativenumber")
vim.cmd("set cursorline")
vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "white" })
vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#ead84e" })

-- color themes same as terminal
vim.opt.termguicolors = true
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  end,
})

-- To copy from vim to clipboard
vim.opt.clipboard = "unnamedplus"

-- Highlight search result
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- paste over highlight word
-- vim.keymap.set("x", "<leader>p", '"_dP')
vim.opt.colorcolumn = "120"
vim.opt.wrap = true
vim.opt.linebreak = true

-- Remove swap file
vim.opt.swapfile = false

-- Reload files changed outside of Neovim automatically
vim.opt.autoread = true

-- autoread only re-checks on certain events; nudge it on focus/buffer enter
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  pattern = "*",
  command = "checktime", -- check if the file changed on disk and reload if so
})
