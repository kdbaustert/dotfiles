-- Makes `:colorscheme voltage` work. LunarVim finds this through
-- `nvim_get_runtime_file("colors/voltage.*")`, which is why the config
-- directory has to be the one on the runtimepath — see the note in config.lua
-- about `~/.config/lvim` being a symlink into this repo.
--
-- All the actual color decisions live in lua/voltage/init.lua.

vim.cmd.highlight "clear"

if vim.fn.exists "syntax_on" == 1 then
  vim.cmd.syntax "reset"
end

vim.o.background = "dark"
vim.g.colors_name = "voltage"

-- Reload from disk rather than the module cache: without this, editing the
-- palette and re-sourcing this file would repaint with the colors that were
-- loaded at startup, which is a confusing way to lose ten minutes.
package.loaded["voltage"] = nil
package.loaded["voltage.palette"] = nil

require("voltage").apply()
