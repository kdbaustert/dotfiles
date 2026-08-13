-- lazy.nvim bootstrap and setup.
--
-- lazy is not vendored: it clones itself on first launch, then pins every
-- plugin through lazy-lock.json, which IS tracked in this repo. So a fresh box
-- needs no vendored runtime, and `:Lazy restore` reproduces the exact plugin
-- set that was last known to work.

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup {
  -- Every file under lua/plugins returns a spec; lazy imports them all rather
  -- than requiring a manual list to keep in sync.
  spec = { { import = "plugins" } },

  install = {
    -- What to load while plugins are still installing on first launch. Voltage
    -- is the local directory, so it is present before anything is cloned.
    colorscheme = { "voltage", "habamax" },
  },

  ui = { border = "rounded" },

  checker = {
    -- Check for updates but never apply them: the point of the tracked
    -- lockfile is that plugins move when this repo says so, not on a timer.
    enabled = true,
    notify = false,
    frequency = 60 * 60 * 24 * 7,
  },

  change_detection = { notify = false },

  performance = {
    rtp = {
      -- Neovim ships a lot of Vim-era runtime that nothing here replaces.
      -- `matchit` and `matchparen` are deliberately NOT in this list: no
      -- plugin here takes over `%` or bracket-match highlighting, and the
      -- colorscheme styles MatchParen on the assumption it still runs.
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
}

vim.keymap.set("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Lazy" })
