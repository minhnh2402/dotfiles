vim.keymap.set("n", "<leader>cpe", function()
    local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
    if #diagnostics > 0 then
        local message = diagnostics[1].message
        vim.fn.setreg("+", message)
        print("Copied diagnostic: " .. message)
    else
        print("No diagnostic at cursor")
    end
end, { noremap = true, silent = true })

-- diagnostics
vim.keymap.set("n", "<leader>ne", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>pe", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
vim.keymap.set("n", "<leader>ce",  vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- copy absolute file path
vim.keymap.set("n", "<leader>cp", function()
  local filepath = vim.fn.expand("%:p")
  vim.fn.setreg("+", filepath)
  print("Copied: " .. filepath)
end, { desc = "Copy absolute file path" })

