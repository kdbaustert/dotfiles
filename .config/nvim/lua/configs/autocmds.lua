-- Autocommands. Each gets its own group so re-sourcing this file replaces the
-- previous definitions rather than stacking a second copy on top.

local function group(name)
  return vim.api.nvim_create_augroup("configs_" .. name, { clear = true })
end

-- Flash what was just yanked. The only reliable feedback that a motion grabbed
-- what you meant it to, short of looking at the register.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group "yank",
  callback = function()
    vim.hl.on_yank { higroup = "Visual", timeout = 150 }
  end,
})

-- Reopen a file where it was left. Skipped for commit messages, where the
-- previous position is from an unrelated commit and always wrong.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group "last_position",
  callback = function(args)
    local exclude = { "gitcommit", "gitrebase", "help" }
    if vim.tbl_contains(exclude, vim.bo[args.buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close throwaway windows with a bare `q`, so they never need :bdelete.
vim.api.nvim_create_autocmd("FileType", {
  group = group "close_with_q",
  pattern = { "help", "man", "qf", "checkhealth", "lspinfo", "startuptime", "query" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = args.buf, silent = true })
  end,
})

-- Create the parent directory on write, rather than failing with E212 on a
-- path that doesn't exist yet.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group "mkdir",
  callback = function(args)
    if args.match:match "^%w%w+://" then
      return -- a URL-ish buffer (oil://, fugitive://); not ours to create
    end
    vim.fn.mkdir(vim.fn.fnamemodify(vim.uv.fs_realpath(args.match) or args.match, ":p:h"), "p")
  end,
})

-- Trailing whitespace is shown by `listchars` everywhere, but highlighting it
-- while typing the line you are on is just noise.
vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
  group = group "list_in_insert",
  callback = function(args)
    vim.opt_local.list = args.event == "InsertLeave"
  end,
})

-- Prose gets spellcheck and no ruler; code gets the reverse.
vim.api.nvim_create_autocmd("FileType", {
  group = group "prose",
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
  end,
})

-- Terminal buffers are not files: no numbers, no sign column, no spell.
vim.api.nvim_create_autocmd("TermOpen", {
  group = group "terminal",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.spell = false
  end,
})

-- Equalise splits when the terminal window itself is resized, so a Ghostty
-- resize doesn't leave one pane two columns wide.
vim.api.nvim_create_autocmd("VimResized", {
  group = group "resize",
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    vim.cmd "tabdo wincmd ="
    vim.api.nvim_set_current_tabpage(tab)
  end,
})

-- zsh files in this repo are frequently named `.zsh` but are sourced by an
-- interactive zsh, so treat the whole family as zsh rather than sh.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = group "zsh",
  pattern = { ".zshrc", ".zshenv", ".zprofile", "*.zsh" },
  callback = function(args)
    vim.bo[args.buf].filetype = "zsh"
  end,
})
