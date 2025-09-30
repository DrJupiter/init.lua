return {
    {
        "williamboman/mason.nvim",
        opts = {
            ui = {
                border = "rounded",
            },
        },
        config = function(_, opts)
            require("mason").setup(opts)
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "williamboman/mason.nvim",
        },
        opts = function(_, opts)
            local ensure = {
                "lua_ls",
                "html",
                "cssls",
                "tailwindcss",
                "emmet_ls",
                "jsonls",
                "yamlls",
                "bashls",
                "dockerls",
                "marksman",
                "basedpyright",
                "ruff_lsp",
                "gopls",
                "rust_analyzer",
                "ts_ls",
                "vue_ls",
                "svelte",
                "terraformls",
            }

            opts = opts or {}
            opts.ensure_installed = opts.ensure_installed or {}

            local present = {}
            for _, server in ipairs(opts.ensure_installed) do
                present[server] = true
            end

            for _, server in ipairs(ensure) do
                if not present[server] then
                    table.insert(opts.ensure_installed, server)
                end
            end

            return opts
        end,
        config = function(_, opts)
            require("mason-lspconfig").setup(opts)
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-path",
            "b0o/SchemaStore.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local cmp = require("cmp")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            vim.diagnostic.config({
                severity_sort = true,
                virtual_text = false,
                float = {
                    border = "rounded",
                    source = "if_many",
                },
            })

            local lsp_group = vim.api.nvim_create_augroup("JupiterLspConfig", { clear = true })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = lsp_group,
                callback = function(event)
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    local function map(mode, lhs, rhs, desc)
                        local opts = { buffer = event.buf, desc = desc }
                        vim.keymap.set(mode, lhs, rhs, opts)
                    end

                    map("n", "K", vim.lsp.buf.hover, "Hover")
                    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
                    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
                    map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
                    map("n", "go", vim.lsp.buf.type_definition, "Go to type definition")
                    map("n", "gr", vim.lsp.buf.references, "Go to references")
                    map("n", "gs", vim.lsp.buf.signature_help, "Signature help")
                    map("n", "<F2>", vim.lsp.buf.rename, "Rename symbol")
                    map("n", "<F4>", vim.lsp.buf.code_action, "Code action")
                    map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
                    map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
                    map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")

                    if client and client.supports_method("textDocument/formatting") then
                        map({ "n", "x" }, "<leader>cf", function()
                            vim.lsp.buf.format({ async = true })
                        end, "Format document")
                    end

                    if client and client.supports_method("textDocument/inlayHint") then
                        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
                    end
                end,
            })

            local schemastore = require("schemastore")

            local util = require("lspconfig.util")

            local servers = {
                lua_ls = {
                    on_init = function(client)
                        local path = client.workspace_folders and client.workspace_folders[1] and client.workspace_folders[1].name
                        if path then
                            if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then
                                return
                            end
                        end

                        client.config.settings = client.config.settings or {}
                        client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
                            runtime = {
                                version = "LuaJIT",
                            },
                            workspace = {
                                checkThirdParty = false,
                                library = vim.api.nvim_get_runtime_file("", true),
                            },
                            diagnostics = {
                                globals = { "vim" },
                            },
                            telemetry = {
                                enable = false,
                            },
                        })
                    end,
                    settings = {
                        Lua = {
                            hint = {
                                enable = true,
                            },
                        },
                    },
                },
                basedpyright = {
                    root_dir = util.root_pattern(
                        "pyproject.toml",
                        "setup.py",
                        "setup.cfg",
                        "requirements.txt",
                        "Pipfile",
                        "pyrightconfig.json",
                        "ruff.toml",
                        ".git"
                    ),
                    settings = {
                        basedpyright = {
                            analysis = {
                                autoImportCompletions = true,
                                autoSearchPaths = true,
                                diagnosticMode = "workspace",
                                typeCheckingMode = "standard",
                                useLibraryCodeForTypes = true,
                            },
                        },
                    },
                },
                ruff_lsp = {
                    init_options = {
                        settings = {
                            args = {},
                        },
                    },
                },
                bashls = {},
                dockerls = {},
                marksman = {},
                html = {},
                cssls = {},
                tailwindcss = {},
                emmet_ls = {},
                jsonls = {
                    settings = {
                        json = {
                            schemas = schemastore.json.schemas(),
                            validate = { enable = true },
                        },
                    },
                },
                yamlls = {
                    settings = {
                        yaml = {
                            schemaStore = {
                                enable = false,
                                url = "",
                            },
                            schemas = schemastore.yaml.schemas(),
                        },
                    },
                },
                gopls = {
                    settings = {
                        gopls = {
                            analyses = {
                                unusedparams = true,
                            },
                            staticcheck = true,
                        },
                    },
                },
                rust_analyzer = {},
                ts_ls = {},
                vue_ls = {},
                svelte = {},
                terraformls = {},
            }

            for name, server in pairs(servers) do
                if server then
                    vim.lsp.config(name, server)
                end
                vim.lsp.enable(name)
            end

            cmp.setup({
                snippet = {
                    expand = function(args)
                        vim.snippet.expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<C-Space>"] = cmp.mapping.complete(),
                }),
                sources = {
                    { name = "nvim_lsp" },
                    { name = "path" },
                },
            })
        end,
    },
}
