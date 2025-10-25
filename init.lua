-- Basic settings
vim.o.termguicolors = true
vim.g.mapleader = " "
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.autochdir = true -- Change cwd in each buffer.
vim.opt.autoread = true -- Reload files when changed on disk.

require("config.lazy")

-- Color scheme
require("tokyonight").setup({
  style = "night",
  on_colors = function(colors)
    -- Brighten up comments a bit.
    colors.comment = require("tokyonight.util").lighten(colors.comment, 0.6)
  end
})
vim.cmd[[colorscheme tokyonight]]

-- Use Esc to turn off highlighting after searching for something.
vim.keymap.set("n", "<esc>", "<cmd>noh<cr>")

-- Set up treesitter.
require('nvim-treesitter.configs').setup {
  ensure_installed = { "lua", "vim", "vimdoc", "c", "cpp", "python", "rust", "markdown", "markdown_inline" },

  sync_install = false,

  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
}

-- Set up oil (this a directory editor).
require("oil").setup({
  watch_for_changes = true,
})
-- Autocommand to run actions.cd when entering an Oil buffer
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "oil://*",
  callback = function()
    require("oil.actions").cd.callback({
      silent = true
    })
  end,
})


-- Check if a string ends with a suffix
local function str_ends_with(str, suffix)
  return str:match(suffix .. "$") ~= nil
end

-- Add the suffix to the string if not already there.
local function ensure_suffix(str, suffix)
  if str_ends_with(str, suffix) then
    return str
  end
  return str .. suffix
end

-- Helper function to determine the directory of the buffer.
-- Otherwise, return directory of current buffer.
local function get_buffer_dir()
  return vim.loop.cwd()
end

-- Relative edit.  This prepopulates the current buffer's directory.
vim.keymap.set("n", "<leader>e", function()
  local buffer_dir = ensure_suffix(get_buffer_dir(), "/")
  vim.api.nvim_feedkeys(string.format(":edit %s", buffer_dir), "n", true)
end, { desc = "Edit from the relative directory." })

-- Get project root if in one.  Returns nil if no project is recognized.
local function get_project_root()
  -- First check for git.
  local job = vim.fn.systemlist(string.format("cd %s; git rev-parse --show-toplevel 2>/dev/null || true", get_buffer_dir()))
  local git_root = job[1]
  if git_root and git_root ~= "" then
    return git_root
  end
  return nil
end

-- Find project files.  By default it tries to search from the root of the
-- git repo.  If not in a repo, it searches from the current directory and
-- down.
local function find_project_files()
  local project_root = get_project_root()

  if project_root and project_root ~= "" then
    require("fzf-lua").git_files({ cwd = project_root })
  else
    local buffer_dir = get_buffer_dir()
    -- Fallback to current working directory if not in a git repo
    require("fzf-lua").files({cwd = buffer_dir})
    vim.notify(string.format("Not in a Git repository. Searching from current directory: %s", buffer_dir), vim.log.levels.WARN)
  end
end

-- Find files in projecct.
vim.keymap.set("n", "<leader>pf", find_project_files, { desc = "Find project files with FZF." })

-- Grep through the contents of project files.  It tries to search from the
-- root of the git repo.  If not in a repo, it searches from the current
-- directory and down.
local function grep_project_files()
  local git_root = get_project_root()

  -- Default to current working directory if not in a git repo
  local dir_to_search = get_buffer_dir()
  if git_root and git_root ~= "" then
    dir_to_search = git_root
  else
    vim.notify(string.format("Not in a Git repository. Searching from current directory: %s", buffer_dir), vim.log.levels.WARN)
  end
  require("fzf-lua").live_grep_native({ cwd = dir_to_search })
end

-- Grep files in project.
vim.keymap.set("n", "<leader>ps", grep_project_files, { desc = "Grep project files with FZF." })

local find_directory_cmd = "find . -name \".git\" -prune -o -type d -print"

-- Find project directories.  By default it tries to search from the root of
-- the git repo.  If not in a repo, it searches from the current directory and
-- down.
local function find_project_directories()
  local git_root = get_project_root()

  -- Default to current working directory if not in a git repo
  local dir_to_search = get_buffer_dir()
  if git_root and git_root ~= "" then
    dir_to_search = git_root
  else
    vim.notify(string.format("Not in a Git repository. Searching from current directory: %s", buffer_dir), vim.log.levels.WARN)
  end
  require("fzf-lua").files({ cmd = find_directory_cmd, cwd = dir_to_search })
end

-- Find directories in project.
vim.keymap.set("n", "<leader>pd", find_project_directories, { desc = "Find project directories with FZF." })

-- Find files under current directory
vim.keymap.set("n", "<leader>lf", function() require("fzf-lua").files({ search = get_buffer_dir(), cmd = "rg --files --sort path --max-depth 1 .", cwd = get_buffer_dir() }) end, { desc = "Find files in same directory" })

-- Grep files under current directory
vim.keymap.set("n", "<leader>ls", function() require("fzf-lua").live_grep_native({ cwd = get_buffer_dir() }) end, { desc = "Grep files in same directory" })

-- Find directories under current directory.
vim.keymap.set("n", "<leader>ld", function() require("fzf-lua").files({ search = get_buffer_dir(), cmd = find_directory_cmd, cwd = get_buffer_dir() }) end, { desc = "Find files in same directory" })

-- Find open buffers
vim.keymap.set("n", "<leader>b", require("fzf-lua").buffers, { desc = "Find open buffers with FZF." })

-- Switch buffers. This is easier to type than :b#.
vim.keymap.set("n", "<leader>bs", ":b#<CR>",
  { noremap = true, silent = true, desc = "Switch to last buffer." })

-- Close buffer without closing window.
vim.keymap.set("n", "<leader>bc", ":bp<bar>sp<bar>bn<bar>bd<CR>",
  { noremap = true, silent = true, desc = "Switch to last buffer." })

-- Trim whitespace when saving a file.
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function(ev)
    local save_cursor = vim.fn.getpos(".") -- Save current cursor position
    vim.cmd([[%s/\s\+$//e]]) -- Remove trailing whitespaces
    vim.fn.setpos(".", save_cursor) -- Restore cursor position
  end,
})



-- Bazel integration (This is a work in progress...)
vim.api.nvim_create_user_command("Bazel",
  function(command)
    local original_wd = vim.fn.getcwd()

    local job = vim.fn.systemlist(string.format("cd %s; git rev-parse --show-toplevel 2>/dev/null || true", buffer_dir))
    local git_root = job[1]

    vim.notify(git_root)

    vim.api.nvim_exec("set makeprg=bazel", false)
    vim.api.nvim_exec(string.format("make %s", command.args), false)
  end,
  {
    nargs = "*",
    desc = "Invoke bazel.",
  })

