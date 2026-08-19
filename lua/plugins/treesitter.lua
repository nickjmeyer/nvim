return {{
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local parsers = {
      "lua",
      "vim",
      "vimdoc",
      "c",
      "cpp",
      "python",
      "rust",
      "markdown",
      "markdown_inline",
    }

    -- The maintained nvim-treesitter branch builds parsers with the standalone
    -- tree-sitter CLI.  Install tree-sitter with cargo:
    -- `cargo install tree-sitter --locked`
    local function has_supported_tree_sitter_cli()
      local executable = vim.fn.exepath("tree-sitter")
      if executable == "" then
        return false
      end

      local result = vim.system({ executable, "--version" }, { text = true }):wait()
      if result.code ~= 0 then
        return false
      end

      local major, minor, patch = result.stdout:match("(%d+)%.(%d+)%.(%d+)")
      major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)
      return major ~= nil
        and (major > 0 or minor > 26 or (minor == 26 and patch >= 1))
    end

    if has_supported_tree_sitter_cli() then
      require("nvim-treesitter").install(parsers)
    else
      vim.notify(
        "nvim-treesitter: tree-sitter CLI 0.26.1+ is required; install it via `cargo install tree-sitter --locked`",
        vim.log.levels.ERROR
      )
    end

    local parser_by_filetype = {
      help = "vimdoc",
    }

    local function language_for_buffer(bufnr)
      local filetype = vim.bo[bufnr].filetype
      return parser_by_filetype[filetype] or vim.treesitter.language.get_lang(filetype)
    end

    local function start_highlighting(args)
      local lang = language_for_buffer(args.buf)
      if not lang then
        return
      end

      -- A parser may not be installed yet (for example while the async install
      -- above is still running). Do not make opening that buffer fail.
      local ok, loaded = pcall(vim.treesitter.language.add, lang)
      if not ok or not loaded then
        return
      end

      vim.treesitter.start(args.buf, lang)
    end

    local treesitter_group = vim.api.nvim_create_augroup("nvim-treesitter", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
      group = treesitter_group,
      pattern = { "lua", "vim", "help", "c", "cpp", "python", "rust", "markdown" },
      callback = start_highlighting,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = treesitter_group,
      pattern = { "lua", "c", "cpp", "python", "rust", "markdown" },
      callback = function(args)
        local lang = language_for_buffer(args.buf)
        if not lang then
          return
        end

        local ok, loaded = pcall(vim.treesitter.language.add, lang)
        if ok and loaded then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}}
