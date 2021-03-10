local wezterm = require 'wezterm';

return {
  font_dirs = {"fonts"},
  font = wezterm.font_with_fallback({
    "Hack Nerd Font",
    "JetBrainsMono Nerd Font Mono",
  }),
  font_size = 17.5,
  line_height = 1.0,
  window_background_opacity = 0.9,

  window_padding = {
    left = 2,
    right = 2,
    top = 0,
    bottom = 0,
  }
}