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
  "kotlin-language-server",
  "android-language-server",
  "google-java-format",
  "java-debug-adapter",
  "java-test",
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
      local has_modern_lsp = type(vim.lsp) == "table"
        and type(vim.lsp.enable) == "function"
        and type(vim.lsp.config) == "function"

      if has_modern_lsp then
        local ok, defaults = pcall(vim.lsp.config, "*")
        defaults = ok and defaults or {}
        vim.lsp.config("*", vim.tbl_deep_extend("force", {}, defaults, {
          capabilities = vim.tbl_deep_extend("force", {}, defaults.capabilities or {}, cmp_capabilities),
        }))
      end

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
        jdtls = {
          filetypes = { "java" },
          root_dir = function(fname)
            return vim.fs.root(fname, {
              "gradlew",
              "gradle.properties",
              "settings.gradle",
              "settings.gradle.kts",
              "mvnw",
              "pom.xml",
              "build.gradle",
              "build.gradle.kts",
              ".git",
            })
              or vim.loop.cwd()
          end,
          on_new_config = function(config, root)
            root = root or vim.loop.cwd()
            local registry = require("mason-registry")
            local function jar_glob(pkg_name, pattern)
              local ok, pkg = pcall(registry.get_package, pkg_name)
              if not ok then
                return {}
              end
              local install_dir = pkg:get_install_path()
              return vim.fn.glob(install_dir .. pattern, 0, 1)
            end

            local bundles = {}
            for _, jar in ipairs(jar_glob("java-debug-adapter", "/extension/server/com.microsoft.java.debug.plugin-*.jar")) do
              table.insert(bundles, jar)
            end
            for _, jar in ipairs(jar_glob("java-test", "/extension/server/*.jar")) do
              table.insert(bundles, jar)
            end

            config.cmd = {
              "jdtls",
              "-data",
              string.format("%s/jdtls/%s", vim.fn.stdpath("data"), vim.fn.sha256(root)),
            }
            config.init_options = config.init_options or {}
            config.init_options.bundles = bundles
          end,
          settings = {
            java = {
              format = {
                enabled = true,
                settings = {
                  url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
                  profile = "GoogleStyle",
                },
              },
              saveActions = {
                organizeImports = true,
              },
              completion = {
                favoriteStaticMembers = {
                  "java.util.Objects.requireNonNull",
                  "java.util.Objects.requireNonNullElse",
                  "org.junit.Assert.*",
                },
                filteredTypes = {
                  "com.sun.*",
                  "io.micrometer.shaded.*",
                  "java.awt.*",
                  "jdk.*",
                  "sun.*",
                },
              },
              contentProvider = { preferred = "fernflower" },
              signatureHelp = { enabled = true },
            },
          },
        },
        kotlin_language_server = {
          filetypes = { "kotlin" },
          root_dir = function(fname)
            return vim.fs.root(fname, {
              "settings.gradle",
              "settings.gradle.kts",
              "build.gradle",
              "build.gradle.kts",
              ".git",
            })
              or vim.loop.cwd()
          end,
        },
        android_language_server = {
          filetypes = { "kotlin", "java", "xml" },
          root_dir = function(fname)
            return vim.fs.root(fname, {
              "AndroidManifest.xml",
              "build.gradle",
              "build.gradle.kts",
              ".git",
            })
              or vim.loop.cwd()
          end,
        },
      }

      if has_modern_lsp then
        for server, cfg in pairs(server_settings) do
          if cfg and next(cfg) ~= nil then
            local _, existing = pcall(vim.lsp.config, server)
            existing = existing or {}
            local merged = vim.tbl_deep_extend("force", {}, existing, cfg)
            merged.capabilities = vim.tbl_deep_extend(
              "force",
              {},
              existing.capabilities or {},
              cmp_capabilities,
              cfg.capabilities or {}
            )
            vim.lsp.config(server, merged)
          end
        end

        vim.lsp.enable(vim.tbl_keys(server_settings))
      else
        local ok, lspconfig = pcall(require, "lspconfig")
        if ok then
          for server, cfg in pairs(server_settings) do
            if cfg and next(cfg) ~= nil and lspconfig[server] then
              local fallback_cfg = vim.tbl_deep_extend("force", {}, cfg, {
                capabilities = cmp_capabilities,
              })
              lspconfig[server].setup(fallback_cfg)
            end
          end
        end
      end

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
