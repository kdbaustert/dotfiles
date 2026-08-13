-- Voltage, as Lua. The authoritative table is themes/voltage.md at the root of
-- this repo; this file is a transcription of it and nothing here should be
-- tuned in isolation — the whole point of the palette is that every tool
-- agrees, so a color that looks better only inside Neovim is a bug.
--
-- Names match the roles in that document rather than the ANSI slot numbers,
-- because the highlight groups in voltage/init.lua are easier to read as
-- "keyword is magenta" than "keyword is slot 5".

return {
  -- Base
  bg = "#0F0D0E", -- warm near-black; Ghostty draws it at 75% + blur
  bg_alt = "#1C191A", -- sidebars, floats, the inactive half of a split
  sel = "#2A2427", -- selection/panel fill, lifted off bg_alt to stay visible
  black = "#393A3D", -- ANSI 0
  subtle = "#6B6B6B", -- ANSI 8 — comments, ghost text, borders
  fg = "#E7E7E7", -- ANSI 7 — body text
  white = "#F8F8F8", -- ANSI 15

  -- Accents, normal (0-7) and bright (8-15)
  red = "#FF4D5E",
  red_br = "#FF6B7A",
  green = "#B3E053",
  green_br = "#C6EE6E",
  yellow = "#F9E906",
  yellow_br = "#F8F079",
  blue = "#5CC9F5",
  blue_br = "#7FD8F8",
  magenta = "#EB43F4",
  magenta_br = "#F712FF",
  cyan = "#17D5DF",
  cyan_br = "#4EE3EC",

  -- Extras — not ANSI slots. `violet` is a fill color only: it is too dark on
  -- `bg` to set text in, so it is used behind glyphs and never as a foreground.
  orange = "#FF9A4D",
  violet = "#6638F0",
  accent = "#F712FF", -- cursor; same value as bright magenta
}
