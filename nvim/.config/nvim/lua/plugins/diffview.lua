return {
  "sindrets/diffview.nvim",
  cmd = { -- lazy-load only when one of these is called
    "DiffviewOpen",
    "DiffviewFileHistory",
    "DiffviewClose",
  },
  keys = {
    -- Browse the commit history of the WHOLE repo
    { "<leader>gv", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history (all commits)" },
    -- Browse the commit history of ONLY the current file
    { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
    -- Diff working tree against last commit
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff working tree" },
  },
  opts = {
    enhanced_diff_hl = true, -- better colors for changed regions
  },
}
