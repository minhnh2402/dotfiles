-- <leader>cE (was <leader>cpe, which made <leader>cp wait for a 3rd key)
vim.keymap.set("n", "<leader>cE", function()
    local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
    if #diagnostics > 0 then
        local message = diagnostics[1].message
        vim.fn.setreg("+", message)
        print("Copied diagnostic: " .. message)
    else
        print("No diagnostic at cursor")
    end
end, { silent = true, desc = "Copy diagnostic message" })

-- diagnostics
vim.keymap.set("n", "<leader>ne", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>pe", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
vim.keymap.set("n", "<leader>ce",  vim.diagnostic.open_float, { desc = "Show diagnostic" })

local pick = require("utils.pick")

vim.keymap.set("n", "<leader>cp", function() pick.copy(pick.rel_path()) end,
  { desc = "Copy file path (git-relative)" })
vim.keymap.set("n", "<leader>cd", function() pick.copy(pick.rel_path(true)) end,
  { desc = "Copy dir path (git-relative)" })
vim.keymap.set("n", "<leader>cP", function() pick.copy(vim.fn.expand("%:p")) end,
  { desc = "Copy absolute file path" })

