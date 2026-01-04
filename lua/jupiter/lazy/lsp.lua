local mason_packages = {
    "lua-language-server",
    "basedpyright",
    "ruff",
    "rust-analyzer",
    -- "clangd", -- Using custom clangd 22+ for better Doxygen support
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

-- TEMPORARY: Custom clangd 22+ for Doxygen comment rendering support
-- Remove this block once Mason ships clangd 22+
local function ensure_clangd_snapshot()
    local install_dir = vim.fn.stdpath("data") .. "/clangd-snapshot"
    local clangd_bin = install_dir .. "/bin/clangd"

    if vim.fn.executable(clangd_bin) == 1 then
        return clangd_bin
    end

    -- Download clangd 22 snapshot (async, non-blocking)
    local url = "https://github.com/clangd/clangd/releases/download/snapshot_20251228/clangd-linux-snapshot_20251228.zip"
    local zip_path = "/tmp/clangd-snapshot.zip"

    vim.notify("Downloading clangd 22 snapshot...", vim.log.levels.INFO)

    vim.fn.jobstart({
        "sh", "-c",
        string.format(
            "curl -sL -o %s %s && unzip -q -o %s -d /tmp && rm -rf %s && mv /tmp/clangd_snapshot_20251228 %s",
            zip_path, url, zip_path, install_dir, install_dir
        )
    }, {
        on_exit = function(_, code)
            if code == 0 then
                vim.notify("clangd 22 snapshot installed! Restart Neovim to use it.", vim.log.levels.INFO)
            else
                vim.notify("Failed to install clangd 22 snapshot", vim.log.levels.ERROR)
            end
        end,
    })

    -- Return nil for now, will be available after restart
    return nil
end

local function get_clangd_cmd()
    local snapshot_bin = ensure_clangd_snapshot()
    if snapshot_bin then
        return { snapshot_bin, "--background-index", "--clang-tidy" }
    end
    -- Fallback to Mason or system clangd
    return { "clangd", "--background-index", "--clang-tidy" }
end

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
                    vim.keymap.set("n", "<leader>rn", lsp_buf.rename, { buffer = event.buf, desc = "LSP rename symbol" })
                    vim.keymap.set({'n','v'}, '<leader>ca', vim.lsp.buf.code_action, {buffer = event.buf, desc='Code action'})
                    vim.keymap.set('n', '<leader>cf', function()
                        vim.lsp.buf.code_action({ apply = true, context = { only = { 'quickfix', 'source.fixAll' } } })
                    end, { desc = 'Apply fix' })
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
                clangd = {
                    cmd = get_clangd_cmd(),
                },
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
