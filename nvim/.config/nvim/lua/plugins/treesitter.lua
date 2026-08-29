return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",        -- rewrite branch for Neovim 0.12; master is frozen, do NOT use it
  lazy = false,
  build = ":TSUpdate",
  config = function()
    -- The main branch dropped 'ensure_installed'; install parsers via install().
    -- This also pulls the matching queries, so no manual copying is needed.
    require("nvim-treesitter").install({
      "c", "cpp", "go", "rust", "lua",
      "vim", "vimdoc", "query", "markdown", "markdown_inline",
    })
 
    -- Highlighting is NOT auto-enabled on main branch: start it ourselves.
    -- Map the filetype to a language, and only start when a parser exists,
    -- so buffers without a parser never throw an error.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(args.match)
        if not lang then
          return
        end
        if not vim.treesitter.language.add(lang) then
          return
        end
        vim.treesitter.start(args.buf, lang)
      end,
    })
  end,
}
