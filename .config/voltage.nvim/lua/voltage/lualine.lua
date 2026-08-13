-- lualine theme.
--
-- Mode color doubles as the mode indicator here — the same trick starship uses
-- in `.config/starship.toml`, where the prompt character changes color instead
-- of growing a word. Magenta is normal (it matches the cursor, so "the editor
-- is idle and the cursor is yours"), and the louder colors mean you have
-- entered a mode that changes the buffer.

local p = require "voltage.palette"

-- `b` and `c` are shared by every mode: only section `a` reacts, so the
-- statusline changes one block on mode switch rather than the whole bar.
local b = { fg = p.fg, bg = p.sel }
local c = { fg = p.subtle, bg = p.bg_alt }

local function mode(color)
  return {
    a = { fg = p.bg, bg = color, gui = "bold" },
    b = b,
    c = c,
  }
end

return {
  normal = mode(p.magenta_br),
  insert = mode(p.green),
  visual = mode(p.cyan),
  replace = mode(p.red),
  command = mode(p.yellow),
  terminal = mode(p.orange),
  inactive = {
    a = { fg = p.subtle, bg = p.bg_alt },
    b = { fg = p.subtle, bg = p.bg_alt },
    c = { fg = p.black, bg = p.bg_alt },
  },
}
