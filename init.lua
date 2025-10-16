-- Basic settings
vim.o.termguicolors = true
vim.g.mapleader = " "
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

require("config.lazy")

-- Color scheme
vim.cmd[[colorscheme tokyonight-night]]

-- Set up treesitter.
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true, -- Enable Treesitter highlighting
  },
}

-- Search project files.  By default it tries to search from the root of the
-- git repo.  If not in a repo, it searches from the current directory and
-- down.
local function search_project_files()
  -- Get the directory from the buffer to use as the "current directory".
  local buffer_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')
  local job = vim.fn.systemlist(string.format("cd %s; git rev-parse --show-toplevel", buffer_dir))
  local git_root = job[1]

  if git_root and git_root ~= "" then
    require("fzf-lua").git_files({ cwd = git_root })
  else
    -- Fallback to current working directory if not in a git repo
    require("fzf-lua").files({cwd = buffer_dir})
    vim.notify("Not in a Git repository. Searching from current directory.", vim.log.levels.WARN)
  end
end

-- Map `search_project_files` to a keybinding.
vim.keymap.set("n", "<leader>fp", search_project_files, { desc = "Search project files with FZF." })

-- Trim whitespace when saving a file.
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function(ev)
    local save_cursor = vim.fn.getpos(".") -- Save current cursor position
    vim.cmd([[%s/\s\+$//e]]) -- Remove trailing whitespaces
    vim.fn.setpos(".", save_cursor) -- Restore cursor position
  end,
})
