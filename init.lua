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

-- Set up yanky.
vim.keymap.set({"n","x"}, "p", "<Plug>(YankyPutAfter)")
vim.keymap.set({"n","x"}, "P", "<Plug>(YankyPutBefore)")

vim.keymap.set("n", "[e", "<Plug>(YankyPreviousEntry)")
vim.keymap.set("n", "]e", "<Plug>(YankyNextEntry)")


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

-- Enable the buffer MRU
require("buffer_mru")

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
vim.keymap.set("n", "<leader>bl", require("fzf-lua").buffers, { desc = "Find open buffers with FZF." })

-- Switch to the last used buffer that isn't visible in another window.
local function switch_to_mru_buffer_not_visibile()
  local buffers = require("buffer_mru").mru_buffers()

  for _, bufnr in ipairs(buffers) do
    if vim.tbl_isempty(vim.fn.win_findbuf(bufnr))
    then
      vim.cmd(string.format("buffer %d", bufnr))
      return
    end
  end
  vim.print("All buffers are visible.  Doing nothing.")
end

-- Switch buffers.
vim.keymap.set("n", "<leader>bs",
  switch_to_mru_buffer_not_visibile,
  { noremap = true, silent = false, desc = "Switch to most recently used buffer not currently viewed."})

-- Close buffer without closing window.
vim.keymap.set("n", "<leader>bc",
  function ()
    local buf_to_delete = vim.api.nvim_get_current_buf()

    local buffers = require("buffer_mru").mru_buffers()
    -- Try to switch to another buffer that isn't viewed before we delete the original buffer.
    for _, bufnr in ipairs(buffers) do
      if vim.tbl_isempty(vim.fn.win_findbuf(bufnr))
      then
        vim.cmd(string.format("buffer %d", bufnr))
        vim.cmd(string.format("bdelete %d", buf_to_delete))
        return
      end
    end
    -- If there aren't any buffers to switch to, then switch to a new buffer
    -- and then delete it. This ay be annoying if we find ourselves here often.
    -- It could be better to just switch to another buffer even if its already
    -- open in another window.
    vim.cmd("enew")
    vim.cmd(string.format("bdelete %d", buf_to_delete))
  end,
  { noremap = true, silent = true, desc = "Close buffer but keep window open." })

-- Print MRU buffers.
vim.api.nvim_create_user_command("ShowMRUBuffers",
  function()
    local buffers = require("buffer_mru").mru_buffers()

    local message = {string.format("Open Buffers: %d", #buffers)}
    for _, bufnr in ipairs(buffers) do
      local buf_name = vim.api.nvim_buf_get_name(bufnr)
      local is_valid = vim.api.nvim_buf_is_valid(bufnr)
      local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
      local is_listed = vim.fn.buflisted(bufnr)
      table.insert(message, string.format("Buffer %d: {Valid: %s, Loaded: %s, Listed: %s, Name: %s}", bufnr, tostring(is_valid), tostring(is_loaded), tostring(is_listed), buf_name))
    end
    vim.print(table.concat(message, "\n"))
  end,
  { desc = "Print MRU buffers."})

-- Copy the path to the current buffer to the `+` register.  Can be yanked with "+p.
vim.keymap.set("n", "<leader>bp", ":let @+ = expand('%:p')<CR>",
  { noremap = true, silent = true, desc = "Copy path to current buffer to register `+`." })

-- Trim whitespace when saving a file.
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function(ev)
    local save_cursor = vim.fn.getpos(".") -- Save current cursor position
    vim.cmd([[%s/\s\+$//e]]) -- Remove trailing whitespaces
    vim.fn.setpos(".", save_cursor) -- Restore cursor position
  end,
})

-- Add a shortcut for showing the git log with --decorate.
vim.api.nvim_create_user_command("Log",
  function (command)
    vim.api.nvim_exec("G log --decorate", false)
  end,
  {
    desc = "Git log with --decorate.",
  })

-- Bazel integration (This is a work in progress...)
vim.api.nvim_create_user_command("Bazel",
  function(command)
    vim.api.nvim_exec("set makeprg=bazel", false)
    vim.api.nvim_exec(string.format("make %s", command.args), false)
  end,
  {
    complete = "shellcmd",
    nargs = "*",
    desc = "Invoke bazel.",
  })

