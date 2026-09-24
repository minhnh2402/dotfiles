-- ~/.config/nvim/lua/plugins/grug-far.lua
--
-- Search & replace across files, with a live, editable results buffer.
-- Keys inside the grug-far buffer (<localleader> is "\" by default):
--   <Tab> / <S-Tab>   jump between inputs (search, replace, files filter, flags, paths)
--   <Enter>           go to the result under the cursor
--   \r                replace ALL matches          \s   sync edited result lines back to files
--   \j / \k           replace next / previous match only
--   \q                send results to quickfix     \t   search history
--   \e                swap engine (ripgrep <-> ast-grep)
--   g?                show every key
--
-- Handy "Flags" input values:  -w (whole word)  -i (ignore case)  -F (literal, no regex)
-- Handy "Files Filter" values: *.{c,h}   !build/**   **/*.dts

local function escape_path(path)
  return (path:gsub(" ", "\\ "))
end

local C_FILES = "*.{c,h,cc,cpp,hpp}"

return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  opts = {
    -- Closed grug-far buffers are wiped instead of piling up in the buffer list
    transient = true,
  },
  keys = {
    -- Project wide. In visual mode the selection prefills the search.
    {
      "<leader>sr",
      function() require("grug-far").open() end,
      mode = { "n", "v" },
      desc = "Search & replace (project)",
    },
    -- Word under cursor, whole-word match: good for identifiers and macros
    {
      "<leader>sw",
      function()
        require("grug-far").open({
          prefills = { search = vim.fn.expand("<cword>"), flags = "-w" },
        })
      end,
      desc = "Search & replace word under cursor",
    },
    -- Current file only
    {
      "<leader>sf",
      function()
        require("grug-far").open({
          prefills = { paths = escape_path(vim.fn.expand("%:p")) },
        })
      end,
      desc = "Search & replace (current file)",
    },
    -- Directory of the current file
    {
      "<leader>sd",
      function()
        require("grug-far").open({
          prefills = { paths = escape_path(require("utils.pick").buf_dir()) },
        })
      end,
      desc = "Search & replace (current file's dir)",
    },
    -- Pick one or more directories with fzf first (<Tab> to multi-select)
    {
      "<leader>sD",
      function()
        require("utils.pick").pick_dir("Dirs for replace> ", function(dirs)
          local paths = vim.tbl_map(escape_path, dirs)
          require("grug-far").open({ prefills = { paths = table.concat(paths, " ") } })
        end)
      end,
      desc = "Search & replace (pick directories)",
    },
    -- C/C++ sources and headers only, word under cursor
    {
      "<leader>sc",
      function()
        require("grug-far").open({
          prefills = {
            search = vim.fn.expand("<cword>"),
            flags = "-w",
            filesFilter = C_FILES,
          },
        })
      end,
      desc = "Search & replace in C/C++ files",
    },
    -- Replace only inside the selected lines of the current buffer
    {
      "<leader>sv",
      function()
        require("grug-far").open({ visualSelectionUsage = "operate-within-range" })
      end,
      mode = "v",
      desc = "Search & replace within selection",
    },
  },
}
