-- Neovim.
--
-- Hand-rolled, and deliberately not a second LunarVim. `lvim` is the batteries-
-- included IDE layer (see .config/lvim and the note in README.MD); this is the
-- editor that starts fast, has no vendored runtime, and is entirely readable in
-- an afternoon. They share exactly one thing — the Voltage colorscheme in
-- .config/voltage.nvim — and nothing else.
--
-- The `lua/configs` + `lua/plugins` split is inherited from the NvChad config
-- that used to live here: `configs` is settings that need no plugin, `plugins`
-- is one file per concern, each returning a lazy.nvim spec.
--
-- Leader has to be set before lazy.nvim loads, because any mapping a plugin
-- spec declares with `<leader>` is resolved at definition time.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require "configs.options"
require "configs.keymaps"
require "configs.autocmds"
require "configs.lazy"
