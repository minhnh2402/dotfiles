-- ~/.config/nvim/lua/plugins/fzf.lua
--
-- Useful keys inside any fzf-lua picker:
--   <C-v> / <C-s> / <C-t>  open in vsplit / split / tab
--   <Tab>                  multi-select, <Enter> sends the selection to quickfix
--   <C-q>                  select everything and send it to quickfix
--   <A-h> / <A-i>          toggle hidden files / files ignored by .gitignore
--   <F4>                   toggle preview
-- Live grep filter by file type: type  my_func -- *.c  or  my_func -- !*test*

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local fzf = require("fzf-lua")

    fzf.setup({
      winopts = {
        height = 0.85,
        width = 0.90,
        preview = { layout = "horizontal" },
      },
      fzf_colors = { true, bg = "-1", gutter = "-1" },
      keymap = {
        fzf = { ["ctrl-q"] = "select-all+accept" },
      },
    })

    local pick = require("utils.pick")
    local pick_dir, buf_dir = pick.pick_dir, pick.buf_dir

    local function map(mode, keys, fn, desc)
      vim.keymap.set(mode, keys, fn, { desc = desc })
    end

    -- Find files ---------------------------------------------------------
    map("n", "<leader>ff", fzf.files, "Find files (cwd)")
    map("n", "<leader>fF", function()
      fzf.files({ cwd = buf_dir() })
    end, "Find files (current file's dir)")
    map("n", "<leader>fd", function()
      pick_dir("Dir for files> ", function(dir)
        fzf.files({ cwd = dir, prompt = "Files (" .. dir .. ")> " })
      end)
    end, "Find files (pick a directory)")
    map("n", "<leader>pf", fzf.git_files, "Find git files")
    map("n", "<leader>fo", fzf.oldfiles, "Recent files")
    map("n", "<leader>fb", fzf.buffers, "Buffers")

    -- Grep ---------------------------------------------------------------
    map("n", "<leader>fg", fzf.live_grep, "Live grep (cwd)")
    map("n", "<leader>fG", function()
      fzf.live_grep({ cwd = buf_dir() })
    end, "Live grep (current file's dir)")
    map("n", "<leader>fD", function()
      pick_dir("Dir for grep> ", function(dir)
        fzf.live_grep({ cwd = dir, prompt = "Grep (" .. dir .. ")> " })
      end)
    end, "Live grep (pick a directory)")
    map("n", "<leader>fs", fzf.grep, "Grep for a string (prompt)")
    map("n", "<leader>fw", fzf.grep_cword, "Grep word under cursor")
    map("v", "<leader>fw", fzf.grep_visual, "Grep selection")
    map("n", "<leader>f/", fzf.lgrep_curbuf, "Grep in current buffer")

    -- Misc ---------------------------------------------------------------
    map("n", "<leader>fr", fzf.resume, "Resume last picker")
    map("n", "<leader>fq", fzf.quickfix, "Quickfix list")
    map("n", "<leader>fk", fzf.keymaps, "Keymaps")
    map("n", "<leader>fh", fzf.help_tags, "Help tags")
  end,
}
