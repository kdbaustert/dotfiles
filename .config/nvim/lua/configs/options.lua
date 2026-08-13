-- Editor settings that need no plugin. Anything a plugin owns lives with that
-- plugin's spec instead, so this file stays true even with lua/plugins deleted.

local opt = vim.opt

-- Lines and cursor
opt.number = true
opt.relativenumber = true -- relative jumps; the cursor line shows absolute
opt.cursorline = true
opt.scrolloff = 8 -- never park the cursor on the edge of the viewport
opt.sidescrolloff = 8
opt.signcolumn = "yes" -- always on, or the text shifts when a sign appears

-- Wrapping. On, because a lot of what gets opened here is prose — READMEs,
-- commit messages, Obsidian notes — and a hard cut mid-word is worse than a
-- soft one. `breakindent` keeps the continuation aligned with the list item or
-- indent it belongs to, which is what makes this bearable in code too.
opt.wrap = true
opt.linebreak = true
opt.breakindent = true

-- Indentation. .editorconfig at the repo root is the real authority for files
-- it covers; these are the fallback for everything else.
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true -- ...unless the pattern has a capital in it
opt.hlsearch = true
opt.incsearch = true

-- Splits open where the eye already is, rather than pushing the current window
-- around.
opt.splitright = true
opt.splitbelow = true

-- Files. Undo history outlives the buffer; swap and backup files do not exist,
-- because undofile plus git covers what they were for and neither leaves
-- droppings next to the source.
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- Timings
opt.updatetime = 250 -- CursorHold delay: gitsigns blame, diagnostic float
opt.timeoutlen = 400 -- how long which-key waits before showing itself
opt.ttimeoutlen = 10 -- how long <Esc> takes to be recognised as itself

-- Completion menu behaviour: never auto-insert, always show the menu even for
-- one match, so the choice is always explicit.
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 12

-- Appearance
opt.termguicolors = true
opt.showmode = false -- lualine already says what mode this is
opt.laststatus = 3 -- one statusline for the whole window, not one per split
opt.conceallevel = 0 -- show markdown syntax rather than hiding it
opt.fillchars = { eob = " " } -- no ~ on lines past the end of the buffer
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- make the invisible visible

-- Behaviour
opt.mouse = "a"
opt.clipboard = "unnamedplus" -- share the system clipboard
opt.confirm = true -- prompt on :q with unsaved changes instead of failing
opt.splitkeep = "screen" -- don't scroll the text when a split opens
opt.virtualedit = "block" -- let visual block select past end of line
opt.inccommand = "split" -- live preview of :s, with the off-screen hits listed

-- Shell scripts here are zsh (see zsh/ and .zshrc), but a bare `.sh` extension
-- makes Neovim guess `sh`. This makes the guess match the repo.
vim.g.is_posix = 1
