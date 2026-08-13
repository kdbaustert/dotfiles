-- Statusline.
--
-- The theme is the shared Voltage table (.config/voltage.nvim/lua/voltage/
-- lualine.lua), the same one .config/lvim uses — so both editors have the same
-- statusline colors even though nothing else about them matches.

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      return {
        options = {
          theme = require "voltage.lualine",
          -- No powerline separators: the terminal font has the glyphs, but
          -- they only look right when the statusline background matches the
          -- section beside it, and `laststatus=3` breaks that assumption at
          -- the window edges.
          component_separators = "",
          section_separators = "",
          globalstatus = true, -- one bar, matching laststatus=3
          disabled_filetypes = { statusline = { "oil" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            { "diagnostics", symbols = { error = "󰅚 ", warn = "󰀪 ", info = "󰋽 ", hint = "󰌶 " } },
            { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "" } },
          },
          lualine_x = {
            -- Which formatter would run on this buffer. The quiet failure mode
            -- of format-on-save is "nothing happened and you didn't notice",
            -- so it is worth a few columns.
            {
              function()
                local ok, conform = pcall(require, "conform")
                if not ok then
                  return ""
                end
                local names = vim.tbl_map(function(f)
                  return f.name
                end, conform.list_formatters_to_run(0))
                return #names > 0 and ("󰉼 " .. table.concat(names, " ")) or ""
              end,
              cond = function()
                return not (vim.g.disable_autoformat or vim.b.disable_autoformat)
              end,
            },
            { "diff", symbols = { added = " ", modified = " ", removed = " " } },
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        extensions = { "lazy", "mason", "quickfix", "man" },
      }
    end,
  },
}
