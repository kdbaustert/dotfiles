-- Treesitter: syntax highlighting, indentation and text objects.
--
-- Pinned to the `master` branch on purpose. Upstream's `main` rewrite changes
-- the setup API completely and moves parser installation to a different
-- command; master is the branch the `require("nvim-treesitter.configs").setup`
-- form below belongs to, and pinning means a `:Lazy update` can't silently
-- swap one for the other.

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TSUpdate", "TSInstall", "TSInstallInfo" },
  main = "nvim-treesitter.configs",
  opts = {
    -- The stack this machine actually edits — the web tooling implied by
    -- setup/npm.sh and the Brewfile's php, plus the languages this repo is
    -- itself written in.
    ensure_installed = {
      "bash",
      "css",
      "diff",
      "gitcommit",
      "gitignore",
      "html",
      "javascript",
      "json",
      "jsonc",
      "lua",
      "luadoc",
      "markdown",
      "markdown_inline",
      "php",
      "phpdoc",
      "query",
      "regex",
      "scss",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "vue",
      "yaml",
    },

    -- Install missing parsers in the background rather than blocking the first
    -- open of an unfamiliar filetype.
    auto_install = true,
    sync_install = false,

    highlight = {
      enable = true,
      -- Vim's regex highlighting on top of treesitter is redundant everywhere
      -- except commit messages, where it is what highlights the diff below
      -- the message.
      additional_vim_regex_highlighting = { "gitcommit" },
    },

    -- Indent is the one treesitter module that regularly gets things wrong.
    -- It is on because it is right far more often than `smartindent`, but
    -- disabled for the languages where it is a known problem.
    indent = {
      enable = true,
      disable = { "php", "yaml" },
    },

    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<CR>",
        node_incremental = "<CR>",
        node_decremental = "<BS>",
        scope_incremental = false,
      },
    },
  },
}
