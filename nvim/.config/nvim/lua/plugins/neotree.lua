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
        local pick = require("utils.pick")

        -- Folder of the node under the cursor (a file's parent folder).
        local function node_dir(state)
            local node = state.tree:get_node()
            return node.type == "directory" and node.path or vim.fn.fnamemodify(node.path, ":h")
        end

        -- Keys inside Neo-tree (built-in ones worth knowing):
        --   D        fuzzy find a DIRECTORY in the tree, <Enter> jumps to it
        --   /        fuzzy find a file or directory      <C-x> clears the filter
        --   .        make this folder the root            <BS> go up a level
        -- Added below:
        --   Y        copy path of node (git-relative)     gy  copy its folder
        --   F        fzf files inside node's folder       G   live grep there
        require("neo-tree").setup({
            close_if_last_window = true,
            commands = {
                copy_git_path = function(state)
                    pick.copy(pick.git_rel(state.tree:get_node().path))
                end,
                copy_git_dir = function(state)
                    pick.copy(pick.git_rel(node_dir(state)))
                end,
                find_in_node = function(state)
                    pick.files_in({ node_dir(state) })
                end,
                grep_in_node = function(state)
                    pick.grep_in({ node_dir(state) })
                end,
            },
            window = {
                width = 50,
                mappings = {
                    ["Y"] = "copy_git_path",
                    ["gy"] = "copy_git_dir",
                    ["F"] = "find_in_node",
                    ["G"] = "grep_in_node",
                },
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
