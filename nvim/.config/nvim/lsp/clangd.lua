-- ~/.config/nvim/lsp/clangd.lua
--
-- The location of compile_commands.json is set in a .clangd file at the
-- project root:
--   CompileFlags:
--     CompilationDatabase: build
-- We avoid --compile-commands-dir=build here because that path is resolved
-- relative to where Neovim was started, so it breaks when you open Neovim
-- from a subdirectory.

-- clangd has its own request to jump between a header and its source file.
-- nvim-lspconfig is not installed, so we implement the command ourselves.
local function switch_source_header(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })[1]
  if not client then
    return vim.notify("clangd is not running", vim.log.levels.WARN)
  end
  local params = vim.lsp.util.make_text_document_params(bufnr)
  client:request("textDocument/switchSourceHeader", params, function(err, result)
    if err then
      return vim.notify(err.message or tostring(err), vim.log.levels.ERROR)
    end
    if not result then
      return vim.notify("No matching header/source file found", vim.log.levels.INFO)
    end
    vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(result)))
  end, bufnr)
end

return {
  cmd = {
    "clangd",
    "--background-index",         -- index the whole project for symbols / references
    "--clang-tidy",
    "--header-insertion=never",   -- don't auto-insert #include when accepting a completion
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm",      -- style used when no .clang-format file is found
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  -- .clangd comes first so that nested repos with their own .git
  -- (as in rcar-env) are not picked as the root by mistake.
  root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" },
  on_attach = function(_, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "ClangdSwitchSourceHeader", function()
      switch_source_header(bufnr)
    end, { desc = "Switch between header and source" })
    vim.keymap.set("n", "<leader>lh", function()
      switch_source_header(bufnr)
    end, { buffer = bufnr, desc = "Switch header <-> source" })
  end,
}
