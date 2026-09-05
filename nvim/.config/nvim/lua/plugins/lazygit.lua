return {
  "kdheepak/lazygit.nvim",
  lazy = true, -- don't load at startup
  cmd = {       -- load only when one of these commands is first called
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  dependencies = {
    "nvim-lua/plenary.nvim", -- optional: nicer floating window border
  },
  -- Defining the key in `keys` lets lazy load the plugin on first press
  keys = {
    { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit (repo root)" },
    { "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file's repo)" },
  },
}
