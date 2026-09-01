-- Tell every language server that this client supports the richer
-- completion capabilities that blink.cmp provides (snippets, extra
-- completion item fields, etc.). Must run BEFORE vim.lsp.enable().
-- Safe version: won't error if blink hasn't loaded yet
local ok, blink = pcall(require, "blink.cmp")vim.lsp.config("*", {  capabilities = ok and blink.get_lsp_capabilities() or {},})
 
-- Turn on the servers (definitions live in ~/.config/nvim/lsp/*.lua)
vim.lsp.enable({ "clangd"})
 
-- Buffer-local keymaps, set when a server attaches to a buffer
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    local map = function(keys, fn) vim.keymap.set("n", keys, fn, { buffer = buf }) end
 
    map("gd", vim.lsp.buf.definition)      -- go to definition
    map("gD", vim.lsp.buf.declaration)     -- go to declaration
    map("K",  vim.lsp.buf.hover)           -- show documentation on hover
    map("gr", vim.lsp.buf.references)       -- list references
    map("<leader>rn", vim.lsp.buf.rename)   -- rename symbol
    map("<leader>ca", vim.lsp.buf.code_action)
    map("<leader>f", function() vim.lsp.buf.format({ async = true }) end)
  end,
})
 
-- Diagnostic display (underlines, virtual text, signs)
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  severity_sort = true,
})
