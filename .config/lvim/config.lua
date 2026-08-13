-- LunarVim.
--
-- LunarVim keeps its own runtime in ~/.local/share/lunarvim (installed by its
-- upstream script, not by install.sh) and reads exactly one file for user
-- config: this one. Everything else in this directory is loaded from here or
-- found on the runtimepath, which `~/.config/lvim` is a member of — so the
-- symlink install.sh creates is what makes `require "voltage"` and
-- `colors/voltage.lua` resolvable at all.
--
-- Docs: https://www.lunarvim.org/docs/configuration
--
-- Note on the Neovim version: LunarVim's master branch targets Neovim 0.10 and
-- upstream has been quiet for a while, while the Brewfile tracks whatever
-- `neovim` currently is. Startup logs one `vim.tbl_flatten is deprecated`
-- warning from LunarVim's own code because of that gap. It is harmless, it is
-- not from anything in this file, and it is not worth patching a vendored
-- runtime to silence. `:checkhealth` is the place to look if that ever turns
-- into a real error.

-- ---------------------------------------------------------------------------
-- Appearance
-- ---------------------------------------------------------------------------

-- The colorscheme is a plugin-shaped directory shared with .config/nvim rather
-- than a copy living here — see .config/voltage.nvim and themes/voltage.md.
-- Two editors with two transcriptions of the same palette is precisely the
-- drift the palette exists to prevent, so both add this one path instead.
-- It has to go on the runtimepath before either the `require` below or
-- LunarVim's `colorscheme` call can resolve out of it.
vim.opt.rtp:append(vim.fn.expand "~/.config/voltage.nvim")

-- Replaces LunarVim's `lunar` scheme outright rather than tweaking it: a
-- near-miss against the rest of the shell is more jarring than a clean swap.
lvim.colorscheme = "voltage"
lvim.builtin.lualine.options.theme = require "voltage.lualine"

-- Ghostty already draws the window at 75% opacity with a blur. A transparent
-- Neovim would put a second backdrop under the same text and lose contrast for
-- no visual gain, so the editor stays opaque and lets the terminal own it.
lvim.transparent_window = false
vim.opt.winblend = 0
vim.opt.pumblend = 0

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------

vim.opt.relativenumber = true -- pairs with the absolute number on the cursor
vim.opt.cursorline = true
vim.opt.scrolloff = 8 -- never put the cursor on the very edge of the viewport
vim.opt.sidescrolloff = 8

-- Wrap at word boundaries and indent the continuation. Off by default in
-- LunarVim, but a lot of what gets opened here is prose — READMEs, Obsidian
-- notes, commit messages — where a hard cut mid-word is worse than a soft one.
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

vim.opt.undofile = true -- undo history survives closing the buffer
vim.opt.confirm = true -- prompt instead of failing on :q with unsaved changes
vim.opt.updatetime = 250 -- how fast CursorHold fires (hover, gitsigns blame)
vim.opt.timeoutlen = 400 -- how long which-key waits before showing itself

-- The repo already has a .editorconfig; these are only the fallback for files
-- it does not cover.
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- ---------------------------------------------------------------------------
-- Treesitter
-- ---------------------------------------------------------------------------

-- Parsers for what actually gets edited here: the web stack the global npm and
-- Composer packages imply, plus the languages this repo itself is written in.
lvim.builtin.treesitter.ensure_installed = {
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
}
lvim.builtin.treesitter.highlight.enable = true
lvim.builtin.treesitter.rainbow.enable = false

-- ---------------------------------------------------------------------------
-- Language servers
-- ---------------------------------------------------------------------------

-- Mason installs anything missing in this list on first launch, which makes
-- that one launch slow and every later one instant. Names are lspconfig's, not
-- Mason's — note `tsserver` rather than `ts_ls`, since the nvim-lspconfig
-- version pinned in lazy-lock.json predates that rename.
lvim.lsp.installer.setup.ensure_installed = {
  "cssls",
  "html",
  "intelephense",
  "jsonls",
  "lua_ls",
  "tailwindcss",
  "tsserver",
  "volar",
}

-- ---------------------------------------------------------------------------
-- Formatting and linting
-- ---------------------------------------------------------------------------

-- Every tool named below is one this repo already installs, and none-ls only
-- shells out to PATH — it never fetches anything. So Mason is deliberately not
-- in the loop here: prettier/eslint/stylelint come from setup/npm.sh, and
-- stylua/shfmt/shellcheck/php-cs-fixer from the Brewfile. A Mason-installed
-- copy would sit under ~/.local/share/lunarvim and disappear the moment that
-- runtime is reinstalled, which is exactly the drift the Brewfile exists to
-- prevent. Project-local binaries in node_modules/.bin still win where a
-- project has them; the globals are the fallback.
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  {
    name = "prettier",
    filetypes = {
      "css",
      "html",
      "javascript",
      "javascriptreact",
      "json",
      "jsonc",
      "markdown",
      "scss",
      "typescript",
      "typescriptreact",
      "vue",
      "yaml",
    },
  },
  { name = "stylua", filetypes = { "lua" } },
  { name = "shfmt", filetypes = { "sh", "bash", "zsh" } },
  -- PHP goes to php-cs-fixer rather than prettier, even though
  -- @prettier/plugin-php is installed: it is PHP-native, it reads a project's
  -- .php-cs-fixer.php, and it is what the Brewfile declares. Swap the filetype
  -- onto the prettier block above if a project wants prettier's style instead.
  { name = "phpcsfixer", filetypes = { "php" } },
}

local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { name = "eslint", filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" } },
  { name = "stylelint", filetypes = { "css", "scss" } },
  { name = "shellcheck", filetypes = { "sh", "bash" } },
}

-- Safe to leave on because every formatter above reformats rather than
-- rewrites, so saving can't change what the code means. The pattern is scoped
-- to the filetypes actually configured — without it, saving a file with no
-- registered formatter falls through to the LSP, which formats to its own
-- defaults and quietly ignores .editorconfig.
lvim.format_on_save.enabled = true
lvim.format_on_save.pattern = {
  "*.lua",
  "*.php",
  "*.css",
  "*.scss",
  "*.js",
  "*.jsx",
  "*.ts",
  "*.tsx",
  "*.vue",
  "*.json",
  "*.md",
  "*.yml",
  "*.yaml",
  "*.sh",
}

-- ---------------------------------------------------------------------------
-- Keys
-- ---------------------------------------------------------------------------

-- `jk` to leave insert mode, matching the muscle memory the shell's vi-mode
-- bindings already train.
lvim.keys.insert_mode["jk"] = "<Esc>"

-- Move by screen line when a line is wrapped, unless a count was given — so
-- `j` behaves visually but `5j` still means five real lines, which is what
-- relativenumber is showing you.
lvim.keys.normal_mode["j"] = { "v:count == 0 ? 'gj' : 'j'", { expr = true } }
lvim.keys.normal_mode["k"] = { "v:count == 0 ? 'gk' : 'k'", { expr = true } }

-- Keep the cursor centered when jumping half a page or stepping through search
-- results; scrolloff can't do this because the target may be mid-file.
lvim.keys.normal_mode["<C-d>"] = "<C-d>zz"
lvim.keys.normal_mode["<C-u>"] = "<C-u>zz"
lvim.keys.normal_mode["n"] = "nzzzv"
lvim.keys.normal_mode["N"] = "Nzzzv"

-- Clear search highlight. `<Esc>` is otherwise a no-op in normal mode.
lvim.keys.normal_mode["<Esc>"] = "<cmd>nohlsearch<CR>"

-- ---------------------------------------------------------------------------
-- Which-key
-- ---------------------------------------------------------------------------

-- lazygit is already configured and themed (.config/lazygit/config.yml), so
-- the useful thing here is a way to reach it without leaving the editor rather
-- than a second git UI inside Neovim.
lvim.builtin.which_key.mappings["gg"] = { "<cmd>lua require('lvim.core.terminal').lazygit_toggle()<CR>", "Lazygit" }

lvim.builtin.which_key.mappings["r"] = {
  name = "Voltage",
  r = { "<cmd>colorscheme voltage<CR>", "Reload colorscheme" },
}

-- ---------------------------------------------------------------------------
-- Builtins
-- ---------------------------------------------------------------------------

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = true

-- yazi is the file manager of record (.config/yazi); nvim-tree here is for
-- moving around a project you already have open, so it follows the buffer
-- rather than trying to be a browser.
lvim.builtin.nvimtree.setup.update_focused_file.enable = true
