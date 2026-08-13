-- Completion.
--
-- blink.cmp rather than nvim-cmp: it does the fuzzy matching in a prebuilt
-- Rust binary it downloads itself, which matters because this box has no
-- cargo (see the LunarVim install prerequisites in README.MD) and because the
-- alternative is a Lua matcher that gets visibly slow in a large TypeScript
-- project. `version` pins to a release tag, which is what makes the prebuilt
-- binary available at all — a branch build would need to compile.

return {
  "saghen/blink.cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  version = "1.*",
  dependencies = { "rafamadriz/friendly-snippets" },

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- "default" is the Neovim-native feel: <C-y> accepts, <C-n>/<C-p> cycle,
    -- and Tab is left alone so it still indents. Snippet jumping keeps Tab
    -- only while a snippet is actually active.
    keymap = {
      preset = "default",
      ["<Tab>"] = { "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
    },

    appearance = {
      -- Tells blink which glyph set to measure, not which font to use — the
      -- terminal font is a Nerd Font (see the LunarVim install note).
      nerd_font_variant = "mono",
    },

    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = { border = "rounded" },
      },
      menu = {
        border = "rounded",
        draw = { treesitter = { "lsp" } }, -- colorise items like real code
      },
      -- Ghost text is off: with `auto_show` documentation already open, a
      -- third piece of speculative text in the buffer is one too many.
      ghost_text = { enabled = false },
    },

    signature = { enabled = true, window = { border = "rounded" } },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    -- Rust matcher. If the prebuilt binary is ever unavailable this is the one
    -- line to flip to "lua" — everything else keeps working.
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },

  opts_extend = { "sources.default" },
}
