-- Voltage, loaded from the shared directory rather than copied in.
--
-- `dir` makes lazy treat a local path as a plugin: no clone, no lockfile
-- entry, and edits to the palette take effect on the next start. The same
-- directory is on LunarVim's runtimepath (.config/lvim/config.lua), which is
-- the entire reason it lives outside both configs — see themes/voltage.md.
--
-- priority 1000 + lazy=false because everything else styles itself against
-- whatever scheme is already loaded; a colorscheme that arrives late leaves
-- half the UI painted by the default.

return {
  dir = vim.fn.expand "~/.config/voltage.nvim",
  name = "voltage",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme "voltage"
  end,
}
