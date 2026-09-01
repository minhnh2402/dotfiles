return {
  "saghen/blink.cmp",
  -- Use a tagged release so the prebuilt Rust binary is downloaded
  -- (no need to have the Rust toolchain installed locally)
  version = "1.*",
  -- Only load blink when entering insert mode -> faster startup
  event = "InsertEnter",
  opts = {
    keymap = {
      -- "default" preset:
      --   <C-space> : open / toggle the completion menu
      --   <C-y>     : accept the selected item
      --   <C-e>     : close the menu
      --   <C-n>/<C-p> or <Up>/<Down> : navigate items
      preset = "default",
 
      -- Use Tab / Shift-Tab to move through the completion items.
      -- Remove this block if you prefer Tab to stay as a normal tab key.
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
 
    -- Where completion items come from, in priority order
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
 
    -- Use the fast Rust fuzzy matcher; warn (don't crash) if unavailable
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
}
