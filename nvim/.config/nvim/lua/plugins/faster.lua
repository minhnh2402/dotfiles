-- lua/plugins/faster.lua
return {
  "pteroctopus/faster.nvim",
  opts = {
    behaviours = {
      bigfile = {
        on = true,
        -- Hạ ngưỡng xuống 1.1 MB để bắt cả file 1.34 MB
        -- (bạn có thể chọn 1.3 hay 1.0 tuỳ thích)
        filesize = 1.1, -- đơn vị: MB
        -- Tắt các feature nặng khi gặp file lớn:
        features_disabled = {
          "illuminate", "matchparen", "lsp", "treesitter",
          "indent_blankline", "vimopts", "syntax", "filetype",
        },
        -- Áp dụng cho mọi đuôi file; có thể tinh chỉnh theo pattern:
        -- extra_patterns = { {pattern="*.log"}, {filesize=0.8, pattern="*.md"} },
      },
      fastmacro = {
        on = true,
        features_disabled = { "lualine", "mini_clue" },
      },
    },
    -- (Giữ nguyên phần features mặc định của plugin)
  },
}

