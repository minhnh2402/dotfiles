return {
  "saghen/blink.cmp",
  -- Use a tagged release so the prebuilt Rust binary is downloaded
  -- (no need to have the Rust toolchain installed locally)
  version = "1.*",
  -- Only load blink when entering insert mode -> faster startup
  event = "InsertEnter",
  -- (ADDED) LuaSnip must be available for the "luasnip" snippet preset below
  dependencies = { "L3MON4D3/LuaSnip" },
  opts = {
    keymap = {
      -- "default" preset:
      --   <C-space> : open / toggle the completion menu
      --   <C-y>     : accept the selected item
      --   <C-e>     : close the menu
      --   <C-n>/<C-p> or <Up>/<Down> : navigate items
      preset = "default",

      -- Tab / Shift-Tab: move through menu items, and ALSO jump between
      -- snippet placeholders ($1 -> $2). Order matters: it tries each action
      -- in turn and stops at the first that applies, falling back to a real
      -- tab only when neither a menu nor a snippet is active.
      ["<Tab>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },

      -- Accept the current item with Enter as well as <C-y>
      ["<CR>"] = { "accept", "fallback" },
    },

    completion = {
      -- Automatically show the documentation window next to the menu
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      -- Highlight the fuzzy-matched characters in each item
      menu = { draw = { treesitter = { "lsp" } } },
    },

    -- Where completion items come from, in priority order.
    -- The "snippets" source will surface our LuaSnip snippets (incl. "dsa").
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    -- (ADDED) Expand/enumerate snippets through LuaSnip instead of vim.snippet
    snippets = {
      preset = "luasnip",
    },

    -- Show the function signature while typing arguments
    signature = { enabled = true },

    -- Use the fast Rust fuzzy matcher; warn (don't crash) if unavailable
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
}
