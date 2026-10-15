-- ~/.config/nvim/lua/utils/pick.lua
-- Small helpers shared by fzf-lua, neo-tree and grug-far keymaps.

local M = {}

-- Paths -----------------------------------------------------------------

-- Directory of the current buffer (falls back to cwd for unnamed buffers).
function M.buf_dir()
  local name = vim.api.nvim_buf_get_name(0)
  return name ~= "" and vim.fn.fnamemodify(name, ":p:h") or vim.uv.cwd()
end

-- Git root containing `path` (default: current buffer's dir), or nil.
function M.git_root(path)
  local dir = path or M.buf_dir()
  if vim.fn.isdirectory(dir) == 0 then dir = vim.fn.fnamemodify(dir, ":h") end
  local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then return nil end
  return vim.uv.fs_realpath(out[1]) or out[1]
end

-- Git root, or cwd when not in a repo.
function M.root(path)
  return M.git_root(path) or vim.uv.cwd()
end

-- `abs` relative to `base` (symlinks resolved, so /data1/home/... matches).
function M.rel_to(abs, base)
  abs = vim.uv.fs_realpath(abs) or abs
  base = vim.uv.fs_realpath(base) or base
  if abs == base then return "." end
  if abs:sub(1, #base + 1) == base .. "/" then return abs:sub(#base + 2) end
  return abs
end

-- Any absolute path -> relative to its git root (cwd-relative outside a repo).
function M.git_rel(abs)
  local root = M.git_root(abs)
  if root then return M.rel_to(abs, root) end
  return vim.fn.fnamemodify(abs, ":.")
end

-- Current buffer path relative to the git root.
-- dir_only = true returns the directory instead of the file.
function M.rel_path(dir_only)
  local name = vim.api.nvim_buf_get_name(0)
  local abs = name ~= "" and vim.fn.fnamemodify(name, ":p") or vim.uv.cwd()
  if dir_only and name ~= "" then abs = vim.fn.fnamemodify(abs, ":h") end
  return M.git_rel(abs)
end

-- Copy text to the system clipboard and the unnamed register.
function M.copy(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  vim.notify("Copied: " .. text)
end

-- Short label for a list of directories, used in picker prompts.
function M.label(dirs)
  if #dirs == 1 then return dirs[1] end
  return dirs[1] .. " +" .. (#dirs - 1)
end

-- Pickers ---------------------------------------------------------------

-- Fuzzy-pick one or more directories under `opts.cwd` (default: git root),
-- then call `on_pick(dirs)` with ABSOLUTE paths.
-- Select several with <Tab> (or <C-q> for all), confirm with <Enter>.
function M.pick_dir(prompt, on_pick, opts)
  opts = opts or {}
  local cwd = opts.cwd or M.root()
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
    cwd = cwd,
    preview = "ls -p --color=always {}",
    fzf_opts = { ["--multi"] = true, ["--scheme"] = "path" },
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then return end
        local abs = vim.tbl_map(function(s)
          return vim.fs.normalize(cwd .. "/" .. s:gsub("/$", ""))
        end, selected)
        vim.schedule(function() on_pick(abs) end)
      end,
    },
  })
end

-- Browse folders one level at a time, like shell <Tab> completion.
-- Starts in the current file's folder.
--   <Tab> / <C-l>        go into the highlighted folder
--   <S-Tab>              go up one level ("../" + <Tab> also works)
--   <C-g>                jump to the git root
--   <C-f>                fuzzy search every folder below here (multi-select)
--   <Enter>              done: call on_pick({ dir }) ("./" = this folder)
function M.browse_dir(prompt, on_pick, start)
  local root = M.root(start)

  local function open(dir)
    local subs = {}
    for name, kind in vim.fs.dir(dir) do
      local is_dir = kind == "directory"
        or (kind == "link" and vim.fn.isdirectory(dir .. "/" .. name) == 1)
      if is_dir and name ~= ".git" then table.insert(subs, name .. "/") end
    end
    table.sort(subs)
    local items = vim.list_extend({ "./", "../" }, subs)

    -- Absolute path of the highlighted entry.
    local function target(selected)
      local s = selected and selected[1]
      if not s then return dir end
      local p = vim.fn.simplify(dir .. "/" .. s):gsub("/+$", "")
      return p ~= "" and p or "/"
    end
    local function reopen(d) vim.schedule(function() open(d) end) end
    local function up() reopen(vim.fn.fnamemodify(dir, ":h")) end

    local here = M.rel_to(dir, root)
    require("fzf-lua").fzf_exec(items, {
      prompt = prompt .. (here == "." and "" or here .. "/") .. " ",
      cwd = dir,
      preview = "ls -p --color=always {}",
      fzf_opts = { ["--multi"] = false },
      actions = {
        ["default"] = function(sel)
          local t = target(sel)
          vim.schedule(function() on_pick({ t }) end)
        end,
        ["tab"] = function(sel) reopen(target(sel)) end,
        ["ctrl-l"] = function(sel) reopen(target(sel)) end,
        ["btab"] = up,
        ["ctrl-g"] = function() reopen(root) end,
        ["ctrl-f"] = function()
          vim.schedule(function() M.pick_dir(prompt, on_pick, { cwd = dir }) end)
        end,
      },
    })
  end

  open(start or M.buf_dir())
end

-- Run fzf-lua inside some directories, paths shown relative to git root.
local function scoped(dirs)
  local root = M.root(dirs[1])
  return root, vim.tbl_map(function(d) return M.rel_to(d, root) end, dirs)
end

function M.files_in(dirs)
  local root, rel = scoped(dirs)
  require("fzf-lua").files({
    cwd = root, search_paths = rel, prompt = "Files (" .. M.label(rel) .. ")> ",
  })
end

function M.grep_in(dirs)
  local root, rel = scoped(dirs)
  require("fzf-lua").live_grep({
    cwd = root, search_paths = rel, prompt = "Grep (" .. M.label(rel) .. ")> ",
  })
end

-- Show a path in Neo-tree (expands its parents and moves the cursor there).
function M.reveal_in_tree(path)
  require("neo-tree.command").execute({
    action = "focus",
    source = "filesystem",
    reveal_file = path,
    reveal_force_cwd = true,
  })
end

return M
