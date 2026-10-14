-- ~/.config/nvim/lua/utils/pick.lua
-- Small helpers shared by fzf-lua and grug-far keymaps.

local M = {}

-- Directory of the current buffer (falls back to cwd for unnamed buffers).
function M.buf_dir()
  local name = vim.api.nvim_buf_get_name(0)
  return name ~= "" and vim.fn.fnamemodify(name, ":p:h") or vim.uv.cwd()
end

-- Pick one or more directories with fzf-lua, then call `on_pick(dirs)`
-- with a list of paths relative to cwd.
-- Select several with <Tab> (or <C-q> for all), confirm with <Enter>.
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
    fzf_opts = { ["--multi"] = true },
    actions = {
      ["default"] = function(selected)
        if selected and #selected > 0 then
          vim.schedule(function() on_pick(selected) end)
        end
      end,
    },
  })
end

-- Short label for a list of directories, used in picker prompts.
function M.label(dirs)
  if #dirs == 1 then return dirs[1] end
  return dirs[1] .. " +" .. (#dirs - 1)
end
-- Git root of the current buffer's directory (nil if not in a repo).
function M.git_root()
  local out = vim.fn.systemlist({ "git", "-C", M.buf_dir(), "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then return nil end
  return out[1]
end

-- Current buffer path relative to the git root.
-- dir_only = true returns the directory instead of the file.
-- Falls back to a cwd-relative path outside a repo.
function M.rel_path(dir_only)
  local name = vim.api.nvim_buf_get_name(0)
  local abs = name ~= "" and vim.fn.fnamemodify(name, ":p") or vim.uv.cwd()
  if dir_only and name ~= "" then abs = vim.fn.fnamemodify(abs, ":h") end
  -- Resolve symlinks so /data1/home/... matches what git reports.
  abs = vim.uv.fs_realpath(abs) or abs

  local root = M.git_root()
  if root then
    root = vim.uv.fs_realpath(root) or root
    if abs == root then return "." end
    if abs:sub(1, #root + 1) == root .. "/" then
      return abs:sub(#root + 2)
    end
  end
  return vim.fn.fnamemodify(abs, ":.")
end

-- Copy text to the system clipboard and the unnamed register.
function M.copy(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  vim.notify("Copied: " .. text)
end

return M
