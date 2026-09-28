-- ~/.config/nvim/lua/plugins/leetcode.lua
--
-- LeetCode practice inside Neovim (kawre/leetcode.nvim), wired to a git repo:
--   * solutions are written to <repo>/solutions/<id>.<slug>.cpp
--   * <repo>/neetcode150.json drives the NeetCode 150 picker
--   * a problem counts as "done" once its file is committed to the repo
--
-- Repo location: $LEETCODE_REPO, or ~/leetcode by default.
--
-- Keys (all under <leader>L, so they don't clash with the <leader>l LSP group):
--   <leader>Ll  menu            <leader>Lr  run tests       <leader>Ls  submit
--   <leader>Ln  next NeetCode   <leader>Lp  pick NeetCode   <leader>Lc  commit + push
--   <leader>Lo  open in browser <leader>Ld  toggle description
--   <leader>Lb  restore last submission   <leader>Lt  switch between open problems
--
-- First run: :Leet asks for your cookie. In the Windows browser, open DevTools on
-- leetcode.com -> Network -> any request -> Request Headers -> copy the whole "Cookie"
-- value (not "set-cookie") and paste it into the prompt.

local REPO = vim.fs.normalize(vim.env.LEETCODE_REPO or "~/leetcode")
local SOLUTIONS = REPO .. "/solutions"
local NEETCODE_JSON = REPO .. "/neetcode150.json"

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, { title = "leetcode" })
  end)
end

-- Run git inside the repo asynchronously; call on_ok on success.
local function git(args, on_ok)
  vim.system(vim.list_extend({ "git", "-C", REPO }, args), { text = true }, function(r)
    if r.code ~= 0 then
      return notify("git " .. args[1] .. " failed:\n" .. (r.stderr ~= "" and r.stderr or r.stdout),
        vim.log.levels.ERROR)
    end
    if on_ok then on_ok(r) end
  end)
end

---------------------------------------------------------------------------
-- NeetCode 150 helpers
---------------------------------------------------------------------------

-- Slugs whose solution file is committed to the repo.
local function committed_slugs()
  local done = {}
  local out = vim.fn.systemlist({ "git", "-C", REPO, "ls-files", "solutions" })
  if vim.v.shell_error == 0 then
    for _, path in ipairs(out) do
      local slug = path:match("^solutions/%d+%.(.+)%.cpp$")
      if slug then done[slug] = true end
    end
  end
  return done
end

local function load_neetcode()
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(NEETCODE_JSON), "\n"))
  end)
  if not ok then
    notify("Cannot read " .. NEETCODE_JSON, vim.log.levels.ERROR)
    return nil
  end
  return data
end

-- LeetCode's own solved status, from leetcode.nvim's problem cache.
local function leetcode_status()
  local status = {}
  local ok, problems = pcall(function()
    return require("leetcode.cache.problemlist").get()
  end)
  if ok then
    for _, p in ipairs(problems) do
      status[p.title_slug] = { ac = p.status == "ac", paid = p.paid_only }
    end
  end
  return status
end

---------------------------------------------------------------------------
-- Opening a problem by slug
---------------------------------------------------------------------------

-- Start leetcode.nvim if needed, wait until signed in, then run cb.
local function with_leetcode(cb)
  local function ready()
    local c = package.loaded["leetcode.config"]
    return c and c.auth and c.auth.is_signed_in
  end
  if ready() then return cb() end

  vim.cmd("Leet")
  local tries = 0
  local function poll()
    if ready() then return cb() end
    tries = tries + 1
    if tries > 75 then -- ~15s
      return notify("Not signed in yet. Finish signing in via :Leet, then try again.",
        vim.log.levels.WARN)
    end
    vim.defer_fn(poll, 200)
  end
  poll()
end

-- Uses leetcode.nvim internals (the same calls :Leet daily uses).
local function open_slug(slug)
  with_leetcode(function()
    local ok, err = pcall(function()
      local problemlist = require("leetcode.cache.problemlist")
      require("leetcode-ui.question")(problemlist.get_by_title_slug(slug)):mount()
    end)
    if not ok then
      notify("Could not open " .. slug .. ": " .. tostring(err) ..
        "\nTry :Leet cache update", vim.log.levels.ERROR)
    end
  end)
end

local function neetcode_next()
  local list = load_neetcode()
  if not list then return end
  local done = committed_slugs()
  for _, p in ipairs(list) do
    if not done[p.slug] then
      notify(("Next: %s (%s, %s)"):format(p.title, p.pattern, p.difficulty))
      return open_slug(p.slug)
    end
  end
  notify("NeetCode 150 complete!")
end

-- fzf-lua picker over the whole list, in roadmap order.
--   ✓ committed to the repo   ● accepted on LeetCode but not in the repo yet
--   · not solved              $ premium
local function neetcode_pick()
  local list = load_neetcode()
  if not list then return end
  with_leetcode(function()
    local done, lc = committed_slugs(), leetcode_status()
    local entries, by_line, solved = {}, {}, 0
    for i, p in ipairs(list) do
      local st = lc[p.slug] or {}
      local mark = done[p.slug] and "✓" or (st.ac and "●" or "·")
      if done[p.slug] then solved = solved + 1 end
      local line = ("%s %3d  %-24s %-6s %s%s"):format(mark, i, p.pattern, p.difficulty:sub(1, 6),
        p.title, st.paid and "  $" or "")
      entries[#entries + 1] = line
      by_line[line] = p.slug
    end
    require("fzf-lua").fzf_exec(entries, {
      prompt = ("NeetCode 150 (%d/150)> "):format(solved),
      winopts = { height = 0.6, width = 0.7, preview = { hidden = true } },
      fzf_opts = { ["--no-sort"] = true },
      actions = {
        ["default"] = function(selected)
          local slug = selected[1] and by_line[selected[1]]
          if slug then open_slug(slug) end
        end,
      },
    })
  end)
end

-- Commit the current solution file and push.
local function commit_current()
  local file = vim.api.nvim_buf_get_name(0)
  if not vim.startswith(file, SOLUTIONS .. "/") then
    return notify("Current buffer is not a file in " .. SOLUTIONS, vim.log.levels.WARN)
  end
  vim.cmd.write()
  local name = vim.fn.fnamemodify(file, ":t:r")
  git({ "add", file }, function()
    git({ "commit", "-m", "solve: " .. name }, function()
      git({ "push" }, function() notify("Pushed " .. name) end)
    end)
  end)
end

---------------------------------------------------------------------------
-- Plugin spec
---------------------------------------------------------------------------

return {
  "kawre/leetcode.nvim",
  cmd = "Leet",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "ibhagwan/fzf-lua",
  },
  -- The "html" treesitter parser (used to render descriptions) is installed
  -- from lua/plugins/treesitter.lua.
  opts = {
    lang = "cpp",
    storage = { home = SOLUTIONS },
    plugins = { non_standalone = true }, -- allow :Leet with other buffers open
    picker = { provider = "fzf-lua" },
    injector = {
      cpp = {
        -- Folded at the top of the buffer; never sent to LeetCode.
        imports = function()
          return { "#include <bits/stdc++.h>", "using namespace std;" }
        end,
      },
    },
    editor = {
      reset_previous_code = false, -- reopening a problem keeps your code
      fold_imports = true,
    },
    hooks = {
      -- Always start from the latest state when switching machines.
      ["enter"] = {
        function()
          git({ "pull", "--rebase", "--autostash" }, function() notify("Repo up to date") end)
        end,
      },
    },
  },
  keys = {
    { "<leader>Ll", "<cmd>Leet<cr>", desc = "Menu" },
    { "<leader>Lr", "<cmd>Leet run<cr>", desc = "Run tests" },
    { "<leader>Ls", "<cmd>Leet submit<cr>", desc = "Submit" },
    { "<leader>Lo", "<cmd>Leet open<cr>", desc = "Open in browser" },
    { "<leader>Ld", "<cmd>Leet desc<cr>", desc = "Toggle description" },
    { "<leader>Lb", "<cmd>Leet last_submit<cr>", desc = "Restore last submission" },
    { "<leader>Lt", "<cmd>Leet tabs<cr>", desc = "Open problems" },
    { "<leader>Ln", neetcode_next, desc = "NeetCode: next problem" },
    { "<leader>Lp", neetcode_pick, desc = "NeetCode: pick problem" },
    { "<leader>Lc", commit_current, desc = "Commit + push solution" },
  },
}
