return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" }, -- lazy-load only when opening a real file
  opts = {
    -- Signs shown in the gutter for each change type
    signs = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
      untracked    = { text = "▎" },
    },
    current_line_blame = false, -- toggle inline blame with a keymap below

    -- on_attach runs per buffer; the right place to define git keymaps
    on_attach = function(bufnr)
      local gs = require("gitsigns")

      -- Small helper to set buffer-local mappings with a description
      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
      end

      -- === Hunk navigation ===
      -- ]c / [c : jump to next / previous change (gitgutter-style)
      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true }) -- fall back to native diff nav
        else
          gs.nav_hunk("next")
        end
      end, "Next Hunk")

      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev Hunk")

      -- === Staging / resetting (prefix <leader>h = "hunk") ===
      map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
      map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
      -- Visual mode: stage/reset only the selected lines
      map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
      map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selection")
      map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
      map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
      map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")

      -- === Preview / diff ===
      map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>hd", gs.diffthis, "Diff against index")
      map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff against last commit")

      -- === Blame ===
      map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line (full)")
      map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle inline blame")

      -- === Text object: select the current hunk (works with d/c/y etc.) ===
      -- e.g. "dih" deletes inside the current hunk
      map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
    end,
  },
}
