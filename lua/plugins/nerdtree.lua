return {
	{
		"preservim/nerdtree",
		lazy = true, -- Set to true for lazy loading
		keys = {
			{ "<leader>n", "<cmd>NERDTreeToggle<cr>", desc = "Toggle NERDTree" }
		},
		cmd = { "NERDTree" },
		opts = {
			-- Optional: Add any specific NERDTree options here
			-- For example:
			-- autostart = true,
			-- show_hidden = 1,
		},
	},
}
