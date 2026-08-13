-- The Voltage colorscheme for Neovim.
--
-- Written by hand rather than reusing an existing dark theme, for the same
-- reason every other row in the "Where it's applied" table of
-- themes/voltage.md exists: the tools have to agree. LunarVim's default
-- (`lunar`) is a perfectly good scheme, it just isn't this one, and an editor
-- filling most of the screen is the worst place to let the palette drift.
--
-- Neovim is not one of the tools that can track the terminal for free. It sets
-- `termguicolors`, so it emits 24-bit hex and resolves nothing through the
-- Ghostty palette — which is why this file spells out every group instead of
-- leaning on ANSI indices the way rg, git and jq do.
--
-- Entry point is colors/voltage.lua; this module only knows how to paint.

local p = require "voltage.palette"

local M = {}

-- Deliberately close to the ANSI set: `:terminal` buffers and anything drawing
-- through them (lazygit, the toggleterm splits) resolve through these, so they
-- are the one place Neovim *can* hand color decisions back to the palette.
local terminal_colors = {
  p.black,
  p.red,
  p.green,
  p.yellow,
  p.blue,
  p.magenta,
  p.cyan,
  p.fg,
  p.subtle,
  p.red_br,
  p.green_br,
  p.yellow_br,
  p.blue_br,
  p.magenta_br,
  p.cyan_br,
  p.white,
}

local groups = {
  ---------------------------------------------------------------------------
  -- Editor chrome
  ---------------------------------------------------------------------------
  Normal = { fg = p.fg, bg = p.bg },
  -- Kept opaque on purpose. Ghostty already draws the window at 75% with a
  -- blur; a transparent Normal would stack a second layer of backdrop under
  -- the text and cost more contrast than it buys.
  NormalNC = { fg = p.fg, bg = p.bg },
  NormalFloat = { fg = p.fg, bg = p.bg_alt },
  FloatBorder = { fg = p.subtle, bg = p.bg_alt },
  FloatTitle = { fg = p.magenta_br, bg = p.bg_alt, bold = true },

  Cursor = { fg = p.bg, bg = p.accent },
  lCursor = { link = "Cursor" },
  CursorIM = { link = "Cursor" },
  TermCursor = { link = "Cursor" },
  CursorLine = { bg = p.bg_alt },
  CursorColumn = { bg = p.bg_alt },
  ColorColumn = { bg = p.bg_alt },
  CursorLineNr = { fg = p.magenta_br, bold = true },
  LineNr = { fg = p.black },
  -- `signcolumn=yes` is always on, so this has to match Normal exactly or the
  -- gutter reads as a separate, slightly-off panel.
  SignColumn = { fg = p.subtle, bg = p.bg },
  FoldColumn = { fg = p.black, bg = p.bg },
  Folded = { fg = p.subtle, bg = p.sel },

  WinSeparator = { fg = p.black, bg = p.bg },
  VertSplit = { link = "WinSeparator" },

  Visual = { bg = p.sel },
  VisualNOS = { bg = p.sel },
  Search = { fg = p.bg, bg = p.yellow },
  IncSearch = { fg = p.bg, bg = p.accent },
  CurSearch = { fg = p.bg, bg = p.accent },
  Substitute = { fg = p.bg, bg = p.red },
  MatchParen = { fg = p.accent, bold = true },

  Pmenu = { fg = p.fg, bg = p.bg_alt },
  PmenuSel = { fg = p.white, bg = p.sel, bold = true },
  PmenuSbar = { bg = p.bg_alt },
  PmenuThumb = { bg = p.black },
  WildMenu = { link = "PmenuSel" },

  StatusLine = { fg = p.fg, bg = p.bg_alt },
  StatusLineNC = { fg = p.subtle, bg = p.bg_alt },
  TabLine = { fg = p.subtle, bg = p.bg_alt },
  TabLineFill = { bg = p.bg },
  TabLineSel = { fg = p.white, bg = p.sel, bold = true },
  WinBar = { fg = p.subtle, bg = p.bg },
  WinBarNC = { fg = p.black, bg = p.bg },

  Directory = { fg = p.blue },
  Title = { fg = p.magenta_br, bold = true },
  Question = { fg = p.green },
  MoreMsg = { fg = p.green },
  ModeMsg = { fg = p.fg, bold = true },
  MsgArea = { fg = p.fg },
  MsgSeparator = { fg = p.black },
  ErrorMsg = { fg = p.red },
  WarningMsg = { fg = p.yellow },
  NonText = { fg = p.black },
  Whitespace = { fg = p.black },
  SpecialKey = { fg = p.black },
  EndOfBuffer = { fg = p.bg },
  Conceal = { fg = p.subtle },
  QuickFixLine = { bg = p.sel, bold = true },
  -- `winblend`/`pumblend` stay at 0 (see config.lua), so this only ever shows
  -- up behind genuinely dimmed regions like an inactive `:h ins-completion`.
  NormalSB = { fg = p.fg, bg = p.bg_alt },

  ---------------------------------------------------------------------------
  -- Diff and spell
  ---------------------------------------------------------------------------
  DiffAdd = { fg = p.green, bg = p.bg_alt },
  DiffChange = { fg = p.yellow, bg = p.bg_alt },
  DiffDelete = { fg = p.red, bg = p.bg_alt },
  DiffText = { fg = p.bg, bg = p.yellow },
  Added = { fg = p.green },
  Changed = { fg = p.yellow },
  Removed = { fg = p.red },

  SpellBad = { sp = p.red, undercurl = true },
  SpellCap = { sp = p.yellow, undercurl = true },
  SpellLocal = { sp = p.cyan, undercurl = true },
  SpellRare = { sp = p.magenta, undercurl = true },

  ---------------------------------------------------------------------------
  -- Vim syntax. Treesitter handles most real editing, but these still back
  -- filetypes without a parser installed, and every @group below falls back
  -- here when a capture is missing.
  ---------------------------------------------------------------------------
  Comment = { fg = p.subtle, italic = true },

  Constant = { fg = p.orange },
  String = { fg = p.green },
  Character = { fg = p.green },
  Number = { fg = p.orange },
  Boolean = { fg = p.orange },
  Float = { fg = p.orange },

  Identifier = { fg = p.fg },
  Function = { fg = p.blue },

  Statement = { fg = p.magenta },
  Conditional = { fg = p.magenta },
  Repeat = { fg = p.magenta },
  Label = { fg = p.yellow },
  Operator = { fg = p.cyan },
  Keyword = { fg = p.magenta },
  Exception = { fg = p.magenta },

  PreProc = { fg = p.magenta_br },
  Include = { fg = p.magenta_br },
  Define = { fg = p.magenta_br },
  Macro = { fg = p.magenta_br },
  PreCondit = { fg = p.magenta_br },

  Type = { fg = p.yellow_br },
  StorageClass = { fg = p.yellow_br },
  Structure = { fg = p.yellow_br },
  Typedef = { fg = p.yellow_br },

  Special = { fg = p.red_br },
  SpecialChar = { fg = p.red_br },
  Tag = { fg = p.magenta },
  Delimiter = { fg = p.subtle },
  SpecialComment = { fg = p.cyan, italic = true },
  Debug = { fg = p.orange },

  Underlined = { underline = true },
  Bold = { bold = true },
  Italic = { italic = true },
  Ignore = { fg = p.black },
  Error = { fg = p.red },
  Todo = { fg = p.bg, bg = p.yellow, bold = true },

  ---------------------------------------------------------------------------
  -- Treesitter
  ---------------------------------------------------------------------------
  ["@variable"] = { fg = p.fg },
  ["@variable.builtin"] = { fg = p.red, italic = true }, -- $this, self, super
  ["@variable.parameter"] = { fg = p.orange },
  ["@variable.member"] = { fg = p.blue_br }, -- struct/object fields
  ["@property"] = { fg = p.blue_br },

  ["@constant"] = { fg = p.orange },
  ["@constant.builtin"] = { fg = p.orange, bold = true },
  ["@constant.macro"] = { fg = p.magenta_br },

  ["@module"] = { fg = p.cyan },
  ["@module.builtin"] = { fg = p.cyan, bold = true },
  ["@namespace"] = { fg = p.cyan },
  ["@label"] = { fg = p.yellow },

  ["@string"] = { fg = p.green },
  ["@string.documentation"] = { fg = p.green, italic = true },
  ["@string.escape"] = { fg = p.red_br },
  ["@string.regexp"] = { fg = p.cyan_br },
  ["@string.special"] = { fg = p.red_br },
  ["@string.special.url"] = { fg = p.cyan, underline = true },
  ["@character"] = { fg = p.green },
  ["@character.special"] = { fg = p.red_br },
  ["@number"] = { fg = p.orange },
  ["@number.float"] = { fg = p.orange },
  ["@boolean"] = { fg = p.orange },

  ["@function"] = { fg = p.blue },
  ["@function.builtin"] = { fg = p.cyan_br },
  ["@function.call"] = { fg = p.blue },
  ["@function.method"] = { fg = p.blue },
  ["@function.method.call"] = { fg = p.blue },
  ["@function.macro"] = { fg = p.magenta_br },
  ["@constructor"] = { fg = p.cyan },
  ["@operator"] = { fg = p.cyan },

  ["@keyword"] = { fg = p.magenta },
  ["@keyword.function"] = { fg = p.magenta },
  ["@keyword.operator"] = { fg = p.magenta },
  ["@keyword.return"] = { fg = p.magenta, bold = true },
  ["@keyword.import"] = { fg = p.magenta_br },
  ["@keyword.exception"] = { fg = p.magenta },
  ["@keyword.conditional"] = { fg = p.magenta },
  ["@keyword.repeat"] = { fg = p.magenta },
  ["@keyword.directive"] = { fg = p.magenta_br },

  -- Punctuation carries no meaning, so it is deliberately the dimmest thing
  -- on screen that is still text — brackets slightly above delimiters so
  -- nesting stays traceable.
  ["@punctuation.delimiter"] = { fg = p.subtle },
  ["@punctuation.bracket"] = { fg = p.fg },
  ["@punctuation.special"] = { fg = p.red_br },

  ["@comment"] = { fg = p.subtle, italic = true },
  ["@comment.todo"] = { fg = p.bg, bg = p.yellow, bold = true },
  ["@comment.note"] = { fg = p.bg, bg = p.cyan, bold = true },
  ["@comment.warning"] = { fg = p.bg, bg = p.orange, bold = true },
  ["@comment.error"] = { fg = p.bg, bg = p.red, bold = true },

  ["@type"] = { fg = p.yellow_br },
  ["@type.builtin"] = { fg = p.yellow_br, italic = true },
  ["@type.definition"] = { fg = p.yellow_br },
  ["@attribute"] = { fg = p.yellow },

  -- Markup: Obsidian notes and this repo's own READMEs get read in here, so
  -- markdown is worth styling properly rather than leaving on defaults.
  ["@markup.heading"] = { fg = p.magenta_br, bold = true },
  ["@markup.heading.1"] = { fg = p.magenta_br, bold = true },
  ["@markup.heading.2"] = { fg = p.cyan, bold = true },
  ["@markup.heading.3"] = { fg = p.green, bold = true },
  ["@markup.heading.4"] = { fg = p.yellow, bold = true },
  ["@markup.heading.5"] = { fg = p.orange, bold = true },
  ["@markup.heading.6"] = { fg = p.subtle, bold = true },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },
  ["@markup.strikethrough"] = { strikethrough = true },
  ["@markup.underline"] = { underline = true },
  ["@markup.quote"] = { fg = p.subtle, italic = true },
  ["@markup.math"] = { fg = p.cyan },
  ["@markup.link"] = { fg = p.cyan },
  ["@markup.link.label"] = { fg = p.blue },
  ["@markup.link.url"] = { fg = p.cyan, underline = true },
  ["@markup.raw"] = { fg = p.green },
  ["@markup.raw.block"] = { fg = p.green },
  ["@markup.list"] = { fg = p.magenta },
  ["@markup.list.checked"] = { fg = p.green },
  ["@markup.list.unchecked"] = { fg = p.subtle },

  ["@diff.plus"] = { fg = p.green },
  ["@diff.minus"] = { fg = p.red },
  ["@diff.delta"] = { fg = p.yellow },

  -- Vue/Blade/HTML. Tags share the keyword color so that markup reads with
  -- the same weight as control flow does in the script block beside it.
  ["@tag"] = { fg = p.magenta },
  ["@tag.builtin"] = { fg = p.magenta },
  ["@tag.attribute"] = { fg = p.yellow },
  ["@tag.delimiter"] = { fg = p.subtle },

  ---------------------------------------------------------------------------
  -- LSP semantic tokens. These land on top of treesitter, so anything not
  -- linked here silently overrides the block above.
  ---------------------------------------------------------------------------
  ["@lsp.type.class"] = { link = "@type" },
  ["@lsp.type.comment"] = {}, -- treesitter's comment capture is better
  ["@lsp.type.decorator"] = { link = "@attribute" },
  ["@lsp.type.enum"] = { link = "@type" },
  ["@lsp.type.enumMember"] = { link = "@constant" },
  ["@lsp.type.function"] = { link = "@function" },
  ["@lsp.type.interface"] = { link = "@type" },
  ["@lsp.type.macro"] = { link = "@function.macro" },
  ["@lsp.type.method"] = { link = "@function.method" },
  ["@lsp.type.namespace"] = { link = "@module" },
  ["@lsp.type.parameter"] = { link = "@variable.parameter" },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.struct"] = { link = "@type" },
  ["@lsp.type.type"] = { link = "@type" },
  ["@lsp.type.typeParameter"] = { link = "@type.definition" },
  ["@lsp.type.variable"] = {}, -- defer to treesitter; the LSP over-claims
  ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
  ["@lsp.typemod.variable.readonly"] = { link = "@constant" },

  ---------------------------------------------------------------------------
  -- Diagnostics
  ---------------------------------------------------------------------------
  DiagnosticError = { fg = p.red },
  DiagnosticWarn = { fg = p.yellow },
  DiagnosticInfo = { fg = p.blue },
  DiagnosticHint = { fg = p.cyan },
  DiagnosticOk = { fg = p.green },

  -- Virtual text is dimmed relative to the sign: it sits inline with code and
  -- at full saturation it competes with the line it is describing.
  DiagnosticVirtualTextError = { fg = p.red, bg = p.bg_alt },
  DiagnosticVirtualTextWarn = { fg = p.yellow, bg = p.bg_alt },
  DiagnosticVirtualTextInfo = { fg = p.blue, bg = p.bg_alt },
  DiagnosticVirtualTextHint = { fg = p.cyan, bg = p.bg_alt },

  DiagnosticUnderlineError = { sp = p.red, undercurl = true },
  DiagnosticUnderlineWarn = { sp = p.yellow, undercurl = true },
  DiagnosticUnderlineInfo = { sp = p.blue, undercurl = true },
  DiagnosticUnderlineHint = { sp = p.cyan, undercurl = true },

  DiagnosticSignError = { fg = p.red, bg = p.bg },
  DiagnosticSignWarn = { fg = p.yellow, bg = p.bg },
  DiagnosticSignInfo = { fg = p.blue, bg = p.bg },
  DiagnosticSignHint = { fg = p.cyan, bg = p.bg },

  DiagnosticDeprecated = { sp = p.subtle, strikethrough = true },
  DiagnosticUnnecessary = { fg = p.subtle },

  LspReferenceText = { bg = p.sel },
  LspReferenceRead = { bg = p.sel },
  LspReferenceWrite = { bg = p.sel, underline = true },
  LspInlayHint = { fg = p.black, bg = p.bg_alt, italic = true },
  LspSignatureActiveParameter = { fg = p.accent, bold = true },
  LspCodeLens = { fg = p.subtle, italic = true },

  ---------------------------------------------------------------------------
  -- Plugins LunarVim ships. Each of these draws its own windows, and without
  -- explicit groups they inherit whichever scheme loaded last.
  ---------------------------------------------------------------------------
  GitSignsAdd = { fg = p.green, bg = p.bg },
  GitSignsChange = { fg = p.yellow, bg = p.bg },
  GitSignsDelete = { fg = p.red, bg = p.bg },
  GitSignsCurrentLineBlame = { fg = p.black, italic = true },

  TelescopeNormal = { fg = p.fg, bg = p.bg_alt },
  TelescopeBorder = { fg = p.subtle, bg = p.bg_alt },
  TelescopeTitle = { fg = p.bg, bg = p.magenta_br, bold = true },
  TelescopePromptNormal = { fg = p.fg, bg = p.sel },
  TelescopePromptBorder = { fg = p.sel, bg = p.sel },
  TelescopePromptTitle = { fg = p.bg, bg = p.accent, bold = true },
  TelescopePromptPrefix = { fg = p.accent },
  TelescopePromptCounter = { fg = p.subtle },
  TelescopeResultsTitle = { fg = p.bg_alt, bg = p.bg_alt },
  TelescopePreviewTitle = { fg = p.bg, bg = p.green, bold = true },
  TelescopeSelection = { fg = p.white, bg = p.sel, bold = true },
  TelescopeSelectionCaret = { fg = p.accent, bg = p.sel },
  TelescopeMatching = { fg = p.accent, bold = true },
  TelescopeMultiSelection = { fg = p.cyan },

  NvimTreeNormal = { fg = p.fg, bg = p.bg_alt },
  NvimTreeNormalNC = { fg = p.fg, bg = p.bg_alt },
  NvimTreeWinSeparator = { fg = p.bg_alt, bg = p.bg_alt },
  NvimTreeEndOfBuffer = { fg = p.bg_alt },
  NvimTreeRootFolder = { fg = p.magenta_br, bold = true },
  NvimTreeFolderName = { fg = p.blue },
  NvimTreeOpenedFolderName = { fg = p.blue_br, bold = true },
  NvimTreeEmptyFolderName = { fg = p.subtle },
  NvimTreeFolderIcon = { fg = p.blue },
  NvimTreeSymlink = { fg = p.cyan, italic = true },
  NvimTreeExecFile = { fg = p.green, bold = true },
  NvimTreeSpecialFile = { fg = p.yellow, underline = true },
  NvimTreeImageFile = { fg = p.magenta },
  NvimTreeOpenedFile = { fg = p.white, bold = true },
  NvimTreeCursorLine = { bg = p.sel },
  NvimTreeIndentMarker = { fg = p.black },
  NvimTreeGitDirty = { fg = p.yellow },
  NvimTreeGitStaged = { fg = p.green },
  NvimTreeGitMerge = { fg = p.orange },
  NvimTreeGitRenamed = { fg = p.cyan },
  NvimTreeGitNew = { fg = p.green_br },
  NvimTreeGitDeleted = { fg = p.red },

  BufferLineFill = { bg = p.bg_alt },
  BufferLineBackground = { fg = p.subtle, bg = p.bg_alt },
  BufferLineBufferSelected = { fg = p.white, bg = p.bg, bold = true, italic = false },
  BufferLineBufferVisible = { fg = p.fg, bg = p.bg_alt },
  BufferLineIndicatorSelected = { fg = p.accent, bg = p.bg },
  BufferLineSeparator = { fg = p.bg_alt, bg = p.bg_alt },
  BufferLineSeparatorSelected = { fg = p.bg_alt, bg = p.bg },
  BufferLineModified = { fg = p.yellow, bg = p.bg_alt },
  BufferLineModifiedSelected = { fg = p.yellow, bg = p.bg },
  BufferLineCloseButtonSelected = { fg = p.red, bg = p.bg },

  -- Completion menu. Kind icons reuse the syntax color of the thing they
  -- stand for, so the popup and the buffer under it say the same thing.
  CmpItemAbbr = { fg = p.fg },
  CmpItemAbbrDeprecated = { fg = p.subtle, strikethrough = true },
  CmpItemAbbrMatch = { fg = p.accent, bold = true },
  CmpItemAbbrMatchFuzzy = { fg = p.accent },
  CmpItemMenu = { fg = p.subtle, italic = true },
  CmpItemKindDefault = { fg = p.fg },
  CmpItemKindText = { fg = p.fg },
  CmpItemKindVariable = { fg = p.fg },
  CmpItemKindFunction = { fg = p.blue },
  CmpItemKindMethod = { fg = p.blue },
  CmpItemKindConstructor = { fg = p.cyan },
  CmpItemKindClass = { fg = p.yellow_br },
  CmpItemKindInterface = { fg = p.yellow_br },
  CmpItemKindStruct = { fg = p.yellow_br },
  CmpItemKindEnum = { fg = p.yellow_br },
  CmpItemKindEnumMember = { fg = p.orange },
  CmpItemKindConstant = { fg = p.orange },
  CmpItemKindValue = { fg = p.orange },
  CmpItemKindField = { fg = p.blue_br },
  CmpItemKindProperty = { fg = p.blue_br },
  CmpItemKindKeyword = { fg = p.magenta },
  CmpItemKindSnippet = { fg = p.green },
  CmpItemKindModule = { fg = p.cyan },
  CmpItemKindFile = { fg = p.blue },
  CmpItemKindFolder = { fg = p.blue },
  CmpItemKindColor = { fg = p.magenta },

  WhichKey = { fg = p.accent, bold = true },
  WhichKeyGroup = { fg = p.blue },
  WhichKeyDesc = { fg = p.fg },
  WhichKeySeparator = { fg = p.subtle },
  WhichKeyFloat = { bg = p.bg_alt },
  WhichKeyBorder = { fg = p.subtle, bg = p.bg_alt },
  WhichKeyValue = { fg = p.subtle },

  IblIndent = { fg = p.black },
  IblScope = { fg = p.violet },
  IndentBlanklineChar = { fg = p.black },
  IndentBlanklineContextChar = { fg = p.violet },

  IlluminatedWordText = { bg = p.sel },
  IlluminatedWordRead = { bg = p.sel },
  IlluminatedWordWrite = { bg = p.sel, underline = true },

  AlphaHeader = { fg = p.magenta_br },
  AlphaButtons = { fg = p.fg },
  AlphaShortcut = { fg = p.accent, bold = true },
  AlphaFooter = { fg = p.subtle, italic = true },

  LirDir = { fg = p.blue },
  LirSymLink = { fg = p.cyan, italic = true },
  LirEmptyDirText = { fg = p.subtle },
  LirFloatNormal = { fg = p.fg, bg = p.bg_alt },
  LirFloatBorder = { fg = p.subtle, bg = p.bg_alt },

  MasonHeader = { fg = p.bg, bg = p.magenta_br, bold = true },
  MasonHighlight = { fg = p.cyan },
  MasonHighlightBlock = { fg = p.bg, bg = p.cyan },
  MasonHighlightBlockBold = { fg = p.bg, bg = p.cyan, bold = true },
  MasonMuted = { fg = p.subtle },
  MasonMutedBlock = { fg = p.fg, bg = p.sel },

  NavicText = { fg = p.fg },
  NavicSeparator = { fg = p.subtle },
  NavicIconsFile = { fg = p.blue },
  NavicIconsModule = { fg = p.cyan },
  NavicIconsFunction = { fg = p.blue },
  NavicIconsMethod = { fg = p.blue },
  NavicIconsClass = { fg = p.yellow_br },
  NavicIconsProperty = { fg = p.blue_br },
  NavicIconsField = { fg = p.blue_br },
  NavicIconsVariable = { fg = p.fg },
  NavicIconsConstant = { fg = p.orange },
  NavicIconsKeyword = { fg = p.magenta },

  NotifyERRORBorder = { fg = p.red },
  NotifyWARNBorder = { fg = p.yellow },
  NotifyINFOBorder = { fg = p.blue },
  NotifyDEBUGBorder = { fg = p.subtle },
  NotifyTRACEBorder = { fg = p.magenta },
  NotifyERRORIcon = { fg = p.red },
  NotifyWARNIcon = { fg = p.yellow },
  NotifyINFOIcon = { fg = p.blue },
  NotifyDEBUGIcon = { fg = p.subtle },
  NotifyTRACEIcon = { fg = p.magenta },
  NotifyERRORTitle = { fg = p.red, bold = true },
  NotifyWARNTitle = { fg = p.yellow, bold = true },
  NotifyINFOTitle = { fg = p.blue, bold = true },
  NotifyDEBUGTitle = { fg = p.subtle, bold = true },
  NotifyTRACETitle = { fg = p.magenta, bold = true },

  DapUIVariable = { fg = p.fg },
  DapUIScope = { fg = p.cyan },
  DapUIType = { fg = p.yellow_br },
  DapUIValue = { fg = p.orange },
  DapUIModifiedValue = { fg = p.accent, bold = true },
  DapUIDecoration = { fg = p.subtle },
  DapUIThread = { fg = p.green },
  DapUIStoppedThread = { fg = p.red },
  DapUISource = { fg = p.magenta },
  DapUILineNumber = { fg = p.subtle },
  DapUIFloatBorder = { fg = p.subtle, bg = p.bg_alt },
  DapUIWatchesEmpty = { fg = p.subtle },
  DapUIWatchesValue = { fg = p.green },
  DapUIWatchesError = { fg = p.red },
  DapUIBreakpointsPath = { fg = p.blue },
  DapUIBreakpointsInfo = { fg = p.cyan },
  DapUIBreakpointsCurrentLine = { fg = p.accent, bold = true },
  DapStoppedLine = { bg = p.sel },
}

function M.apply()
  for group, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, group, spec)
  end

  for i, color in ipairs(terminal_colors) do
    vim.g["terminal_color_" .. (i - 1)] = color
  end
end

-- Exposed so config.lua can build a matching lualine theme without reaching
-- back into the palette itself.
M.palette = p

return M
