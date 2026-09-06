return {
	"MagicDuck/grug-far.nvim",
	config = function()
		require("grug-far").setup({})

		local grug = require("grug-far")

		vim.keymap.set({ "n", "v" }, "<leader>sr", function()
			grug.open()
		end, { desc = "Search & Replace (project)" })

		vim.keymap.set("n", "<leader>sw", function()
			grug.open({ prefills = { search = vim.fn.expand("<cword>") } })
		end, { desc = "Search word under cursor" })

		vim.keymap.set("n", "<leader>sf", function()
			grug.open({ prefills = { paths = vim.fn.expand("%") } })
		end, { desc = "Search & Replace (current file)" })

		vim.keymap.set("v", "<leader>sv", function()
			grug.with_visual_selection()
		end, { desc = "Search with visual selection" })
	end,
}
