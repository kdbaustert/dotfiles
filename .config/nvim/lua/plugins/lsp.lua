-- LSP.
--
-- Neovim 0.11 moved server configuration into core: `vim.lsp.config` merges
-- settings into a named config and `vim.lsp.enable` starts it. nvim-lspconfig
-- is still here, but only as the *data* — it ships an `lsp/<name>.lua` per
-- server with the command and root markers — and mason-lspconfig calls
-- `vim.lsp.enable` for whatever mason has installed. So there is no
-- `require("lspconfig").x.setup{}` anywhere below; that form is the old API.

-- Servers are per-language and mostly node-based, so mason manages them here
-- rather than the Brewfile. That is the opposite of the formatter decision in
-- format.lua, and deliberately: formatters are sharp little binaries the shell
-- also wants, language servers are an editor implementation detail.
local servers = {
  "cssls",
  "html",
  "intelephense",
  "jsonls",
  "lua_ls",
  "tailwindcss",
  "ts_ls",
  "vue_ls",
}

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", opts = { ui = { border = "rounded" } } },
      "mason-org/mason-lspconfig.nvim",
      "b0o/schemastore.nvim",
    },
    config = function()
      -- Diagnostics --------------------------------------------------------
      vim.diagnostic.config {
        -- Virtual text on the current line only. Full virtual text turns a
        -- file with a dozen warnings into unreadable soup, but hiding it
        -- entirely means never noticing anything.
        virtual_text = { current_line = true, spacing = 2, prefix = "●" },
        underline = true,
        update_in_insert = false, -- errors mid-keystroke are always wrong
        severity_sort = true,
        float = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
          },
        },
      }

      -- Keymaps ------------------------------------------------------------
      -- Buffer-local, because half of these only mean anything where a server
      -- is actually attached. Neovim 0.11 already provides grn/gra/grr/gri
      -- and K out of the box; these are the additions and the renames.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("configs_lsp_attach", { clear = true }),
        callback = function(args)
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = args.buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "Definition")
          map("gD", vim.lsp.buf.declaration, "Declaration")
          map("gy", vim.lsp.buf.type_definition, "Type definition")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>cs", vim.lsp.buf.document_symbol, "Document symbols")

          local client = vim.lsp.get_client_by_id(args.data.client_id)

          -- Inlay hints are genuinely useful in TypeScript and genuinely
          -- noisy elsewhere, so they are opt-in per buffer rather than on.
          if client and client:supports_method "textDocument/inlayHint" then
            map("<leader>ch", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = args.buf }, { bufnr = args.buf })
            end, "Toggle inlay hints")
          end

          -- Underline the symbol under the cursor. Cheap, and the fastest way
          -- to see every use of a variable without running a search.
          if client and client:supports_method "textDocument/documentHighlight" then
            local hl = vim.api.nvim_create_augroup("configs_lsp_highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              group = hl,
              buffer = args.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              group = hl,
              buffer = args.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      -- Per-server settings ------------------------------------------------
      -- `vim.lsp.config` merges over whatever nvim-lspconfig defines, so only
      -- the differences need stating.

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              -- Teach it the Neovim API, so `vim.` completes and editing this
              -- config is not a wall of undefined-global warnings.
              library = vim.api.nvim_get_runtime_file("", true),
            },
            diagnostics = { globals = { "vim" } },
            format = { enable = false }, -- stylua owns formatting; see format.lua
          },
        },
      })

      vim.lsp.config("jsonls", {
        settings = {
          json = {
            -- SchemaStore gives completion and validation for package.json,
            -- tsconfig, composer.json and friends without hand-listing them.
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      -- Vue 3 runs in "hybrid mode": vue_ls handles the template and ts_ls
      -- handles the script, with a TypeScript plugin bridging them. Without
      -- the plugin, ts_ls sees a .vue file as opaque and every import from one
      -- resolves to `any`. The path is mason's copy of the Vue language
      -- server; the guard keeps ts_ls working for plain TS if it is missing.
      local vue_plugin = vim.fn.stdpath "data"
        .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
      local ts_ls_opts = { filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" } }

      if vim.uv.fs_stat(vue_plugin) then
        ts_ls_opts.filetypes = vim.list_extend(vim.deepcopy(ts_ls_opts.filetypes), { "vue" })
        ts_ls_opts.init_options = {
          plugins = {
            { name = "@vue/typescript-plugin", location = vue_plugin, languages = { "vue" } },
          },
        }
      end

      vim.lsp.config("ts_ls", ts_ls_opts)

      -- mason-lspconfig enables everything mason has installed, which is what
      -- actually starts the servers above.
      require("mason-lspconfig").setup {
        ensure_installed = servers,
        automatic_enable = true,
      }
    end,
  },
}
