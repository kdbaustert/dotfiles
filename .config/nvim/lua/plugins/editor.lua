-- The small things: file editing, git signs, keybinding discovery, brackets,
-- indent guides. One file because none of them need more than a spec.

return {
  -- oil.nvim — the filesystem as an editable buffer.
  --
  -- Not the file *browser*: that is the always-open sidebar in
  -- lua/plugins/filetree.lua. This is the other half of the job — renaming
  -- twenty files with `:%s` and a write, which neither a tree nor yazi can do.
  -- It keeps netrw (the tree explicitly does not take it) so that `:e some/dir`
  -- lands in an editable buffer rather than a sidebar.
  {
    "stevearc/oil.nvim",
    lazy = false, -- it takes over netrw, which has to happen before a dir opens
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {
      default_file_explorer = true,
      delete_to_trash = true, -- macOS Trash, so a bad :w is recoverable
      skip_confirm_for_simple_edits = true,
      view_options = { show_hidden = true },
      float = { padding = 4, border = "rounded" },
      keymaps = {
        ["q"] = "actions.close",
        ["<Esc>"] = "actions.close",
      },
    },
  },

  -- gitsigns — the gutter, plus hunk staging without leaving the buffer.
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
      on_attach = function(buf)
        local gs = require "gitsigns"
        local function map(keys, fn, desc)
          vim.keymap.set("n", keys, fn, { buffer = buf, desc = "Git: " .. desc })
        end

        map("]h", function()
          gs.nav_hunk "next"
        end, "Next hunk")
        map("[h", function()
          gs.nav_hunk "prev"
        end, "Previous hunk")
        map("<leader>hs", gs.stage_hunk, "Stage hunk")
        map("<leader>hr", gs.reset_hunk, "Reset hunk")
        map("<leader>hp", gs.preview_hunk, "Preview hunk")
        map("<leader>hb", gs.blame_line, "Blame line")
        map("<leader>hd", gs.diffthis, "Diff this")
        map("<leader>ht", gs.toggle_current_line_blame, "Toggle line blame")
      end,
    },
  },

  -- which-key — shows what a half-typed prefix can still become.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      win = { border = "rounded" },
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>e", group = "explorer" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hunk" },
        { "<leader>x", group = "diagnostics" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show { global = false }
        end,
        desc = "Buffer keymaps",
      },
    },
  },

  -- Brackets and quotes. mini.pairs over nvim-autopairs: same behaviour, one
  -- file, and it already knows not to pair inside strings and comments.
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    opts = {
      modes = { insert = true, command = false, terminal = false },
    },
  },

  -- Surround: `gsa`/`gsd`/`gsr` to add, delete and replace quotes and tags.
  {
    "echasnovski/mini.surround",
    keys = { "gs" },
    opts = { mappings = { add = "gsa", delete = "gsd", replace = "gsr" } },
  },

  -- Indent guides. Scope-aware, which is the only part that earns its keep in
  -- deeply nested Vue templates.
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│", tab_char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = {
        filetypes = { "help", "checkhealth", "lazy", "mason", "oil", "markdown", "" },
      },
    },
  },

  -- Highlight and list TODO/FIXME/NOTE. The comments in this repo lean on
  -- these markers, so making them findable costs one plugin.
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Todos" },
    },
  },
}
