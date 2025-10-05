local mason_packages = {
  "lua-language-server",
  "basedpyright",
  "ruff",
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
  "jdtls",
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
        ruff = {},
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
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local uv = vim.uv or vim.loop

      local function setup_jdtls()
        local install_dir = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
        if not uv.fs_stat(install_dir) then
          vim.notify("Mason package 'jdtls' is not installed", vim.log.levels.ERROR)
          return
        end

        local root_markers = {
          "mvnw",
          "gradlew",
          "pom.xml",
          "build.gradle",
          ".git",
        }

        local root_dir = vim.fs.root(0, root_markers)
          or vim.fs.dirname(vim.api.nvim_buf_get_name(0))
        if not root_dir then
          return
        end

        local project_name = vim.fs.basename(root_dir)
        local workspace_dir = vim.fn.stdpath("data") .. "/java-workspaces/" .. project_name

        local jdtls_path = install_dir
        local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
        if launcher_jar == "" then
          vim.notify("Could not find jdtls launcher jar", vim.log.levels.ERROR)
          return
        end

        local os_config
        local sysname = vim.uv.os_uname().sysname
        if sysname == "Darwin" then
          os_config = "config_mac"
        elseif sysname == "Linux" then
          os_config = "config_linux"
        else
          os_config = "config_win"
        end

        local config_dir = jdtls_path .. "/" .. os_config
        local java_cmd = vim.fn.exepath("java")
        if java_cmd == "" then
          vim.notify("Could not find 'java' executable in PATH", vim.log.levels.ERROR)
          return
        end

        local bundles = {}

        local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()
        local capabilities = vim.tbl_deep_extend(
          "force",
          {},
          vim.lsp.protocol.make_client_capabilities(),
          cmp_capabilities
        )

        local jdtls = require("jdtls")
        jdtls.start_or_attach({
          cmd = {
            java_cmd,
            "-Declipse.application=org.eclipse.jdt.ls.core.id1",
            "-Dosgi.bundles.defaultStartLevel=4",
            "-Declipse.product=org.eclipse.jdt.ls.core.product",
            "-Dlog.protocol=true",
            "-Dlog.level=ALL",
            "-Xms1g",
            "-Xmx2g",
            "-jar",
            launcher_jar,
            "-configuration",
            config_dir,
            "-data",
            workspace_dir,
          },
          root_dir = root_dir,
          capabilities = capabilities,
          settings = {
            java = {},
          },
          init_options = {
            bundles = bundles,
          },
        })

        jdtls.setup_dap({ hotcodereplace = "auto" })
        jdtls.setup.add_commands()
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("jupiter-jdtls", { clear = true }),
        pattern = { "java" },
        callback = setup_jdtls,
      })
    end,
  },
}
