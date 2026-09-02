-- diagnostics
vim.keymap.set("n", "<leader>ne", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>pe", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set("n", "<leader>ce",  vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- copy absolute file path
vim.keymap.set("n", "<leader>cp", function()
  local filepath = vim.fn.expand("%:p")
  vim.fn.setreg("+", filepath)
  print("Copied: " .. filepath)
end, { desc = "Copy absolute file path" })

