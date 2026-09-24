-- ~/.config/nvim/lua/utils/pick.lua
-- Small helpers shared by fzf-lua and grug-far keymaps.

local M = {}

-- Directory of the current buffer (falls back to cwd for unnamed buffers).
function M.buf_dir()
  local name = vim.api.nvim_buf_get_name(0)
  return name ~= "" and vim.fn.fnamemodify(name, ":p:h") or vim.uv.cwd()
end

-- Pick a directory with fzf-lua, then call `on_pick(dir)`.
-- Uses fd (or fdfind on Ubuntu) when available, falls back to find.
function M.pick_dir(prompt, on_pick)
  local cmd
  if vim.fn.executable("fd") == 1 then
    cmd = "fd --type d --exclude .git"
  elseif vim.fn.executable("fdfind") == 1 then
    cmd = "fdfind --type d --exclude .git"
  else
    cmd = "find . -mindepth 1 -type d -not -path '*/.git*' -printf '%P\\n'"
  end
  require("fzf-lua").fzf_exec(cmd, {
    prompt = prompt,
    cwd = vim.uv.cwd(),
    preview = "ls -p --color=always {}",
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          vim.schedule(function() on_pick(selected[1]) end)
        end
      end,
    },
  })
end

return M
