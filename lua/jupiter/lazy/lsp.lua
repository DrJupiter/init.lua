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
  "lombok-nightly",
  "spring-boot-tools",
  "openjdk-17",
}

return {
  {
    "mason-org/mason.nvim",
    build = ":MasonUpdate",
    opts = {
      ensure_installed = mason_packages,
      registries = {
        "github:nvim-java/mason-registry",
        "github:mason-org/mason-registry",
      },
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
    "nvim-java/nvim-java",
    lazy = false,
    dependencies = {
      "nvim-java/lua-async-await",
      "nvim-java/nvim-java-refactor",
      "nvim-java/nvim-java-core",
      "nvim-java/nvim-java-test",
      "nvim-java/nvim-java-dap",
      "MunifTanjim/nui.nvim",
      "mfussenegger/nvim-dap",
      { "JavaHello/spring-boot.nvim", commit = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "mason-org/mason.nvim",
      "nvim-java/nvim-java",
    },
    config = function()
      local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
      local lspconfig_configs = lspconfig_ok and rawget(lspconfig, "configs") or nil
      local java_root_markers = {
        "settings.gradle",
        "settings.gradle.kts",
        "build.gradle",
        "build.gradle.kts",
        "gradlew",
        "mvnw",
        "pom.xml",
        "AndroidManifest.xml",
        ".git",
      }

      local has_java, java = pcall(require, "java")
      if has_java then
        if not lspconfig_ok then
          has_java = false
        else
          local ok = pcall(java.setup, {
            root_markers = java_root_markers,
          })
          if not ok then
            has_java = false
          end
        end
      end

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
              or (vim.uv or vim.loop).cwd()
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
              or (vim.uv or vim.loop).cwd()
          end,
        },
      }

      local jdtls_config = {
        filetypes = { "java" },
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
      }

      if not has_java then
        local uv = vim.uv or vim.loop
        jdtls_config.root_dir = function(fname)
          return vim.fs.root(fname, vim.deepcopy(java_root_markers)) or uv.cwd()
        end

        jdtls_config.on_new_config = function(config, root)
          root = root or uv.cwd()
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
        end

        server_settings.jdtls = jdtls_config
      end

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
      elseif lspconfig_ok then
        for server, cfg in pairs(server_settings) do
          if cfg and next(cfg) ~= nil and lspconfig_configs and lspconfig_configs[server] then
            local fallback_cfg = vim.tbl_deep_extend("force", {}, cfg, {
              capabilities = cmp_capabilities,
            })
            lspconfig[server].setup(fallback_cfg)
          end
        end
      end

      if has_java and lspconfig_ok and lspconfig.jdtls then
        local config_with_capabilities = vim.tbl_deep_extend("force", {}, jdtls_config, {
          capabilities = cmp_capabilities,
        })
        lspconfig.jdtls.setup(config_with_capabilities)
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
