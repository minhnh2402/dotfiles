-- ~/.config/nvim/lua/config/lsp.lua

---------------------------------------------------------------------------
-- 1. blink.cmp completion capabilities (must run BEFORE vim.lsp.enable)
---------------------------------------------------------------------------
local ok, blink = pcall(require, "blink.cmp")
if ok then
  vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
end

---------------------------------------------------------------------------
-- 2. Enable servers (configs live in ~/.config/nvim/lsp/*.lua)
---------------------------------------------------------------------------
vim.lsp.enable({ "clangd" })

---------------------------------------------------------------------------
-- 3. Keymaps and features, set when a server attaches to a buffer
---------------------------------------------------------------------------
local attach_group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true })

-- Format on save is OFF by default: reformatting whole vendor files
-- (e.g. in rcar-env) creates huge diffs. Toggle it with :FormatToggle.
vim.g.autoformat = false

vim.api.nvim_create_autocmd("LspAttach", {
  group = attach_group,
  callback = function(args)
    local buf = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local fzf = require("fzf-lua")

    -- nowait: don't wait for timeoutlen, since Neovim 0.11 ships grr/grn/gra/gri
    local function map(mode, keys, fn, desc)
      vim.keymap.set(mode, keys, fn, { buffer = buf, nowait = true, desc = desc })
    end

    -- Go TO a symbol -----------------------------------------------------
    map("n", "gd", fzf.lsp_definitions, "Go to definition")
    map("n", "gD", fzf.lsp_declarations, "Go to declaration (header)")
    map("n", "gy", fzf.lsp_typedefs, "Go to type definition")
    map("n", "gi", fzf.lsp_implementations, "Go to implementation")

    -- Find WHERE a symbol is used ---------------------------------------
    map("n", "gr", function()
      fzf.lsp_references({ includeDeclaration = false, ignore_current_line = true })
    end, "References")
    map("n", "<leader>lc", fzf.lsp_incoming_calls, "Incoming calls (who calls this)")
    map("n", "<leader>lC", fzf.lsp_outgoing_calls, "Outgoing calls (what this calls)")
    map("n", "<leader>lf", fzf.lsp_finder, "Finder (defs + refs + impls)")
    map("n", "<leader>lw", fzf.grep_cword, "Grep word under cursor (fallback)")

    -- Symbol -------------------------------------------------------------
    map("n", "<leader>ls", fzf.lsp_document_symbols, "Document symbols")
    map("n", "<leader>lS", fzf.lsp_live_workspace_symbols, "Workspace symbols")
    map("n", "<leader>lt", fzf.lsp_type_super, "Type hierarchy: base classes (C++)")
    map("n", "<leader>lT", fzf.lsp_type_sub, "Type hierarchy: derived classes (C++)")

    -- Info and editing --------------------------------------------------
    map("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover documentation")
    map("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
    map({ "n", "v" }, "<leader>la", fzf.lsp_code_actions, "Code action")
    map({ "n", "v" }, "<leader>lF", function()
      vim.lsp.buf.format({ async = true })
    end, "Format (buffer or selection)")

    -- Diagnostics --------------------------------------------------------
    map("n", "<leader>ld", fzf.lsp_document_diagnostics, "Document diagnostics")
    map("n", "<leader>lD", fzf.lsp_workspace_diagnostics, "Workspace diagnostics")

    -- Inlay hints: show parameter names and deduced types inline
    if client and client:supports_method("textDocument/inlayHint") then
      map("n", "<leader>lH", function()
        local on = vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
        vim.lsp.inlay_hint.enable(not on, { bufnr = buf })
      end, "Toggle inlay hints")
    end

    -- Format on save (only runs when vim.g.autoformat is true)
    if client and client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("user_lsp_format_" .. buf, { clear = true }),
        buffer = buf,
        callback = function()
          if vim.g.autoformat then
            vim.lsp.buf.format({ bufnr = buf, id = client.id, timeout_ms = 2000 })
          end
        end,
      })
    end

    -- Highlight every use of the symbol under the cursor (needs a low updatetime)
    if client and client:supports_method("textDocument/documentHighlight") then
      local hl = vim.api.nvim_create_augroup("user_lsp_highlight_" .. buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = hl, buffer = buf, callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = hl, buffer = buf, callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

-- Clean up highlight autocmds when a server detaches (avoids errors after a restart)
vim.api.nvim_create_autocmd("LspDetach", {
  group = attach_group,
  callback = function(args)
    pcall(vim.api.nvim_del_augroup_by_name, "user_lsp_highlight_" .. args.buf)
    pcall(vim.api.nvim_del_augroup_by_name, "user_lsp_format_" .. args.buf)
    pcall(vim.lsp.util.buf_clear_references, args.buf)
  end,
})

---------------------------------------------------------------------------
-- 4. Diagnostics display
---------------------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  signs = true,
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  float = { border = "rounded", source = true },
})

---------------------------------------------------------------------------
-- 5. Helper commands (nvim-lspconfig is not installed, so define them here)
---------------------------------------------------------------------------
vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", { desc = "Show LSP status" })

vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd.tabnew(vim.lsp.log.get_filename())
end, { desc = "Open the LSP log file" })

vim.api.nvim_create_user_command("LspRestart", function()
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    table.insert(names, c.name)
    c:stop()
  end
  if #names == 0 then
    return vim.notify("No LSP client attached to this buffer", vim.log.levels.WARN)
  end
  vim.defer_fn(function() vim.lsp.enable(names) end, 1000)
end, { desc = "Restart LSP clients of the current buffer" })

vim.api.nvim_create_user_command("FormatToggle", function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify("Format on save: " .. (vim.g.autoformat and "ON" or "OFF"))
end, { desc = "Toggle format on save" })
