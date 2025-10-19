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

-- Use Esc to turn off highlighting after searching for something.
vim.keymap.set("n", "<esc>", "<cmd>noh<cr>")

-- Set up treesitter.
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
}

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

-- Check if the buffer is NERDTree.
local function is_nerd_tree()
  local buffer_name = vim.api.nvim_buf_get_name(0)
  local buffer_stem = vim.fn.fnamemodify(buffer_name, ":t")
  if string.find(buffer_stem, "NERD_tree_") then
    return true
  end
  return false
end

-- If in NERDTree, toggle off.
local function toggle_nerd_tree()
  if is_nerd_tree() then
    vim.api.nvim_exec(":NERDTreeToggle", false)
  end
end

-- Helper function to determine the directory of the buffer.
-- If in NERDTree, return the root dir.
-- Otherwise, return directory of current buffer.
local function get_buffer_dir()
  if is_nerd_tree() then
    local nerd_tree_root = vim.api.nvim_exec("echo b:NERDTree.root.path.str()", true)
    return nerd_tree_root
  end

  local buffer_name = vim.api.nvim_buf_get_name(0)
  local buffer_dir = vim.fn.fnamemodify(buffer_name, ":h")
  return buffer_dir
end

-- Relative edit.  This prepopulates the current buffer's directory.
vim.keymap.set("n", "<leader>e", function()
  local buffer_dir = ensure_suffix(get_buffer_dir(), "/")
  vim.api.nvim_feedkeys(string.format(":edit %s", buffer_dir), "n", true)
end, { desc = "Edit from the relative directory." })


-- Find project files.  By default it tries to search from the root of the
-- git repo.  If not in a repo, it searches from the current directory and
-- down.
local function find_project_files()
  local buffer_dir = get_buffer_dir()

  -- Get the directory from the buffer to use as the "current directory".
  local job = vim.fn.systemlist(string.format("cd %s; git rev-parse --show-toplevel 2>/dev/null || true", buffer_dir))
  local git_root = job[1]

  toggle_nerd_tree()
  if git_root and git_root ~= "" then
    require("fzf-lua").git_files({ cwd = git_root })
  else
    -- Fallback to current working directory if not in a git repo
    require("fzf-lua").files({cwd = buffer_dir})
    vim.notify(string.format("Not in a Git repository. Searching from current directory: %s", buffer_dir), vim.log.levels.WARN)
  end
end

-- Map to a keybinding.
vim.keymap.set("n", "<leader>ff", find_project_files, { desc = "Find project files with FZF." })

-- Search through project files.  By default it tries to search from the root of the
-- git repo.  If not in a repo, it searches from the current directory and
-- down.
local function search_project_files()
  local buffer_dir = get_buffer_dir()

  -- Get the directory from the buffer to use as the "current directory".
  local job = vim.fn.systemlist(string.format("cd %s; git rev-parse --show-toplevel 2>/dev/null || true", buffer_dir))
  local git_root = job[1]

  toggle_nerd_tree()
  if git_root and git_root ~= "" then
    require("fzf-lua").live_grep({ cwd = git_root })
  else
    -- Fallback to current working directory if not in a git repo
    require("fzf-lua").live_grep({cwd = buffer_dir})
    vim.notify(string.format("Not in a Git repository. Searching from current directory: %s", buffer_dir), vim.log.levels.WARN)
  end
end

-- Map to a keybinding.
vim.keymap.set("n", "<leader>fs", search_project_files, { desc = "Search project files with FZF." })

-- Find open buffers
vim.keymap.set("n", "<leader>fb", require("fzf-lua").buffers, { desc = "Find open buffers with FZF." })

-- Find files in same directory
vim.keymap.set("n", "<leader>fd", function() require("fzf-lua").files({ search = get_buffer_dir(), cmd = "rg --files --max-depth 1 .", cwd = get_buffer_dir() }) end, { desc = "Find files in same directory" })

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

