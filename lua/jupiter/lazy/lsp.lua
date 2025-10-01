local mason_packages = {
  "lua-language-server",
  "basedpyright",
  "ruff-lsp",
  "rust-analyzer",
  "clangd",
  "dockerfile-language-server",
  "lemminx",
  "bash-language-server",
  "json-lsp",
  "yaml-language-server",
  "html-lsp",
  "css-lsp",
  "typescript-language-server",
  "svelte-language-server",
}

return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = {
      ensure_installed = mason_packages,
    },
    config = function(_, opts)
      local mason = require("mason")
      mason.setup(opts)

      local registry = require("mason-registry")
      for _, tool in ipairs(opts.ensure_installed or {}) do
        local ok, pkg = pcall(registry.get_package, tool)
        if ok and not pkg:is_installed() then
          pkg:install()
        end
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "williamboman/mason.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()

      local defaults = rawget(vim.lsp.config, "*") or {}
      vim.lsp.config("*", vim.tbl_deep_extend("force", {}, defaults, {
        capabilities = vim.tbl_deep_extend("force", {}, defaults.capabilities or {}, cmp_capabilities),
      }))

      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP keymaps",
        callback = function(event)
          local lsp_buf = vim.lsp.buf
          local opts = { buffer = event.buf }

          vim.keymap.set("n", "K", lsp_buf.hover, opts)
          vim.keymap.set("n", "gd", lsp_buf.definition, opts)
          vim.keymap.set("n", "gD", lsp_buf.declaration, opts)
          vim.keymap.set("n", "gi", lsp_buf.implementation, opts)
          vim.keymap.set("n", "go", lsp_buf.type_definition, opts)
          vim.keymap.set("n", "gr", lsp_buf.references, opts)
          vim.keymap.set("n", "gs", lsp_buf.signature_help, opts)
          vim.keymap.set("n", "<F2>", lsp_buf.rename, opts)
          vim.keymap.set({ "n", "x" }, "<F3>", function()
            lsp_buf.format({ async = true })
          end, opts)
          vim.keymap.set("n", "<F4>", lsp_buf.code_action, opts)
        end,
      })

      local server_settings = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
              hint = { enable = true },
            },
          },
        },
        basedpyright = {
          settings = {
            python = {
              analysis = {
                autoImportCompletions = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "basic",
              },
            },
          },
        },
        ruff_lsp = {},
        rust_analyzer = {},
        clangd = {},
        dockerls = {},
        lemminx = {},
        bashls = {},
        jsonls = {},
        yamlls = {},
        html = {},
        cssls = {},
        ts_ls = {},
        svelte = {},
      }

      for server, cfg in pairs(server_settings) do
        if cfg and next(cfg) ~= nil then
          local existing = rawget(vim.lsp.config, server) or {}
          vim.lsp.config(server, vim.tbl_deep_extend("force", {}, existing, cfg))
        end
      end

      vim.lsp.enable(vim.tbl_keys(server_settings))

      cmp.setup({
        sources = {
          { name = "nvim_lsp" },
          { name = "path" },
        },
        snippet = {
          expand = function(args)
            vim.snippet.expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-CR>"] = cmp.mapping.confirm({ select = true }),
        }),
      })
    end,
  },
}
