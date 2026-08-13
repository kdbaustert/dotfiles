-- nvim-tree — the always-open sidebar.
--
-- Chosen over neo-tree because the Voltage colorscheme already spells out the
-- full NvimTree* group set (it was written for LunarVim, which ships this same
-- tree), so both editors get an identical sidebar with no second transcription
-- of the palette. See themes/voltage.md.
--
-- It does NOT take over netrw: oil.nvim owns that (lua/plugins/editor.lua), and
-- both hijacking it means whichever loads last wins. The two split cleanly —
-- this is for seeing where you are, oil is for editing the filesystem as text.
--
-- `lazy = false` is forced by the requirement: a sidebar that opens on demand
-- can be lazy, one that is always present cannot.

local function is_tree(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].filetype == "NvimTree"
end

return {
  "nvim-tree/nvim-tree.lua",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },

  keys = {
    { "<leader>ee", "<cmd>NvimTreeToggle<CR>", desc = "Toggle tree" },
    { "<leader>ef", "<cmd>NvimTreeFindFile<CR>", desc = "Reveal file in tree" },
    { "<leader>ec", "<cmd>NvimTreeCollapse<CR>", desc = "Collapse tree" },
  },

  opts = {
    hijack_netrw = false, -- oil has it
    disable_netrw = false,
    hijack_cursor = true, -- keep the cursor on the filename, not column 0
    sync_root_with_cwd = true,
    respect_buf_cwd = true,

    -- Follow the buffer you are actually in. `update_root` stays off: jumping
    -- to a file outside the project (a plugin's source, a system header)
    -- should not silently re-root the whole tree there.
    update_focused_file = { enable = true, update_root = false },

    view = {
      width = 34,
      side = "left",
      preserve_window_proportions = true, -- don't reflow splits on open/close
      signcolumn = "no",
    },

    renderer = {
      group_empty = true, -- collapse a/b/c chains into one line
      highlight_git = "name",
      highlight_opened_files = "name",
      indent_markers = { enable = true },
      root_folder_label = ":~:s?$??",
    },

    -- Dotfiles are the entire subject of this repo, so they are visible. .git
    -- is hidden because nothing in it is editable by hand, and node_modules
    -- because it is never what you are looking for.
    filters = {
      dotfiles = false,
      git_ignored = false,
      custom = { "^\\.git$", "^node_modules$", "^\\.DS_Store$" },
    },

    git = { enable = true, ignore = false },
    diagnostics = {
      enable = true,
      show_on_dirs = true,
      icons = { hint = "󰌶", info = "󰋽", warning = "󰀪", error = "󰅚" },
    },

    actions = {
      open_file = {
        quit_on_open = false, -- the whole point is that it stays
        resize_window = false,
      },
    },
  },

  config = function(_, opts)
    require("nvim-tree").setup(opts)

    local api = require "nvim-tree.api"
    local group = vim.api.nvim_create_augroup("configs_nvim_tree", { clear = true })

    -- Open on start, and hand focus straight back — the sidebar is context,
    -- not where the work happens.
    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      callback = function(data)
        -- Skip the cases where a sidebar is actively wrong: nvim as $EDITOR
        -- for a commit message, `git difftool`, reading a pipe on stdin, or a
        -- man page. Opening a tree next to a commit buffer is the fastest way
        -- to regret setting this up.
        if vim.o.diff or vim.bo[data.buf].filetype == "gitcommit" or vim.bo[data.buf].filetype == "gitrebase" then
          return
        end
        if vim.bo[data.buf].buftype ~= "" and vim.bo[data.buf].buftype ~= "nofile" then
          return
        end

        -- Open, then put the cursor back where it was. `tree.open{focus=false}`
        -- does not reliably keep focus off the sidebar, and landing in the
        -- tree on every start means the first keystroke of the day goes to the
        -- wrong window. Restoring the window explicitly is unambiguous.
        --
        -- This covers the directory case too: `nvim some/dir` leaves oil in
        -- the main window with the tree beside it, which is the same shape.
        local origin = vim.api.nvim_get_current_win()
        api.tree.open { focus = false }

        if vim.api.nvim_win_is_valid(origin) then
          vim.api.nvim_set_current_win(origin)
        end
      end,
    })

    -- Never let the tree be the reason Neovim stays open.
    --
    -- This deliberately hooks WinClosed and defers, rather than the QuitPre
    -- recipe that is usually posted for this. Closing or tearing down the tree
    -- *inside* QuitPre wedges Neovim: the quit is already in progress, and
    -- both `nvim_win_close` and nvim-tree's own `tree.close()` hang `:q` and
    -- `:qa` outright. WinClosed fires after the window is gone, and the
    -- schedule puts the check outside the autocmd entirely, so by the time it
    -- runs this is an ordinary quit with nothing in flight.
    -- The latch matters as much as the deferral: `qall` closes the tree
    -- window, which fires WinClosed again and schedules another `qall`. Once
    -- the decision to quit is made it must only be made once.
    local quitting = false

    vim.api.nvim_create_autocmd("WinClosed", {
      group = group,
      callback = function()
        if quitting then
          return
        end

        vim.schedule(function()
          if quitting then
            return
          end

          local trees, others = 0, 0
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_config(win).relative == "" then
              if is_tree(win) then
                trees = trees + 1
              else
                others = others + 1
              end
            end
          end

          if trees > 0 and others == 0 then
            quitting = true
            vim.cmd "qall"
          end
        end)
      end,
    })
  end,
}
