-- Mappings that belong to no plugin. Plugin mappings are declared in that
-- plugin's own spec via lazy's `keys =`, so they double as lazy-load triggers.
--
-- Leader is <Space>, matching .config/lvim — the two editors are different in
-- almost every other way, so the least they can do is not fight each other's
-- muscle memory.

local map = vim.keymap.set

-- Escape hatches
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Move by screen line when a line is wrapped — but only without a count, so
-- `5j` still means five real lines, which is what relativenumber is showing.
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Keep the cursor centered through big jumps. `scrolloff` can't do this,
-- because the landing point may be anywhere in the file.
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down, centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up, centered" })
map("n", "n", "nzzzv", { desc = "Next match, centered" })
map("n", "N", "Nzzzv", { desc = "Prev match, centered" })

-- Window navigation without the <C-w> prefix
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Resize with the arrows, since they are otherwise unused here
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Height +" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Height -" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Width -" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Width +" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Move the selection, reindenting as it goes
map("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Stay in visual mode when shifting, so it can be repeated
map("x", "<", "<gv", { desc = "Outdent" })
map("x", ">", ">gv", { desc = "Indent" })

-- Paste over a selection without losing the register to the thing replaced.
map("x", "p", [["_dP]], { desc = "Paste without yanking" })

-- Files
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })

-- Diagnostics. Both live under <leader>x: <leader>e is the explorer prefix
-- (lua/plugins/filetree.lua), and a single-key mapping that is also the start
-- of a longer one costs `timeoutlen` on every press.
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- lazygit is already installed and Voltage-themed (.config/lazygit), so the
-- useful thing here is reaching it without leaving the editor rather than
-- running a second git UI inside Neovim.
map("n", "<leader>gg", function()
  vim.cmd "tabnew"
  vim.cmd.terminal "lazygit"
  vim.cmd.startinsert()
  vim.b.lazygit = true
end, { desc = "Lazygit" })

-- <Esc> in a terminal buffer means "escape", not "send escape" — except in
-- lazygit, which needs the real key to back out of its own panels.
map("t", "<Esc>", function()
  return vim.b.lazygit and "<Esc>" or [[<C-\><C-n>]]
end, { expr = true, desc = "Leave terminal mode" })
