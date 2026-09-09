-- ~/.config/nvim/lua/plugins/dsa.lua
--
-- DSA practice setup for LazyVim:
--   1. A "dsa" snippet (defined in Lua) that expands the full C++ template.
--   2. An <F5> keymap (C++ buffers only) to compile with sanitizers and run.
--
-- NOTE: the blink.cmp side (snippet preset + Tab jump keys) lives in your
-- existing blink config file, not here. This file only owns LuaSnip + keymap.

-- Compile-and-run keymap, scoped to C++ buffers via a FileType autocmd.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function(ev)
    vim.keymap.set("n", "<F5>", function()
      vim.cmd("write") -- save first
      local file = vim.fn.expand("%") -- e.g. trees/two_sum.cpp
      local out = vim.fn.expand("%:r") -- e.g. trees/two_sum (no extension)
      -- -Wall -Wextra: extra warnings
      -- -fsanitize=address,undefined: catch out-of-bounds / UB at runtime
      -- -g: keep debug info so sanitizer reports point at the right line
      local cmd = string.format(
        "g++ -std=c++17 -Wall -Wextra -fsanitize=address,undefined -g %s -o %s && ./%s",
        vim.fn.shellescape(file),
        vim.fn.shellescape(out),
        vim.fn.shellescape(out)
      )
      -- Run in a terminal split so colored sanitizer output and stdin both work.
      vim.cmd("botright split | resize 15 | terminal " .. cmd)
      vim.cmd("startinsert") -- drop straight into the terminal
    end, { buffer = ev.buf, desc = "Compile & run C++ (sanitizers)" })
  end,
})

return {
  -- LuaSnip: the snippet engine. We declare it (with the jsregexp build step)
  -- and register the DSA snippet in its opts function. blink.cmp is told to
  -- use it via `snippets.preset = "luasnip"` in your blink config file.
  {
    "L3MON4D3/LuaSnip",
    lazy = true,
    build = (not jit.os:find("Windows"))
        and "echo 'jsregexp is optional; fine if this fails'; make install_jsregexp"
      or nil,
    opts = function(_, opts)
      opts.history = true
      opts.delete_check_events = "TextChanged"

      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node

      -- Available in C++ files. Type "dsa" then accept from the blink menu.
      -- $1 = write the solution, $2 = write test cases, $0 = final cursor.
      ls.add_snippets("cpp", {
        s("dsa", {
          t({
            "#include <bits/stdc++.h>",
            "using namespace std;",
            "",
            "class Solution {",
            "public:",
            "    ",
          }),
          i(1),
          t({
            "",
            "};",
            "",
            "int main() {",
            "    Solution sol;",
            "    ",
          }),
          i(2),
          t({
            "",
            "    return 0;",
            "}",
          }),
          i(0),
        }),
      })

      return opts
    end,
  },
}
