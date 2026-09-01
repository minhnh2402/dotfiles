return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    
    keys = {
        { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
    },
    
    config = function()
        vim.keymap.set("n", "<leader>o", "<cmd>Neotree focus<cr>", { desc = "Enter file explorer" })
        require("neo-tree").setup({
            close_if_last_window = true,
            window = {
                width = 32,
            },
            filesystem = {
            -- jump to & highlight file opened (include using fzf)
                follow_current_file = {
                    enabled = true,
                    leave_dirs_open = false,  -- false = only open folder of current file
                },
                use_libuv_file_watcher = true, -- refesh self after file update
                filtered_items = {
                    visible = false,        
                    hide_dotfiles = false,  -- unhide .dotfiles (change to true if hide)
                    hide_gitignored = true, -- hide file gitignored
                },
            },
        })
  end
}
