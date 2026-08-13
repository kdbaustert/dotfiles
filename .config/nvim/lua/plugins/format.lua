-- Formatting and linting.
--
-- conform.nvim + nvim-lint rather than a null-ls-style shim. The difference
-- that matters: neither pretends to be a language server, so a formatter
-- failing is a formatter failing, not a mystery LSP error.
--
-- Every tool named here is one this repo already installs, and neither plugin
-- will fetch anything — prettier/eslint/stylelint come from setup/npm.sh, and
-- stylua/shfmt/shellcheck/php-cs-fixer from the Brewfile. Deliberately not
-- mason: these are sharp little binaries the shell wants anyway, and a copy
-- under ~/.local/share/nvim would vanish with the plugin dir. Language servers
-- go the other way — see the note in lsp.lua.

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format { async = true, lsp_format = "fallback" }
        end,
        mode = { "n", "x" },
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        css = { "prettier" },
        html = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier" },
        -- php-cs-fixer over prettier's PHP plugin: it is PHP-native, it reads
        -- a project's .php-cs-fixer.php, and it is what the Brewfile declares.
        php = { "php_cs_fixer" },
        scss = { "prettier" },
        sh = { "shfmt" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        yaml = { "prettier" },
        zsh = { "shfmt" },
      },

      format_on_save = function(buf)
        -- Nothing here rewrites code, only reformats it, so save-formatting is
        -- safe by default. The two exceptions are escape hatches: a global
        -- toggle for a session spent in someone else's tree, and a buffer
        -- toggle for the one file whose diff you want kept clean.
        if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
          return
        end
        return { timeout_ms = 1000, lsp_format = "fallback" }
      end,

      formatters = {
        shfmt = {
          -- Match .editorconfig and the repo's own scripts: two-space indent,
          -- and indent the bodies of case statements.
          prepend_args = { "-i", "2", "-ci" },
        },
      },
    },
    init = function()
      -- Makes gq use conform, so the manual formatting motion and the on-save
      -- path go through the same tool.
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

      vim.api.nvim_create_user_command("FormatToggle", function(args)
        if args.bang then
          vim.b.disable_autoformat = not vim.b.disable_autoformat
          vim.notify("Buffer autoformat " .. (vim.b.disable_autoformat and "off" or "on"))
        else
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Autoformat " .. (vim.g.disable_autoformat and "off" or "on"))
        end
      end, { desc = "Toggle autoformat (! for buffer only)", bang = true })
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require "lint"

      lint.linters_by_ft = {
        bash = { "shellcheck" },
        css = { "stylelint" },
        javascript = { "eslint" },
        javascriptreact = { "eslint" },
        scss = { "stylelint" },
        sh = { "shellcheck" },
        typescript = { "eslint" },
        typescriptreact = { "eslint" },
        vue = { "eslint" },
      }

      -- Lint on write and on leaving insert, not on every keystroke: these
      -- shell out, and eslint in particular is slow enough to feel.
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufReadPost" }, {
        group = vim.api.nvim_create_augroup("configs_lint", { clear = true }),
        callback = function()
          -- Only run linters whose binary actually exists, so a missing
          -- global (stylelint is not currently installed — see README.MD)
          -- degrades to "no diagnostics" rather than an error per save.
          --
          -- `cmd` is not reliably a string: nvim-lint lets a linter be a
          -- factory function, and eslint's cmd is itself a function so it can
          -- resolve a project's node_modules/.bin before the global. Both have
          -- to be called before there is a path to test.
          local names = lint.linters_by_ft[vim.bo.filetype] or {}
          local runnable = vim.tbl_filter(function(name)
            local ok, linter = pcall(function()
              local l = lint.linters[name]
              return type(l) == "function" and l() or l
            end)
            if not ok or type(linter) ~= "table" then
              return false
            end

            local cmd = linter.cmd or name
            if type(cmd) == "function" then
              ok, cmd = pcall(cmd)
              if not ok then
                return false
              end
            end

            return type(cmd) == "string" and vim.fn.executable(cmd) == 1
          end, names)

          if #runnable > 0 then
            lint.try_lint(runnable)
          end
        end,
      })
    end,
  },
}
