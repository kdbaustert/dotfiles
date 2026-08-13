-- Telescope: the fuzzy finder.
--
-- Note what it is NOT used for. fzf owns Ctrl-T/Ctrl-R at the shell, atuin
-- owns history, and yazi is the file manager — this is scoped to finding
-- things *inside the project you already have open*, which is the one job
-- none of those do from within the editor.

return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      -- The native sorter. `make` is the whole build; it is a prerequisite of
      -- the LunarVim install too, so it is present on any box this repo is on.
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable "make" == 1
      end,
    },
  },

  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
    { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Symbols" },
    { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search buffer" },
    { "<leader><leader>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
  },

  opts = function()
    local actions = require "telescope.actions"

    return {
      defaults = {
        prompt_prefix = "  ",
        selection_caret = " ",
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = { prompt_position = "top", preview_width = 0.55 },
          width = 0.9,
          height = 0.85,
        },
        -- rg is already installed and already tracks the terminal palette
        -- (themes/voltage.md), so the picker and the shell agree for free.
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "--glob=!.git/",
        },
        mappings = {
          i = {
            -- One <Esc> closes, rather than dropping to normal mode inside the
            -- prompt first. The prompt is not a buffer worth navigating.
            ["<Esc>"] = actions.close,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
          },
        },
      },

      pickers = {
        find_files = {
          -- Dotfiles are the point of this repo, so hidden files are findable;
          -- .git is still excluded because nothing in it is editable by hand.
          hidden = true,
          find_command = { "fd", "--type=f", "--hidden", "--exclude=.git" },
        },
      },

      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    }
  end,

  config = function(_, opts)
    local telescope = require "telescope"
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf") -- no-op if the build was skipped
  end,
}
